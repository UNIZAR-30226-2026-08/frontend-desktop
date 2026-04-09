class_name PlayerModel
extends RefCounted

# Señal añadida de la versión nueva
signal player_updated(update_data: Dictionary)

var id: String
var player_name: String
var color: Color

var balance: int = 1500 
var current_tile_id: String = "000"
var is_in_jail: bool = false # TODO: Hay que ver esto
var jail_turn_count: int = 1 
var owned_properties: Array[String] = []

func _init(p_id: String, p_name: String, p_color: Color) -> void:
	id = p_id
	player_name = p_name
	color = p_color

func move_to_tile(new_tile_id: String) -> void:    
	current_tile_id = new_tile_id
	emit_update() # Añadido para que avise a la UI al moverse

func emit_update() -> void:
	# Emitimos el diccionario igual que en React
	var data: Dictionary = {
		"id": id,
		"balance": balance,
		"properties": owned_properties.duplicate(),
		"jailTurnCount": jail_turn_count,
		"current_tile_id": current_tile_id
	}
	player_updated.emit(data)
