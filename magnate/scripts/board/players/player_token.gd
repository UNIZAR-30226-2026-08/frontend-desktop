class_name PlayerToken
extends Area2D

signal on_token_clicked(token_node: PlayerToken) # DEBUG
var token_color: Color = Color.WHITE
var hop_audio: AudioResource
var offset: Vector2 = Vector2.ZERO:
	set(value):
		offset = value
		queue_redraw()
var radius: float = 20.0:
	set(value):
		radius = value
		queue_redraw()

func _ready() -> void:
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 20.0
	collision.shape = shape
	add_child(collision)
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	input_event.connect(_on_input_event)
	
	hop_audio = AudioResource.from_type(Globals.AUDIO_PLAYER_HOP, AudioResource.AudioResourceType.SFX)

func setup(color: Color) -> void:
	token_color = color
	queue_redraw()

func _draw() -> void:
	draw_set_transform(offset, 0, Vector2.ONE)
	
	draw_circle(Vector2(3, 3), radius, Color(0, 0, 0, 0.3))
	draw_circle(Vector2.ZERO, radius, token_color)
	
	# TAU = 2*PI, 32 is the resolution, 3.0 is line width
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color.WHITE, 3.0, true)

func _on_mouse_entered() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)

func _on_mouse_exited() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)

func tp_to_pos(pos: Vector2) -> void:
	position = pos

func move_to(positions: Array[Vector2]) -> void:
	var hop_height: float = 40.0
	var duration: float = 0.4
	
	for target_pos in positions:
		AudioSystem.play_audio(hop_audio)
		
		var movement_vector = (target_pos - position).abs()
		var is_vertical = movement_vector.y > movement_vector.x
		
		var hop_tween = create_tween().set_trans(Tween.TRANS_QUAD)
		if is_vertical:
			hop_tween.tween_property(self, "radius", 22.0, duration / 2.0) \
					.set_ease(Tween.EASE_OUT)
			hop_tween.tween_property(self, "radius", 20.0, duration / 2.0) \
				.set_ease(Tween.EASE_IN)
		else:
			hop_tween.tween_property(self, "offset", Vector2(0, -hop_height), duration / 2.0) \
					.set_ease(Tween.EASE_OUT)
			hop_tween.tween_property(self, "offset", Vector2.ZERO, duration / 2.0) \
				.set_ease(Tween.EASE_IN)
			
		var tween = create_tween().set_trans(Tween.TRANS_QUAD)
		tween.tween_property(self, "position", target_pos, duration) \
			.set_ease(Tween.EASE_IN)
			
		await tween.finished
		await get_tree().create_timer(0.05).timeout

# DEBUG
func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		on_token_clicked.emit(self)
