class_name PlayerModel
extends RefCounted

# Señal añadida de la versión nueva
signal player_updated(update_data: Dictionary)

var id: int
var player_name: String
var color: Color
var token: PlayerToken

var balance: int = 300 
var current_tile_id: String = "000"
var is_in_jail: bool = false
var jail_turn_count: int = 0
var owned_properties: Array[String] = []

func _init(p_id: int, p_name: String, p_color: Color) -> void:
	id = p_id
	player_name = p_name
	color = p_color
	token = PlayerToken.new()
	token.setup(color)

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
