extends Panel

@onready var settings_button: Button = %SettingsButton

const SETTINGS_OVERLAY_SCENE = preload("uid://d31dwv0u5en1g")

func _ready() -> void:
	var active_game = null
	if not RestClient.game_active_checked:
		active_game = (await RestClient.user_get_active_game()).get("active_game", null)
		RestClient.game_active_checked = true
	if active_game:
		WsClient._conn_state = WsClient.ConnState.GO_TO_GAME
		WsClient.game_id = int(active_game)
		SceneTransition.change_scene("res://scenes/board/board.tscn")
	settings_button.pressed.connect(func():
		var scene = SETTINGS_OVERLAY_SCENE.instantiate()
		add_child(scene)
	)

func _on_btn_publica_pressed() -> void:
	SceneTransition.change_scene("res://scenes/UI/loading_screen.tscn")

func _on_btn_privada_pressed() -> void:
	SceneTransition.change_scene("res://scenes/UI/private_play.tscn")

func _on_btn_shop_pressed() -> void:
	SceneTransition.change_scene("res://scenes/UI/shop_screen.tscn")

func _on_btn_profile_pressed() -> void:
	SceneTransition.change_scene("res://scenes/UI/profile_screen.tscn")

func _on_help_button_pressed() -> void:
	SceneTransition.change_scene("res://scenes/UI/rules_screen.tscn")
