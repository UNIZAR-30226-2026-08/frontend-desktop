class_name MagnateTileSpawner
extends RefCounted

const PROPERTY_TILE = preload("uid://cphy0sd46xk4g")
const FANTASY_TILE = preload("uid://cbwe3sts61rxb")
const BRIDGE_TILE = preload("uid://cf417oe42rk3d")
const GO_TO_JAIL_TILE = preload("uid://dh48464mm8og5")
const PARKING_TILE = preload("uid://c2q0i0vsel4nv")
const JAIL_TILE = preload("uid://dtdx4dou1ljl6")
const SERVER_TILE = preload("uid://cov8rn28xmtuf")
const START_TILE = preload("uid://dqdoqvx1b8srl")
const TRAM_TILE = preload("uid://38yhgyxt25m4")

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
		Globals.TileType.GO_TO_JAIL:
			tile_entity = GO_TO_JAIL_TILE
		Globals.TileType.PARKING:
			tile_entity = PARKING_TILE
		Globals.TileType.JAIL:
			tile_entity = JAIL_TILE
		Globals.TileType.SERVER:
			tile_entity = SERVER_TILE
		Globals.TileType.START:
			tile_entity = START_TILE
		Globals.TileType.TRAM:
			tile_entity = TRAM_TILE
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
			tile_instance.set_bridge_name(tile_def["name"])
		Globals.TileType.SERVER:
			tile_instance.set_server_name(tile_def["name"])
		Globals.TileType.TRAM:
			tile_instance.set_stop_name(tile_def["stop_name"])
	tile_instance.mouse_filter = Control.MOUSE_FILTER_STOP
	return tile_instance

static func spawn_board(parent_scene: Node2D) -> Dictionary[String, Control]:
	var tile_defs = BoardDefinitionParser.parse_board(Globals.BOARD_JSON_FILEPATH)
	var tile_dict: Dictionary[String, Control] = {}
	for tile_id in tile_defs:
		tile_dict[tile_id] = _spawn_tile(parent_scene, tile_defs[tile_id])
		if tile_defs[tile_id].type in [Globals.TileType.PROPERTY, Globals.TileType.SERVER]:
			tile_dict[tile_id].set_property_price(ModelManager.get_property(tile_id).buy_price)
		if tile_dict[tile_id].has_method("update"):
			ModelManager.get_property(tile_id).updated.connect(tile_dict[tile_id].update)
	return tile_dict
