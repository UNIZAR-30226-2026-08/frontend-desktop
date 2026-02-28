extends Node2D

@onready var camera_system: MagnateCameraSystem = $CameraSystem
@onready var tile_parent_node: Node2D = $Tiles
var tiles: Dictionary[String, Control]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tiles = BoardSpawner.spawn_board(tile_parent_node)
	camera_system.init_camera_system(self)

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
