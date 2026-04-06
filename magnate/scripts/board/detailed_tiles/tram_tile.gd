extends Control

@onready var stop_name: Label = %StopName

func set_stop_name(_name: String) -> void:
	stop_name.text = _name
