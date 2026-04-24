class_name GameModel
extends RefCounted

# VARIABLES GLOBALES ÚTILES INGAME
var game_id: int
var my_id: int
var current_turn_player_id: int
var current_phase_player_id: int
var parking_money: int = 0
var is_paused: bool = false
var current_turn: int = 1
var current_phase: MagnateWSClient.Phase

# Diccionarios para simular los 'Record<string, Model>' de TypeScript
var board_properties: Dictionary[String, PropertyModel] = {} 
var players: Dictionary[int, PlayerModel] = {}

# Diccionario de casillas importantes
var important_tiles = {
	"start": "000",
	"jail": "201",
	"go_to_jail": "020"
}

# Variables relacionadas con la cárcel

# Vars to save last trade proposal
# Money is not needed as it is updated by the general response
var trade_p1_id: int = -1
var trade_p2_id: int = -1
var trade_p1_properties: Array[String] = []
var trade_p2_properties: Array[String] = []

func _init(_game_id: int, player_list: Array[PlayerModel], properties: Array[PropertyModel]) -> void:
	game_id = _game_id
	
	if player_list.size() > 0:
		current_turn_player_id = player_list[0].id
		
	for property in properties:
		board_properties[property.id] = property
		
	for player in player_list:
		players[player.id] = player

func get_property_owner(property_id: String) -> int:
	# Siempre es buena práctica comprobar si existe la key en el diccionario en Godot
	if board_properties.has(property_id):
		return board_properties[property_id].owner_id
	return -1
