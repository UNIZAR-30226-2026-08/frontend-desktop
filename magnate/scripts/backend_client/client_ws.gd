class_name MagnateWSClient
extends Node

## <class_doc>
## **MagnateWSClient** makes use of the Godot WebSocket API.
## It exposes public functions that send the packages to the backend and
## signals that emit when certain packages from the backend are received.
## Each of them has 3 sections for 3 different stages of the communication:
## - Private queue: for communication related to the private lobby
## - Public queue: for communication when public queueing
## - In game: for in game logic and comms
## Some explaining about how communication with the backend is designed:
## During the game it works with actions (sent by players to the backend)
## and responses (sent to players from backend), you send actions and
## recieve all actions and responses (even those from other players).
## Outside of the game some messages for queue administration are sent.

# =======
#  ENUMS
# =======
## Phases of the game
enum Phase {
	ROLL_THE_DICES, # A dice roll is needed
	CHOOSE_SQUARE, # A tile needs to be chosen (multiple possible)
	CHOOSE_FANTASY, # A fantasy card must be selected
	MANAGEMENT, # Decide to buy or auction a property
	BUSINESS, # Property administration phase, build houses, mortgage...
	LIQUIDATION, # Player has negative balance and must sell something
	AUCTION, # An auction is taking place
	PROPOSAL_ACCEPTANCE, # The player must accept or decline the incoming offer
	END_GAME, # The game is finished
}

## Levels of difficulty for bots in the private lobby
enum BotLevel {EASY, MEDIUM, HARD}

## Internal state enum (Ignore)
enum ConnState {START, IN_PUBLIC_QUEUE, IN_PRIVATE_QUEUE, GO_TO_GAME, IN_GAME}

# =====================
#  GENERAL USE SIGNALS
# =====================
## Emitted when an error is received, String contains the error message
signal error(String)

## Emitted when a chat message is received
## Dictionary contains:
## - "user": String	- Name of the chat message sender
## - "msg": String	- Contents of the chat message
signal chat_message(Dictionary)

## Emitted when a game state is received, you should probably set everything to this values
## Dictionary contains: TODO
signal game_state(Dictionary)

# ======================
#  PUBLIC QUEUE SIGNALS
# ======================
## Emitted when a match is found
signal public_match_found

# =======================
#  PRIVATE QUEUE SIGNALS
# =======================
## Emitted when a player joins the lobby
## Dictionary contains:
## - "user": String					- Username of the user that joined
## - "owner": String					- Username of the owner of the lobby
## - "is_owner": bool				- True if I am the owner (NOTE: **I**, not the joined player)
## - "players": Array[Dictionary]	- Array with info on each player
##		- Dictionary contains: "username": String and "ready_to_play": bool
signal player_join(Dictionary)

## Emitted when a player leaves the lobby
## Dictionary contains:
## - "user_left": String				- Username of the user that left
## - "owner": String					- Username of the owner of the lobby
## - "is_owner": bool				- True if I am the owner (NOTE: **I**, not the joined player)
## - "players": Array[Dictionary]	- Array with info on each player
##		- Dictionary contains: "username": String and "ready_to_play": bool
signal player_leave(Dictionary)

## Emitted when a player changes ready status
## Dictionary contains:
## - "user": String		- Username of the user that changes status
## - "is_ready": bool	- New status of the user
## - "owner": String		- Username of the owner of the lobby
## - "is_owner": bool	- True if I am the owner (NOTE: **I**, not the joined player)
signal player_ready(Dictionary)

## Emitted when a private lobby starts the game
signal private_match_found

# ================
#  INGAME SIGNALS
# ================

# RESPONSE SIGNALS
## !IMPORTANT: The following response signals all contain the data from response_general

## Emitted when a match is finished
signal match_finished

## General response, comes with every response
## Response Dictionary includes:
## - "money": Dictionary[String, int]	- Dictionary with ids of players and their money
## - "active_phase_player": int			- ID of the player playing the current phase
## - "active_turn_player": int			- ID of the player playing the current turn
## - "phase": Enum <Phase> above			- phase of the game
signal response_general(Dictionary)

## Response to a dice throw, contains result of the throw
## Response Dictionary includes:
## - "path": Array[String],			- Movement path to follow (list of ids),
##										if multiple destinations then dont use this
##										the correct path will be in response_choose_square
## - "dice1": int,					- Result of the first dice
## - "dice2": int,					- Result of the second dice
## - "dice_bus": int,				- Result of the bus/third dice
## - "destinations": Array[String],	- Possible destinations for the player (list of ids)
## - "triple": bool,					- If the throw is a triple
## - "streak": int					- Streak of doubles for the current player
## - "fantasy_event": TODO
signal response_throw_dices(Dictionary)

# This is an abstract response and shouldnt be received
# Base response for an action that moved the player
# Response Dictionary includes:
# - "path": Array[String]				- Movement path to follow (list of ids)
# - "fantasy_event": TODO
# signal response_movement(Dictionary)

## Response for an square election
## Response Dictionary includes:
## - "path": Array[String]				- Movement path to follow (list of ids)
## - "fantasy_event": TODO
signal response_choose_square(Dictionary)

## Response to a fantasy card choice
## Response Dictionary includes:
## - "fantasy_event": TODO
signal response_choose_fantasy(Dictionary)

## Response for the result of an auction, shows who won
## Response Dictionary includes:
## - "winner": int
## - "final_amount": int
## - "is_tie": bool
signal response_auction(Dictionary)

# ACTION SIGNALS
## !IMPORTANT: The following action signals all contain the data from action_general

## General action, comes in every action
## Action dictionary includes:
## - "game": int		- ID of the game the action took place in
## - "player": int	- ID of the player that took action
signal action_general(Dictionary)

## Action sent when throwing dices
## Dictionary doesnt contain additional info
signal action_throw_dices(Dictionary)

## Action sent when the player chooses the tile to move to
## Action dictionary includes:
## - "square": String	- ID of the tile the player moved to
signal action_move_to(Dictionary)

## Action sent when the tram is taken
## Action dictionary includes:
## - "square": String	- ID of the tile the player moved to
signal action_take_tram(Dictionary)

## Action sent when the player declines a property purchase and starts an auction
## Action dictionary includes:
## - "square": String	- ID of the tile the player started an auction on
signal action_start_auction(Dictionary)

## Action sent when the player bought a square
## Action dictionary includes:
## - "square": String	- ID of the tile the player bought
signal action_buy_square(Dictionary)

## Action sent when buildings are purchased on a tile
## Action dictionary includes:
## - "houses": int		- Number of houses built in the property
## - "square": String	- ID of the tile the houses where built
signal action_build(Dictionary)

## Action sent when buildings are sold on a tile
## Action dictionary includes:
## - "houses": int		- Number of houses sold in the property
## - "square": String	- ID of the tile the houses where sold
signal action_demolish(Dictionary)

## Action sent when a fantasy card is chosen
## Action dictionary includes:
## - "chosen_revealed_card": bool	- true if the up-facing card is chosen
signal action_choose_card(Dictionary)

## Action sent when surrendering the game
## Dictionary doesnt contain additional info
signal action_surrender(Dictionary)

## Action sent when making a trade proposal
## Action dictionary includes:
## - "destination_user": int				- ID of the user to recieve the proposal
## - "offered_money": int				- Quantity of money to recieve in the trade
## - "asked_money": int					- Quantity of money to lose in the trade
## - "offered_properties": Array[String] - List of properties to gain in the trade
## - "asked_properties": Array[String]	- List of properties to lose in the trade
signal action_trade_proposal(Dictionary)

## Action sent when responding to a trade proposal
## Action dictionary includes:
## - "choose": bool		- true if the proposal is accepted, false otherwise
signal action_trade_answer(Dictionary)

## Action sent when mortgaging a property
## Action dictionary includes:
## - "square": String	- ID of the tile to mortgage
signal action_mortgage_set(Dictionary)

## Action sent when paying the mortgage of a property
## Action dictionary includes:
## - "square": String	- ID of the tile to pay the mortgage of
signal action_mortgage_unset(Dictionary)

## Action sent when the bail is paid
## Dictionary doesnt contain additional info
signal action_pay_bail(Dictionary)

## Action sent when ending the current phase
## Dictionary doesnt contain additional info
signal action_next_phase(Dictionary)

## Action sent when bidding on a property
## Action dictionary includes:
## - "amount": int	- Amount bidded on the property
signal action_bid(Dictionary)

# =================
#  CLASS ATRIBUTES
# =================
var socket = WebSocketPeer.new() # WS instance
var game_id: int # ID of the current playing game (Only valid if _conn_state = IN_GAME)
var player_id: int # ID of the player (Only valid if _conn_state = IN_GAME)
var session_id: String # ID of the session
var player_username: String # Username of the player
var _conn_state: ConnState = ConnState.START # Internal state of the connection

# The following comes straight from the Godot docs with slight modifications:
# https://docs.godotengine.org/en/stable/tutorials/networking/websocket.html#using-websocket-in-godot

func _safe_connect(url: String, headers: PackedStringArray = []) -> void:
	# Initiate connection to the given URL.
	socket.handshake_headers = headers
	var err = socket.connect_to_url(url)
	if err == OK:
		Utils.debug("Started WS in URL: " + url)
		set_process(true)
	else:
		Utils.debug("ERROR: Unable to connect to " + url)

## WARNING: You probably shouldn't be using this. There should be a
## specific function in this class that abstracts your interaction logic.
func send_data(data_to_send: Variant) -> void:
	data_to_send = JSON.stringify(data_to_send)
	socket.send_text(data_to_send)

func start_client_public_queue() -> void:
	_safe_connect(
		Globals.WS_BASE_URL + "/queue/public/",
		["Cookie: sessionid=" + session_id]
	)
	_conn_state = ConnState.IN_PUBLIC_QUEUE

func start_client_private_lobby(lobby_code: String) -> void:
	_safe_connect(Globals.WS_BASE_URL + "/room/" + lobby_code)
	_conn_state = ConnState.IN_PRIVATE_QUEUE

func _ready() -> void:
	set_process(false)

func _process(_delta) -> void:
	# Data transfer and state updates will only happen when calling this function.
	socket.poll()

	while socket.get_available_packet_count():
		var packet = socket.get_packet()
		if socket.was_string_packet():
			var packet_text: String = packet.get_string_from_utf8()
			var response: Dictionary = JSON.parse_string(packet_text)
			Utils.debug("Got response " + str(response))
			if _conn_state == ConnState.IN_GAME:
				_game_dispatcher(response)
			elif _conn_state  == ConnState.IN_PUBLIC_QUEUE:
				_public_queue_dispatcher(response)
			elif _conn_state  == ConnState.IN_PRIVATE_QUEUE:
				_private_queue_dispatcher(response)
			else:
				Utils.debug("ERROR: Invalid _conn_state with open socket")
		else: # This shouldn't happen to us
			Utils.debug("ERROR: Got a binary packet")
	
	# get_ready_state() tells you what state the socket is in.
	var state = socket.get_ready_state()
	# `WebSocketPeer.STATE_OPEN` means the socket is connected and ready
	# to send and receive data.
	if state == WebSocketPeer.STATE_OPEN:
		pass
	# `WebSocketPeer.STATE_CLOSING` means the socket is closing.
	# It is important to keep polling for a clean close.
	elif state == WebSocketPeer.STATE_CLOSING:
		pass
	# `WebSocketPeer.STATE_CLOSED` means the connection has fully closed.
	# It is now safe to stop polling.
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = socket.get_close_code()
		var reason = socket.get_close_reason()
		Utils.debug("Socket closed. Code: %d, Reason: %s" % [code, reason])
		if code == 4001 and _conn_state == ConnState.GO_TO_GAME:
			Utils.debug("Connecting to game: " + str(game_id))
			_safe_connect(Globals.WS_BASE_URL + "/game/" + str(game_id) + "/")
			_conn_state = ConnState.IN_GAME
		else: # Reset the state
			_conn_state = ConnState.START
			set_process(false) # Stop processing.
			match_finished.emit()

# =====================
#  AUXILIARY FUNCTIONS
# =====================
func _normalize_tile_id(id: Variant) -> Variant:
	if typeof(id) == TYPE_INT:
		return "%03d" % id
	elif typeof(id) == TYPE_STRING:
		return "%03d" % int(id)
	elif typeof(id) == TYPE_PACKED_INT32_ARRAY:
		var new_array: Array[String]
		for i in id:
			new_array.append(_normalize_tile_id(i))
		return new_array
	Utils.debug("Invalid type to normalize tile ID.")
	return ""

func _phase_string_to_enum(phase: String) -> Phase:
	match phase:
		"roll_the_dices": return Phase.ROLL_THE_DICES
		"choose_square": return Phase.CHOOSE_SQUARE
		"choose_fantasy": return Phase.CHOOSE_FANTASY
		"management": return Phase.MANAGEMENT
		"business": return Phase.BUSINESS
		"liquidation": return Phase.LIQUIDATION
		"auction": return Phase.AUCTION
		"proposal_acceptance": return Phase.PROPOSAL_ACCEPTANCE
		"end_game": return Phase.END_GAME
		_: Utils.debug("Not recognized string phase: " + phase)
	return Phase.END_GAME

func _botlevel_enum_to_string(bot_level: BotLevel) -> String:
	match bot_level:
		BotLevel.EASY: return "easy"
		BotLevel.MEDIUM: return "medium"
		BotLevel.HARD: return "hard"
		_: Utils.debug("BotLevel - This is impossible")
	return ""

func _build_base_action() -> Dictionary:
	return {"game": game_id, "player": player_id,}

func _build_action(data: Dictionary = {}) -> Dictionary:
	data.merge(_build_base_action())
	return data

func _build_and_send_action(data: Dictionary) -> void:
	var action_data = _build_action(data)
	send_data(action_data)

# =============
#  DISPATCHERS
# =============
func _public_queue_dispatcher(response: Dictionary) -> void:
	if not response.has("action"): return
	if response["action"] == "error":
		Utils.debug("ERROR: Error joining public game: " + response["message"])
		return
	
	if response["action"] == "match_found":
		game_id = response["game_id"]
		_conn_state = ConnState.GO_TO_GAME
		public_match_found.emit()

func _private_queue_dispatcher(response: Dictionary) -> void:
	if not response.has("action"): return
	if response["action"] == "error":
		Utils.debug("ERROR: Error joining private game: " + response["message"])
		return
	
	if response["action"] == "joined":
		player_join.emit(response)
	elif response["action"] == "player_left":
		player_leave.emit(response)
	elif response["action"] == "ready_status":
		player_ready.emit(response)
	elif response["action"] == "game_start":
		private_match_found.emit()
		game_id = response["game_id"]
		_conn_state = ConnState.GO_TO_GAME

# TODO
func _game_action_dispatcher(action: Dictionary) -> void:
	pass

# TODO
func _game_state_dispatcher(state: Dictionary) -> void:
	pass

func _game_response_dispatcher(response: Dictionary) -> void:
	if not response.has("phase") or not response.has("type"):
		Utils.debug("ERROR: Response doesnt have a phase or type")
	
	Utils.debug("Received " + response["type"])
	response["phase"] = _phase_string_to_enum(response["phase"])
	response_general.emit(response)
	match response["type"]:
		"ResponseMovement": Utils.debug("ERROR: Received ResponseMovement, this shouldnt happen")
		"ResponseThrowDices": response_throw_dices.emit(response)
		"ResponseChooseSquare": response_choose_square.emit(response)
		"ResponseChooseFantasy": response_choose_fantasy.emit(response)
		"ResponseAuction": response_auction.emit(response)

func _game_dispatcher(response: Dictionary) -> void:
	if not response.has("event_type"):
		Utils.debug("ERROR: Response without 'event_type' key")
		return
	match response["event_type"]:
		"error": error.emit(response["data"]["message"])
		"chat_message": chat_message.emit(response)
		"init_identity":
			player_id = response["data"]["player_id"]
			player_username = response["data"]["username"]
		"game_state": _game_state_dispatcher(response["game_state"])
		"game_response": _game_response_dispatcher(response["data"])
		"game_action": _game_action_dispatcher(response["data"])

# Now we get into the specifics of the communication
# The following functions encapsulate outgoing messages

# ==============
#  PUBLIC QUEUE
# ==============
## Cancels the queueing
func ws_public_queue_cancel() -> void:
	send_data({"action": "cancel"})

# ================
#  PRIVATE QUEUE
# ================
## Sends lobby ready message
func ws_private_lobby_readystatus(is_ready: bool) -> void:
	send_data({"command": "ready_status", "is_ready": is_ready})

## Send game start message as lobby owner
func ws_private_lobby_start() -> void:
	send_data({"command": "start_game"})

## Send new lobby settings as lobby owner
func ws_private_lobby_settings(bot_level: BotLevel, target_players: int) -> void:
	var bot_level_string: String = _botlevel_enum_to_string(bot_level)
	send_data({
		"command": "update_settings",
		"bot_level": bot_level_string,
		"target_players": target_players
	})

# ================
#  INGAME ACTIONS
# ================
## Chat message sending
func ws_send_chat_message(message: String) -> void:
	send_data({"type": "ChatMessage", "msg": message})

## Action: Throw the dice
func ws_action_throw_dice() -> void:
	_build_and_send_action({"type": "ActionThrowDices"})

## Action: Move to the given tile
## @params:
## - tile_id: ID of the tile to move to
func ws_action_move_to(tile_id: String) -> void:
	_build_and_send_action({"type": "ActionMoveTo", "square": int(tile_id)})

## Action: Buy property in given tile
## @params:
## - tile_id: ID of the tile to buy
func ws_action_buy_property(tile_id: String) -> void:
	_build_and_send_action({"type": "ActionBuySquare", "square": int(tile_id)})

## Action: Build houses in given property
## @params:
## - tile_id: ID of the tile where to build
## - houses: number of houses to build
func ws_action_build_house(tile_id: String, houses: int) -> void:
	_build_and_send_action({"type": "ActionBuild", "square": int(tile_id), "houses": houses})

## Action: Demolish houses in given property
## @params:
## - tile_id: ID of the tile where to demolish
## - houses: number of houses to demolish
func ws_action_demolish_house(tile_id: String, houses: int) -> void:
	_build_and_send_action({"type": "ActionDemolish", "square": int(tile_id), "houses": houses})

## Action: Mortgages a given property
## @params:
## - tile_id: ID of the tile to mortgage
func ws_action_mortgage_property(tile_id: String) -> void:
	_build_and_send_action({"type": "ActionMortgageSet", "square": int(tile_id)})

## Action: Unmortgages a given property
## @params:
## - tile_id: ID of the tile to unmortgage
func ws_action_unmortgage_property(tile_id: String) -> void:
	_build_and_send_action({"type": "ActionMortgageUnset", "square": int(tile_id)})

## Action: Starts an auction on the given tile
## @params:
## - tile_id: ID of the tile to auction
func ws_action_start_auction(tile_id: String) -> void:
	_build_and_send_action({"type": "ActionDropPurchase", "square": int(tile_id)})

## Action: Takes the tram to a given tile
## @params:
## - tile_id: ID of the tile to travel to
func ws_action_take_tram_to(tile_id: String) -> void:
	_build_and_send_action({"type": "ActionTakeTram", "square": int(tile_id)})

## Action: Chooses a fantasy card
## @params:
## - choose_revealed_card: True if the front-facing card is chosen, False otherwise
func ws_action_choose_fantasy_card(choose_revealed_card: bool) -> void:
	_build_and_send_action({"type": "ActionChooseCard", "chosen_revealed_card": choose_revealed_card})

## Action: Bids amount on current auction
## @params:
## - amount: amount of money to bid
func ws_action_bid(amount: int) -> void:
	_build_and_send_action({"type": "ActionBid", "amount": amount})

## Action: Ends current phase
func ws_action_end_current_phase() -> void:
	_build_and_send_action({"type": "ActionNextPhase"})

## Action: Starts a trade with user give its id
## @params:
## - destination_user_id: ID of the user to send the trade
## - offered_money: amount of money offered to the target user
## - asked_monery: amount of money asked from the target user
## - offered_properties: list of IDs of the properties offered to the target user
## - asked_properties: list of IDs of the properties asked from the target user
func ws_action_start_trade(
	destination_user_id: int,
	offered_money: int,
	asked_money: int,
	offered_properties: Array[String],
	asked_properties: Array[String]
) -> void:
	var _offered_properties: String = ",".join(offered_properties)
	var _asked_properties: String = ",".join(asked_properties)
	_build_and_send_action({
		"type": "ActionTradeProposal",
		"destination_user": destination_user_id,
		"offered_money": offered_money,
		"asked_money": asked_money,
		"offered_properties": _offered_properties,
		"asked_properties": _asked_properties,
	})

## Action: Respond to the current trade
## @params:
## - accept: True if the trade was accepted
func ws_action_respond_to_trade(accept: bool) -> void:
	_build_and_send_action({
		"type": "ActionTradeAnswer",
		"choose": accept,
	})

## Action: Pays bail for current player
func ws_action_pay_bail() -> void:
	_build_and_send_action({"type": "ActionPayBail"})

## Action: Surrenders current player
func ws_action_surrender() -> void:
	_build_and_send_action({"type": "ActionSurrender"})
