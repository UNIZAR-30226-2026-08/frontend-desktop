extends Panel

@onready var bridge_name: Label = %BridgeName

var owner_id: int = -1
var is_mortgaged = false

func update(tile_id: String) -> void:
	var property = ModelManager.get_property(tile_id)
	set_property_owner(property.owner_id)
	update_mortgage_visuals(property.is_mortgaged)

func set_bridge_name(_name: String) -> void:
	bridge_name.text = _name

func set_property_owner(player_id: int) -> void:
	if owner_id == player_id: return
	owner_id = player_id
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

# Función principal que se llama cuando se pulsa el botón
func update_mortgage_visuals(_is_mortgaged: bool) -> void:
	if is_mortgaged == _is_mortgaged: return
	is_mortgaged = _is_mortgaged
	var tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE).set_parallel()
	var tween_duration = 1
	if is_mortgaged:
		# Casilla hipotecada: Fondo rojo, letras blancas
		tween.tween_property(self, "self_modulate", Color(0.8, 0, 0, 1), tween_duration)
		tween.tween_property(bridge_name, "theme_override_colors/font_color", Color.WHITE, tween_duration)
	else:
		# Casilla normal: Restauramos (ajusta estos colores a los tuyos por defecto)
		tween.tween_property(self, "self_modulate", Color.WHITE, tween_duration)
		tween.tween_property(bridge_name, "theme_override_colors/font_color", Color.BLACK, tween_duration)
