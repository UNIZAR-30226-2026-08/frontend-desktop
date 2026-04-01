class_name MagnateTileManager
extends RefCounted

var tile_parent_node: Node2D = null
var tile_entities: Dictionary[String, Control]
var clickable_tile_ids: Array[String]

## Emitted when a tile is pressed, gives the tile id
signal tile_pressed(String)

func setup_tiles(parent: Node2D) -> void:
	tile_parent_node = parent
	tile_entities = MagnateTileSpawner.spawn_board(tile_parent_node)
	for tile_id in tile_entities:
		var tile_node = tile_entities[tile_id]
		tile_node.gui_input.connect(_check_input_is_press.bind(tile_id))

func _check_input_is_press(ev: InputEvent, tile_id: String):
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
		if tile_id in clickable_tile_ids:
			tile_pressed.emit(tile_id)

func highlight_tiles(ids: Array[String]) -> void:
	var tiles_to_darken: Array[String] = []
	for id in tile_entities.keys():
		if id in ids or not tile_entities[id]:
			continue
		tiles_to_darken.append(id)
	darken_tiles(tiles_to_darken)

func darken_tiles(ids: Array[String]) -> void:
	var darken_canvas = CanvasGroup.new()
	tile_parent_node.add_child(darken_canvas)
	for id in ids:
		if not tile_entities.has(id): continue
		tile_entities[id].reparent(darken_canvas)
	var tween = tile_parent_node.create_tween()
	var target_color = Color("#666666")
	tween.tween_property(darken_canvas, "self_modulate", target_color, .5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished

func reset_tile_highlight() -> void:
	reset_clickable_tiles()
	var darken_canvas = null
	for child in tile_parent_node.get_children():
		if is_instance_of(child, CanvasGroup):
			darken_canvas = child
	if not darken_canvas: return
	
	var tween = tile_parent_node.create_tween()
	tween.tween_property(darken_canvas, "self_modulate", Color.WHITE, .5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
	for child in darken_canvas.get_children():
		child.reparent(tile_parent_node)
	darken_canvas.queue_free()

func set_tile_owner(tile_id: String, player_color: Color) -> void:
	if not tile_entities.has(tile_id):
		return

	var tile: Control = tile_entities[tile_id]
	for child in tile.get_children():
		if child is OwnerMarker:
			child.queue_free()

	var marker = OwnerMarker.new(player_color, tile.size.x)
	marker.position = Vector2(0, tile.size.y)
	tile.add_child(marker)

func reset_clickable_tiles() -> void:
	for id in clickable_tile_ids:
		if tile_entities.has(id):
			tile_entities[id].mouse_default_cursor_shape = Control.CURSOR_ARROW
	clickable_tile_ids.clear()

func _reset_all_tiles(_id: String) -> void:
	reset_tile_highlight()
	reset_clickable_tiles()
	tile_pressed.disconnect(_reset_all_tiles)

func prompt_tile_selection(ids: Array[String]) -> void:
	clickable_tile_ids = ids
	highlight_tiles(ids)

	tile_pressed.connect(_reset_all_tiles)

	for id in ids:
		if tile_entities.has(id):
			tile_entities[id].mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
