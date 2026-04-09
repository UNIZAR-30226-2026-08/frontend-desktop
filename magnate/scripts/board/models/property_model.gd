class_name PropertyModel
extends RefCounted

var id: String
var house_count: int
var owner_id: String 
var is_mortgaged: bool
var group_id: String 

func _init(_id: String, _group_id: String = "") -> void:
	id = _id
	group_id = _group_id
	house_count = 0
	owner_id = ""
	is_mortgaged = false

func set_houses(count: int) -> void:
	house_count = count

func set_mortgage_status(mortgaged: bool) -> void:
	is_mortgaged = mortgaged
	# Regla de Monopoly: si se hipoteca, no puede tener casas
	if is_mortgaged:
		house_count = 0
