extends Control

# TODO: Add integrity checks to the fields and communicate with backend

@onready var password_input: LineEdit = %PassInput
@onready var confirm_password_input: LineEdit = %ConfirmPassInput

func _on_animated_button_pressed() -> void:
	SceneTransition.change_scene("res://scenes/UI/home_screen.tscn")


func _on_confirm_pass_input_text_changed(new_text: String) -> void:
	if new_text != password_input.text:
		confirm_password_input.theme_type_variation = "LineEditError"
	else:
		confirm_password_input.theme_type_variation = ""
