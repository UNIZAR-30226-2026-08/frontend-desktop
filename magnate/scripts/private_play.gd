extends Panel

@onready var tab_container: TabContainer = $VBoxContainer/TabContainer
@onready var join_button: Button = $VBoxContainer/HBoxContainer/JoinButton
@onready var confirm_button: Button = $VBoxContainer/ConfirmButton
@onready var code_input: LineEdit = %CodeInput
@onready var tooltip: PanelContainer = %Tooltip
var button_group: ButtonGroup

var _regex = RegEx.new()

func _ready() -> void:
	_regex.compile("[^A-Z0-9]")
	button_group = join_button.button_group
	button_group.pressed.connect(_change_option)

func _change_option(button: BaseButton) -> void:
	confirm_button.disabled = false
	if button.name == "JoinButton":
		tab_container.current_tab = 0
	else:
		tab_container.current_tab = 1

func _on_confirm_button_pressed() -> void:
	if not tab_container.current_tab in [0, 1]:
		return
	var code: String = ""
	if tab_container.current_tab == 0:
		if len(code_input.text) != 6: return
		code = code_input.text
		var code_exists = await RestClient.game_check_private_code(code)
		if code_exists == {} or not code_exists.get("exists", false):
			tooltip.flash()
			code_input.text = ""
			return
	elif tab_container.current_tab == 1:
		var response = await RestClient.game_get_private_code()
		if response == {}: return
		code = response["code"]
	WsClient.start_client_private_lobby(code)
	SceneTransition.change_scene("res://scenes/UI/waiting_lobby.tscn")

func _on_header_back_action_requested() -> void:
	SceneTransition.change_scene("res://scenes/UI/home_screen.tscn")

func _on_code_input_text_changed(new_text: String) -> void:
	code_input.text = _regex.sub(new_text.to_upper(), "", true)
	code_input.caret_column = len(code_input.text)
