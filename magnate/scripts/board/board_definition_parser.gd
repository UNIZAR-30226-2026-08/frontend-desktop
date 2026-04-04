class_name BoardDefinitionParser
extends RefCounted

# Returns the enum type from the string type of a tile
static func _get_tile_type_from_string(tile_type: String) -> Globals.TileType:
	var types_mapping: Dictionary[String, Globals.TileType] = {
		"property" = Globals.TileType.PROPERTY,
		"fantasy" = Globals.TileType.FANTASY,
		"tram" = Globals.TileType.TRAM,
		"bridge" = Globals.TileType.BRIDGE,
		"server" = Globals.TileType.SERVER,
		"jail" = Globals.TileType.JAIL,
		"parking" = Globals.TileType.PARKING,
		"go_to_jail" = Globals.TileType.GO_TO_JAIL,
		"start" = Globals.TileType.START,
	}
	if not types_mapping.has(tile_type):
		printerr("Got unexpected tile type: " + tile_type)
		return Globals.TileType.PROPERTY
	return types_mapping[tile_type]

# Loads board definition from JSON
static func parse_board(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		printerr("Board's JSON definition file not found")
		return {}
	
	var file = FileAccess.open(path, FileAccess.READ)
	var json_text = file.get_as_text()
	var json = JSON.new()
	
	if json.parse(json_text) == OK:
		return _get_tiles(json.data)
	else:
		printerr("Invalid Board definition JSON")
		return {}

# Organizes the tile dictionary with ids as keys and
# dicts with tile attributes as values
static func _get_tiles(data: Dictionary) -> Dictionary:
	# If "tiles" is not a key return empty dict
	if not data.has("tiles"):
		printerr("Theres no \"tiles\" key in the board definition JSON")
		return {}
	elif not data.has("groups"):
		printerr("Theres no \"groups\" key in the board definition JSON")
		return {}
	var tiles_dict: Dictionary[String, Dictionary] = {}
	# TODO: Maybe we should check that all the keys we're going to access are there?
	for tile in data["tiles"]:
		tiles_dict[tile["id"]] = {
			"name" = tile["name"],
			"type" = _get_tile_type_from_string(tile["type"]),
			"position" = Vector2(tile["x"] - tile["width"] / 2, tile["y"] - tile["height"] / 2),
			"size" = Vector2(tile["width"], tile["height"])
		}
		if tile.has("group"):
			var group_color = Color(data["groups"][tile["group"] - 1]["color"])
			tiles_dict[tile["id"]]["color"] = group_color
		if tile.has("rotation"):
			tiles_dict[tile["id"]]["rotation"] = tile["rotation"]
	return tiles_dict
