extends Control

@onready var username_input: LineEdit = %UsernameInput
@onready var password_input: LineEdit = %PassInput
@onready var confirm_password_input: LineEdit = %ConfirmPassInput
@onready var pass_tooltip: PanelContainer = %PassTooltip
@onready var confirm_pass_tooltip: PanelContainer = %ConfirmPassTooltip

const fade_duration = 0.5

var pass_tooltip_shown = false
var confirmpass_tooltip_shown = false

func _test_pass_security(pwd: String) -> bool:
	if pwd == "test": return false # TODO: Actual check
	return true

func _on_animated_button_pressed() -> void:
	if pass_tooltip_shown or confirmpass_tooltip_shown: return

	var response = await RestClient.user_signup({
		"username": username_input.text,
		"email": "johndoe@gmail.com", # TODO: This field will be removed
		"password": password_input.text,
		"password2": confirm_password_input.text
	})
	if response != {}:
		SceneTransition.change_scene("res://scenes/UI/home_screen.tscn")
	else:
		username_input.text = ""
		password_input.text = ""
		confirm_password_input.text = ""

func _on_confirm_pass_input_text_changed(new_text: String) -> void:
	if new_text != password_input.text:
		confirm_password_input.theme_type_variation = "LineEditError"
		if not confirmpass_tooltip_shown:
			confirmpass_tooltip_shown = true
			var tween = get_tree().create_tween()
			tween.tween_property(confirm_pass_tooltip, "modulate:a", 1, fade_duration)
	else:
		confirm_password_input.theme_type_variation = ""
		if confirmpass_tooltip_shown:
			confirmpass_tooltip_shown = false
			var tween = get_tree().create_tween()
			tween.tween_property(confirm_pass_tooltip, "modulate:a", 0, fade_duration)


func _on_pass_input_text_changed(new_text: String) -> void:
	if not _test_pass_security(new_text):
		password_input.theme_type_variation = "LineEditError"
		if not pass_tooltip_shown:
			pass_tooltip_shown = true
			var tween = get_tree().create_tween()
			tween.tween_property(pass_tooltip, "modulate:a", 1, fade_duration)
	else:
		password_input.theme_type_variation = ""
		if pass_tooltip_shown:
			pass_tooltip_shown = false
			var tween = get_tree().create_tween()
			tween.tween_property(pass_tooltip, "modulate:a", 0, fade_duration)

func _on_back_button_pressed() -> void:
	SceneTransition.change_scene("res://scenes/UI/landing_screen.tscn")
