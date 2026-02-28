class_name BoardSpawner
extends RefCounted

const PROPERTY_TILE = preload("uid://cphy0sd46xk4g")
const FANTASY_TILE = preload("uid://cbwe3sts61rxb")
const BRIDGE_TILE = preload("uid://cf417oe42rk3d")

static func _spawn_tile(parent_scene: Node2D, tile_def: Dictionary) -> Control:
	# Instantiate tile type
	var tile_entity: PackedScene
	match tile_def.type:
		Globals.TileType.PROPERTY:
			tile_entity = PROPERTY_TILE
		Globals.TileType.BRIDGE:
			tile_entity = BRIDGE_TILE
		Globals.TileType.FANTASY:
			tile_entity = FANTASY_TILE
		_:
			return null
	# Common tile properties
	var tile_instance: Control = tile_entity.instantiate() as Control
	parent_scene.add_child(tile_instance)
	tile_instance.pivot_offset = tile_def["size"] / 2
	tile_instance.position = tile_def["position"]
	tile_instance.size = tile_def["size"]
	if tile_def.has("rotation"):
		tile_instance.rotation_degrees = tile_def["rotation"]
	# Specific tile properties
	match tile_def.type:
		Globals.TileType.PROPERTY:
			tile_instance.set_property_name(tile_def["name"])
			tile_instance.set_property_color(tile_def["color"])
		Globals.TileType.BRIDGE:
			pass
		Globals.TileType.FANTASY:
			pass
	return tile_instance

static func spawn_board(parent_scene: Node2D) -> Dictionary[String, Control]:
	var tile_defs = BoardDefinitionParser.parse_board(Globals.BOARD_JSON_FILEPATH)
	var tile_dict: Dictionary[String, Control] = {}
	for tile_id in tile_defs:
		tile_dict[tile_id] = _spawn_tile(parent_scene, tile_defs[tile_id])
	return tile_dict
