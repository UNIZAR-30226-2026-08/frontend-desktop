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
## and responses (sent to players from the backend), you send actions and
## recieve all actions and responses (both actions from other players and yourself).
## Outside of the game some messages for queue administration are sent.

# =======
#  ENUMS
# =======
## Possible types of fantasy card events
enum FantasyEventType {
	WIN_PLAIN_MONEY, # Gives the player money in absolute terms
	WIN_RATION_MONEY, # Gives the player money in percetages (relative to their current wealth)
	LOSE_PLAIN_MONEY, # Takes money from the player in absolute terms
	LOSE_RATIO_MONEY, # Takes money from the player in percentages (relative to their current wealth)
	SHARE_MONEY_ALL, # The player sends money to all other players
	EVERYBODY_SENDS_YOU_MONEY, # Receive money (absolute) from all the players
	DOUBLE_OR_NOTHING, # Toss a coin to see if you double your money or lose it all
	GET_PARKING_MONEY, # Receive the money stored in the parking
	GO_TO_JAIL, # Go to the jail tile
	SEND_TO_JAIL, # Send someone to the jail tile # TODO: Choose who to send?
	SHUFFLE_POSITIONS, # Randomly shuffle all player positions TODO: Randomly?
	MOVE_ANYWHERE_RANDOM, # Randomly move somewhere
	MOVE_OPPONENT_ANYWHERE_RANDOM, # Randomly move an opponent somewhere
	MAGNETISM, # All players move to the players tile
	GO_TO_START, # Move to the start tile and get the start tile money
	BREAK_OPPONENT_HOUSE, # Break an opponents house (lastest built)
	BREAK_OWN_HOUSE, # Break one of the players houses (lastest built)
	FREE_HOUSE, # Build a free house (priciest house the player could build if it had the money)
	REVIVE_PROPERTY, # Unmortgages a property TODO: Choose property? Can it be opponent properties?
	EARTHQUAKE, # All streets miss a property
}

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
## It works by setting the percentage of moves that the bot makes randomly.
## The moves that are not random are have an IA implemented. Percentages of random:
## 100%, 80%, 60%, 40%, 20%, 0%
enum BotLevel {VERY_EASY, EASY, MEDIUM, HARD, VERY_HARD, EXPERT}

## Internal state of the WS client
## START is the starting state, not connected anywhere
## IN_PUBLIC_QUEUE the client is connected to a public queue
## IN_PRIVATE_QUEUE the client is connected to a private queue
## GO_TO_GAME a game was found but the client isn't connected yet
## IN_GAME the client is connected to a game
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

## For the following 2 signals define FantasyEvent as a Dictionary with:
## - "fantasy_type": FantasyEventType	- Enum type of fantasy event
## - "value": int | None					- value to apply the effect, might not apply
## - "card_cost": int					- Cost of buying the card

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
## - "fantasy_event": FantasyEvent	- See above
signal response_throw_dices(Dictionary)

## Response for an square election
## Response Dictionary includes:
## - "path": Array[String]			- Movement path to follow (list of ids)
## - "fantasy_event": FantasyEvent	- See above
signal response_choose_square(Dictionary)

## For the following signal define FantasyResult as a Dictionary with:
## - "fantasy_event": FantasyEvent	- See above
## - "result": Dictionary | null		- Depends on "fantasy_event"
##			null for: WIN_PLAIN_MONEY, WIN_RATIO_MONEY, LOSE_PLAIN_MONEY,
##					LOSE_RATIO_MONEY, SHARE_MONEY_ALL, EVERYBODY_SENDS_YOU_MONEY,
##					GET_PARKING_MONEY, GO_TO_JAIL, EVERYBODY_TO_JAIL,
##					SHUFFLE_POSITIONS, MOVE_ANYWHERE_RANDOM, MAGNETISM, GO_TO_START
##			{"square": custom_id} for: BREAK_OPPONENT_HOUSE, BREAK_OWN_HOUSE,
##					FREE_HOUSE, RECEIVE_PROPERTY
##			{"squares": [custom_id, ...]} for: EARTHQUAKE
##			{"target_player": pk} for: MOVE_OPPONENT_ANYWHERE_RANDOM, SEND_TO_JAIL
##			{"doubled": bool} for: DOUBLE_OR_NOTHING

## Response to a fantasy card choice
## Response Dictionary includes:
## - "fantasy_result": FantasyResult
signal response_choose_fantasy(Dictionary)

## Response for the result of an auction, shows who won
## Response Dictionary includes:
## - "winner": int
## - "final_amount": int
## - "is_tie": bool
signal response_auction(Dictionary)

# ACTION SIGNALS
## !IMPORTANT: The following action signals all contain the data from action_general

## Action sent when throwing dices
## Action dictionary includes:
## - "game": int		- ID of the game the action took place in
## - "player": int	- ID of the player that took action
signal action_throw_dices(Dictionary)

## Action sent when the player chooses the tile to move to
## Action dictionary includes:
## - "game": int			- ID of the game the action took place in
## - "player": int		- ID of the player that took action
## - "square": String	- ID of the tile the player moved to
signal action_move_to(Dictionary)

## Action sent when the tram is taken
## Action dictionary includes:
## - "game": int			- ID of the game the action took place in
## - "player": int		- ID of the player that took action
## - "square": String	- ID of the tile the player moved to
signal action_take_tram(Dictionary)

## Action sent when the player declines a property purchase and starts an auction
## Action dictionary includes:
## - "game": int			- ID of the game the action took place in
## - "player": int		- ID of the player that took action
## - "square": String	- ID of the tile the player started an auction on
signal action_start_auction(Dictionary)

## Action sent when the player bought a square
## Action dictionary includes:
## - "game": int			- ID of the game the action took place in
## - "player": int		- ID of the player that took action
## - "square": String	- ID of the tile the player bought
signal action_buy_square(Dictionary)

## Action sent when buildings are purchased on a tile
## Action dictionary includes:
## - "game": int			- ID of the game the action took place in
## - "player": int		- ID of the player that took action
## - "houses": int		- Number of houses built in the property
## - "square": String	- ID of the tile the houses where built
signal action_build(Dictionary)

## Action sent when buildings are sold on a tile
## Action dictionary includes:
## - "game": int			- ID of the game the action took place in
## - "player": int		- ID of the player that took action
## - "houses": int		- Number of houses sold in the property
## - "square": String	- ID of the tile the houses where sold
signal action_demolish(Dictionary)

## Action sent when a fantasy card is chosen
## Action dictionary includes:
## - "game": int						- ID of the game the action took place in
## - "player": int					- ID of the player that took action
## - "chosen_revealed_card": bool	- true if the up-facing card is chosen
signal action_choose_card(Dictionary)

## Action sent when surrendering the game
## Action dictionary includes:
## - "game": int		- ID of the game the action took place in
## - "player": int	- ID of the player that took action
signal action_surrender(Dictionary)

## Action sent when making a trade proposal
## Action dictionary includes:
## - "game": int							- ID of the game the action took place in
## - "player": int						- ID of the player that took action
## - "destination_user": int				- ID of the user to recieve the proposal
## - "offered_money": int				- Quantity of money to recieve in the trade
## - "asked_money": int					- Quantity of money to lose in the trade
## - "offered_properties": Array[String] - List of properties to gain in the trade
## - "asked_properties": Array[String]	- List of properties to lose in the trade
signal action_trade_proposal(Dictionary)

## Action sent when responding to a trade proposal
## Action dictionary includes:
## - "game": int			- ID of the game the action took place in
## - "player": int		- ID of the player that took action
## - "choose": bool		- true if the proposal is accepted, false otherwise
signal action_trade_answer(Dictionary)

## Action sent when mortgaging a property
## Action dictionary includes:
## - "game": int			- ID of the game the action took place in
## - "player": int		- ID of the player that took action
## - "square": String	- ID of the tile to mortgage
signal action_mortgage_set(Dictionary)

## Action sent when paying the mortgage of a property
## Action dictionary includes:
## - "game": int			- ID of the game the action took place in
## - "player": int		- ID of the player that took action
## - "square": String	- ID of the tile to pay the mortgage of
signal action_mortgage_unset(Dictionary)

## Action sent when the bail is paid
## Action dictionary includes:
## - "game": int		- ID of the game the action took place in
## - "player": int	- ID of the player that took action
signal action_pay_bail(Dictionary)

## Action sent when ending the current phase
## Action dictionary includes:
## - "game": int		- ID of the game the action took place in
## - "player": int	- ID of the player that took action
signal action_next_phase(Dictionary)

## Action sent when bidding on a property
## Action dictionary includes:
## - "game": int		- ID of the game the action took place in
## - "player": int	- ID of the player that took action
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
var last_private_lobby_code: String = ""

# The following comes straight from the Godot docs with slight modifications:
# https://docs.godotengine.org/en/stable/tutorials/networking/websocket.html#using-websocket-in-godot

func _safe_connect(url: String, headers: PackedStringArray = ["Cookie: sessionid=" + session_id]) -> void:
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
	Utils.debug("Connecting to public queue with session: " + session_id)
	_safe_connect(Globals.WS_BASE_URL + "/queue/public/")
	_conn_state = ConnState.IN_PUBLIC_QUEUE

func start_client_private_lobby(lobby_code: String) -> void:
	last_private_lobby_code = lobby_code
	_safe_connect(Globals.WS_BASE_URL + "/queue/private/" + lobby_code + "/")
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
		if _conn_state == ConnState.GO_TO_GAME:
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
		BotLevel.VERY_EASY: return "very_easy"
		BotLevel.EASY: return "easy"
		BotLevel.MEDIUM: return "medium"
		BotLevel.HARD: return "hard"
		BotLevel.VERY_HARD: return "very_hard"
		BotLevel.EXPERT: return "expert"
		_: Utils.debug("BotLevel - This is impossible")
	return ""

func _fantasyeventtype_string_to_enum(event_string: String) -> FantasyEventType:
	match event_string:
		"winPlainMoney": return FantasyEventType.WIN_PLAIN_MONEY
		"winRationMoney": return FantasyEventType.WIN_RATION_MONEY
		"losePlainMoney": return FantasyEventType.LOSE_PLAIN_MONEY
		"loseRatioMoney": return FantasyEventType.LOSE_RATIO_MONEY
		"shareMoneyAll": return FantasyEventType.SHARE_MONEY_ALL
		"everybodySendsYouMoney": return FantasyEventType.EVERYBODY_SENDS_YOU_MONEY
		"doubleOrNothing": return FantasyEventType.DOUBLE_OR_NOTHING
		"getParkingMoney": return FantasyEventType.GET_PARKING_MONEY
		"goToJail": return FantasyEventType.GO_TO_JAIL
		"sendToJail": return FantasyEventType.SEND_TO_JAIL
		"shufflePositions": return FantasyEventType.SHUFFLE_POSITIONS
		"moveAnywhereRandom": return FantasyEventType.MOVE_ANYWHERE_RANDOM
		"moveOpponentAnywhereRandom": return FantasyEventType.MOVE_OPPONENT_ANYWHERE_RANDOM
		"magnetism": return FantasyEventType.MAGNETISM
		"goToStart": return FantasyEventType.GO_TO_START
		"breakOpponentHouse": return FantasyEventType.BREAK_OPPONENT_HOUSE
		"breakOwnHouse": return FantasyEventType.BREAK_OWN_HOUSE
		"freeHouse": return FantasyEventType.FREE_HOUSE
		"reviveProperty": return FantasyEventType.REVIVE_PROPERTY
		"earthquake": return FantasyEventType.EARTHQUAKE
		_: Utils.debug("Not recognized string fantasy event type: " + event_string)
		
	return FantasyEventType.WIN_PLAIN_MONEY

func _parse_fantasy_event(fantasy_event: Dictionary) -> Dictionary:
	fantasy_event["type"] = _fantasyeventtype_string_to_enum(fantasy_event["type"])
	return fantasy_event

func _parse_fantasy_result(fantasy_result: Dictionary) -> Dictionary:
	fantasy_result["fantasy_event"] = _parse_fantasy_event(fantasy_result["fantasy_event"])
	if not fantasy_result["result"]: return fantasy_result
	if fantasy_result["result"].has("square"):
		fantasy_result["result"]["square"] = _normalize_tile_id(fantasy_result["result"]["square"])
	elif fantasy_result["result"].has("squares"):
		fantasy_result["result"]["squares"] = _normalize_tile_id(fantasy_result["result"]["squares"])
	return fantasy_result

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
		socket.close(4001, "Match was found, connecting to game socket") # Close the connection once match_found received

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
		game_id = response["game_id"]
		_conn_state = ConnState.GO_TO_GAME
		private_match_found.emit()
		socket.close(4001, "Match was found, connecting to game socket") # Close the connection once game_start received

func _game_action_dispatcher(action: Dictionary) -> void:
	if not action.has("type"):
		Utils.debug("ERROR: Action doesnt have a type")
	
	if action.has("square"):
		action["square"] = _normalize_tile_id(action["square"])
	match action["type"]:
		"ActionThrowDices": action_throw_dices.emit(action)
		"ActionMoveTo": action_move_to.emit(action)
		"ActionTakeTram": action_take_tram.emit(action)
		"ActionDropPurchase": action_start_auction.emit(action)
		"ActionBuySquare": action_buy_square.emit(action)
		"ActionBuild": action_build.emit(action)
		"ActionDemolish": action_demolish.emit(action)
		"ActionChooseCard": action_choose_card.emit(action)
		"ActionSurrender": action_surrender.emit(action)
		"ActionTradeProposal":
			action["offered_properties"] = _normalize_tile_id(action["offered_properties"])
			action["asked_properties"] = _normalize_tile_id(action["asked_properties"])
			action_trade_proposal.emit(action)
		"ActionTradeAnswer": action_trade_answer.emit(action)
		"ActionMortgageSet": action_mortgage_set.emit(action)
		"ActionMortgageUnset": action_mortgage_unset.emit(action)
		"ActionPayBail": action_pay_bail.emit(action)
		"ActionNextPhase": action_next_phase.emit(action)
		"ActionBid": action_bid.emit(action)
		_: Utils.debug("ERROR: Unknown type in socket action")

func _game_response_dispatcher(response: Dictionary) -> void:
	if not response.has("phase") or not response.has("type"):
		Utils.debug("ERROR: Response doesnt have a phase or type")

	response["phase"] = _phase_string_to_enum(response["phase"])
	response_general.emit(response)
	match response["type"]:
		"ResponseMovement": Utils.debug("ERROR: Received ResponseMovement, this shouldnt happen")
		"ResponseThrowDices":
			response["path"] = _normalize_tile_id(response["path"])
			response["destinations"] = _normalize_tile_id(response["destinations"])
			if response["fantasy_event"]:
				response["fantasy_event"] = _parse_fantasy_event(response["fantasy_event"])
			response_throw_dices.emit(response)
		"ResponseChooseSquare":
			response["path"] = _normalize_tile_id(response["path"])
			if response["fantasy_event"]:
				response["fantasy_event"] = _parse_fantasy_event(response["fantasy_event"])
			response_choose_square.emit(response)
		"ResponseChooseFantasy":
			if response["fantasy_result"]:
				response["fantasy_result"] = _parse_fantasy_result(response["fantasy_result"])
			response_choose_fantasy.emit(response)
		"ResponseAuction": response_auction.emit(response)
		_: Utils.debug("ERROR: Unknown type in socket response")

func _game_dispatcher(response: Dictionary) -> void:
	if not response.has("action"):
		Utils.debug("ERROR: Response without 'action' key")
		return

	match response["action"]:
		"error": error.emit(response["data"]["message"])
		"chat_message": chat_message.emit(response)
		"init_identity":
			player_id = response["data"]["player_id"]
			player_username = response["data"]["username"]
		"game_state": game_state.emit(response["game_state"])
		"game_response": _game_response_dispatcher(response["data"])
		"game_action": _game_action_dispatcher(response["data"])
		_: Utils.debug("ERROR: Unknown action in socket message")

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
	ws_private_lobby_readystatus(true) # Set ready to true
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
	_build_and_send_action({"type": "ActionTradeAnswer", "choose": accept})

## Action: Pays bail for current player
func ws_action_pay_bail() -> void:
	_build_and_send_action({"type": "ActionPayBail"})

## Action: Surrenders current player
func ws_action_surrender() -> void:
	_build_and_send_action({"type": "ActionSurrender"})
