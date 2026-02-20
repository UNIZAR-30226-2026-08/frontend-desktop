extends Control


func _on_login_button_pressed() -> void:
	SceneTransition.change_scene("res://scenes/UI/login_screen.tscn")


func _on_signup_button_pressed() -> void:
	SceneTransition.change_scene("res://scenes/UI/signup_screen.tscn")
