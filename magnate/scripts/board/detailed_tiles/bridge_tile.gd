extends Panel

@onready var bridge_name: Label = %BridgeName

var owner_id: int = -1

func update(tile_id: String) -> void:
	var property = ModelManager.get_property(tile_id)
	set_property_owner(property.owner_id)

func set_bridge_name(_name: String) -> void:
	bridge_name.text = _name

func set_property_owner(player_id: int) -> void:
	if owner_id == player_id: return
	var player = ModelManager.get_player(player_id)
	var tween
	for child in get_children():
		if child is OwnerMarker:
			tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(child, "position:y", size.y - child.marker_height, 0.5)
			await tween.finished
			child.queue_free()

	var marker = OwnerMarker.new(player.color, size.x)
	marker.position = Vector2(0, size.y)
	add_child(marker)
	tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(marker, "position:y", size.y, 0.5)
