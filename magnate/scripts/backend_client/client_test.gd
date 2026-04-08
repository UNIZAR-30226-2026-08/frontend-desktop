extends Node2D

var ws_client: MagnateWSClient = MagnateWSClient.new()

func _ready() -> void:
	add_child(ws_client)
	ws_client.session_id = 'oy5s45m80gjvrmtskt5zxwelusrhboii'
	ws_client.player_id = 2
	Utils.debug("Connecting to public queue")
	ws_client.start_client_public_queue()
