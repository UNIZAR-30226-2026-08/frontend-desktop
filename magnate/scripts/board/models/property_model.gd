class_name PropertyModel
extends RefCounted

signal updated(tile_id: String)

var id: String
var name: String = ""
var house_count: int = 0
var owner_id: int = -1
var is_mortgaged: bool = false
var group_id: int = -1 :
	set(value):
		is_server = value == 13
		is_bridge = value == 14
		group_id = value
var build_price: int = -1
var buy_price: int = -1
var rent_prices: Array = [0, 0, 0, 0, 0]
var color: Color = Color()
var is_server: bool = false
var is_bridge: bool = false

func _init(_id: String) -> void:
	id = _id

func set_houses(count: int) -> void:
	house_count = count

func set_mortgage_status(mortgaged: bool) -> void:
	is_mortgaged = mortgaged
	# Regla de Monopoly: si se hipoteca, no puede tener casas
	if is_mortgaged:
		house_count = 0
