class_name PlayerModel
extends RefCounted

var id: String
var player_name: String
var color: Color

var balance: int = 1500 
var current_tile_id: String = "000"
var is_in_jail: bool = false # TODO: Hay que ver esto
var owned_properties: Array[String] = []

func _init(p_id: String, p_name: String, p_color: Color) -> void:
	id = p_id
	player_name = p_name
	color = p_color

func move_to_tile(new_tile_id: String) -> void:
	current_tile_id = new_tile_id
