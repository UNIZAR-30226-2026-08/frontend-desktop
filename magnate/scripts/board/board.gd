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
	var music = AudioResource.from_type(Globals.AUDIO_BOARDMUSIC, AudioResource.AudioResourceType.MUSIC)
	AudioSystem.play_audio(music)
	WsClient.start_client_game()
	
	# 1. Mundo físico y Cámara
	tile_manager.setup_tiles(tile_parent_node)
	camera_system.init_camera_system(self)
	
	# 2. Inicializar los datos del juego 
	await _setup_game_data()
	
	# 3. Interfaz de Usuario y Overlays
	overlay_manager.setup_overlays(self, %DiceRoller, %JailDiceRoller)
	overlay_manager.setup_huds(ModelManager.game.players.values())
	_start_turn()
	
	# 4. Conectar tooooodas las señales
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
	PlayerSpawner.spawn_players(self, tile_manager.tile_entities, ModelManager.game)
	TokenLayoutManager.update_all_token_positions(ModelManager.game.players.values(), tile_manager.tile_entities)
	
	Utils.debug("💾 ModelManager inicializado con las reglas cargadas desde JSON")

# ==============================================================================================================================================
# CONEXIÓN DE SEÑALES
# ==============================================================================================================================================
func _connect_all_signals() -> void:
	
	if not ModelManager.property_updated.is_connected(_on_model_property_updated):
		ModelManager.property_updated.connect(_on_model_property_updated)
	
	# Señales Generales del Overlay Manager
	overlay_manager.tram_ok.connect(_on_tram_ok_received)
	overlay_manager.tram_travel_confirmed.connect(_on_tram_travel_confirmed)
	overlay_manager.tram_travel_cancelled.connect(_on_tram_travel_cancelled)
	overlay_manager.trade_selection_request.connect(_on_trade_selection_requested)
	# overlay_manager.property_bought.connect(_on_property_purchased)
	overlay_manager.offer_accepted.connect(_on_offer_accepted)
	overlay_manager.offer_rejected.connect(_on_offer_rejected)
	overlay_manager.get_parking_money.connect(tile_manager.parking_money)
	overlay_manager.property_houses_changed.connect(_on_property_houses_changed)
	
	# Señales de Controles (Dados normales)
	overlay_manager.request_admin_selection.connect(_on_admin_selection_requested)
	
	# Señales de Secretaría (Cárcel)
	overlay_manager.jail_roll_requested.connect(_on_jail_roll_requested)
	
	
	
	
	# ------ LOS DE AQUI ABAJO YA ESTÁN MEDIO CONECTADOS ------ #
	
	# CONEXION CON EL TILE MANAGER
	tile_manager.tile_pressed.connect(_on_highlighted_tile_clicked)
	
	# CONEXIONES A LOS OVERLAYS DE DADOS (NO LOS GESTIONA EL OVERLAY MANAGER)
	overlay_manager.dice_roller_overlay.roll_finished.connect(_on_dice_result_received)
	overlay_manager.jail_dice_roller.roll_finished.connect(_on_dice_result_received) # DONE 1

	# CONEXIONES A LOS MANAGERS
	# overlay_manager.normal_roll_requested.connect(_on_hud_roll_requested)
	
	# CONEXIONES AL WS RESPONSES
	WsClient.response_choose_square.connect(_on_choose_square_received)
	WsClient.response_general.connect(_handle_general_response)
	
	# WS ACTION CONECTIONS
	WsClient.action_buy_square.connect(_on_property_purchased)
	
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
	# Dispatch action
	if new_turn: _start_turn()
	if new_phase: _start_phase()

func _start_turn() -> void:
	overlay_manager.controls_hud.toggle_hud_visibility(true)
	var text = "Tu turno"
	var player = ModelManager.get_player(ModelManager.get_current_turn_player_id())
	if not ModelManager.game.is_my_turn():
		text = "Turno de " + player.player_name
	overlay_manager.show_banner(text, player.color)

func _start_phase() -> void:
	match ModelManager.game.current_phase:
		WsClient.Phase.ROLL_THE_DICES:
			if ModelManager.game.is_my_turn(): overlay_manager.show_dice_overlay()
		WsClient.Phase.BUSINESS:
			if ModelManager.game.is_my_turn(): overlay_manager.controls_hud.toggle_hud_visibility(false)

# ============
#  MODO DEBUG
# ============
func _begin_debug(mode: int) -> void:
	if mode == 0:
		return # Juego normal, no hacemos nada de debug
		
	Utils.debug("🔧 Ejecutando Modo Debug: " + str(mode))
	
	if mode == 1:
		pass
	elif mode == 2:
		_run_debug_trade_scenario()
	elif mode == 3:
		_run_debug_offer_scenario()
	elif mode == 4:
		await get_tree().create_timer(2).timeout
		overlay_manager.start_scoreboard_overlay()
	elif mode == 5:
		_run_debug_jail_scenario()
	elif mode == 6:
		_run_debug_train_scenario()


# ==============================================================================================================================================
# LÓGICA DE DADOS - CONEXIÓN: GAME_MODEL <-> BOARD <-> DICE_ROLLER
# ==============================================================================================================================================
# ACTION - Tirada normal DONE 1
#func _on_hud_roll_requested() -> void:
#	# 1. Bloquear la UI para que el jugador no haga doble click
#	overlay_manager.set_roll_disabled(true)
#	# 2. Avisamos al manager de que tiene que esperar a mostrar un overlay
#	overlay_manager.overlay_open.emit()
#	WsClient.ws_action_throw_dice()

# Devolución por parte del Overlay Manager de los dados
func _on_dice_result_received(result: Dictionary) -> void:
	# 1. EXTRAEMOS EL GAME_MODEL Y EL PLAYER_MODEL QUE HA TIRADO PARA UTILIZAR LA INFORMACIÓN 
	var game = ModelManager.game
	var current_player: PlayerModel = ModelManager.get_player(game.current_turn_player_id)
	
	# 3. LÓGICA DE DADOS (PARA EL USUARIO QUE LOS HA LANZADO)
	if game.is_my_turn():
		if current_player.is_in_jail: 
			#_handle_jail_dice_logic()
			pass
		else:
			# Jugador ha sacado dobles 3 veces
			if result.streak == 3:
				# TODO mensaje de has sacado dobles 3 veces: Yendo a la cárcel
				# Al mandarlo a la casilla de ir a la cárcel, ya sale la animación de ir a la cárcel
				current_player.current_tile_id = game.important_tiles["go_to_jail"]
				_handle_normal_movement(false, result.path)
				overlay_manager.overlay_closed.emit()
			elif len(result.destinations) > 1:
				tile_manager.prompt_tile_selection(result.destinations)
			# Jugador se mueve automáticamente
			else:
				_handle_normal_movement(true, result.path)
				overlay_manager.overlay_closed.emit()
	# 4. LÓGICA DE DADOS (PARA EL RESTO DE USUARIOS)
	else:
		if current_player.is_in_jail: 
			#_handle_jail_dice_logic()
			pass
		else:
			# Jugador ha sacado triples
			if result.streak == 3:
				# TODO mensaje de has sacado dobles 3 veces: Yendo a la cárcel
				# Al mandarlo a la casilla de ir a la cárcel, ya sale la animación de ir a la cárcel
				current_player.current_tile_id = game.important_tiles["go_to_jail"]
				_handle_normal_movement(false, result.path)
			# Jugador ha de seleccionar a dónde ir con el bus
			elif len(result.destinations) == 1:
				_handle_normal_movement(true, result.path)
				# TODO aquí habría que ponerles a los usuarios algo de idle: "El jugador X está gestionando su turno..."

# Tirada desde la cárcel #TODO
func _on_jail_roll_requested() -> void:
	#is_in_jail_roll = true
	
	# 📢 ¡Avisamos para que se oculte la UI!
	overlay_manager.overlay_open.emit()
	
	overlay_manager.dice_roller_overlay.hide_overlay()
	overlay_manager.jail_dice_roller.show_overlay()

# ==============================================================================================================================================
# LÓGICA DE MOVIMIENTO - CONEXIÓN: GAME_MODEL, PLAYERMODEL <-> BOARD
# ==============================================================================================================================================
# Función que actualiza el movimieneto del player a su destino en GAME_MODEL
# PRE: animation = false teletransporta al player sin la animación
func _handle_normal_movement(animation: bool, path: Array[String]) -> void:
	# 1. EXTRAEMOS EL GAME_MODEL PARA UTILIZAR LA INFORMACIÓN
	var game = ModelManager.game
	
	# 2. EXTRAEMOS EL TOKEN PARA UTILIZAR LA INFORMACIÓN
	var current_player = ModelManager.get_player(game.current_turn_player_id)
	var current_token = current_player.token
	
	# 3. GESTION EN CASO DE MOSTRAR ANIMACIÓN DE MOV
	if animation:
		# EXTRAEMOS EL PATH Y MOVEMOS PLAYER
		var path_positions: Array[Vector2] = []
	
		for step_id in path.slice(1):
			if tile_manager.tile_entities.has(step_id):
				var step_tile = tile_manager.tile_entities[step_id]
				path_positions.append(step_tile.position + step_tile.pivot_offset)
		
		if not path_positions.is_empty():
			overlay_manager.player_hud.toggle_hud_visibility(true)
			camera_system.follow_node(current_token, Vector2(2, 2))
			await camera_system.stopped
			await current_token.move_to(path_positions)
			camera_system.main_camera()
			await camera_system.stopped
			overlay_manager.player_hud.toggle_hud_visibility(false)
		
		# La última posición del path es el destino final
		current_player.move_to_tile(path[-1])
		#TODO esta linea comentada ahora irá mal porque players ya no es lo que era
		#TokenLayoutManager.update_all_token_positions(players, tile_manager.tile_entities)
		
		# Si es el turno del usuario, mostramos overlay de la casilla a la que va
		if game.is_my_turn():
			overlay_manager.display_overlay_for_tile(path[-1])

	else:
		current_player.move_to_tile(current_player.current_tile_id)
		#TODO esta linea comentada ahora irá mal porque players ya no es lo que era
		#TokenLayoutManager.update_all_token_positions(players, tile_manager.tile_entities)
		
		# Si es el turno del usuario, mostramos overlay de la casilla a la que va
		if game.current_turn_player_id == game.my_id:
			overlay_manager.display_overlay_for_tile(current_player.current_tile_id)

# RESPONSE - JUGADOR ACTUAL HA SELECCIONADO CASILLA PARA MOVERSE
func _on_choose_square_received(data: Dictionary) -> void:
	# game.fantasy_event: FantasyEvent = data["fantasy_event"]
	# movemos al player actual a la posición elegida
	_handle_normal_movement(true, data["path"])
	
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
	
	#var model: PlayerModel = players[0]["model"]
	#model.move_to_tile(tile_id)
	#TokenLayoutManager.update_all_token_positions(players, tile_manager.tile_entities)

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
	
	var game = ModelManager.game
	
	# Mandamos la action de haber pagado la fianza
	WsClient.action_pay_bail.emit({"game": game.game_id, "player": game.current_turn_player_id})
	
	# TODO FALTA CAPTURAR EL ACTION QUE BROADCASTEA EL BACK PARA MOVER AL JUGADOR
	return

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
	var mis_propiedades_ids: Array[String] = ModelManager.get_player_properties(current_player_id)
	
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
	# Si seguimos en modo admin después del frame, es que el clic fue en el césped
	if is_selecting_for_admin:
		Utils.debug("↩️ Clic fuera de casilla. Cancelando administración...")
		_cancel_admin_selection()
		
func _handle_tram_selection(clicked_tile_id: String) -> void:
		var current_player_id = ModelManager.get_current_turn_player_id()
		var current_tile_id = "010" #HARDCODEADO
		var tile_name = "Estación" # Aquí puedes sacar el nombre real si lo tienes en el PropertyModel
		
		overlay_manager.show_tram_selection(clicked_tile_id, current_tile_id, tile_name)

func _on_tram_ok_received() -> void:
	Utils.debug("🚂 El jugador ha decidido usar el tranvía. Iluminando paradas...")
	
	# 1. Activamos el modo selección para que el click en la casilla sea interceptado
	is_selecting_for_train = true 
	
	# 2. Iluminamos las casillas del tranvía usando tu constante TRAM_IDS
	tile_manager.prompt_tile_selection(TRAM_IDS)

# Respuestas a los botones del Overlay
func _on_tram_travel_confirmed(target_tile_id: String, cost: int) -> void:
	is_selecting_for_train = false # Salimos del modo selección
	var current_player_id = ModelManager.get_current_turn_player_id()
	
	if cost > 0:
		ModelManager.set_player_balance(current_player_id, ModelManager.get_player(current_player_id).balance - cost)
		
	# Movemos al jugador (usando la función que arreglamos antes)
	ModelManager.update_player_position(current_player_id, target_tile_id)
	
	TokenLayoutManager.update_all_token_positions(ModelManager.game.players.values(), tile_manager.tile_entities)
	
	overlay_manager.overlay_closed.emit()

func _on_tram_travel_cancelled() -> void:
	# El usuario eligió "Elegir otra parada". Se cierra el overlay pero seguimos en modo selección.
	print("Elige otra estación...")
	_on_tram_ok_received()
####################################################################################

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

# FUNCIÓN QUE MUEVE A UN PLAYER AL DESTINO AL QUE DEBE IR SEGÚN GAMEMODEL.PENDINGPATH


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
	var player: PlayerModel = ModelManager.get_player(data["player"])
	tile_manager.set_tile_owner(data["square"], player.color)
	player.owned_properties.append(data["square"])
	player.balance -= ModelManager.get_property(data["square"]).buy_price
	overlay_manager.player_hud.update_player_stats(player.id, player.balance, len(player.owned_properties))

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
	overlay_manager.dice_roller_overlay.hide_overlay()

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
	
	overlay_manager.dice_roller_overlay.hide_overlay()

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
	
# ==========================================
# ESCENARIO DE DEBUG 6: TRANVIAS
# ==========================================
func _run_debug_train_scenario() -> void:
	# 1. Conseguir al jugador que queremos mover
	# (Usamos la función que ya tienes en ModelManager para el turno actual)
	var target_player_id = ModelManager.get_current_turn_player_id()
	
	# Si por algún motivo el juego acaba de arrancar y no hay turno asignado, forzamos el Jugador 1
	if target_player_id == 1:
		target_player_id = 1 
		
	print("🚂 [DEBUG] Ejecutando escenario de Tranvía para el jugador: ", target_player_id)

	# 2. Mover al jugador usando tu función del ModelManager
	#_handle_normal_movement()
