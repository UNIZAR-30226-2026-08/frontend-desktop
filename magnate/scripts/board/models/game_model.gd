class_name GameModel
extends RefCounted

var game_id: String
var my_id: String
var current_turn_player_id: String = ""
var parking_money: int = 0
var has_rolled_dice: bool = false
var is_paused: bool = false

# VARIABLES PARA EL TURNO ACTUAL. VIENEN DE RESPONSE DE LANZAR DADOS
var current_streak: int = 0
var has_triple: bool = false
var pending_destinations: Array[String] = []
var pending_path: Array[String] = []
var d1: int
var d2: int
var dbus: int

# Diccionarios para simular los 'Record<string, Model>' de TypeScript
var board_properties: Dictionary = {} 
var players: Dictionary = {}

func _init(_game_id: String, player_list: Array[PlayerModel], property_ids: Array[String]) -> void:
	game_id = _game_id
	
	if player_list.size() > 0:
		current_turn_player_id = player_list[0].id
		
	for prop_id in property_ids:
		board_properties[prop_id] = PropertyModel.new(prop_id)
		
	for player in player_list:
		players[player.id] = player

func get_property_owner(property_id: String) -> String:
	# Siempre es buena práctica comprobar si existe la key en el diccionario en Godot
	if board_properties.has(property_id):
		return board_properties[property_id].owner_id
	return ""
