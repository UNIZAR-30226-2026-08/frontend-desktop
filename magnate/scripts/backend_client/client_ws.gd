class_name MagnateWSClient
extends Node

## <class_doc>
## **MagnateWSClient** makes use of the Godot WebSocket API

var socket = WebSocketPeer.new()

# The following comes straight from the Godot docs with slight
# modifications:
# https://docs.godotengine.org/en/stable/tutorials/networking/websocket.html#using-websocket-in-godot

func _ready():
	# Initiate connection to the given URL.
	var err = socket.connect_to_url(Globals.WS_BASE_URL)
	if err == OK:
		# Wait for the socket to connect.
		await get_tree().create_timer(2).timeout
	else:
		push_error("Unable to connect to " + Globals.WS_BASE_URL)
		set_process(false)

func _process(_delta):
	# Call this in `_process()` or `_physics_process()`.
	# Data transfer and state updates will only happen when calling this function.
	socket.poll()

	# get_ready_state() tells you what state the socket is in.
	var state = socket.get_ready_state()

	# `WebSocketPeer.STATE_OPEN` means the socket is connected and ready
	# to send and receive data.
	if state == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count():
			var packet = socket.get_packet()
			if socket.was_string_packet():
				var packet_text = packet.get_string_from_utf8()
				print("< Got text data from server: %s" % packet_text)
			else: # This shouldn't happen to us
				print("< Got binary data from server: %d bytes" % packet.size())
	# `WebSocketPeer.STATE_CLOSING` means the socket is closing.
	# It is important to keep polling for a clean close.
	elif state == WebSocketPeer.STATE_CLOSING:
		pass
	# `WebSocketPeer.STATE_CLOSED` means the connection has fully closed.
	# It is now safe to stop polling.
	elif state == WebSocketPeer.STATE_CLOSED:
		set_process(false) # Stop processing.

## WARNING: You probably shouldn't be using this. There should be a
## specific function in this class that abstracts your interaction logic.
func send_data(data_to_send: Variant):
	data_to_send = JSON.stringify(data_to_send)
	socket.send_text(data_to_send)

# Now we get into the specifics of the communication

func buy_property(id: String):
	pass
