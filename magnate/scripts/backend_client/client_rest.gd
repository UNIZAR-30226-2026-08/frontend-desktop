class_name MagnateRestClient
extends Node

## <class_doc>
## **MagnateRestClient** makes use of the Godot HTTP request API to make the
## Rest request needed to the backend and return a response.
## Only one reponse can be made at a time. When the current response finishes
## the signal <response> will be emitted with the parsed reponse body.

var needs_login: bool = true
var username: String = ""
var last_faulty_response: Variant
var last_faulty_response_code: int
signal logout
signal login

# NOTE: If multiple requests at a time need to be implemented remember to do
# the following:
# - [ ] Introduce a politeness delay for the server
# - [ ] Return a ticket number to each caller
# - [ ] Emit the response signal with the ticket number
# - [ ] Introduce a flag to either handle the await here or rely on the caller

# The following code implements a client for the Rest backend

const SAVE_PATH = "user://auth_data.dat"
var ENCRYPTION_KEY = ""

var needs_refresh: bool = false
var token_refresh: String = "" # Stores the refresh token
var token_access: String = "" # Stores the access token
var current_request: HTTPRequest = null # Start off with no request
var waiting_for_response: bool = false

var _was_auth_request: bool = false
var has_last_data: bool = false
var last_url: String
var last_verb: HTTPClient.Method
var last_data: Variant
var last_headers: Array

signal response(Variant)

# The following are the base functions used by the client
func get_device_key() -> String:
	var device_id = OS.get_unique_id()
	var salt = "j6=F:{0h432gcvP3Gp[b!-Y£~\"KC;"
	return (device_id + salt).sha256_text()

func _ready() -> void:
	ENCRYPTION_KEY = get_device_key()
	_load_refresh_token()
	if token_refresh == "":
		needs_login = true
	else:
		await _refresh_access_token()

## WARNING: You probably shouldn't be using this. There should be a
## specific function in this class that abstracts your request logic.
## ---
## If the request is made true is returned, in any other case false is returned.
## The <reponse> signal is emitted when the server reponse reaches back
## it will contain the parsed response
func make_request(
	url: String,
	data_to_send: Variant = null, # String or Dictionary
	verb: HTTPClient.Method = HTTPClient.METHOD_GET,
	headers: Array = [],
) -> bool:
	if waiting_for_response:
		response.emit({})
		return false
	current_request = HTTPRequest.new()
	add_child(current_request)
	current_request.request_completed.connect(_response_handler)
	
	if verb == HTTPClient.METHOD_GET:
		var error = current_request.request(url, headers)
		if error != OK:
			push_error("An error occurred in the HTTP request.")
		else:
			waiting_for_response = true
			return true
	elif verb == HTTPClient.METHOD_POST:
		headers += ['Content-Type: application/json']
		if typeof(data_to_send) == TYPE_DICTIONARY:
			data_to_send = JSON.stringify(data_to_send)
		var error = current_request.request(url, headers, HTTPClient.METHOD_POST, data_to_send)
		if error != OK:
			push_error("An error occurred in the HTTP request.")
		else:
			waiting_for_response = true
			return true
	else:
		push_error("Unsupported verb in HTTP request")
	current_request.queue_free()
	response.emit({})
	_was_auth_request = false
	return false

func make_auth_request(
	url: String,
	data_to_send: Variant = null, # String or Dictionary
	verb: HTTPClient.Method = HTTPClient.METHOD_GET,
	additional_headers: Array = [],
):
	has_last_data = true
	last_url = url
	last_verb = verb
	last_data = data_to_send
	last_headers = additional_headers
	
	_was_auth_request = true
	
	var headers: Array = ["Authorization: Bearer " + token_access] + additional_headers
	make_request(url, data_to_send, verb, headers)

func _refresh_access_token():
	needs_refresh = false
	
	# Create a temporary HTTPRequest node for the refresh call
	var refresh_req = HTTPRequest.new()
	add_child(refresh_req)
	
	var refresh_body = JSON.stringify({"refresh": token_refresh})
	var headers = ["Content-Type: application/json"]
	
	refresh_req.request(
		Globals.REST_BASE_URL + "/auth/refresh/",
		headers,
		HTTPClient.METHOD_POST,
		refresh_body
	)
	
	# Wait for the refresh to finish
	var resp = await refresh_req.request_completed
	var refresh_json = JSON.parse_string(resp[3].get_string_from_utf8())
	
	if resp[1] == 200:
		token_access = refresh_json["access"]
		Utils.debug("Token refreshed!")
		login.emit()
		if username == "" or WsClient.player_id == -1:
			var user_info = await user_get_info()
			username = user_info.get("username", "")
			WsClient.player_id = int(user_info["pk"])
		if has_last_data:
			Utils.debug("Retrying las request")
			make_auth_request(last_url, last_data, last_verb, last_headers)
	else:
		user_logout()
	
	refresh_req.queue_free()

func _response_handler(_result, response_code, _headers, body) -> void:
	current_request.queue_free()
	current_request = null
	waiting_for_response = false
	var response_data = JSON.parse_string(body.get_string_from_utf8())
	if response_code == 401 and _was_auth_request:
		if not _was_auth_request:
			last_faulty_response = response_data
			last_faulty_response_code = response_code
		if needs_refresh:
			Utils.debug("Access token expired. Attempting refresh...")
			await _refresh_access_token()
		else:
			Utils.debug("Refresh token also expired. Redirecting to login.")
			user_logout()
	elif response_code < 200 or response_code >= 300:
		last_faulty_response = response_data
		last_faulty_response_code = response_code
		Utils.debug("Got faulty response: " + str(response_data))
		response.emit({})
	else:
		needs_refresh = true
		response.emit(response_data)

func _save_auth_data(tokens: Dictionary):
	token_access = tokens["access"]
	token_refresh = tokens["refresh"]
	needs_login = false
	
	var file = FileAccess.open_encrypted_with_pass(SAVE_PATH, FileAccess.WRITE, ENCRYPTION_KEY)
	if not file: return
	
	var data = {"refresh": token_refresh}
	file.store_var(data)
	file.close()

func _load_refresh_token():
	if not FileAccess.file_exists(SAVE_PATH): return
	
	var file = FileAccess.open_encrypted_with_pass(SAVE_PATH, FileAccess.READ, ENCRYPTION_KEY)
	if not file: return
	
	var data = file.get_var()
	token_refresh = data.get("refresh", "")
	file.close()

# Now we get into the specifics of the communication

## Takes signup info as dictionary:
## - "username": String	- Username
## - "password": String	- User's password
## - "password2": String	- Password confirmation field
## Return dictionary with:
## - "message" = "correctly registered user"
## TODO: do I explain the rest? seems pretty useless at this point
func user_signup(data: Dictionary) -> Dictionary:
	make_request(
		Globals.REST_BASE_URL + "/auth/register/",
		data,
		HTTPClient.METHOD_POST,
	)
	var resp = await response
	if resp.has("tokens"):
		_save_auth_data(resp["tokens"])
	return resp

## Takes login info as dictionary:
## - "username": String	- Username
## - "password": String	- User's password
## Return dictionary with:
## - "message" = "succesful login"
## TODO: do I explain the rest? seems pretty useless at this point
func user_login(data: Dictionary) -> Dictionary:
	make_request(
		Globals.REST_BASE_URL + "/auth/login/",
		data,
		HTTPClient.METHOD_POST,
	)
	var resp = await response
	if resp.has("tokens"):
		_save_auth_data(resp["tokens"])
	if resp != {}:
		var user_info = await user_get_info()
		username = user_info.get("username", "")
		WsClient.player_id = int(user_info["pk"])
	return resp

func user_logout() -> void:
	needs_login = true
	username = ""
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	logout.emit()

## Return Dictionary with user info
## - "username": String		- Username of the user
## - "points": int			- Points of the user
## - "exp": float			- Experience of the user
## - "elo": float			- ELO of the user
## - "date_joined": String	- String in standard ISO format
## - "num_played_games": int	- Number of played games
## - "num_won_games": int	- Number of won games
## - "user_piece": int		- ID of the piece of the current user
func user_get_info() -> Dictionary:
	make_auth_request(Globals.REST_BASE_URL + "/user/info/")
	var resp = await response
	if resp.has("points"):
		resp["points"] = int(resp["points"])
	if resp.has("num_played_games"):
		resp["num_won_games"] = int(resp["num_won_games"])
	if resp.has("num_played_games"):
		resp["num_played_games"] = int(resp["num_won_games"])
	return resp

# TODO
func user_get_games() -> Dictionary:
	make_auth_request(Globals.REST_BASE_URL + "/user/games-played/")
	return await response

# TODO
func user_get_game_summary(game_id: int) -> Dictionary:
	make_auth_request(Globals.REST_BASE_URL + "/game/summary/" + str(game_id) + "/")
	return await response

# TODO
func user_change_piece(piece_id: int) -> Dictionary:
	make_auth_request(
		Globals.REST_BASE_URL + "/user/change-piece/",
		{"custom_id": piece_id},
		HTTPClient.METHOD_POST
	)
	return await response

# TODO
func fetch_user_name_and_piece(pk: String) -> Dictionary:
	make_auth_request(Globals.REST_BASE_URL + "/info/user-name-piece/" + pk + "/")
	return await response

# TODO [{ "custom_id": 1.0, "itemType": "piece", "price": 100.0, "owned": false }, { "custom_id": 2.0, "itemType": "piece", "price": 200.0, "owned": false }, { "custom_id": 3.0, "itemType": "piece", "price": 300.0, "owned": false }, { "custom_id": 4.0, "itemType": "emoji", "price": 150.0, "owned": false }, { "custom_id": 5.0, "itemType": "emoji", "price": 250.0, "owned": false }]
func shop_get_items() -> Array:
	make_auth_request(Globals.REST_BASE_URL + "/shop/items/")
	return await response

# TODO
func shop_buy_item(item_id: int) -> Dictionary:
	make_auth_request(
		Globals.REST_BASE_URL + "/shop/buy/",
		{"item_id": item_id},
		HTTPClient.METHOD_POST
	)
	return await response

# TODO
func shop_get_user_pieces() -> Array:
	make_auth_request(Globals.REST_BASE_URL + "/shop/user-pieces/")
	var resp = await response
	if typeof(resp) == TYPE_ARRAY:
		return resp
	return []

# TODO
func shop_get_user_emojis() -> Dictionary:
	make_auth_request(Globals.REST_BASE_URL + "/shop/user-emojis/")
	return await response

# TODO
func game_get_private_code() -> Dictionary:
	make_auth_request(Globals.REST_BASE_URL + "/lobby/get-private-code")
	return await response

# Returns {"exists": bool}
func game_check_private_code(code: String) -> Dictionary:
	make_auth_request(Globals.REST_BASE_URL + "/lobby/check-code/" + code + "/")
	return await response
