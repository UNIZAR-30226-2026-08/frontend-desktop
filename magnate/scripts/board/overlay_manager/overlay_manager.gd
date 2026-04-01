class_name MagnateOverlayManager
extends RefCounted

#  ===== MOCK DATA, CAN BE DELETED FOR RELEASE =====
var final_bids = [
	{"name": "Lucas", "color": Color.RED, "bet": 180},
	{"name": "Cris", "color": Color.BLUE, "bet": 179},
	{"name": "Nic", "color": Color.ORANGE, "bet": 30},
	{"name": "Naud", "color": Color.GREEN, "bet": 10}
]
var _dummy_fantasy_cards = [
	{"name": "Beca por Excelencia", "description": "Tus notas en Programación son increíbles. Ganas 100€."},
	{"name": "Multa de Biblioteca", "description": "Olvidaste devolver un libro de SQL. Pagas 20€."},
	{"name": "Cafetería Cerrada", "description": "No hay café hoy. Pierdes 10€ buscando otra máquina."},
	{"name": "Regalo de Graduación", "description": "Tus abuelos están orgullosos de ti. Ganas 200€."}
]
# ================ END OF MOCK DATA ================

signal trade_selection_request
signal tram_ok
signal property_bought(String, Variant) # tile id + color (null if current players color)

var board: Node2D
var board_data_list: Array = []
var current_trade_overlay: CanvasLayer = null
var in_trade_selection_mode: bool = false
var trade_selecting_for_p1: bool = true

# Overlays
const AUCTION_OVERLAY = preload("uid://s5i6upd25o0y")
const FANTASY_OVERLAY = preload("uid://blvke57w4belm")
const NEW_PROPERTY_OVERLAY = preload("uid://bormjc5jqq80j")
const RESULTS_AUCTION_OVERLAY = preload("uid://by8ymobr7asbh")
const TRAM_OVERLAY = preload("uid://63e2qbbi7ye3")
const TRADE_OVERLAY = preload("uid://b1ddwdjk7emik")

func _load_board_data() -> void:
	var file = FileAccess.open("res://assets/game_info/board.json", FileAccess.READ)
	if file:
		var parsed = JSON.parse_string(file.get_as_text())
		if parsed is Array:
			board_data_list = parsed
		elif parsed is Dictionary and parsed.has("tiles"):
			board_data_list = parsed["tiles"]

func setup_overlays(_board: Node2D) -> void:
	board = _board
	_load_board_data()

func display_overlay_for_tile(tile_id: String) -> void:
	Utils.debug("Manejando llegada a la casilla: " + tile_id)

	# 1. Buscamos los datos de la casilla en el JSON cargado
	var tile_data = {}
	for item in board_data_list:
		if item.get("id", "") == tile_id:
			tile_data = item
			break

	if tile_data.is_empty():
		Utils.debug("⚠️ Error: No se encontraron datos para la casilla " + tile_id)
		return

	# 2. Extraemos el tipo
	var tile_type = tile_data.get("type", "")
	Utils.debug("🔍 Tipo detectado: " + tile_type)

	# 3. Call the overlay handler
	var handlers: Dictionary[String, Callable] = {
		"property" = _start_new_property.bind(tile_id),
		"server" = _start_new_property.bind(tile_id),
		"fantasy" = _start_fantasy_overlay.bind(tile_id),
		"go_to_jail" = _start_go_to_jail_overlay.bind(tile_id),
		"jail" = _start_jail_overlay.bind(tile_id),
		"parking" = _start_parking_overlay.bind(tile_id),
		"bridge" = _start_bridge_overlay.bind(tile_id),
		"tram" = _start_tram_overlay
	}
	if handlers.has(tile_type):
		handlers[tile_type].call()
	else:
		Utils.debug("⚠️ Tipo de casilla desconocido o sin acción programada: " + tile_type)

func _start_new_property(tile_id: String) -> void:
	Utils.debug("Abriendo overlay de propiedad para la casilla: " + tile_id)
	
	# Buscamos los datos exactos de esta casilla en el JSON cargado
	var tile_data = {}
	for item in board_data_list:
		if item.get("id", "") == tile_id:
			tile_data = item
			break
			
	if tile_data.is_empty():
		Utils.debug("⚠️ Error: No se encontraron datos en el JSON para la casilla " + tile_id)
		return
	
	var overlay = NEW_PROPERTY_OVERLAY.instantiate()
	board.add_child(overlay)
	overlay.property_bought.connect(
		property_bought.emit.bind(tile_id, null)
		# _on_property_purchased.bind(tile_id)
	)
	overlay.property_auctioned.connect(_start_auction.bind(tile_id))
	
	# Le pasamos el diccionario completo al overlay
	overlay.abrir_carta(tile_data)

func _start_auction(tile_id: String) -> void:
	Utils.debug("🔨 Empezando subasta para la casilla: " + tile_id)
	
	# Recuperamos los datos de nuevo (o podrías pasarlos por la señal, pero así es seguro)
	var tile_data = {}
	for item in board_data_list:
		if item.get("id", "") == tile_id:
			tile_data = item
			break
			
	if tile_data.is_empty():
		Utils.debug("⚠️ Error: No se encontraron datos para subastar la casilla " + tile_id)
		return
		
	# Instanciamos el overlay de subasta
	var auction_screen = AUCTION_OVERLAY.instantiate()
	board.add_child(auction_screen)
	
	auction_screen.auction_finished.connect(_start_finished_auction.bind(tile_id))
	
	# Le inyectamos los datos para que dibuje la carta correctamente
	auction_screen.abrir_carta(tile_data)

func _start_finished_auction(tile_id: String) -> void:
	Utils.debug("🏆 Subasta terminada. Mostrando resultados para: " + tile_id)
	
	var results_screen = RESULTS_AUCTION_OVERLAY.instantiate()
	board.add_child(results_screen)
	
	# Show results
	results_screen.mostrar_resultados(final_bids)
	
	# Winner is at the top (index 0)
	var winner_color = final_bids[0]["color"]
	property_bought.emit(tile_id, winner_color)
	# tile_manager.set_tile_owner(tile_id, winner_color)
	Utils.debug("✅ La propiedad " + tile_id + " ahora pertenece al color " + winner_color)

func _start_fantasy_overlay(_tile_id: String) -> void:
	Utils.debug("✨ Iniciando evento de Fantasía...")
	
	# 1. Instanciar el overlay
	var overlay = FANTASY_OVERLAY.instantiate()
	board.add_child(overlay)
	
	# 2. Elegir una carta aleatoria del mazo dummy
	var random_card = _dummy_fantasy_cards.pick_random()
	
	# 3. Configurar la carta con los datos (Step 4)
	# Importante: Asegúrate de que FantasyOverlay.gd tenga esta función como vimos antes
	overlay.setup_card(random_card)
	
	# 4. Conectar la señal de cierre
	overlay.card_action_resolved.connect(func(): 
		Utils.debug("Fin del evento Fantasía. Continuando juego...")
		# Aquí llamarías a tu función de siguiente turno
	)

func _start_tram_overlay() -> void:
	Utils.debug("✨ Iniciando tranvía...")
	var overlay = TRAM_OVERLAY.instantiate()
	board.add_child(overlay)
	overlay.button_pressed.connect(tram_ok.emit)

func _start_go_to_jail_overlay(tile_id: String) -> void:
	Utils.debug("🚨 Has caído en 'Ve a secretaría': " + tile_id)

func _start_jail_overlay(tile_id: String) -> void:
	Utils.debug("🔒 Estás de visita en Secretaría: " + tile_id)

func _start_parking_overlay(tile_id: String) -> void:
	Utils.debug("🅿️ Has caído en el Parking Libre: " + tile_id)

func _start_bridge_overlay(tile_id: String) -> void:
	Utils.debug("🌉 Has cruzado un puente: " + tile_id)

func _start_trade(p1_name: String, p2_name: String, p1_money: int, p2_money: int, p1_props: Array[Dictionary], p2_props: Array[Dictionary]) -> void:
	Utils.debug("🤝 Iniciando overlay de tradeo...")
	current_trade_overlay = TRADE_OVERLAY.instantiate()
	board.add_child(current_trade_overlay)
	
	# Conectamos la señal que emite el TradeOverlay cuando pide iluminar casillas
	current_trade_overlay.request_board_selection.connect(trade_selection_request.emit)
	# current_trade_overlay.request_board_selection.connect(_on_trade_selection_requested)
	
	# Le pasamos los datos iniciales
	current_trade_overlay.setup_trade(p1_name, p2_name, p1_money, p2_money, p1_props, p2_props)
