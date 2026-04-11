extends Control

@onready var username_input: LineEdit = %UsernameInput
@onready var pass_input: LineEdit = %PassInput
@onready var tooltip: PanelContainer = $Tooltip

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
			Utils.debug("FLASHING")
			tooltip.flash()

func _on_back_button_pressed() -> void:
	SceneTransition.change_scene("res://scenes/UI/landing_screen.tscn")
