class_name MagnateRestClient
extends Node

## <class_doc>
## **MagnateRestClient** makes use of the Godot HTTP request API to make the
## Rest request needed to the backend and return a response.
## Only one reponse can be made at a time. When the current response finishes
## the signal <response> will be emitted with the parsed reponse body.

# NOTE: If multiple requests at a time need to be implemented remember to do
# the following:
# - [ ] Introduce a politeness delay for the server
# - [ ] Return a ticket number to each caller
# - [ ] Emit the response signal with the ticket number
# - [ ] Introduce a flag to either handle the await here or rely on the caller

# The following code implements a client for the Rest backend

var current_request: HTTPRequest = null # Start off with no request
var waiting_for_response: bool = false

signal response

# The following are the base functions used by the client

## WARNING: You probably shouldn't be using this. There should be a
## specific function in this class that abstracts your request logic.
## ---
## If the request is made true is returned, in any other case false is returned.
## The <reponse> signal is emitted when the server reponse reaches back
## it will contain the parsed response
func make_request(
	url: String,
	verb: HTTPClient.Method = HTTPClient.METHOD_GET,
	headers: Array[String] = [],
	data_to_send: Variant = "" # String or Dictionary
) -> bool:
	if waiting_for_response:
		return false
	current_request = HTTPRequest.new()
	add_child(current_request)
	current_request.request_completed.connect(_response_handler)
	
	if verb == HTTPClient.METHOD_GET:
		var error = current_request.request(url)
		if error != OK:
			push_error("An error occurred in the HTTP request.")
		else:
			waiting_for_response = true
			return true
	elif verb == HTTPClient.METHOD_POST:
		data_to_send = JSON.stringify(data_to_send)
		var error = current_request.request(url, headers, HTTPClient.METHOD_POST, data_to_send)
		if error != OK:
			push_error("An error occurred in the HTTP request.")
		else:
			waiting_for_response = true
			return true
	else:
		push_error("Unsupported verb in HTTP request")
	return false

func _response_handler(result, response_code, headers, body) -> void:
	waiting_for_response = false
	if result != HTTPRequest.RESULT_SUCCESS:
		response.emit()
		return
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response_data = json.get_data()
	response.emit(response_data)

# Now we get into the specifics of the communication

## Takes login info as input and returns the following:
##  - if the login is successful {"succ": true, "err": ""}
##  - if the login is unsuccessful {"succ": false, "err": "error msg"}
func login_user() -> Dictionary:
	return {}

## Takes signup info as input and returns the following:
##  - if the signup is successful {"succ": true, "err": ""}
##  - if the signup is unsuccessful {"succ": false, "err": "error msg"}
func signup_user() -> Dictionary:
	return {}
