class_name PlayerModel
extends RefCounted

# Señal añadida de la versión nueva
signal player_updated(p_id: int)

var id: int
var player_name: String
var color: Color
var token: PlayerToken

var balance: int = 1500
var current_tile_id: String = "000"
var is_in_jail: bool = false
var jail_turn_count: int = 0
var owned_properties: Array[String] = []
var surrendered: bool = false
var last_path_taken: Array[Vector2] = []

func _init(p_id: int, p_name: String, p_color: Color) -> void:
	id = p_id
	player_name = p_name
	color = p_color
	token = PlayerToken.new()
	token.setup(color)

func move_to_tile(new_tile_id: String, new_path: Array[Vector2]) -> void:    
	current_tile_id = new_tile_id
	last_path_taken = new_path

func emit_update() -> void:
	# Emitimos el diccionario igual que en React
	player_updated.emit(id)
