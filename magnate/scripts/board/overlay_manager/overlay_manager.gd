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
signal property_houses_changed(tile_id: String, new_houses: int, final_mortgage: bool)

# jail signals
signal jail_roll_requested
signal jail_stay_confirmed
signal jail_pay_bail_confirmed
signal jail_reselect_requested

# train signals
signal tram_travel_confirmed(target_tile_id: String, cost: int)
signal tram_travel_cancelled()

# HUD signals
signal normal_roll_requested
signal request_admin_selection

var board: Node2D
var tile_data: Dictionary
var current_trade_overlay: CanvasLayer = null
var in_trade_selection_mode: bool = false
var trade_selecting_for_p1: bool = true

# messages
var toast_instance: CanvasLayer = null
var banner_instance: CanvasLayer = null

# HUD
var controls_hud: ControlsHUD
var chat_hud: CanvasLayer
var player_hud: PlayerHUD

# trade
var is_selecting_trade_target: bool = false
var trade_selection_instance: Node = null

# Menu principal
const HOME_PAGE = preload("uid://d2twidlaag5qv")

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
const CONTROLS_HUD_SCENE = preload("uid://cp5cmlsncsi6t")
const SETTINGS_OVERLAY_SCENE = preload("uid://d31dwv0u5en1g")
const CHAT_SCENE = preload("uid://bb3relwhb88sa")
const SURRENDER_OVERLAY = preload("uid://r7wff0p1ra5x")
const TRADE_SELECTION_OVERLAY = preload("uid://cf7vsw1q85viu")
const TRAIN_SELECTION_OVERLAY = preload("uid://dbleh2dgxratm")

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
		Globals.TileType.BRIDGE: _start_new_property.bind(tile_id),
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
	
	# 👇 LA MAGIA OCURRE AQUÍ 👇
	# Obtenemos los datos desde el manager de nuestro board
	var manager = board.model_manager
	var current_player_id = manager.get_current_turn_player_id()
	var current_houses = manager.get_property_houses(tile_id)
	
	board.add_child(overlay)
	
	# Le pasamos los 5 parámetros que configuramos en tu script del overlay
	overlay.setup(current_tile, current_houses, tile_id, current_player_id, manager)
	
	overlay.administration_confirmed.connect(func(final_houses: int, final_mortgage: bool):
		property_houses_changed.emit(tile_id, final_houses, final_mortgage)
	)
	
	overlay.tree_exited.connect(func():
		if player_hud:
			player_hud.toggle_hud_visibility(false)
		if controls_hud:
			controls_hud.show()
			
		overlay_closed.emit()
	)

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

func _start_trade(p1_name: String, p2_name: String, p1_money: int, p2_money: int, p1_props: Array[Dictionary], p2_props: Array[Dictionary]) -> void:
	Utils.debug("🤝 Iniciando overlay de tradeo...")
	current_trade_overlay = TRADE_OVERLAY.instantiate()
	board.add_child(current_trade_overlay)
	
	# Propagar señales de selección del tablero
	current_trade_overlay.request_board_selection.connect(trade_selection_request.emit)
	
	# 👇 NUEVO: Qué hacer si cancela
	current_trade_overlay.trade_cancelled.connect(func():
		Utils.debug("🚫 Tradeo cancelado. Cerrando menú...")
		current_trade_overlay.queue_free()
		current_trade_overlay = null
		overlay_closed.emit() # Magia: vuelven los HUDs normales
	)
	
	# 👇 NUEVO: Qué hacer si envía (de momento lo mismo)
	current_trade_overlay.offer_sent.connect(func():
		Utils.debug("📤 Oferta enviada al backend (mock). Cerrando menú...")
		
		# TODO: En el futuro aquí cogerás los diccionarios y emitirás algo hacia el servidor
		
		current_trade_overlay.queue_free()
		current_trade_overlay = null
		overlay_closed.emit() # Magia: vuelven los HUDs normales
	)
	
	# Inicializar overlay con datos
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

# ==========================================
# GESTIÓN DE HUDS PRINCIPALES Y CHAT
# ==========================================

func setup_huds(players_data: Array) -> void:
	# 1. Inicializar PlayerHUD (La barra de los jugadores)
	player_hud = PlayerHUD.new()
	board.add_child(player_hud)
	player_hud.setup_players(players_data)
	
	# 2. Inicializar Controles (Dados, ajustes...)
	controls_hud = CONTROLS_HUD_SCENE.instantiate()
	board.add_child(controls_hud)
	controls_hud.open_settings_requested.connect(_open_settings)
	controls_hud.roll_dice_requested.connect(func(): normal_roll_requested.emit())
	controls_hud.bankrupt_requested.connect(_start_surrender_overlay)
	controls_hud.trade_requested.connect(_start_trade_target_selection)
	controls_hud.admin_requested.connect(func(): request_admin_selection.emit())
	player_hud.player_selected.connect(_on_trade_target_selected)
	
	# 3. Inicializar Chat
	chat_hud = CHAT_SCENE.instantiate()
	board.add_child(chat_hud)
	chat_hud.init_chat(players_data)

	# 4. GESTIÓN AUTOMÁTICA DE VISIBILIDAD
	overlay_open.connect(func():
		if not is_selecting_trade_target:
			player_hud.toggle_hud_visibility(true)
		controls_hud.toggle_hud_visibility(true)
	)
	
	# Cuando se cierra, los volvemos a mostrar
	overlay_closed.connect(func():
		player_hud.toggle_hud_visibility(false)
		controls_hud.toggle_hud_visibility(false)
	)

func _open_settings() -> void:
	var settings = SETTINGS_OVERLAY_SCENE.instantiate()
	board.add_child(settings)

func set_roll_disabled(disabled: bool) -> void:
	if controls_hud:
		controls_hud.set_roll_disabled(disabled)

func add_chat_message(player_id: String, msg: String, is_important: bool = false) -> void:
	if chat_hud:
		chat_hud.add_player_message(player_id, msg, is_important)

func _start_surrender_overlay() -> void:
	Utils.debug("🏳️ Abriendo overlay de rendición...")
	overlay_open.emit() 
	
	var overlay = SURRENDER_OVERLAY.instantiate()
	board.add_child(overlay)
	
	# Si se arrepiente:
	overlay.cancel_surrender.connect(func():
		Utils.debug("🔙 Botón cancelar pulsado. Destruyendo overlay...")
		overlay.queue_free() # Esto es lo que lo destruye
		overlay_closed.emit() # Esto devuelve el HUD
	)
	
	# Si confirma salir:
	overlay.exit_game_confirmed.connect(func():
		Utils.debug("🏠 Botón salir pulsado. Cambiando escena...")
		
		board.get_tree().change_scene_to_packed(HOME_PAGE)
		
	)

# ==========================================
# GESTIÓN DE TRADEOS
# ==========================================

func _start_trade_target_selection() -> void:
	Utils.debug("🔍 Entrando en modo selección de jugador para tradeo...")
	
	# 👇 AÑADE ESTO PARA VER LOS IDs EXISTENTES
	print("👀 IDs de las tarjetas actuales: ", player_hud.cards.keys())
	
	is_selecting_trade_target = true
	overlay_open.emit() 
	
	var my_local_id = "0001" # (Luego cambiaremos esto por el que veas en la consola)
	player_hud.set_selection_mode(true, my_local_id)
	
	trade_selection_instance = TRADE_SELECTION_OVERLAY.instantiate()
	board.add_child(trade_selection_instance)
	
	trade_selection_instance.cancel_selection.connect(_cancel_trade_selection)

func _cancel_trade_selection() -> void:
	Utils.debug("🚫 Selección de tradeo cancelada.")
	is_selecting_trade_target = false
	player_hud.set_selection_mode(false)
	
	if trade_selection_instance:
		trade_selection_instance.queue_free()
		trade_selection_instance = null
		
	overlay_closed.emit() # Devuelve los controles a la pantalla

func _on_trade_target_selected(target_id: String) -> void:
	# Ignoramos clics si no estamos en modo selección
	if not is_selecting_trade_target: return
	
	Utils.debug("🤝 ¡Jugador " + target_id + " seleccionado!")
	
	# Limpiamos el overlay de selección sin emitir overlay_closed 
	# para que el fondo siga borroso para el tradeo
	is_selecting_trade_target = false
	player_hud.set_selection_mode(false)
	player_hud.toggle_hud_visibility(true) # Ahora sí ocultamos las tarjetas
	
	if trade_selection_instance:
		trade_selection_instance.queue_free()
		trade_selection_instance = null
	
	# TODO: Aquí debes obtener los datos reales del jugador en el futuro
	#var p1_props: Array[Dictionary] = []
	#var p2_props: Array[Dictionary] = []
	
	var p1_props: Array[Dictionary] = [
		{"id": "001", "name": "Microondas Ada Byron", "color": "#FC5C65"},
		{"id": "003", "name": "Microondas Betancourt", "color": "#FC5C65"}
	]
	var p2_props: Array[Dictionary] = [
		{"id": "005", "name": "Pilgor", "color": Color.GRAY}
	]
	
	# Llamamos a tu función existente de tradeo (con datos de prueba de momento)
	_start_trade("TÚ", "JUGADOR #" + target_id.right(4), 1500, 800, p1_props, p2_props)

# ==========================================
# GESTIÓN DE TRANVIA
# ==========================================

func show_tram_selection(target_tile_id: String, current_tile_id: String, tile_name: String) -> void:
	# 1. Creamos la instancia del overlay a partir de tu constante
	var overlay = TRAIN_SELECTION_OVERLAY.instantiate()
	
	# 2. Conectamos las señales ANTES de añadirlo al árbol de nodos
	# (Estas son las señales que definiste en tram_turn_overlay.gd)
	overlay.confirm_travel.connect(_on_tram_travel_confirmed)
	overlay.cancel_travel.connect(_on_tram_travel_cancelled)
	
	# 3. Lo añadimos a la pantalla para que el jugador lo vea
	board.add_child(overlay)
	
	# 4. Le pasamos los datos para que actualice sus textos
	print(target_tile_id)
	print(current_tile_id)
	var is_same_station = (target_tile_id == current_tile_id)
	overlay.setup_tram_selection(target_tile_id, is_same_station, tile_name)

# ==========================================
# 🎧 RECEPTORES DE LAS SEÑALES DEL OVERLAY
# ==========================================

func _on_tram_travel_confirmed(target_tile_id: String, cost: int) -> void:
	# El overlay ya ha hecho queue_free() por su cuenta, así que solo 
	# tenemos que avisar al tablero de lo que ha decidido el jugador.
	tram_travel_confirmed.emit(target_tile_id, cost)

func _on_tram_travel_cancelled() -> void:
	# Igual que arriba, avisamos al tablero de que se ha cancelado
	tram_travel_cancelled.emit()
