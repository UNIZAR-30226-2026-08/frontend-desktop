extends Panel

@onready var tab_container: TabContainer = $VBoxContainer/TabContainer
@onready var join_button: Button = $VBoxContainer/HBoxContainer/JoinButton
var button_group: ButtonGroup

func _ready() -> void:
	button_group = join_button.button_group
	button_group.pressed.connect(_change_option)
	
func _change_option(button: BaseButton) -> void:
	if button.name == "JoinButton":
		tab_container.current_tab = 0
	else:
		tab_container.current_tab = 1
