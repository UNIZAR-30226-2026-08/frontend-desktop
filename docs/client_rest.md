# MagnateRestClient    
**Extends** Node
        
**MagnateRestClient** makes use of the Godot HTTP request API to make the Rest request needed to the backend and return a response. Only one reponse can be made at a time. When the current response finishes the signal <response> will be emitted with the parsed reponse body. 



---
# Signals

| | Signal Name | Signal Arguments |
| --- | :--- | ---: |
| signal | **[response](#signal-response)** | 
---
# Properties
| | Property Name | Property Type | Property Default Value |
| --- | :--- | :---: | ---: |
| var | **[current_request](#var-current_request)** | *HTTPRequest* | null # Start off with no request |
| var | **[waiting_for_response](#var-waiting_for_response)** | *bool* | false |


---
# Functions

| | Function Name | Function Arguments | Function Return Value |
| --- | :--- | :--- | ---: |
| public | **[make_request](#bool-make_request)** | url: String<br>verb: HTTPClient.Method = HTTPClient.METHOD_GET<br>headers: Array[String] = []<br>data_to_send: Variant = "" # String or Dictionary<br> | bool
| public | **[login_user](#dictionary-login_user)** |  | Dictionary
| public | **[signup_user](#dictionary-signup_user)** |  | Dictionary
| private | **[_response_handler](#void-_response_handler)** | result<br>response_code<br>headers<br>body<br> | void


---
# Signals


---
## SIGNALS
### signal response



---
# Properties


---
## PUBLIC VARS
### var current_request
- **type:** httprequest

- *[default value = null # start off with no request]*
### var waiting_for_response
- **type:** bool

- *[default value = false]*



---
# Functions


---
## PUBLIC FUNCS
### (bool) make_request
- **url: String**
- **verb: HTTPClient.Method = HTTPClient.METHOD_GET**
- **headers: Array[String] = []**
- **data_to_send: Variant = "" # String or Dictionary**


WARNING: You probably shouldn't be using this. There should be a specific function in this class that abstracts your request logic. --- If the request is made true is returned, in any other case false is returned. The <reponse> signal is emitted when the server reponse reaches back it will contain the parsed response
### (Dictionary) login_user


Takes login info as input and returns the following: - if the login is successful {"succ": true, "err": ""} - if the login is unsuccessful {"succ": false, "err": "error msg"}
### (Dictionary) signup_user


Takes signup info as input and returns the following: - if the signup is successful {"succ": true, "err": ""} - if the signup is unsuccessful {"succ": false, "err": "error msg"}



---
## PRIVATE FUNCS
### (void) _response_handler
- **result**
- **response_code**
- **headers**
- **body**




---
*Documentation generated with [Godoct](https://github.com/newwby/Godoct)*