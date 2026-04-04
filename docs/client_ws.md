# MagnateWSClient    
**Extends** Node
        
**MagnateWSClient** makes use of the Godot WebSocket API 





---
# Properties
| | Property Name | Property Type | Property Default Value |
| --- | :--- | :---: | ---: |
| var | **[socket](#var-socket)** | ** | WebSocketPeer.new() |


---
# Functions

| | Function Name | Function Arguments | Function Return Value |
| --- | :--- | :--- | ---: |
| public | **[send_data](#void-send_data)** | data_to_send: Variant<br> | void
| public | **[buy_property](#void-buy_property)** | id: String<br> | void
| private | **[_ready](#void-_ready)** |  | void
| private | **[_process](#void-_process)** | _delta<br> | void




---
# Properties


---
## PUBLIC VARS
### var socket
- *[default value = websocketpeer.new()]*



---
# Functions


---
## PUBLIC FUNCS
### (void) send_data
- **data_to_send: Variant**


WARNING: You probably shouldn't be using this. There should be a specific function in this class that abstracts your interaction logic.
### (void) buy_property
- **id: String**




---
## PRIVATE FUNCS
### (void) _ready

### (void) _process
- **_delta**




---
*Documentation generated with [Godoct](https://github.com/newwby/Godoct)*