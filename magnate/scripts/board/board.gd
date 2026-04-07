extends Node2D

const DEBUG_MODE: int = 5 # Cambiado a 5 para probar Secretaría

@onready var camera_system: MagnateCameraSystem = %CameraSystem
@onready var tile_parent_node: Node2D = %Tiles
@onready var dice_roller_overlay: DiceRollerOverlay = %DiceRoller
@onready var jail_dice_roller: DiceRollerOverlay = %JailDiceRoller

# TODO: Ya lo siento Nico pero no sé dónde meter esto
const CONTROLS_HUD_SCENE = preload("uid://cp5cmlsncsi6t")
const SETTINGS_OVERLAY_SCENE = preload("uid://d31dwv0u5en1g")
const CHAT_SCENE = preload("uid://bb3relwhb88sa")

# Managers
var tile_manager: MagnateTileManager = MagnateTileManager.new()
var overlay_manager: MagnateOverlayManager = MagnateOverlayManager.new()

var players: Array[Dictionary] = []
var player_hud: PlayerHUD
var controls_hud: ControlsHUD
var chat_hud: CanvasLayer

const TRAM_IDS: Array[String] = ["010", "030", "100", "107"]

# --- Variables de Estado para Cárcel dummy---
var is_in_jail_roll: bool = false
var jail_target_tile: String = "108"
var jail_current_turn: int = 1

func _ready() -> void:
	# Spawn the board
	tile_manager.setup_tiles(tile_parent_node)
	
	# Prepare overlays
	overlay_manager.setup_overlays(self)
	overlay_manager.tram_ok.connect(tile_manager.prompt_tile_selection.bind(TRAM_IDS))
	overlay_manager.trade_selection_request.connect(_on_trade_selection_requested)
	overlay_manager.property_bought.connect(_on_property_purchased)
	overlay_manager.offer_accepted.connect(_on_offer_accepted)
	overlay_manager.offer_rejected.connect(_on_offer_rejected)
	overlay_manager.get_parking_money.connect(tile_manager.parking_money)
	overlay_manager.overlay_open.connect(_on_overlay_open)
	overlay_manager.overlay_closed.connect(_on_overlay_close)

	# Setup camera system
	camera_system.init_camera_system(self)

	# Connect tile click events
	tile_manager.tile_pressed.connect(_on_highlighted_tile_clicked)

	# Setup players
	var json_path = "res://assets/game_info/board.json"
	players = PlayerSpawner.spawn_players(self, tile_manager.tile_entities, json_path)
	
	player_hud = PlayerHUD.new()
	add_child(player_hud)
	player_hud.setup_players(players)
	
	TokenLayoutManager.update_all_token_positions(players, tile_manager.tile_entities)
	
	# Controls
	controls_hud = CONTROLS_HUD_SCENE.instantiate()
	add_child(controls_hud)
	
	controls_hud.open_settings_requested.connect(_on_open_settings_requested)
	controls_hud.roll_dice_requested.connect(_on_hud_roll_requested)
	
	# NUEVO: Conectar señales de Secretaría del overlay_manager
	overlay_manager.jail_roll_requested.connect(_on_jail_roll_requested)
	overlay_manager.jail_stay_confirmed.connect(_on_jail_stay_confirmed)
	overlay_manager.jail_pay_bail_confirmed.connect(_on_jail_pay_bail_confirmed)
	overlay_manager.jail_reselect_requested.connect(_on_jail_reselect_requested)
	
	# Chat
	chat_hud = CHAT_SCENE.instantiate()
	add_child(chat_hud)
	chat_hud.init_chat(players)
	
	# Start playing the board background music
	var music = AudioResource.from_type(Globals.AUDIO_BOARDMUSIC, AudioResource.AudioResourceType.MUSIC)
	AudioSystem.play_audio(music)
	
	# Asegurarnos de que ambos dados están ocultos por defecto
	# Apagamos ambos al arrancar usando nuestra nueva función
	if dice_roller_overlay:
		dice_roller_overlay.hide_overlay()
		if not dice_roller_overlay.roll_finished.is_connected(_on_dice_result_received):
			dice_roller_overlay.roll_finished.connect(_on_dice_result_received)
			
	if jail_dice_roller:
		jail_dice_roller.hide_overlay()
		if not jail_dice_roller.roll_finished.is_connected(_on_dice_result_received):
			jail_dice_roller.roll_finished.connect(_on_dice_result_received)
	
	#  Debug modes
	if DEBUG_MODE == 1 and dice_roller_overlay:
		dice_roller_overlay.roll_finished.connect(_on_dice_result_received)
		dice_roller_overlay.show() # Mostramos el overlay esperando tu click para tirar
	elif DEBUG_MODE == 2:
		_run_debug_trade_scenario()
	elif DEBUG_MODE == 3:
		_run_debug_offer_scenario()
	elif DEBUG_MODE == 4:
		await get_tree().create_timer(2).timeout
		overlay_manager.start_scoreboard_overlay()
	elif DEBUG_MODE == 5:
		_run_debug_jail_scenario() # NUEVO MODO

# Hide the HUD when an overlay opens
func _on_overlay_open() -> void:
	player_hud.toggle_hud_visibility(true)
	controls_hud.toggle_hud_visibility(true)

# Show the HUD when an overlay closes
func _on_overlay_close() -> void:
	player_hud.toggle_hud_visibility(false)
	controls_hud.toggle_hud_visibility(false)

func _on_open_settings_requested() -> void:
	var settings = SETTINGS_OVERLAY_SCENE.instantiate()
	add_child(settings)
	
# Tirada normal
func _on_hud_roll_requested() -> void:
	controls_hud.set_roll_disabled(true)
	
	# 📢 ¡Avisamos para que se oculte la UI!
	overlay_manager.overlay_open.emit()
	
	if jail_dice_roller:
		jail_dice_roller.hide_overlay()
	if dice_roller_overlay:
		dice_roller_overlay.show_overlay()
		
# Tirada de la cárcel
func _on_jail_roll_requested() -> void:
	is_in_jail_roll = true
	
	# 📢 ¡Avisamos para que se oculte la UI!
	overlay_manager.overlay_open.emit()
	
	if dice_roller_overlay:
		dice_roller_overlay.hide_overlay()
	if jail_dice_roller:
		jail_dice_roller.show_overlay()

# ============
#  Dice logic
# ============
func _on_dice_result_received(total: int) -> void:
	Utils.debug("🎲 RESULTADO FINAL: " + str(total))
	
	await get_tree().create_timer(1.0).timeout
	
	# Ocultamos los dados (esto sí se queda aquí)
	if dice_roller_overlay:
		dice_roller_overlay.hide_overlay()
	if jail_dice_roller:
		jail_dice_roller.hide_overlay()
	
	# Seguimos con la lógica
	if is_in_jail_roll:
		_handle_jail_dice_logic()
	else:
		_handle_normal_movement(total)

func _handle_normal_movement(total: int) -> void:
	# overlay_manager.show_banner("¡Turno de ...!", Color("f94144"))
	# overlay_manager.show_toast("Esto es una prueba")
	
	# Get destination
	#if players.size() > 0:
		#var model: PlayerModel = players[0]["model"]
		#var current_id: int = model.current_tile_id.to_int()
		#var target_id: int = current_id + total
		#var target_tile_string: String = "%03d" % target_id
		#tile_manager.prompt_tile_selection([target_tile_string])
		
	# DEBUG
	if players.size() > 0:
		var model: PlayerModel = players[0]["model"]
		var token: PlayerToken = players[0]["token"]
		
		var test_path: Array[String] = ["001", "002", "003"]
		var path_positions: Array[Vector2] = []
		
		for step_id in test_path:
			if tile_manager.tile_entities.has(step_id):
				var step_tile = tile_manager.tile_entities[step_id]
				path_positions.append(step_tile.position + step_tile.pivot_offset)
		
		if not path_positions.is_empty():
			camera_system.follow_node(token, Vector2(2, 2))
			await camera_system.stopped
			await token.move_to(path_positions)
			camera_system.main_camera()
		
		model.move_to_tile("003")
		TokenLayoutManager.update_all_token_positions(players, tile_manager.tile_entities)
		overlay_manager.display_overlay_for_tile("003")
		
		# TODO: Es un poco lío lo del estado global
		var p1_id = players[0]["model"].id
		var p2_id = players[1]["model"].id
		var p3_id = players[2]["model"].id
		chat_hud.add_player_message(p1_id, "Ofrezco el baño de chicas con terraza por 500M!", true)
		chat_hud.add_player_message(p2_id, "Pero vamos a ver, si la ventana está cerrada. Eso no vale nada.", false)
		chat_hud.add_player_message(p3_id, "Que sí, que se puede salir por ahí mientras que no te pille ninguna señora.", false)
		
		await overlay_manager.overlay_closed

func _handle_jail_dice_logic() -> void:
	is_in_jail_roll = false
	# Simulación: El backend nos diría si hubo par. 
	var is_pair = false
	
	if is_pair:
		Utils.debug("✨ ¡DOUBLES! Sales de Secretaría gratis.")
		overlay_manager.show_toast("¡Has sacado par! Sales libre.")
		_on_jail_pay_bail_confirmed() # Reutilizamos la lógica de movernos al destino
	else:
		Utils.debug("🚫 No hubo par. Debes elegir: Quedarte o Pagar.")
		# Iluminamos la cárcel (ID "010" por ejemplo) y el destino
		tile_manager.prompt_tile_selection(["104", jail_target_tile])

# ================
#  Input handlers
# ================
func _on_highlighted_tile_clicked(tile_id: String) -> void:
	Utils.debug("👉 Casilla seleccionada por el jugador: " + tile_id)
	
	# Si estamos en modo cárcel y el jugador hace clic:
	if tile_id == "104": # ID de la Cárcel
		overlay_manager.show_jail_stay_decision(jail_current_turn, 3)
		return
	elif tile_id == jail_target_tile:
		overlay_manager.show_jail_pay_decision(50)
		return
	
	if overlay_manager.in_trade_selection_mode:
		overlay_manager.in_trade_selection_mode = false
		if overlay_manager.current_trade_overlay:
			overlay_manager.current_trade_overlay.property_selected_from_board(
				overlay_manager.trade_selecting_for_p1,
				tile_id
			)
		return
	
	# --- LÓGICA ORIGINAL DE MOVIMIENTO ---
	if players.size() > 0:
		var model: PlayerModel = players[0]["model"]
		model.move_to_tile(tile_id)
		TokenLayoutManager.update_all_token_positions(players, tile_manager.tile_entities)

func _on_property_purchased(tile_id: String, color: Variant) -> void:
	Utils.debug("💰 ¡El jugador ha comprado la casilla " + tile_id)
	if color == null:
		var current_player = players[0]["model"]
		tile_manager.set_tile_owner(tile_id, current_player.color)
	else:
		tile_manager.set_tile_owner(tile_id, color)
	Utils.debug("✅ Fin del turno.")

func _on_trade_selection_requested(is_player_1: bool, available_ids: Array) -> void:	
	# Set the trade state to active
	overlay_manager.in_trade_selection_mode = true
	overlay_manager.trade_selecting_for_p1 = is_player_1
	
	# Data conversion Array -> Array[String]
	var valid_ids_string: Array[String] = []
	valid_ids_string.assign(available_ids)
	
	# Highlight tiles
	tile_manager.prompt_tile_selection(valid_ids_string)
	
func _on_offer_accepted() -> void:
	Utils.debug("🤝 BOARD: El intercambio ha sido ACEPTADO. Ejecutando lógica de transferencia de bienes...")
	# Aquí en el futuro harás que el tile_manager cambie los dueños de las propiedades y restes el dinero.

func _on_offer_rejected() -> void:
	Utils.debug("❌ BOARD: El intercambio ha sido RECHAZADO. Fin del turno.")

# ==========================================
# FUNCION DE DEBUG PARA PROBAR LOS TRADEOS
# ==========================================
func _run_debug_trade_scenario() -> void:
	Utils.debug("🐛 DEBUG MODE: Preparando escenario de tradeo ficticio...")
	
	# Esperamos 1.5 segundos para que la cámara y el tablero terminen de cargar visualmente
	await get_tree().create_timer(1.5).timeout
	
	# Ocultamos los dados si estaban visibles para que no molesten en la prueba
	if dice_roller_overlay:
		dice_roller_overlay.hide()

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
	overlay_manager._start_trade("Tu Nombre", "Rival Ficticio", 1500, 800, p1_mock_props, p2_mock_props)
	
# ==========================================
# FUNCION DE DEBUG PARA PROBAR LA OFERTA DE TRADEO
# ==========================================
func _run_debug_offer_scenario() -> void:
	Utils.debug("🐛 DEBUG MODE 3: Preparando escenario de PROPUESTA de trato...")
	
	await get_tree().create_timer(1.5).timeout
	
	if dice_roller_overlay:
		dice_roller_overlay.hide()

	# Simulamos los datos que habrían salido del panel de tradeo anterior
	var left_data = {
		"name": "TÚ",
		"color": Color("f2b705"), # Amarillo
		"money_offered": 20,
		"properties": [
			{"name": "CIRCE", "color": Color("3b82f6")},
			{"name": "LABORATORIO DE FÍSICA Y ELECTRÓNICA", "color": Color("7c3aed")},
			{"name": "SALÓN DE ACTOS TORRES Q.", "color": Color("7c3aed")},
			{"name": "BAÑO DE CHICAS CON TERRAZA", "color": Color("3b82f6")},
			{"name": "BAÑO DE CHICAS CON TERRAZA", "color": Color("3b82f6")},
			{"name": "BAÑO DE CHICAS CON TERRAZA", "color": Color("3b82f6")}
		]
	}

	var right_data = {
		"name": "PLAYER 1",
		"color": Color("ef4444"), # Rojo
		"money_offered": 500,
		"properties": [
			{"name": "LAB 0.05B", "color": Color("475569")},
			{"name": "MICROONDAS BETANCOURT", "color": Color("22c55e")}
		]
	}
	
	# Llamamos a la función que creaste en tu overlay_manager.gd
	overlay_manager.start_offer(left_data, right_data)

# ==========================================
# GESTIÓN DE SEÑALES DE SECRETARÍA
# ==========================================

func _on_jail_stay_confirmed() -> void:
	Utils.debug("🔒 El jugador decide quedarse en Secretaría.")
	tile_manager.reset_tile_highlight() # Limpiamos el tablero
	overlay_manager.show_toast("Turno terminado en Secretaría.")

func _on_jail_pay_bail_confirmed() -> void:
	Utils.debug("💰 Fianza pagada o Salida por par. Moviendo a " + jail_target_tile)
	tile_manager.reset_tile_highlight()
	
	if players.size() > 0:
		var model: PlayerModel = players[0]["model"]
		model.move_to_tile(jail_target_tile)
		TokenLayoutManager.update_all_token_positions(players, tile_manager.tile_entities)
		overlay_manager.display_overlay_for_tile(jail_target_tile)

func _on_jail_reselect_requested() -> void:
	# Simplemente volvemos a iluminar las casillas para que el jugador elija
	tile_manager.prompt_tile_selection(["104", jail_target_tile])

# ==========================================
# ESCENARIO DE DEBUG 5: SECRETARÍA
# ==========================================
func _run_debug_jail_scenario() -> void:
	Utils.debug("🐛 DEBUG MODE 5: Iniciando flujo de Secretaría...")
	await get_tree().create_timer(1.5).timeout
	
	if dice_roller_overlay:
		dice_roller_overlay.hide()
	
	# Simulamos que es nuestro turno y estamos en la cárcel
	# (Asegúrate de que la ID coincide con la de tu JSON para la cárcel)
	jail_current_turn = 1
	overlay_manager.show_jail_initial_warning(jail_current_turn, 3)
