extends Panel

@onready var bridge_name: Label = %BridgeName

func set_bridge_name(brid_name: String) -> void:
	bridge_name.text = brid_name
