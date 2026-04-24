extends Control

@onready var username_input: LineEdit = %UsernameInput
@onready var pass_input: LineEdit = %PassInput
@onready var unauthorized_tooltip: PanelContainer = %UnauthorizedTooltip
@onready var animated_button: MagnateTweenButton = $MainVBox/HBoxContainer/AnimatedButton

func _on_animated_button_pressed() -> void:
	var response = await RestClient.user_login({
		"username": username_input.text,
		"password": pass_input.text,
	})
	if response != {}:
		SceneTransition.change_scene("res://scenes/UI/home_screen.tscn")
	else:
		username_input.text = ""
		pass_input.text = ""
		if RestClient.last_faulty_response_code == 401:
			unauthorized_tooltip.flash()

func _on_back_button_pressed() -> void:
	SceneTransition.change_scene("res://scenes/UI/landing_screen.tscn")

func _on_username_input_text_submitted(_new_text: String) -> void:
	_on_animated_button_pressed()

func _on_pass_input_text_submitted(_new_text: String) -> void:
	_on_animated_button_pressed()
