extends Control

# TODO: Add integrity checks to the fields and communicate with backend

func _on_animated_button_pressed() -> void:
	SceneTransition.change_scene("res://scenes/UI/home_screen.tscn")
