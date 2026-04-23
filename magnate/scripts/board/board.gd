extends Node2D

const DEBUG_MODE: int = 0

# Variables de Escenas de Godot
@onready var camera_system: MagnateCameraSystem = %CameraSystem
@onready var tile_parent_node: Node2D = %Tiles

# Managers
var tile_manager: MagnateTileManager = MagnateTileManager.new()
var overlay_manager: MagnateOverlayManager = MagnateOverlayManager.new()

const TRAM_IDS: Array[String] = ["010", "030", "100", "107"]

# --- Variables de Estado para indicar si estoy eligiendo casilla en administración---
var is_selecting_for_admin: bool = false
var is_selecting_for_train: bool = false

# =======
#  READY
# =======
func _ready() -> void:
	WsClient.start_client_game()
	await _setup_game_data()
	
	tile_manager.setup_tiles(tile_parent_node)
	PlayerSpawner.spawn_players(self, tile_manager.tile_entities)
	TokenLayoutManager.update_all_token_positions(ModelManager.game.players.values(), tile_manager.tile_entities)
	
	var music = AudioResource.from_type(Globals.AUDIO_BOARDMUSIC, AudioResource.AudioResourceType.MUSIC)
	AudioSystem.play_audio(music)
	
	camera_system.init_camera_system(self)
	
	overlay_manager.setup_overlays(self, %DiceRoller, %JailDiceRoller)
	overlay_manager.setup_huds(ModelManager.game.players.values())
	
	_start_turn()
	
	_connect_all_signals()
	
	# 5. Modo Debug
	# _begin_debug(DEBUG_MODE)

# ===========================
#  SETUP DE DATOS DE PARTIDA
# ===========================
func _setup_game_data() -> void:
	var game_state = await WsClient.game_state
	if game_state == {}: return

	await ModelManager.initialize_game(game_state)
	
	Utils.debug("💾 ModelManager inicializado con las reglas cargadas desde JSON")

# ===================
#  SIGNAL CONNECTION
# ===================
func _connect_all_signals() -> void:
	
	if not ModelManager.property_updated.is_connected(_on_model_property_updated):
		ModelManager.property_updated.connect(_on_model_property_updated)
	
	# Señales Generales del Overlay Manager
	overlay_manager.tram_ok.connect(_on_tram_ok_received)
	overlay_manager.tram_travel_confirmed.connect(_on_tram_travel_confirmed)
	overlay_manager.tram_travel_cancelled.connect(_on_tram_travel_cancelled)
	overlay_manager.trade_selection_request.connect(_on_trade_selection_requested)
	overlay_manager.offer_accepted.connect(_on_offer_accepted)
	overlay_manager.offer_rejected.connect(_on_offer_rejected)
	overlay_manager.get_parking_money.connect(tile_manager.parking_money)
	overlay_manager.property_houses_changed.connect(_on_property_houses_changed)
	
	# Señales de Controles (Dados normales)
	overlay_manager.request_admin_selection.connect(_on_admin_selection_requested)
	
	# Señales de Secretaría (Cárcel)
	overlay_manager.jail_roll_requested.connect(_on_jail_roll_requested)
	
	# Normal dice
	overlay_manager.dice_roller_overlay.roll_finished.connect(_on_dice_result_received)
	
	# WS Response connections
	WsClient.response_choose_square.connect(_on_choose_square_received)
	WsClient.response_general.connect(_handle_general_response)
	WsClient.response_auction.connect(_handle_end_auction)
	WsClient.response_bonus.connect(_handle_end_game)
	
	# WS Action connections
	WsClient.action_buy_square.connect(_on_property_purchased)
	WsClient.action_start_auction.connect(_handle_start_auction)
	WsClient.action_surrender.connect(_handle_surrender)
	WsClient.action_trade_proposal.connect(_handle_trade_proposal)
	WsClient.action_trade_answer.connect(_handle_trade_answer)
	
	# ------ LOS DE AQUI ABAJO YA ESTÁN MEDIO CONECTADOS ------ #
	
	# CONEXION CON EL TILE MANAGER
	tile_manager.tile_pressed.connect(_on_highlighted_tile_clicked)
	
	# CONEXIONES A LOS OVERLAYS DE DADOS (NO LOS GESTIONA EL OVERLAY MANAGER)
	overlay_manager.jail_dice_roller.roll_finished.connect(_on_dice_result_received) # DONE 1
	
	# CONEXIONES RELACIONADAS CON LA CARCEL
	# CONECTADOS A NIVEL 1
	overlay_manager.jail_stay_confirmed.connect(_on_jail_stay_confirmed)
	overlay_manager.jail_pay_bail_confirmed.connect(_on_jail_pay_bail_confirmed)
	overlay_manager.jail_reselect_requested.connect(_on_jail_reselect_requested) 

func _handle_general_response(data: Dictionary) -> void:
	if data == {}: return
	# Update the model
	var new_turn = ModelManager.game.current_turn_player_id != data["active_turn_player"]
	ModelManager.game.current_turn_player_id = data["active_turn_player"]
	var new_phase = ModelManager.game.current_phase != data["phase"]
	ModelManager.game.current_phase = data["phase"]
	for pk in data["money"]:
		ModelManager.set_player_balance(int(pk), data["money"][pk])
	if data["type"] == "Response":
		for pk in data["positions"]:
			var path = tile_manager.solve_path([data["positions"][pk]])
			ModelManager.update_player_position(int(pk), data["positions"][pk], path)
	# Dispatch action
	if new_turn: _start_turn()
	if new_phase: _start_phase()

func _start_turn() -> void:
	overlay_manager.automatic_control_visibility = false
	overlay_manager.controls_hud.toggle_hud_visibility(true)
	var text = "Tu turno"
	var player = ModelManager.get_player(ModelManager.get_current_turn_player_id())
	if not ModelManager.is_my_turn():
		text = "Turno de " + player.player_name
	overlay_manager.show_banner(text, player.color)

func _start_phase() -> void:
	match ModelManager.game.current_phase:
		WsClient.Phase.ROLL_THE_DICES:
			overlay_manager.show_dice_overlay()
		WsClient.Phase.BUSINESS:
			overlay_manager.show_controls_now.emit()

# ================
#  LOGIC HANDLERS
# ================
func _handle_start_auction(response: Dictionary) -> void:
	if !ModelManager.is_my_turn(): overlay_manager.start_auction(response)

func _handle_end_auction(response: Dictionary) -> void:
	overlay_manager.start_finished_auction(response)
	if response["auction"]["is_tie"]: return
	var auction = response["auction"]
	for bid in auction["bids"]:
		ModelManager.update_player_balance(int(bid), -auction["bids"][bid])
	ModelManager.set_property_owner(auction["square"], response["auction"]["winner"])

func _handle_surrender(action: Dictionary) -> void:
	ModelManager.set_player_surrender(action["player"])

func _handle_trade_proposal(action: Dictionary) -> void:
	ModelManager.game.trade_p1_id = action["player"]
	ModelManager.game.trade_p2_id = action["destination_user"]
	ModelManager.game.trade_p1_properties = action["offered_properties"]
	ModelManager.game.trade_p2_properties = action["asked_properties"]
	if action["destination_user"] != ModelManager.game.my_id: return
	var left_data = {
		"name": "TÚ",
		"color": ModelManager.get_player().color,
		"money_offered": action["asked_money"],
		"properties": ModelManager.solve_properties(action["asked_properties"])
	}
	var right_data = {
		"name": ModelManager.get_player(action["player"]).player_name,
		"color": ModelManager.get_player(action["player"]).color,
		"money_offered": action["offered_money"],
		"properties": ModelManager.solve_properties(action["offered_properties"])
	}
	overlay_manager.start_offer(left_data, right_data)

func _handle_trade_answer(action: Dictionary) -> void:
	if action["choose"]:
		for property_id in ModelManager.game.trade_p1_properties:
			ModelManager.set_property_owner(property_id, ModelManager.game.trade_p2_id)
		for property_id in ModelManager.game.trade_p2_properties:
			ModelManager.set_property_owner(property_id, ModelManager.game.trade_p1_id)
	overlay_manager.show_controls_when_possible()
	ModelManager.game.trade_p1_id = -1
	ModelManager.game.trade_p2_id = -1
	ModelManager.game.trade_p1_properties = []
	ModelManager.game.trade_p2_properties = []

func _handle_end_game(response: Dictionary) -> void:
	overlay_manager.start_scoreboard_overlay(response)
	WsClient.socket.close()

# ============
#  MODO DEBUG
# ============
func _begin_debug(mode: int) -> void:
	if mode == 0:
		return # Juego normal, no hacemos nada de debug
		
	Utils.debug("🔧 Ejecutando Modo Debug: " + str(mode))
	
	if mode == 1:
		_run_debug_jail_scenario()

# ============
#  DICE LOGIC
# ============
# Devolución por parte del Overlay Manager de los dados
func _on_dice_result_received(result: Dictionary) -> void:
	# 1. EXTRAEMOS EL GAME_MODEL Y EL PLAYER_MODEL QUE HA TIRADO PARA UTILIZAR LA INFORMACIÓN 
	var game = ModelManager.game
	var current_player: PlayerModel = ModelManager.get_player(game.current_turn_player_id)
	
	# 3. LÓGICA DE DADOS (PARA EL USUARIO QUE LOS HA LANZADO)
	if ModelManager.is_my_turn():
		if current_player.is_in_jail: 
			#_handle_jail_dice_logic()
			pass
		else:
			# Jugador ha sacado dobles 3 veces
			if result.streak == 3:
				# TODO mensaje de has sacado dobles 3 veces: Yendo a la cárcel
				# Al mandarlo a la casilla de ir a la cárcel, ya sale la animación de ir a la cárcel
				_handle_normal_movement(false, current_player.id, result.path)
				overlay_manager.overlay_closed.emit()
			elif len(result.destinations) > 1:
				tile_manager.prompt_tile_selection(result.destinations)
			# Jugador se mueve automáticamente
			else:
				_handle_normal_movement(true, current_player.id, result.path)
				overlay_manager.overlay_closed.emit()
	# 4. LÓGICA DE DADOS (PARA EL RESTO DE USUARIOS)
	else:
		if current_player.is_in_jail: 
			#_handle_jail_dice_logic()
			pass
		elif result.streak == 3:
			_handle_normal_movement(false, current_player.id, result.path)
		elif len(result.destinations) == 1:
			_handle_normal_movement(true, current_player.id, result.path)

# Tirada desde la cárcel #TODO
func _on_jail_roll_requested() -> void:
	#is_in_jail_roll = true
	
	# 📢 ¡Avisamos para que se oculte la UI!
	overlay_manager.overlay_open.emit()
	
	overlay_manager.dice_roller_overlay.hide_overlay()
	overlay_manager.jail_dice_roller.show_overlay()

# ================
#  MOVEMENT LOGIC
# ================
# Función que actualiza el movimieneto del player a su destino en GAME_MODEL
func _handle_normal_movement(animation: bool, player_id: int, path: Array[String]) -> void:
	var current_token = ModelManager.get_player(player_id).token
	
	if animation:
		var path_positions = tile_manager.solve_path(path.slice(1))
		if not path_positions.is_empty():
			overlay_manager.player_hud.toggle_hud_visibility(true)
			camera_system.follow_node(current_token, Vector2(2, 2))
			await camera_system.stopped
			ModelManager.update_player_position(player_id, path[-1], path_positions)
			await current_token.stopped
			camera_system.main_camera()
			await camera_system.stopped
			overlay_manager.player_hud.toggle_hud_visibility(false)
	else:
		var step_tile = tile_manager.tile_entities[path[-1]]
		ModelManager.update_player_position(player_id, path[-1], [step_tile.position + step_tile.pivot_offset])
		
	TokenLayoutManager.update_all_token_positions(ModelManager.game.players.values(), tile_manager.tile_entities)
	if ModelManager.is_my_turn():
		overlay_manager.display_overlay_for_tile(path[-1])

# RESPONSE - JUGADOR ACTUAL HA SELECCIONADO CASILLA PARA MOVERSE
func _on_choose_square_received(data: Dictionary) -> void:
	# game.fantasy_event: FantasyEvent = data["fantasy_event"]
	# movemos al player actual a la posición elegida
	_handle_normal_movement(true, ModelManager.get_current_turn_player_id(), data["path"])
	
# ==============================================================================================================================================
#  HANDLER DE CLIQUEAR EN UNA CASILLA -> Hay que avisar al back
# ==============================================================================================================================================
func _on_highlighted_tile_clicked(tile_id: String) -> void:
	overlay_manager.overlay_closed.emit()
	var game = ModelManager.game
	var current_player = ModelManager.get_player(game.current_turn_player_id)
	
	#TODO
	if is_selecting_for_admin:
		is_selecting_for_admin = false # Apagamos el modo
		tile_manager.reset_tile_highlight() # Limpiamos las luces del tablero
		
		# Abrimos el menú pasándole el ID que acabamos de tocar
		overlay_manager._start_property_administration(tile_id) 
		return # Cortamos la función aquí para que no mueva la ficha
	
	# El player está eligiendo casilla desde la cárcel
	elif current_player.is_in_jail:
		# Player elige quedarse en la cárcel un turno más
		if tile_id == game.important_tiles["jail"]:
			overlay_manager.show_jail_stay_decision(current_player.jail_turn_count, 3)
			return
		# Player selecciona la casilla para pagar el bail
		else:
			overlay_manager.show_jail_pay_decision(50)
			return
	
	#TODO
	elif overlay_manager.in_trade_selection_mode:
		overlay_manager.in_trade_selection_mode = false
		if overlay_manager.current_trade_overlay:
			overlay_manager.current_trade_overlay.property_selected_from_board(
				overlay_manager.trade_selecting_for_p1,
				tile_id
			)
		return
	
	#TODO
	elif is_selecting_for_train:
		_handle_tram_selection(tile_id)
		return
	
	# LOGICA DE SELECCIONAR CASILLA ESTÁNDAR: ENVIAR ACTION DE LA CASILLA SELECCIONADA
	else:
		WsClient.ws_action_move_to(tile_id)

# ==========================================
# GESTIÓN DE SEÑALES DE SECRETARÍA
# ==========================================
# Jugador confirma que se queda en la cárcel un turno más 
func _on_jail_stay_confirmed() -> void:
	tile_manager.reset_tile_highlight() # Limpiamos el tablero
	overlay_manager.show_toast("Turno terminado en Secretaría.")
	
	# TODO Fase de administrar cosas, mostrar UI si somos el jugador actual

# Jugador confirma que paga la fianza para moverse
func _on_jail_pay_bail_confirmed() -> void:
	tile_manager.reset_tile_highlight()
	# Mandamos la action de haber pagado la fianza
	WsClient.ws_action_pay_bail()
	# TODO FALTA CAPTURAR EL ACTION QUE BROADCASTEA EL BACK PARA MOVER AL JUGADOR

#TODO
func _on_jail_reselect_requested() -> void:
	# Simplemente volvemos a iluminar las casillas para que el jugador elija
	#tile_manager.prompt_tile_selection(["104", jail_target_tile])
	pass

func _on_admin_selection_requested() -> void:
	Utils.debug("🛠️ Entrando en modo selección para administrar propiedades...")
	is_selecting_for_admin = true
	
	if overlay_manager.player_hud:
		overlay_manager.player_hud.toggle_hud_visibility(true) 
	if overlay_manager.controls_hud:
		overlay_manager.controls_hud.hide() 
	
	# 👇 1. Sacamos quién está jugando ahora mismo PRIMERO
	var current_player_id = ModelManager.get_current_turn_player_id()
	
	# 👇 2. Hardcodeamos propiedades para ese jugador
	# (Asegúrate de poner aquí los IDs de TODAS las casillas que formen 
	# un grupo/color en tu board.json, o los botones no se verán)
	ModelManager.set_property_owner("001", current_player_id)
	ModelManager.set_property_owner("003", current_player_id)
	ModelManager.set_property_owner("006", current_player_id)
	
	# 👇 3. Le pedimos al manager las propiedades REALES de ese jugador
	var mis_propiedades_ids: Array[String] = ModelManager.get_player(current_player_id).owned_properties
	
	# Y se las pasamos a tu tile_manager para que las resalte
	tile_manager.prompt_tile_selection(mis_propiedades_ids)


# ESTASS SON UNA GUARRADA GOOOOORDA PARA QUE FUNCIONE LO DE DAR CLICK FUERA DE LA PANTALLA PARA CANCELAR
# LA SELECCION
func _input(event: InputEvent) -> void:
	if is_selecting_for_admin and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Esperamos al final del frame. Si el clic fue en una casilla, 
			# la casilla apagará 'is_selecting_for_admin' antes de que esto se ejecute.
			call_deferred("_check_cancel_admin_click")

func _check_cancel_admin_click() -> void:
	if is_selecting_for_admin:
		Utils.debug("↩️ Clic fuera de casilla. Cancelando administración...")
		_cancel_admin_selection()
		
func _handle_tram_selection(clicked_tile_id: String) -> void:
	var current_tile_id = ModelManager.get_player().current_tile_id
	var tile_name = tile_manager.tile_entities[current_tile_id].get_stop_name()
	overlay_manager.show_tram_selection(clicked_tile_id, current_tile_id, tile_name)

func _on_tram_ok_received() -> void:
	Utils.debug("🚂 El jugador ha decidido usar el tranvía. Iluminando paradas...")
	is_selecting_for_train = true 
	tile_manager.prompt_tile_selection(TRAM_IDS)

# Respuestas a los botones del Overlay
func _on_tram_travel_confirmed(target_tile_id: String) -> void:
	is_selecting_for_train = false # Salimos del modo selección
	WsClient.ws_action_take_tram_to(target_tile_id)

func _on_tram_travel_cancelled() -> void:
	Utils.debug("Elige otra estación...")
	_on_tram_ok_received()

func _cancel_admin_selection() -> void:
	is_selecting_for_admin = false
	tile_manager.reset_tile_highlight()

# ==========================================
# PUENTE: MODELO -> VISUAL (ACTUALIZAR CASILLAS)
# ==========================================
func _on_model_property_updated(property_id: String) -> void:
	Utils.debug("🔄 BOARD: El modelo ha actualizado la propiedad " + property_id + ". Actualizando tablero...")
	
	# 1. Conseguimos los datos puros desde el cerebro
	var prop_data = ModelManager.get_property(property_id)
	if not prop_data: 
		return
		
	# 2. Buscamos la casilla física en el tablero
	if tile_manager.tile_entities.has(property_id):
		var tile = tile_manager.tile_entities[property_id]
		
		# 3. Le mandamos la orden visual de la hipoteca
		if tile.has_method("update_mortgage_visuals"):
			tile.update_mortgage_visuals(prop_data.is_mortgaged)
			
		# EXTRA: Ya que estamos aquí, le actualizamos las casas también por si acaso
		if tile.has_method("set_number_of_houses"):
			tile.set_number_of_houses(prop_data.house_count)

func _handle_jail_dice_logic() -> void:
	#is_in_jail_roll = false
	# Simulación: El backend nos diría si hubo par. 
	var is_pair = false
	
	if is_pair:
		Utils.debug("✨ ¡DOUBLES! Sales de Secretaría gratis.")
		overlay_manager.show_toast("¡Has sacado par! Sales libre.")
		_on_jail_pay_bail_confirmed() # Reutilizamos la lógica de movernos al destino
	else:
		Utils.debug("🚫 No hubo par. Debes elegir: Quedarte o Pagar.")
		# Iluminamos la cárcel (ID "010" por ejemplo) y el destino
		#tile_manager.prompt_tile_selection(["104", jail_target_tile])

func _on_property_houses_changed(tile_id: String, new_houses: int, is_mortgaged: bool) -> void:
	if tile_manager.tile_entities.has(tile_id):
		var tile = tile_manager.tile_entities[tile_id]
		
		# 1. Actualizamos las casas visualmente
		if tile.has_method("set_number_of_houses"):
			tile.set_number_of_houses(new_houses)
		
		# 2. Actualizamos el estado de hipoteca visualmente
		if tile.has_method("set_mortgaged"):
			tile.set_mortgaged(is_mortgaged)

func _on_property_purchased(data: Dictionary) -> void:
	Utils.debug("💰 ¡El jugador ha comprado la casilla " + data["square"])
	#var player: PlayerModel = ModelManager.get_player(data["player"])
	#tile_manager.set_tile_owner(data["square"], player.color)
	ModelManager.set_property_owner(data["square"], data["player"])
	ModelManager.update_player_balance(data["player"], -ModelManager.get_property(data["square"]).buy_price)

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
	WsClient.ws_action_respond_to_trade(true)

func _on_offer_rejected() -> void:
	Utils.debug("❌ BOARD: El intercambio ha sido RECHAZADO.")
	WsClient.ws_action_respond_to_trade(false)

# ==========================================
# ESCENARIO DE DEBUG 5: SECRETARÍA
# ==========================================
func _run_debug_jail_scenario() -> void:
	Utils.debug("🐛 DEBUG MODE 5: Iniciando flujo de Secretaría...")
	await get_tree().create_timer(1.5).timeout
	
	overlay_manager.dice_roller_overlay.hide_overlay()
	
	# Simulamos que es nuestro turno y estamos en la cárcel
	# (Asegúrate de que la ID coincide con la de tu JSON para la cárcel)
	#jail_current_turn = 1
	#overlay_manager.show_jail_initial_warning(jail_current_turn, 3)
