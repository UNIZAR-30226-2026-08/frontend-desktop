# MagnateWSClient    
**Extends** Node
        
**MagnateWSClient** makes use of the Godot WebSocket API. It exposes public functions that send the packages to the backend and signals that emit when certain packages from the backend are received. Each of them has 3 sections for 3 different stages of the communication: - Private queue: for communication related to the private lobby - Public queue: for communication when public queueing - In game: for in game logic and comms Some explaining about how communication with the backend is designed: During the game it works with actions (sent by players to the backend) and responses (sent to players from backend), you send actions and recieve all actions and responses (even those from other players). Outside of the game some messages for queue administration are sent. 



---
# Signals

| | Signal Name | Signal Arguments |
| --- | :--- | ---: |
| signal | **[error](#signal-error)** | String| signal | **[chat_message](#signal-chat_message)** | Dictionary| signal | **[game_state](#signal-game_state)** | Dictionary| signal | **[public_match_found](#signal-public_match_found)** | | signal | **[player_join](#signal-player_join)** | Dictionary| signal | **[player_leave](#signal-player_leave)** | Dictionary| signal | **[player_ready](#signal-player_ready)** | Dictionary| signal | **[private_match_found](#signal-private_match_found)** | | signal | **[match_finished](#signal-match_finished)** | | signal | **[response_general](#signal-response_general)** | Dictionary| signal | **[response_throw_dices](#signal-response_throw_dices)** | Dictionary| signal | **[response_choose_square](#signal-response_choose_square)** | Dictionary| signal | **[response_choose_fantasy](#signal-response_choose_fantasy)** | Dictionary| signal | **[response_auction](#signal-response_auction)** | Dictionary| signal | **[action_general](#signal-action_general)** | Dictionary| signal | **[action_throw_dices](#signal-action_throw_dices)** | Dictionary| signal | **[action_move_to](#signal-action_move_to)** | Dictionary| signal | **[action_take_tram](#signal-action_take_tram)** | Dictionary| signal | **[action_start_auction](#signal-action_start_auction)** | Dictionary| signal | **[action_buy_square](#signal-action_buy_square)** | Dictionary| signal | **[action_build](#signal-action_build)** | Dictionary| signal | **[action_demolish](#signal-action_demolish)** | Dictionary| signal | **[action_choose_card](#signal-action_choose_card)** | Dictionary| signal | **[action_surrender](#signal-action_surrender)** | Dictionary| signal | **[action_trade_proposal](#signal-action_trade_proposal)** | Dictionary| signal | **[action_trade_answer](#signal-action_trade_answer)** | Dictionary| signal | **[action_mortgage_set](#signal-action_mortgage_set)** | Dictionary| signal | **[action_mortgage_unset](#signal-action_mortgage_unset)** | Dictionary| signal | **[action_pay_bail](#signal-action_pay_bail)** | Dictionary| signal | **[action_next_phase](#signal-action_next_phase)** | Dictionary| signal | **[action_bid](#signal-action_bid)** | Dictionary
---
# Properties
| | Property Name | Property Type | Property Default Value |
| --- | :--- | :---: | ---: |
| enum | **[Phase](#enum-phase)** | *enum* | ROLL_THE_DICES, # A dice roll is needed CHOOSE_SQUARE, # A tile needs to be chosen (multiple possible) CHOOSE_FANTASY, # A fantasy card must be selected MANAGEMENT, # Decide to buy or auction a property BUSINESS, # Property administration phase, build houses, mortgage... LIQUIDATION, # Player has negative balance and must sell something AUCTION, # An auction is taking place PROPOSAL_ACCEPTANCE, # The player must accept or decline the incoming offer END_GAME, # The game is finished |
| enum | **[BotLevel](#enum-botlevel)** | *enum* | EASY, MEDIUM, HARD |
| enum | **[ConnState](#enum-connstate)** | *enum* | START, IN_PUBLIC_QUEUE, IN_PRIVATE_QUEUE, GO_TO_GAME, IN_GAME |
| var | **[socket](#var-socket)** | ** | WebSocketPeer.new() # WS instance |
| var | **[game_id](#var-game_id)** | *int # ID of the current playing game (Only valid if _conn_state* | IN_GAME) |
| var | **[player_id](#var-player_id)** | *int # ID of the player (Only valid if _conn_state* | IN_GAME) |
| var | **[session_id](#var-session_id)** | *int # ID of the session* |  |
| var | **[player_username](#var-player_username)** | *String # Username of the player* |  |
| var | **[_conn_state](#var-_conn_state)** | *ConnState* | ConnState.START # Internal state of the connection |


---
# Functions

| | Function Name | Function Arguments | Function Return Value |
| --- | :--- | :--- | ---: |
| public | **[send_data](#void-send_data)** | data_to_send: Variant<br> | void
| public | **[start_client_public_queue](#void-start_client_public_queue)** |  | void
| public | **[start_client_private_lobby](#void-start_client_private_lobby)** | lobby_code: String<br> | void
| public | **[ws_public_queue_cancel](#void-ws_public_queue_cancel)** |  | void
| public | **[ws_private_lobby_readystatus](#void-ws_private_lobby_readystatus)** | is_ready: bool<br> | void
| public | **[ws_private_lobby_start](#void-ws_private_lobby_start)** |  | void
| public | **[ws_private_lobby_settings](#void-ws_private_lobby_settings)** | bot_level: BotLevel<br>target_players: int<br> | void
| public | **[ws_send_chat_message](#void-ws_send_chat_message)** | message: String<br> | void
| public | **[ws_action_throw_dice](#void-ws_action_throw_dice)** |  | void
| public | **[ws_action_move_to](#void-ws_action_move_to)** | tile_id: String<br> | void
| public | **[ws_action_buy_property](#void-ws_action_buy_property)** | tile_id: String<br> | void
| public | **[ws_action_build_house](#void-ws_action_build_house)** | tile_id: String<br>houses: int<br> | void
| public | **[ws_action_demolish_house](#void-ws_action_demolish_house)** | tile_id: String<br>houses: int<br> | void
| public | **[ws_action_mortgage_property](#void-ws_action_mortgage_property)** | tile_id: String<br> | void
| public | **[ws_action_unmortgage_property](#void-ws_action_unmortgage_property)** | tile_id: String<br> | void
| public | **[ws_action_start_auction](#void-ws_action_start_auction)** | tile_id: String<br> | void
| public | **[ws_action_take_tram_to](#void-ws_action_take_tram_to)** | tile_id: String<br> | void
| public | **[ws_action_choose_fantasy_card](#void-ws_action_choose_fantasy_card)** | choose_revealed_card: bool<br> | void
| public | **[ws_action_bid](#void-ws_action_bid)** | amount: int<br> | void
| public | **[ws_action_end_current_phase](#void-ws_action_end_current_phase)** |  | void
| public | **[ws_action_start_trade](#void-ws_action_start_trade)** | destination_user_id: int<br>offered_money: int<br>asked_money: int<br>offered_properties: Array[String]<br>asked_properties: Array[String]<br> | void
| public | **[ws_action_respond_to_trade](#void-ws_action_respond_to_trade)** | accept: bool<br> | void
| public | **[ws_action_pay_bail](#void-ws_action_pay_bail)** |  | void
| public | **[ws_action_surrender](#void-ws_action_surrender)** |  | void
| private | **[_safe_connect](#void-_safe_connect)** | url: String<br> | void
| private | **[_ready](#void-_ready)** |  | void
| private | **[_process](#void-_process)** | _delta<br> | void
| private | **[_normalize_tile_id](#variant-_normalize_tile_id)** | id: Variant<br> | Variant
| private | **[_phase_string_to_enum](#phase-_phase_string_to_enum)** | phase: String<br> | Phase
| private | **[_botlevel_enum_to_string](#string-_botlevel_enum_to_string)** | bot_level: BotLevel<br> | String
| private | **[_build_base_action](#dictionary-_build_base_action)** |  | Dictionary
| private | **[_build_action](#dictionary-_build_action)** | data: Dictionary = {}<br> | Dictionary
| private | **[_build_and_send_action](#void-_build_and_send_action)** | data: Dictionary<br> | void
| private | **[_public_queue_dispatcher](#void-_public_queue_dispatcher)** | response: Dictionary<br> | void
| private | **[_private_queue_dispatcher](#void-_private_queue_dispatcher)** | response: Dictionary<br> | void
| private | **[_game_action_dispatcher](#void-_game_action_dispatcher)** | action: Dictionary<br> | void
| private | **[_game_state_dispatcher](#void-_game_state_dispatcher)** | state: Dictionary<br> | void
| private | **[_game_response_dispatcher](#void-_game_response_dispatcher)** | response: Dictionary<br> | void
| private | **[_game_dispatcher](#void-_game_dispatcher)** | response: Dictionary<br> | void


---
# Signals


---
## SIGNALS
### signal error
(**String**)

Emitted when an error is received, String contains the error message
### signal chat_message
(**Dictionary**)

Emitted when a chat message is received Dictionary contains: - "user": String - Name of the chat message sender - "msg": String - Contents of the chat message
### signal game_state
(**Dictionary**)

Emitted when a game state is received, you should probably set everything to this values Dictionary contains: TODO
### signal public_match_found

Emitted when a match is found
### signal player_join
(**Dictionary**)

Emitted when a player joins the lobby Dictionary contains: - "user": String - Username of the user that joined - "owner": String - Username of the owner of the lobby - "is_owner": bool - True if I am the owner (NOTE: **I**, not the joined player) - "players": Array[Dictionary] - Array with info on each player - Dictionary contains: "username": String and "ready_to_play": bool
### signal player_leave
(**Dictionary**)

Emitted when a player leaves the lobby Dictionary contains: - "user_left": String - Username of the user that left - "owner": String - Username of the owner of the lobby - "is_owner": bool - True if I am the owner (NOTE: **I**, not the joined player) - "players": Array[Dictionary] - Array with info on each player - Dictionary contains: "username": String and "ready_to_play": bool
### signal player_ready
(**Dictionary**)

Emitted when a player changes ready status Dictionary contains: - "user": String - Username of the user that changes status - "is_ready": bool - New status of the user - "owner": String - Username of the owner of the lobby - "is_owner": bool - True if I am the owner (NOTE: **I**, not the joined player)
### signal private_match_found

Emitted when a private lobby starts the game
### signal match_finished

Emitted when a match is finished
### signal response_general
(**Dictionary**)

General response, comes with every response Response Dictionary includes: - "money": Dictionary[String, int] - Dictionary with ids of players and their money - "active_phase_player": int - ID of the player playing the current phase - "active_turn_player": int - ID of the player playing the current turn - "phase": Enum <Phase> above - phase of the game
### signal response_throw_dices
(**Dictionary**)

Response to a dice throw, contains result of the throw Response Dictionary includes: - "path": Array[String], - Movement path to follow (list of ids), if multiple destinations then dont use this the correct path will be in response_choose_square - "dice1": int, - Result of the first dice - "dice2": int, - Result of the second dice - "dice_bus": int, - Result of the bus/third dice - "destinations": Array[String], - Possible destinations for the player (list of ids) - "triple": bool, - If the throw is a triple - "streak": int - Streak of doubles for the current player - "fantasy_event": TODO
### signal response_choose_square
(**Dictionary**)

Response for an square election Response Dictionary includes: - "path": Array[String] - Movement path to follow (list of ids) - "fantasy_event": TODO
### signal response_choose_fantasy
(**Dictionary**)

Response to a fantasy card choice Response Dictionary includes: - "fantasy_event": TODO
### signal response_auction
(**Dictionary**)

Response for the result of an auction, shows who won Response Dictionary includes: - "winner": int - "final_amount": int - "is_tie": bool
### signal action_general
(**Dictionary**)

General action, comes in every action Action dictionary includes: - "game": int - ID of the game the action took place in - "player": int - ID of the player that took action
### signal action_throw_dices
(**Dictionary**)

Action sent when throwing dices Dictionary doesnt contain additional info
### signal action_move_to
(**Dictionary**)

Action sent when the player chooses the tile to move to Action dictionary includes: - "square": String - ID of the tile the player moved to
### signal action_take_tram
(**Dictionary**)

Action sent when the tram is taken Action dictionary includes: - "square": String - ID of the tile the player moved to
### signal action_start_auction
(**Dictionary**)

Action sent when the player declines a property purchase and starts an auction Action dictionary includes: - "square": String - ID of the tile the player started an auction on
### signal action_buy_square
(**Dictionary**)

Action sent when the player bought a square Action dictionary includes: - "square": String - ID of the tile the player bought
### signal action_build
(**Dictionary**)

Action sent when buildings are purchased on a tile Action dictionary includes: - "houses": int - Number of houses built in the property - "square": String - ID of the tile the houses where built
### signal action_demolish
(**Dictionary**)

Action sent when buildings are sold on a tile Action dictionary includes: - "houses": int - Number of houses sold in the property - "square": String - ID of the tile the houses where sold
### signal action_choose_card
(**Dictionary**)

Action sent when a fantasy card is chosen Action dictionary includes: - "chosen_revealed_card": bool - true if the up-facing card is chosen
### signal action_surrender
(**Dictionary**)

Action sent when surrendering the game Dictionary doesnt contain additional info
### signal action_trade_proposal
(**Dictionary**)

Action sent when making a trade proposal Action dictionary includes: - "destination_user": int - ID of the user to recieve the proposal - "offered_money": int - Quantity of money to recieve in the trade - "asked_money": int - Quantity of money to lose in the trade - "offered_properties": Array[String] - List of properties to gain in the trade - "asked_properties": Array[String] - List of properties to lose in the trade
### signal action_trade_answer
(**Dictionary**)

Action sent when responding to a trade proposal Action dictionary includes: - "choose": bool - true if the proposal is accepted, false otherwise
### signal action_mortgage_set
(**Dictionary**)

Action sent when mortgaging a property Action dictionary includes: - "square": String - ID of the tile to mortgage
### signal action_mortgage_unset
(**Dictionary**)

Action sent when paying the mortgage of a property Action dictionary includes: - "square": String - ID of the tile to pay the mortgage of
### signal action_pay_bail
(**Dictionary**)

Action sent when the bail is paid Dictionary doesnt contain additional info
### signal action_next_phase
(**Dictionary**)

Action sent when ending the current phase Dictionary doesnt contain additional info
### signal action_bid
(**Dictionary**)

Action sent when bidding on a property Action dictionary includes: - "amount": int - Amount bidded on the property



---
# Properties


---
## ENUMS
### enum Phase
- **type:** enum

- *[default value = roll_the_dices, # a dice roll is needed choose_square, # a tile needs to be chosen (multiple possible) choose_fantasy, # a fantasy card must be selected management, # decide to buy or auction a property business, # property administration phase, build houses, mortgage... liquidation, # player has negative balance and must sell something auction, # an auction is taking place proposal_acceptance, # the player must accept or decline the incoming offer end_game, # the game is finished]*

Phases of the game
### enum BotLevel
- **type:** enum

- *[default value = easy, medium, hard]*

Levels of difficulty for bots in the private lobby
### enum ConnState
- **type:** enum

- *[default value = start, in_public_queue, in_private_queue, go_to_game, in_game]*

Internal state enum (Ignore)



---
## PUBLIC VARS
### var socket
- *[default value = websocketpeer.new() # ws instance]*
### var game_id
- **type:** int # id of the current playing game (only valid if _conn_state

- *[default value = in_game)]*
### var player_id
- **type:** int # id of the player (only valid if _conn_state

- *[default value = in_game)]*
### var session_id
- **type:** int # id of the session
### var player_username
- **type:** string # username of the player



---
## PRIVATE VARS
### var _conn_state
- **type:** connstate

- *[default value = connstate.start # internal state of the connection]*



---
# Functions


---
## PUBLIC FUNCS
### (void) send_data
- **data_to_send: Variant**


WARNING: You probably shouldn't be using this. There should be a specific function in this class that abstracts your interaction logic.
### (void) start_client_public_queue

### (void) start_client_private_lobby
- **lobby_code: String**

### (void) ws_public_queue_cancel


Cancels the queueing
### (void) ws_private_lobby_readystatus
- **is_ready: bool**


Sends lobby ready message
### (void) ws_private_lobby_start


Send game start message as lobby owner
### (void) ws_private_lobby_settings
- **bot_level: BotLevel**
- **target_players: int**


Send new lobby settings as lobby owner
### (void) ws_send_chat_message
- **message: String**


Chat message sending
### (void) ws_action_throw_dice


Action: Throw the dice
### (void) ws_action_move_to
- **tile_id: String**


Action: Move to the given tile @params: - tile_id: ID of the tile to move to
### (void) ws_action_buy_property
- **tile_id: String**


Action: Buy property in given tile @params: - tile_id: ID of the tile to buy
### (void) ws_action_build_house
- **tile_id: String**
- **houses: int**


Action: Build houses in given property @params: - tile_id: ID of the tile where to build - houses: number of houses to build
### (void) ws_action_demolish_house
- **tile_id: String**
- **houses: int**


Action: Demolish houses in given property @params: - tile_id: ID of the tile where to demolish - houses: number of houses to demolish
### (void) ws_action_mortgage_property
- **tile_id: String**


Action: Mortgages a given property @params: - tile_id: ID of the tile to mortgage
### (void) ws_action_unmortgage_property
- **tile_id: String**


Action: Unmortgages a given property @params: - tile_id: ID of the tile to unmortgage
### (void) ws_action_start_auction
- **tile_id: String**


Action: Starts an auction on the given tile @params: - tile_id: ID of the tile to auction
### (void) ws_action_take_tram_to
- **tile_id: String**


Action: Takes the tram to a given tile @params: - tile_id: ID of the tile to travel to
### (void) ws_action_choose_fantasy_card
- **choose_revealed_card: bool**


Action: Chooses a fantasy card @params: - choose_revealed_card: True if the front-facing card is chosen, False otherwise
### (void) ws_action_bid
- **amount: int**


Action: Bids amount on current auction @params: - amount: amount of money to bid
### (void) ws_action_end_current_phase


Action: Ends current phase
### (void) ws_action_start_trade
- **destination_user_id: int**
- **offered_money: int**
- **asked_money: int**
- **offered_properties: Array[String]**
- **asked_properties: Array[String]**


Action: Starts a trade with user give its id @params: - destination_user_id: ID of the user to send the trade - offered_money: amount of money offered to the target user - asked_monery: amount of money asked from the target user - offered_properties: list of IDs of the properties offered to the target user - asked_properties: list of IDs of the properties asked from the target user
### (void) ws_action_respond_to_trade
- **accept: bool**


Action: Respond to the current trade @params: - accept: True if the trade was accepted
### (void) ws_action_pay_bail


Action: Pays bail for current player
### (void) ws_action_surrender


Action: Surrenders current player



---
## PRIVATE FUNCS
### (void) _safe_connect
- **url: String**

### (void) _ready

### (void) _process
- **_delta**

### (Variant) _normalize_tile_id
- **id: Variant**

### (Phase) _phase_string_to_enum
- **phase: String**

### (String) _botlevel_enum_to_string
- **bot_level: BotLevel**

### (Dictionary) _build_base_action

### (Dictionary) _build_action
- **data: Dictionary = {}**

### (void) _build_and_send_action
- **data: Dictionary**

### (void) _public_queue_dispatcher
- **response: Dictionary**

### (void) _private_queue_dispatcher
- **response: Dictionary**

### (void) _game_action_dispatcher
- **action: Dictionary**

### (void) _game_state_dispatcher
- **state: Dictionary**

### (void) _game_response_dispatcher
- **response: Dictionary**

### (void) _game_dispatcher
- **response: Dictionary**




---
*Documentation generated with [Godoct](https://github.com/newwby/Godoct)*