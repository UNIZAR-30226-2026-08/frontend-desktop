extends Panel

func _ready() -> void:
	WsClient.start_client_public_queue()
	WsClient.public_match_found.connect(
		SceneTransition.change_scene.bind("res://scenes/board/board.tscn")
	)

func _on_back_button_pressed() -> void:
	WsClient.public_match_found.disconnect(
		SceneTransition.change_scene.bind("res://scenes/board/board.tscn")
	)
	WsClient.socket.close(1000, "Player cancelled search")
	SceneTransition.change_scene("res://scenes/UI/home_screen.tscn")
