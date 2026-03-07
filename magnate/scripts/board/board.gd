extends Node2D

@onready var camera_system: MagnateCameraSystem = $CameraSystem
@onready var tile_parent_node: Node2D = $Tiles
var tiles: Dictionary[String, Control]
var players: Array[Dictionary] = []
var player_hud: PlayerHUD

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tiles = BoardSpawner.spawn_board(tile_parent_node)
	camera_system.init_camera_system(self)
	
	var json_path = "res://data/board.json"
	players = PlayerSpawner.spawn_players(self, tiles, json_path)
	
	for player_data in players:
		var token: PlayerToken = player_data["token"]
		token.on_token_clicked.connect(_on_player_token_clicked.bind(player_data))
		
	player_hud = PlayerHUD.new()
	add_child(player_hud)
	player_hud.setup_players(players)
		
	TokenLayoutManager.update_all_token_positions(players, tiles)
	
func set_tile_owner(tile_id: String, player_color: Color) -> void:
	if not tiles.has(tile_id):
		return
		
	var tile: Control = tiles[tile_id]
	
	for child in tile.get_children():
		if child is OwnerMarker:
			child.queue_free()
			
	var marker = OwnerMarker.new(player_color, tile.size.x)
	marker.position = Vector2(0, tile.size.y)
	tile.add_child(marker)

# DEBUG	
func _on_player_token_clicked(_clicked_token: PlayerToken, player_data: Dictionary) -> void:
	var model: PlayerModel = player_data["model"]
	
	var current_id: int = model.current_tile_id.to_int()
	var next_id: int = (current_id + 1) 
	var next_tile_string: String = "%03d" % next_id
	
	if tiles.has(next_tile_string):
		model.move_to_tile(next_tile_string)
		set_tile_owner(next_tile_string, model.color)
		
		TokenLayoutManager.update_all_token_positions(players, tiles)

# Takes a list of tile ids and darkens the rest
func highlight_tiles(ids: Array[String]) -> void:
	var tiles_to_darken: Array[String] = []
	for id in tiles.keys():
		if id in ids or not tiles[id]:
			continue
		tiles_to_darken.append(id)
	darken_tiles(tiles_to_darken)

func darken_tiles(ids: Array[String]) -> void:
	var darken_canvas = CanvasGroup.new()
	tile_parent_node.add_child(darken_canvas)
	for id in ids:
		if not tiles.has(id): continue
		tiles[id].reparent(darken_canvas)
	var tween = create_tween()
	var target_color = Color("#666666")
	tween.tween_property(darken_canvas, "self_modulate", target_color, .5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished

func reset_tile_highlight() -> void:
	var darken_canvas = null
	for child in tile_parent_node.get_children():
		if is_instance_of(child, CanvasGroup):
			darken_canvas = child
	if not darken_canvas: return
	var tween = create_tween()
	tween.tween_property(darken_canvas, "self_modulate", Color.WHITE, .5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
	for child in darken_canvas.get_children():
		child.reparent(tile_parent_node)
	darken_canvas.queue_free()
