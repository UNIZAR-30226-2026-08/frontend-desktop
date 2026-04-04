extends Panel

@onready var bridge_name: Label = %BridgeName

func set_bridge_name(_name: String) -> void:
	bridge_name.text = _name
