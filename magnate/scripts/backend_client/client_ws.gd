class_name MagnateWSClient
extends Node

## <class_doc>
## **MagnateWSClient** makes use of the Godot WebSocket API.
## It exposes public functions that send the packages to the backend and
## signals that emit when certain packages from the backend are received.

var socket = WebSocketPeer.new()
var game_id: int
var player_id: int
var session_id: int

# The following comes straight from the Godot docs with slight
# modifications:
# https://docs.godotengine.org/en/stable/tutorials/networking/websocket.html#using-websocket-in-godot

func _ready() -> void:
	# Initiate connection to the given URL.
	var err = socket.connect_to_url(Globals.WS_BASE_URL)
	if err == OK:
		# Wait for the socket to connect.
		await get_tree().create_timer(2).timeout
	else:
		Utils.debug("ERROR: Unable to connect to " + Globals.WS_BASE_URL)
		set_process(false)

func _process(_delta) -> void:
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
				var packet_text: String = packet.get_string_from_utf8()
				var response: Dictionary = JSON.parse_string(packet_text)
				_response_dispatcher(response)
			else: # This shouldn't happen to us
				Utils.debug("Got binary data from server: %d bytes" % packet.size())
	# `WebSocketPeer.STATE_CLOSING` means the socket is closing.
	# It is important to keep polling for a clean close.
	elif state == WebSocketPeer.STATE_CLOSING:
		pass
	# `WebSocketPeer.STATE_CLOSED` means the connection has fully closed.
	# It is now safe to stop polling.
	elif state == WebSocketPeer.STATE_CLOSED:
		set_process(false) # Stop processing.

# Some auxiliary functions

## WARNING: You probably shouldn't be using this. There should be a
## specific function in this class that abstracts your interaction logic.
func send_data(data_to_send: Variant) -> void:
	data_to_send = JSON.stringify(data_to_send)
	socket.send_text(data_to_send)

func _response_dispatcher(response: Dictionary) -> void:
	var action_code = response.get("action")
	if action_code == null:
		return
	match action_code:
		pass

func _build_base_action() -> Dictionary:
	return {
		"game": game_id,
		"player": player_id,
	}

func _build_action(data: Dictionary = {}) -> Dictionary:
	data.merge(_build_base_action())
	return data

func _build_and_send_action(data: Dictionary) -> void:
	var action_data = _build_action(data)
	send_data(action_data)

# Now we get into the specifics of the communication

## Action: Throw the dice
func ws_throw_dice() -> void:
	_build_and_send_action({"type": "ActionThrowDices"})

## Action: Move to the given tile
## @params:
## - tile_id: ID of the tile to move to
func ws_move_to(tile_id: String) -> void:
	_build_and_send_action({"type": "ActionMoveTo", "square": int(tile_id)})

## Action: Buy property in given tile
## @params:
## - tile_id: ID of the tile to buy
func ws_buy_property(tile_id: String) -> void:
	_build_and_send_action({"type": "ActionBuySquare", "square": int(tile_id)})

# Missing: ActionSellSquare

## Action: Ends current players turn
func ws_end_turn() -> void:
	_build_and_send_action({"type": "ActionNextPhase"})

# Missing: ActionBuild
# Missing: ActionDemolish

## Action: Mortgages a given property
## @params:
## - tile_id: ID of the tile to mortgage
func ws_mortgage_property(tile_id: String) -> void:
	_build_and_send_action({"type": "ActionMortgageSet", "square": int(tile_id)})

## Action: Unmortgages a given property
## @params:
## - tile_id: ID of the tile to unmortgage
func ws_unmortgage_property(tile_id: String) -> void:
	_build_and_send_action({"type": "ActionMortgageUnset", "square": int(tile_id)})

# Missing ActionDropPurchase
# Missing ActionTakeTram
# Missing ActionSkipTram
# Missing ActionChooseCard
# Missing ActionBid
# Missing ActionTradePorposal
# Missing ActionTradeAnswer

## Action: Pays bail for current player
func ws_pay_bail() -> void:
	_build_and_send_action({"type": "ActionPayBail"})

## Action: Surrenders current player
func ws_surrender() -> void:
	_build_and_send_action({"type": "ActionSurrender"})
