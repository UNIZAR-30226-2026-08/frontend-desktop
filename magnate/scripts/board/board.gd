extends Node2D

const DEBUG_MODE: int = 2

@onready var camera_system: MagnateCameraSystem = %CameraSystem
@onready var tile_parent_node: Node2D = %Tiles
@onready var dice_roller_overlay: DiceRollerOverlay = %DiceRollerOverlay 

var tiles: Dictionary[String, Control]
var players: Array[Dictionary] = []
var player_hud: PlayerHUD

var clickable_tile_ids: Array[String] = []
var board_data_list: Array = []

# ==========================================
# VARIABLES DE TRADEO
# ==========================================
var current_trade_overlay: CanvasLayer = null
var _in_trade_selection_mode: bool = false
var _trade_selecting_for_p1: bool = true

const NEW_PROPERTY_OVERLAY = preload("res://scenes/board/overlays/new_property_overlay.tscn")
const FANTASY_OVERLAY = preload("res://scenes/board/overlays/fantasy_overlay.tscn")
const AUCTION_OVERLAY = preload("res://scenes/board/overlays/auction_overlay.tscn")
const RESULTS_AUCTION_OVERLAY = preload("res://scenes/board/overlays/results_auction_overlay.tscn")
const TRADE_OVERLAY = preload("res://scenes/board/overlays/trade_overlay.tscn")

func _ready() -> void:
	# Spawn the board
	tiles = BoardSpawner.spawn_board(tile_parent_node)
	camera_system.init_camera_system(self)
	
	# Conectar los eventos de click de todas las casillas
	for tile_id in tiles:
		var tile_node = tiles[tile_id]
		tile_node.mouse_filter = Control.MOUSE_FILTER_STOP
		tile_node.gui_input.connect(_on_tile_gui_input.bind(tile_id))
	
	var json_path = "res://assets/game_info/board.json"
	_load_board_data(json_path)
	players = PlayerSpawner.spawn_players(self, tiles, json_path)
	
	for player_data in players:
		var token: PlayerToken = player_data["token"]
		token.on_token_clicked.connect(_on_player_token_clicked.bind(player_data))
	
	player_hud = PlayerHUD.new()
	add_child(player_hud)
	player_hud.setup_players(players)
	
	TokenLayoutManager.update_all_token_positions(players, tiles)
	
	# Start playing the board background music
	var music = AudioResource.from_type(Globals.AUDIO_BOARDMUSIC, AudioResource.AudioResourceType.MUSIC)
	AudioSystem.play_audio(music)
	
	# ==========================================
	# MODO DEBUG PARA SIMULAR TIRADA DE DADOS
	# ==========================================
	if DEBUG_MODE == 1:
		if dice_roller_overlay:
			dice_roller_overlay.roll_finished.connect(_on_dice_result_received)
			dice_roller_overlay.show() # Mostramos el overlay esperando tu click para tirar
	
	# ==========================================
	# MODO DEBUG PARA TRADEO
	# ==========================================
	if DEBUG_MODE == 2:
		_run_debug_trade_scenario()

func _load_board_data(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var parsed = JSON.parse_string(file.get_as_text())
		if parsed is Array:
			board_data_list = parsed
		elif parsed is Dictionary and parsed.has("tiles"):
			# Si tu JSON empieza con un objeto { "tiles": [...] }
			board_data_list = parsed["tiles"]

# ==========================================
# LÓGICA DE DADOS
# ==========================================
func _on_dice_result_received(total: int) -> void:
	print("========================================")
	print("🎲 RESULTADO FINAL DE LOS DADOS: ", total)
	print("========================================")
	
	await get_tree().create_timer(1.0).timeout
	dice_roller_overlay.hide_overlay()
	
	# Calculamos el destino del primer jugador
	if players.size() > 0:
		var model: PlayerModel = players[0]["model"]
		var current_id: int = model.current_tile_id.to_int()
		var target_id: int = current_id + total
		
		# OJO: Si tu tablero da la vuelta (ej. 40 casillas), descomenta esta línea y pon el número correcto:
		# target_id = target_id % 40
		
		var target_tile_string: String = "%03d" % target_id
		
		if tiles.has(target_tile_string):
			print("📍 Calculando destino: Iluminando casilla ", target_tile_string)
			prompt_player_tile_selection([target_tile_string])
		else:
			print("⚠️ Error: La casilla destino ", target_tile_string, " no existe en el diccionario.")


# ==========================================
# LÓGICA DE CASILLAS CLICKABLES
# ==========================================
func prompt_player_tile_selection(ids: Array[String]) -> void:
	clickable_tile_ids = ids
	highlight_tiles(ids)
	
	# Cambiamos el cursor para que sepas dónde puedes hacer click
	for id in ids:
		if tiles.has(id):
			tiles[id].mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _on_tile_gui_input(event: InputEvent, tile_id: String) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if tile_id in clickable_tile_ids:
			_on_highlighted_tile_clicked(tile_id)

func _on_highlighted_tile_clicked(tile_id: String) -> void:
	print("👉 Casilla seleccionada por el jugador: ", tile_id)
	reset_tile_highlight() # Apaga las luces y quita el cursor de manita
	
	# --- NUEVO: INTERCEPTOR DE TRADEO ---
	if _in_trade_selection_mode:
		_in_trade_selection_mode = false # Salimos del modo selección
		if current_trade_overlay:
			# Le devolvemos el ID seleccionado al Overlay
			current_trade_overlay.property_selected_from_board(_trade_selecting_for_p1, tile_id)
		return # ⛔ IMPORTANTE: Salimos de la función aquí para no mover al jugador ni abrir overlays
	# ------------------------------------
	
	# --- LÓGICA ORIGINAL DE MOVIMIENTO ---
	if players.size() > 0:
		var model: PlayerModel = players[0]["model"]
		model.move_to_tile(tile_id)
		TokenLayoutManager.update_all_token_positions(players, tiles)
		
		# LLAMAMOS A LA FUNCIÓN MAESTRA EN VEZ DE A _start_new_property
		_open_master_overlay(tile_id)


# ==========================================
# CÓDIGO ORIGINAL MANTENIDO
# ==========================================
func set_tile_owner(tile_id: String, player_color: Color) -> void:
	if not tiles.has(tile_id):
		return
		
	var tile: Control = tiles[tile_id]
	
	for child in tile.get_children():
		if child is OwnerMarker:
			child.queue_free()
			
	var marker = OwnerMarker.new(player_color, tile.size.x)
	marker.position = Vector2(0, tile.size.y)
	tile.add_child(marker)

func _on_player_token_clicked(_clicked_token: PlayerToken, player_data: Dictionary) -> void:
	var model: PlayerModel = player_data["model"]
	
	var current_id: int = model.current_tile_id.to_int()
	var next_id: int = (current_id + 1) 
	var next_tile_string: String = "%03d" % next_id
	
	if tiles.has(next_tile_string):
		model.move_to_tile(next_tile_string)
		set_tile_owner(next_tile_string, model.color)
		TokenLayoutManager.update_all_token_positions(players, tiles)

func highlight_tiles(ids: Array[String]) -> void:
	var tiles_to_darken: Array[String] = []
	for id in tiles.keys():
		if id in ids or not tiles[id]:
			continue
		tiles_to_darken.append(id)
	darken_tiles(tiles_to_darken)

func darken_tiles(ids: Array[String]) -> void:
	var darken_canvas = CanvasGroup.new()
	tile_parent_node.add_child(darken_canvas)
	for id in ids:
		if not tiles.has(id): continue
		tiles[id].reparent(darken_canvas)
	var tween = create_tween()
	var target_color = Color("#666666")
	tween.tween_property(darken_canvas, "self_modulate", target_color, .5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished

func reset_tile_highlight() -> void:
	# Quitamos la manita del cursor de las casillas que estaban iluminadas
	for id in clickable_tile_ids:
		if tiles.has(id):
			tiles[id].mouse_default_cursor_shape = Control.CURSOR_ARROW
			
	clickable_tile_ids.clear()
	
	var darken_canvas = null
	for child in tile_parent_node.get_children():
		if is_instance_of(child, CanvasGroup):
			darken_canvas = child
	if not darken_canvas: return
	
	var tween = create_tween()
	tween.tween_property(darken_canvas, "self_modulate", Color.WHITE, .5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
	for child in darken_canvas.get_children():
		child.reparent(tile_parent_node)
	darken_canvas.queue_free()

# ==========================================
# DIRECTOR DE OVERLAYS (MASTER)
# ==========================================

func _open_master_overlay(tile_id: String) -> void:
	print("Manejando llegada a la casilla: ", tile_id)
	
	# 1. Buscamos los datos de la casilla en el JSON cargado
	var tile_data = {}
	for item in board_data_list:
		if item.get("id", "") == tile_id:
			tile_data = item
			break
			
	if tile_data.is_empty():
		print("⚠️ Error: No se encontraron datos para la casilla ", tile_id)
		return
		
	# 2. Extraemos el tipo
	var tile_type = tile_data.get("type", "")
	print("🔍 Tipo detectado: ", tile_type)
	
	# 3. Redirigimos al overlay correspondiente
	match tile_type:
		"property", "server":
			# Propiedades y servidores comparten el mismo menú de compra/subasta
			_start_new_property(tile_id)
			
		"fantasy":
			_start_fantasy_overlay(tile_id)
			
		"tram":
			_start_tram_overlay(tile_id)
			
		"start":
			_start_go_overlay(tile_id)
			
		"go_to_jail":
			_start_go_to_jail_overlay(tile_id)
			
		"jail":
			_start_jail_overlay(tile_id)
			
		"parking":
			_start_parking_overlay(tile_id)
			
		"bridge":
			_start_bridge_overlay(tile_id)
			
		_: # El guion bajo es el "default"
			print("⚠️ Tipo de casilla desconocido o sin acción programada: ", tile_type)
# ==========================================
# SISTEMA DE OVERLAYS
# ==========================================

func _start_new_property(tile_id: String) -> void:
	print("Abriendo overlay de propiedad para la casilla: ", tile_id)
	
	# Buscamos los datos exactos de esta casilla en el JSON cargado
	var tile_data = {}
	for item in board_data_list:
		if item.get("id", "") == tile_id:
			tile_data = item
			break
			
	if tile_data.is_empty():
		print("⚠️ Error: No se encontraron datos en el JSON para la casilla ", tile_id)
		return
	
	var overlay = NEW_PROPERTY_OVERLAY.instantiate()
	add_child(overlay) 
	overlay.property_bought.connect(_on_property_purchased.bind(tile_id))
	overlay.property_auctioned.connect(_start_auction.bind(tile_id))
	
	# Le pasamos el diccionario completo al overlay
	overlay.abrir_carta(tile_data)

# Esta función se ejecutará automáticamente cuando el overlay emita "property_bought"
func _on_property_purchased(tile_id: String) -> void:
	print("💰 ¡El jugador ha comprado la casilla ", tile_id, "!")
	
	# Aquí meterías la lógica de cobrar el dinero al jugador
	
	# Usamos tu función que ya tenías para ponerle el color del dueño en el tablero
	if players.size() > 0:
		var current_player = players[0]["model"]
		set_tile_owner(tile_id, current_player.color)
		print("✅ Fin del turno.")

func _start_auction(tile_id: String) -> void:
	print("🔨 Empezando subasta para la casilla: ", tile_id)
	
	# Recuperamos los datos de nuevo (o podrías pasarlos por la señal, pero así es seguro)
	var tile_data = {}
	for item in board_data_list:
		if item.get("id", "") == tile_id:
			tile_data = item
			break
			
	if tile_data.is_empty():
		print("⚠️ Error: No se encontraron datos para subastar la casilla ", tile_id)
		return
		
	# Instanciamos el overlay de subasta
	var auction_screen = AUCTION_OVERLAY.instantiate()
	add_child(auction_screen)
	
	auction_screen.auction_finished.connect(_start_finished_auction.bind(tile_id))
	
	# Le inyectamos los datos para que dibuje la carta correctamente
	auction_screen.abrir_carta(tile_data)

func _start_finished_auction(tile_id: String) -> void:
	print("🏆 Subasta terminada. Mostrando resultados para: ", tile_id)
	
	var results_screen = RESULTS_AUCTION_OVERLAY.instantiate()
	add_child(results_screen)
	
	# DATOS SIMULADOS (En el futuro, esto lo calculará tu gestor de red/turnos)
	var final_bids = [
		{"name": "Lucas", "color": Color.RED, "bet": 180},
		{"name": "Cris", "color": Color.BLUE, "bet": 179},
		{"name": "Nic", "color": Color.ORANGE, "bet": 30},
		{"name": "Naud", "color": Color.GREEN, "bet": 10}
	]
	
	# Inyectamos los datos al overlay
	results_screen.mostrar_resultados(final_bids)
	
	# Lógica de juego: El ganador se lleva la casilla (Asumimos que el [0] es el que más pujó)
	var winner_color = final_bids[0]["color"]
	set_tile_owner(tile_id, winner_color)
	print("✅ La propiedad ", tile_id, " ahora pertenece al color ", winner_color)

# Datos temporales para las cartas hasta que tengamos el JSON de Fantasía
var _dummy_fantasy_cards = [
	{"name": "Beca por Excelencia", "description": "Tus notas en Programación son increíbles. Ganas 100€.", "deck_type": "suerte"},
	{"name": "Multa de Biblioteca", "description": "Olvidaste devolver un libro de SQL. Pagas 20€.", "deck_type": "suerte"},
	{"name": "Cafetería Cerrada", "description": "No hay café hoy. Pierdes 10€ buscando otra máquina.", "deck_type": "caja"},
	{"name": "Regalo de Graduación", "description": "Tus abuelos están orgullosos de ti. Ganas 200€.", "deck_type": "caja"}
]


func _start_fantasy_overlay(_tile_id: String) -> void:
	print("✨ Iniciando evento de Fantasía...")
	
	# 1. Instanciar el overlay
	var overlay = FANTASY_OVERLAY.instantiate()
	add_child(overlay)
	
	# 2. Elegir una carta aleatoria del mazo dummy
	var random_card = _dummy_fantasy_cards.pick_random()
	
	# 3. Configurar la carta con los datos (Step 4)
	# Importante: Asegúrate de que FantasyOverlay.gd tenga esta función como vimos antes
	overlay.setup_card(random_card)
	
	# 4. Conectar la señal de cierre
	overlay.card_action_resolved.connect(func(): 
		print("Fin del evento Fantasía. Continuando juego...")
		# Aquí llamarías a tu función de siguiente turno
	)
	
# Función de finalización (Placeholder)
func _on_fantasy_card_resolved(_tile_id: String, _card_data: Dictionary) -> void:
	print("✅ Carta resuelta en ", _tile_id, ". Pasamos turno.")
	# TODO: Aquí va la lógica de cobrar dinero/moverse según card_data["action"]

func _start_tram_overlay(tile_id: String) -> void:
	print("🚋 Has caído en el Tranvía: ", tile_id)
	# TODO: Instanciar overlay de tranvía o aplicar lógica directa (ej: pagar billete o moverse a otro tranvía)

func _start_go_overlay(tile_id: String) -> void:
	print("🏁 Has caído en la Salida: ", tile_id)
	# TODO: Mostrar mensaje de cobrar 200€ o aplicar el dinero directamente si el jugador ya cobró al pasar por encima.

func _start_go_to_jail_overlay(tile_id: String) -> void:
	print("🚨 Has caído en 'Ve a secretaría': ", tile_id)
	# TODO: Mostrar overlay de "¡Pillado!" y mover el token del jugador a la casilla de la cárcel.

func _start_jail_overlay(tile_id: String) -> void:
	print("🔒 Estás de visita en Secretaría: ", tile_id)
	# TODO: Si estás "solo de visita", quizás no hagas nada o muestres un pequeño mensaje. Si estás encarcelado, este turno requeriría pagar fianza o sacar dobles.

func _start_parking_overlay(tile_id: String) -> void:
	print("🅿️ Has caído en el Parking Libre: ", tile_id)
	# TODO: Mostrar mensaje. Si usas la regla de bote, aquí cobrarías el bote del centro del tablero.

func _start_bridge_overlay(tile_id: String) -> void:
	print("🌉 Has cruzado un puente: ", tile_id)
	# TODO: Según tus reglas, los puentes podrían ser solo decorativos, cobrar peaje, o moverte al otro lado del tablero.

# ==========================================
# SISTEMA DE TRADEO
# ==========================================

func _start_trade(p1_name: String, p2_name: String, p1_money: int, p2_money: int, p1_props: Array[Dictionary], p2_props: Array[Dictionary]) -> void:
	print("🤝 Iniciando overlay de tradeo...")
	current_trade_overlay = TRADE_OVERLAY.instantiate()
	add_child(current_trade_overlay)
	
	# Conectamos la señal que emite el TradeOverlay cuando pide iluminar casillas
	current_trade_overlay.request_board_selection.connect(_on_trade_selection_requested)
	
	# Le pasamos los datos iniciales
	current_trade_overlay.setup_trade(p1_name, p2_name, p1_money, p2_money, p1_props, p2_props)

func _on_trade_selection_requested(is_player_1: bool, available_ids: Array) -> void:
	print("🔎 TradeOverlay pide seleccionar casilla. IDs válidos: ", available_ids)
	
	# Activamos el estado de tradeo
	_in_trade_selection_mode = true
	_trade_selecting_for_p1 = is_player_1
	
	# Convertimos el array genérico a Array[String] porque tu función lo exige
	var valid_ids_string: Array[String] = []
	valid_ids_string.assign(available_ids)
	
	# Aprovechamos tu función existente que ya ilumina y pone la manita del ratón
	prompt_player_tile_selection(valid_ids_string)

# ==========================================
# FUNCION DE DEBUG PARA PROBAR LOS TRADEOS
# ==========================================
func _run_debug_trade_scenario() -> void:
	print("🐛 DEBUG MODE: Preparando escenario de tradeo ficticio...")
	
	# Esperamos 1.5 segundos para que la cámara y el tablero terminen de cargar visualmente
	await get_tree().create_timer(1.5).timeout
	
	# Ocultamos los dados si estaban visibles para que no molesten en la prueba
	if dice_roller_overlay:
		dice_roller_overlay.hide()
	
	# IMPORTANTE: Asegúrate de que los "id" coincidan con casillas reales de tu tablero 
	# (por ejemplo, si usas "001", "002" como vi en tu código). 
	# Si pones IDs que no existen, no se iluminarán en el tablero.
	var p1_mock_props: Array[Dictionary] = [
		{"id": "001", "name": "Sala de Estudio A", "color": Color.BROWN},
		{"id": "003", "name": "Laboratorio de Física", "color": Color.BROWN},
		{"id": "006", "name": "Cafetería Central", "color": Color.LIGHT_BLUE}
	]
	
	var p2_mock_props: Array[Dictionary] = [
		{"id": "008", "name": "Biblioteca Norte", "color": Color.PINK},
		{"id": "009", "name": "Aula Magna", "color": Color.PINK}
	]
	
	# Lanzamos el tradeo: Jugador 1 (1500€) vs Jugador 2 (800€)
	_start_trade("Tu Nombre", "Rival Ficticio", 1500, 800, p1_mock_props, p2_mock_props)
