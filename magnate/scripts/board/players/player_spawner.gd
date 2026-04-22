class_name PlayerSpawner
extends RefCounted

static func spawn_players(parent_node: Node2D, tiles: Dictionary):
	var i = 0
	for p in ModelManager.game.players.values():
		p.token = _create_single_player(p, parent_node, tiles, i)
		i += 1

static func _create_single_player(model: PlayerModel, parent_node: Node2D, tiles: Dictionary, player_index: int) -> PlayerToken:
	var token = PlayerToken.new()
	token.setup(model.color)
	var start_tile = tiles["000"]
	token.position = start_tile.position + start_tile.pivot_offset
	token.z_index = 10 + player_index
	model.player_updated.connect(token.update)
	parent_node.add_child(token)
	return token
