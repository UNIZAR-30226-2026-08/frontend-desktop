extends Panel


func _on_btn_publica_pressed() -> void:
	SceneTransition.change_scene("res://scenes/UI/loading_screen.tscn")


func _on_btn_privada_pressed() -> void:
	SceneTransition.change_scene("res://scenes/UI/private_play.tscn")
