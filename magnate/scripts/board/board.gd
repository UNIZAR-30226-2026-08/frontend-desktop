extends Node2D

const DEBUG_MODE: int = 1

@onready var camera_system: MagnateCameraSystem = %CameraSystem
@onready var tile_parent_node: Node2D = %Tiles
@onready var dice_roller_overlay: DiceRollerOverlay = %DiceRoller

# TODO: Ya lo siento Nico pero no sé dónde meter esto
const CONTROLS_HUD_SCENE = preload("uid://cp5cmlsncsi6t")
const SETTINGS_OVERLAY_SCENE = preload("uid://d31dwv0u5en1g")

# Managers
var tile_manager: MagnateTileManager = MagnateTileManager.new()
var overlay_manager: MagnateOverlayManager = MagnateOverlayManager.new()

var players: Array[Dictionary] = []
var player_hud: PlayerHUD
var controls_hud: ControlsHUD

const TRAM_IDS: Array[String] = ["010", "030", "100", "107"]

func _ready() -> void:
	# Spawn the board
	tile_manager.setup_tiles(tile_parent_node)
	
	# Prepare overlays
	overlay_manager.setup_overlays(self)
	overlay_manager.tram_ok.connect(tile_manager.prompt_tile_selection.bind(TRAM_IDS))
	overlay_manager.trade_selection_request.connect(_on_trade_selection_requested)
	overlay_manager.property_bought.connect(_on_property_purchased)

	# Setup camera system
	camera_system.init_camera_system(self)

	# Connect tile click events
	tile_manager.connect("tile_pressed", _on_highlighted_tile_clicked)

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
	
	# Start playing the board background music
	var music = AudioResource.from_type(Globals.AUDIO_BOARDMUSIC, AudioResource.AudioResourceType.MUSIC)
	AudioSystem.play_audio(music)
	
	#  Debug modes
	if DEBUG_MODE == 1 and dice_roller_overlay:
		dice_roller_overlay.roll_finished.connect(_on_dice_result_received)
		dice_roller_overlay.show() # Mostramos el overlay esperando tu click para tirar
	elif DEBUG_MODE == 2:
		_run_debug_trade_scenario()
		
		
func _on_open_settings_requested() -> void:
	var settings = SETTINGS_OVERLAY_SCENE.instantiate()
	add_child(settings)
	
func _on_hud_roll_requested() -> void:
	controls_hud.set_roll_disabled(true)
	
	if dice_roller_overlay:
		dice_roller_overlay.show()

# ============
#  Dice logic
# ============
func _on_dice_result_received(total: int) -> void:
	Utils.debug("🎲 RESULTADO FINAL DE LOS DADOS: " + str(total))
	
	await get_tree().create_timer(1.0).timeout
	dice_roller_overlay.hide_overlay()
	
	player_hud.toggle_hud_visibility(true)
	controls_hud.toggle_hud_visibility(true)
	
	overlay_manager.show_banner("¡Turno de ...!", Color("f94144"))
	overlay_manager.show_toast("Esto es una prueba")
	
	# Get destination
	if players.size() > 0:
		var model: PlayerModel = players[0]["model"]
		var current_id: int = model.current_tile_id.to_int()
		var target_id: int = current_id + total
		var target_tile_string: String = "%03d" % target_id
		tile_manager.prompt_tile_selection([target_tile_string])

# ================
#  Input handlers
# ================
func _on_highlighted_tile_clicked(tile_id: String) -> void:
	Utils.debug("👉 Casilla seleccionada por el jugador: " + tile_id)

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
		
		overlay_manager.display_overlay_for_tile(tile_id)

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
