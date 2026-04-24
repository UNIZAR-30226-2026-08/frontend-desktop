extends Control

@export var player_icon_big_scene: PackedScene 
@onready var room_code_label: Label = %room_code_label
@onready var copy_code_button: Button = %copy_code_button
@onready var start_game_button: MagnateTweenButton = %start_game_button
@onready var bot_dificulty_selector: OptionButton = %BotDificultySelector
@onready var player_list: HBoxContainer = %PlayerList

var is_owner: bool = false
var player_info: Array[Dictionary] = []
var old_number_of_players: int = -1
var num_bots: int = 0
var old_num_bots: int = -1
var bot_level: MagnateWSClient.BotLevel = MagnateWSClient.BotLevel.MEDIUM

func _ready():
	WsClient.player_join.connect(_handle_player_update)
	WsClient.player_leave.connect(_handle_player_update)
	WsClient.player_ready.connect(_handle_player_ready)
	WsClient.lobby_settings_changed.connect(_handle_settings_change)
	WsClient.private_match_found.connect(_handle_match_found)
	WsClient.socket_disconnect.connect(_on_header_back_action_requested)
	WsClient.start_client_private_lobby()
	room_code_label.text = WsClient.private_lobby_code
	if not is_owner: start_game_button.set_btn_text("LISTO")

func _handle_player_update(info: Dictionary) -> void:
	is_owner = info["is_owner"]
	player_info = []
	for p in info["players"]:
		player_info.append({
			"name": p["username"],
			"type": "human",
			"custom_texture": load(Globals.tokens[p["user_piece"]]["icon"] if Globals.tokens.has(p["user_piece"]) else Globals.tokens[0]["icon"]),
			"ready": p["ready_to_play"] or p["username"] == info["owner"]
		})
		if is_owner and p["username"] == RestClient.username and not p["ready_to_play"]:
			WsClient.ws_private_lobby_readystatus(true)
	
	num_bots = clamp(num_bots, 0, 4 - len(player_info))
	
	if info["action"] == "joined" and info["user"] == RestClient.username:
		_handle_settings_change(info)
	else:
		update_lobby()

func _handle_player_ready(info: Dictionary) -> void:
	for p in player_info:
		if p["name"] == info["user"]: p["ready"] = info["is_ready"]
	for p in player_list.get_children():
		if p.player_name == info["user"]:
			p.set_ready(info["is_ready"])
	if not is_owner and info["user"] == RestClient.username:
		if info["is_ready"]: start_game_button.set_btn_text("NO LISTO")
		else: start_game_button.set_btn_text("LISTO")

func _handle_settings_change(settings: Dictionary) -> void:
	bot_level = settings["bot_level"]
	print(settings["target_players"])
	print(len(player_info))
	num_bots = clamp(settings["target_players"] - len(player_info), 0, 4)
	update_lobby()

func _handle_match_found() -> void:
	Utils.debug(RestClient.username + ": MATCH FOUND!")
	WsClient.player_join.disconnect(_handle_player_update)
	WsClient.player_leave.disconnect(_handle_player_update)
	WsClient.player_ready.disconnect(_handle_player_ready)
	WsClient.lobby_settings_changed.disconnect(_handle_settings_change)
	WsClient.private_match_found.disconnect(_handle_match_found)
	WsClient.socket_disconnect.disconnect(_on_header_back_action_requested)
	SceneTransition.change_scene("res://scenes/board/board.tscn")

func update_lobby():
	match bot_level:
		WsClient.BotLevel.VERY_EASY: bot_dificulty_selector.select(0)
		WsClient.BotLevel.EASY: bot_dificulty_selector.select(1)
		WsClient.BotLevel.MEDIUM: bot_dificulty_selector.select(2)
		WsClient.BotLevel.HARD: bot_dificulty_selector.select(3)
		WsClient.BotLevel.VERY_HARD: bot_dificulty_selector.select(4)
		WsClient.BotLevel.EXPERT: bot_dificulty_selector.select(5)
	if is_owner:
		start_game_button.set_btn_text("COMENZAR JUEGO")
		bot_dificulty_selector.disabled = num_bots == 0
	else:
		bot_dificulty_selector.disabled = true
	
	$VBoxContainer/player_count_label.text = "JUGADORES EN SALA: " + str(len(player_info)) + "/4"
	
	# Only update if necessary
	if num_bots == old_num_bots and old_number_of_players == len(player_info): return
	old_num_bots = num_bots
	old_number_of_players = len(player_info)

	# Limpiamos los slots antiguos
	for child in player_list.get_children():
		child.queue_free()
		
	# Creamos los 4 slots
	var first_waiting: bool = true
	for i in range(4):
		var slot = player_icon_big_scene.instantiate()
		player_list.add_child(slot)
		
		if i < len(player_info): # Should be player
			var p = player_info[i]
			var tex = p.get("custom_texture", null) 
			slot.setup(p.name, p.type, is_owner, tex, p.ready)
		elif i < len(player_info) + num_bots: # Should be bot
			slot.setup("", "bot", is_owner)
			slot.bot_removed_locally.connect(
				func ():
					num_bots = clamp(num_bots - 1, 0, 4)
					WsClient.ws_private_lobby_settings(bot_level, len(player_info) + num_bots)
			)
		else: # Should be waiting
			slot.setup("", "waiting", is_owner and first_waiting)
			first_waiting = false
			slot.bot_added_locally.connect(
				func ():
					num_bots = clamp(num_bots + 1, 0, 4)
					WsClient.ws_private_lobby_settings(bot_level, len(player_info) + num_bots)
			)

func _on_header_back_action_requested(close_code: int = 0) -> void:
	WsClient.player_join.disconnect(_handle_player_update)
	WsClient.player_leave.disconnect(_handle_player_update)
	WsClient.player_ready.disconnect(_handle_player_ready)
	WsClient.lobby_settings_changed.disconnect(_handle_settings_change)
	WsClient.private_match_found.disconnect(_handle_match_found)
	WsClient.socket_disconnect.disconnect(_on_header_back_action_requested)
	if close_code == 0:
		WsClient.socket.close(1000, "Player left lobby")
	SceneTransition.change_scene("res://scenes/UI/private_play.tscn")

func _on_start_game_button_pressed() -> void:
	if not is_owner:
		if start_game_button.text == "LISTO": WsClient.ws_private_lobby_readystatus(true)
		else: WsClient.ws_private_lobby_readystatus(false)
	else:
		WsClient.ws_private_lobby_start()

func _on_copy_code_button_pressed() -> void:
	const COPY_SOLID_FULL = preload("uid://cw3ys8ynq0lcm")
	DisplayServer.clipboard_set(room_code_label.text)
	copy_code_button.set_icon(COPY_SOLID_FULL)
	get_tree().create_timer(5).timeout.connect(copy_code_button.set_icon.bind(copy_code_button.icon_texture))

func _on_bot_dificulty_selector_item_selected(index: int) -> void:
	var bot_dif = [
		WsClient.BotLevel.VERY_EASY,
		WsClient.BotLevel.EASY,
		WsClient.BotLevel.MEDIUM,
		WsClient.BotLevel.HARD,
		WsClient.BotLevel.VERY_HARD,
		WsClient.BotLevel.EXPERT,
	]
	WsClient.ws_private_lobby_settings(bot_dif[index], len(player_info) + num_bots)
