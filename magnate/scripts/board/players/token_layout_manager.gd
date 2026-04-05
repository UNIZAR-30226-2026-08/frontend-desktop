class_name TokenLayoutManager
extends RefCounted

static func update_all_token_positions(players: Array[Dictionary], tiles: Dictionary) -> void:
	var tile_occupants: Dictionary = {}
	
	for player_data in players:
		var tile_id: String = player_data["model"].current_tile_id
		if not tile_occupants.has(tile_id):
			tile_occupants[tile_id] = []
		tile_occupants[tile_id].append(player_data["token"])
	
	for tile_id in tile_occupants.keys():
		var tokens_on_tile: Array = tile_occupants[tile_id]
		_arrange_tokens_on_tile(tile_id, tokens_on_tile, tiles)

static func _arrange_tokens_on_tile(tile_id: String, tokens: Array, tiles: Dictionary) -> void:
	if not tiles.has(tile_id):
		return
		
	var target_tile: Control = tiles[tile_id]
	var tile_center: Vector2 = target_tile.position + target_tile.pivot_offset
	
	var count: int = tokens.size()
	var spacing: float = 18.0 

	for i in range(count):
		var token: PlayerToken = tokens[i]
		var offset_vector: Vector2 = Vector2.ZERO
		
		if count == 1:
			offset_vector = Vector2.ZERO 
		elif count == 2:
			if i == 0: offset_vector = Vector2(-spacing, 0)
			if i == 1: offset_vector = Vector2(spacing, 0)
		elif count == 3:
			if i == 0: offset_vector = Vector2(-spacing, spacing * 0.8)
			if i == 1: offset_vector = Vector2(0, -spacing * 0.8)
			if i == 2: offset_vector = Vector2(spacing, spacing * 0.8)
		elif count >= 4:
			if i == 0: offset_vector = Vector2(-spacing, -spacing)
			if i == 1: offset_vector = Vector2(spacing, -spacing)
			if i == 2: offset_vector = Vector2(-spacing, spacing)
			if i == 3: offset_vector = Vector2(spacing, spacing)
		
		var final_pos = tile_center + offset_vector
		token.move_to([final_pos])
