extends Panel

@onready var settings_button: Button = %SettingsButton

const SETTINGS_OVERLAY_SCENE = preload("uid://d31dwv0u5en1g")

func _ready() -> void:
	settings_button.pressed.connect(
		func():
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
