class_name PlayerSpawner
extends RefCounted

static func spawn_players(parent_node: Node2D, tiles: Dictionary, json_path: String) -> Array[Dictionary]:
	var players: Array[Dictionary] = []
	var player_colors: Array = ["#f94144", "#f9c74f", "#90be6d", "#2c7da0"] # Por si acaso, no vaya a ser
	
	if FileAccess.file_exists(json_path):
		var file = FileAccess.open(json_path, FileAccess.READ)
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			if json.data.has("playerColors"):
				player_colors = json.data["playerColors"]
	else:
		printerr("Board JSON not found for player spawning!")

	players.append(_create_single_player("0001", "Jugador 1", Color(player_colors[0]), parent_node, tiles, players.size()))
	players.append(_create_single_player("0002", "Jugador 2", Color(player_colors[1]), parent_node, tiles, players.size()))
	players.append(_create_single_player("0003", "Jugador 3", Color(player_colors[2]), parent_node, tiles, players.size()))
	players.append(_create_single_player("0004", "Jugador 4", Color(player_colors[3]), parent_node, tiles, players.size()))
	
	return players

static func _create_single_player(id: String, player_name: String, color: Color, parent_node: Node2D, tiles: Dictionary, player_index: int) -> Dictionary:
	var model = PlayerModel.new(id, player_name, color)
	
	var token = PlayerToken.new()
	token.setup(color)
	
	if tiles.has("000"):
		var start_tile = tiles["000"]
		token.position = start_tile.position + start_tile.pivot_offset
	else:
		printerr("Start tile '000' not found in tiles dictionary!")
		
	token.z_index = 10 + player_index
	
	parent_node.add_child(token)
	
	return { "model": model, "token": token }
