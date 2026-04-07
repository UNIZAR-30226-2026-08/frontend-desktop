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

# common signals
signal overlay_closed
signal overlay_open

# specific signals
signal trade_selection_request
signal tram_ok
signal property_bought(String, Variant) # tile id + color (null if current players color)
signal offer_accepted
signal offer_rejected
signal get_parking_money

# specific signals (debajo de las que ya tienes)
signal jail_roll_requested
signal jail_stay_confirmed
signal jail_pay_bail_confirmed
signal jail_reselect_requested

var board: Node2D
var tile_data: Dictionary
var current_trade_overlay: CanvasLayer = null
var in_trade_selection_mode: bool = false
var trade_selecting_for_p1: bool = true

# Messages
var toast_instance: CanvasLayer = null
var banner_instance: CanvasLayer = null

# Overlays
const AUCTION_OVERLAY = preload("uid://s5i6upd25o0y")
const FANTASY_OVERLAY = preload("uid://blvke57w4belm")
const NEW_PROPERTY_OVERLAY = preload("uid://bormjc5jqq80j")
const RESULTS_AUCTION_OVERLAY = preload("uid://by8ymobr7asbh")
const TRAM_OVERLAY = preload("uid://63e2qbbi7ye3")
const TRADE_OVERLAY = preload("uid://b1ddwdjk7emik")
const OFFER_OVERLAY = preload("uid://cx4al1avjtxqc")
const SECRETARY_ANIMATION = preload("uid://b1bn1f5bjievo")
const PARKING_OVERLAY = preload("uid://br42lbhn0hqum")
const SCOREBOARD_OVERLAY = preload("uid://njtmnh67mrt5")
const PROPERTY_ADMINISTRATION_OVERLAY = preload("uid://cptx3705we74j")
const MORTGAGE_OVERLAY = preload("uid://iip2p7fd0k63")
const PAY_RENT_OVERLAY = preload("uid://bme7v8a58kf1h")
const JAIL_DECISION_OVERLAY = preload("uid://bmk83o1g8rbb8")

const BANNER_MESSAGE = preload("uid://g1ccyk0arbkf")
const TOAST_MESSAGE = preload("uid://dj0br3kdrndit")

func setup_overlays(_board: Node2D) -> void:
	board = _board
	tile_data = BoardDefinitionParser.parse_board("res://assets/game_info/board.json")
	banner_instance = BANNER_MESSAGE.instantiate()
	board.add_child(banner_instance)
	toast_instance = TOAST_MESSAGE.instantiate()
	board.add_child(toast_instance)
#	_load_board_data()

func show_banner(message: String, bg_color: Color = Color("008a5c"), duration: float = 2.5) -> void:
	if banner_instance:
		overlay_open.emit()
		banner_instance.show_banner(message, bg_color, duration)
		
func show_toast(message: String, duration: float = 3.0) -> void:
	if toast_instance:
		toast_instance.show_toast(message, duration)

func display_overlay_for_tile(tile_id: String) -> void:
	overlay_open.emit()
	Utils.debug("Manejando llegada a la casilla: " + tile_id)

	# 1. Look for the tile
	var current_tile = tile_data[tile_id]
	if current_tile.is_empty():
		Utils.debug("⚠️ Error: No se encontraron datos para la casilla " + tile_id)
		return

	# 2. Get tile type
	var tile_type = current_tile["type"]

	# 3. Call the overlay handler
	var handlers: Dictionary[Globals.TileType, Callable] = {
		Globals.TileType.PROPERTY: _start_new_property.bind(tile_id),
		Globals.TileType.SERVER: _start_new_property.bind(tile_id),
		Globals.TileType.FANTASY: _start_fantasy_overlay.bind(tile_id),
		Globals.TileType.GO_TO_JAIL: _start_go_to_jail_overlay.bind(tile_id),
		Globals.TileType.JAIL: _start_jail_overlay.bind(tile_id),
		Globals.TileType.PARKING: _start_parking_overlay.bind(tile_id),
		Globals.TileType.BRIDGE: _start_bridge_overlay.bind(tile_id),
		Globals.TileType.TRAM: _start_tram_overlay
	}
	if handlers.has(tile_type):
		handlers[tile_type].call()
	else:
		Utils.debug("⚠️ Tipo de casilla desconocido o sin acción programada: " + tile_type)

func _start_new_property(tile_id: String) -> void:
	Utils.debug("Abriendo overlay de propiedad para la casilla: " + tile_id)
	
	# Look for the tile
	var current_tile = tile_data.get(tile_id, {})
			
	if current_tile.is_empty():
		Utils.debug("⚠️ Error: No se encontraron datos en el JSON para la casilla " + tile_id)
		return
	
	# Initialize the overlay
	var overlay = NEW_PROPERTY_OVERLAY.instantiate()
	board.add_child(overlay)
	overlay.property_bought.connect(property_bought.emit.bind(tile_id, null))
	overlay.property_bought.connect(overlay_closed.emit)
	overlay.property_auctioned.connect(_start_auction.bind(tile_id))
	overlay.abrir_carta(current_tile)

func _start_property_administration(tile_id: String) -> void:
	Utils.debug("Abriendo overlay de propiedad para la casilla: " + tile_id)
	
	# Look for the tile
	var current_tile = tile_data.get(tile_id, {})
			
	if current_tile.is_empty():
		Utils.debug("⚠️ Error: No se encontraron datos en el JSON para la casilla " + tile_id)
		return
	
	# Initialize the overlay
	var overlay = PROPERTY_ADMINISTRATION_OVERLAY.instantiate()
	board.add_child(overlay)

func _start_property_with_mortgage(tile_id: String) -> void:
	Utils.debug("Abriendo overlay de propiedad para la casilla: " + tile_id)
	
	# Look for the tile
	var current_tile = tile_data.get(tile_id, {})
			
	if current_tile.is_empty():
		Utils.debug("⚠️ Error: No se encontraron datos en el JSON para la casilla " + tile_id)
		return
	
	# Initialize the overlay
	var overlay = MORTGAGE_OVERLAY.instantiate()
	board.add_child(overlay)

func _start_pay_rent(tile_id: String) -> void:
	Utils.debug("Abriendo overlay de propiedad para la casilla: " + tile_id)
	
	# Look for the tile
	var current_tile = tile_data.get(tile_id, {})
			
	if current_tile.is_empty():
		Utils.debug("⚠️ Error: No se encontraron datos en el JSON para la casilla " + tile_id)
		return
	
	# Initialize the overlay
	var overlay = PAY_RENT_OVERLAY.instantiate()
	board.add_child(overlay)

func _start_auction(tile_id: String) -> void:
	Utils.debug("🔨 Empezando subasta para la casilla: " + tile_id)
	
	# Look for the tile
	var current_tile = tile_data.get(tile_id, {})
			
	if current_tile.is_empty():
		Utils.debug("⚠️ Error: No se encontraron datos para subastar la casilla " + tile_id)
		return
		
	# Initialize the overlay
	var auction_screen = AUCTION_OVERLAY.instantiate()
	board.add_child(auction_screen)
	auction_screen.auction_finished.connect(_start_finished_auction.bind(tile_id))
	auction_screen.abrir_carta(current_tile)

func _start_finished_auction(tile_id: String) -> void:
	Utils.debug("🏆 Subasta terminada. Mostrando resultados para: " + tile_id)
	
	var results_screen = RESULTS_AUCTION_OVERLAY.instantiate()
	board.add_child(results_screen)
	
	# Show results
	results_screen.mostrar_resultados(final_bids)
	
	# Winner is at the top (index 0)
	var winner_name = final_bids[0]["name"]
	var winner_color = final_bids[0]["color"]
	property_bought.emit(tile_id, winner_color)
	results_screen.finished.connect(overlay_closed.emit)
	Utils.debug("✅ La propiedad " + tile_id + " ahora pertenece a " + winner_name)

func _start_fantasy_overlay(_tile_id: String) -> void:
	Utils.debug("✨ Iniciando evento de Fantasía...")
	
	# 1. Instantiate the overlay
	var overlay = FANTASY_OVERLAY.instantiate()
	board.add_child(overlay)
	
	# 2. choose a random card from mock data
	var random_card = _dummy_fantasy_cards.pick_random()
	
	# 3. Setup overlay with card data
	overlay.setup_card(random_card)
	overlay.card_action_resolved.connect(overlay_closed.emit)
	
	# 4. Log final event
	overlay.card_action_resolved.connect(func(): Utils.debug("Fin del evento Fantasía. Continuando juego..."))

func _start_tram_overlay() -> void:
	Utils.debug("✨ Iniciando tranvía...")
	var overlay = TRAM_OVERLAY.instantiate()
	board.add_child(overlay)
	overlay.button_pressed.connect(tram_ok.emit)
	# overlay.button_pressed.connect(overlay_closed.emit)

func _start_go_to_jail_overlay(tile_id: String) -> void:
	# Dejo el icono pero xd
	Utils.debug("🚨 Has caído en 'Ve a secretaría': " + tile_id)
	
	var overlay = SECRETARY_ANIMATION.instantiate()
	board.add_child(overlay)
	
	overlay.animation_complete.connect(func():
		Utils.debug("Termina animación de secretaría")
		overlay.queue_free()
	)
	overlay.animation_complete.connect(overlay_closed.emit)
	
	overlay.play_animation()

func _start_jail_overlay(tile_id: String) -> void:
	Utils.debug("🔒 Estás de visita en Secretaría: " + tile_id)

func _start_parking_overlay(tile_id: String) -> void:
	Utils.debug("🅿️ Has caído en el Parking Libre: " + tile_id)
	var overlay = PARKING_OVERLAY.instantiate()
	board.add_child(overlay)
	overlay.button_pressed.connect(overlay_closed.emit)
	overlay.button_pressed.connect(get_parking_money.emit)

# TODO: Remeber to emit overlay_closed at the end
func _start_bridge_overlay(tile_id: String) -> void:
	Utils.debug("🌉 Has cruzado un puente: " + tile_id)

# TODO: Remeber to emit overlay_closed at the end
func _start_trade(p1_name: String, p2_name: String, p1_money: int, p2_money: int, p1_props: Array[Dictionary], p2_props: Array[Dictionary]) -> void:
	Utils.debug("🤝 Iniciando overlay de tradeo...")
	current_trade_overlay = TRADE_OVERLAY.instantiate()
	board.add_child(current_trade_overlay)
	
	# Propagate signal
	current_trade_overlay.request_board_selection.connect(trade_selection_request.emit)
	
	# Initialize overlay with data
	current_trade_overlay.setup_trade(p1_name, p2_name, p1_money, p2_money, p1_props, p2_props)

func start_scoreboard_overlay() -> void:
	var current_overlay = SCOREBOARD_OVERLAY.instantiate()
	board.add_child(current_overlay)

func start_offer(left_data: Dictionary, right_data: Dictionary) -> void:
	Utils.debug("⚖️ Mostrando propuesta de trato...")
	
	# 1. Instanciamos el overlay
	var overlay = OFFER_OVERLAY.instantiate()
	board.add_child(overlay)
	
	# 2. Conectamos las señales del overlay hacia nuestro manager
	# Usamos funciones anónimas (func) para poder hacer un print de debug y emitir la señal a la vez
	overlay.offer_accepted.connect(func():
		offer_accepted.emit()
		Utils.debug("✅ Trato aceptado por el jugador")
	)
	overlay.offer_accepted.connect(overlay_closed.emit)
	
	overlay.offer_rejected.connect(func():
		offer_rejected.emit()
		Utils.debug("❌ Trato rechazado por el jugador")
	)
	overlay.offer_rejected.connect(overlay_closed.emit)
	
	# 3. Le pasamos los datos para que dibuje la interfaz
	overlay.setup_offer(left_data, right_data)
	
# ==========================================
# LÓGICA DE SECRETARÍA / CÁRCEL
# ==========================================

func show_jail_initial_warning(turn: int, max_turns: int = 3) -> void:
	Utils.debug("🚨 Mostrando advertencia inicial de Secretaría...")
	var overlay = JAIL_DECISION_OVERLAY.instantiate()
	board.add_child(overlay)
	overlay.setup_initial(turn, max_turns)
	
	# Al darle a "Tirar Dados", avisamos al board y destruimos este pop-up específico
	overlay.primary_action.connect(func():
		jail_roll_requested.emit()
		overlay.queue_free() # Destruimos la ventanita de la cárcel visualmente
		# (Y ya no emitimos overlay_closed, de eso se encargará el board cuando muevas la ficha)
	)
	overlay_open.emit()

func show_jail_stay_decision(turn: int, max_turns: int = 3) -> void:
	Utils.debug("🔒 Jugador hizo clic en Secretaría. Mostrando confirmación...")
	var overlay = JAIL_DECISION_OVERLAY.instantiate()
	board.add_child(overlay)
	overlay.setup_jail_selected(turn, max_turns)
	
	overlay.primary_action.connect(func():
		jail_stay_confirmed.emit()
		overlay_closed.emit()
	)
	overlay.secondary_action.connect(func():
		jail_reselect_requested.emit()
		# Aquí no emitimos overlay_closed porque sigue en la fase de elegir
	)
	overlay_open.emit()

func show_jail_pay_decision(bail_price: int = 50) -> void:
	Utils.debug("💸 Jugador hizo clic en otra casilla. Mostrando pago de fianza...")
	var overlay = JAIL_DECISION_OVERLAY.instantiate()
	board.add_child(overlay)
	overlay.setup_pay_bail(bail_price)
	
	overlay.primary_action.connect(func():
		jail_pay_bail_confirmed.emit()
		overlay.queue_free() # ✅ Destruimos el menú visualmente sin devolver el HUD
	)
	overlay.secondary_action.connect(func():
		jail_reselect_requested.emit()
	)
	overlay_open.emit()
