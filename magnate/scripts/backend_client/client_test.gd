extends Node2D

var ws_client: MagnateWSClient = MagnateWSClient.new()

func _ready() -> void:
	add_child(ws_client)
	ws_client.session_id = 'p2br5cpcbylbreio6hq1v6xlcpfqxn73'
	ws_client.player_id = 1
	Utils.debug("Connecting to private queue")
	var private_code = '4H8KSO'
	ws_client.start_client_private_lobby(private_code)
	await get_tree().create_timer(1).timeout
	Utils.debug("Ready up")
	ws_client.ws_private_lobby_readystatus(true)
	Utils.debug("Waiting for match")
	await ws_client.private_match_found
	Utils.debug("Throwing dice")
	ws_client.ws_send_chat_message("UwU")
