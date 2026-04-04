class_name PlayerToken
extends Area2D

signal on_token_clicked(token_node: PlayerToken) # DEBUG
var token_color: Color = Color.WHITE
var hop_audio: AudioResource

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
	var radius = 20.0
	
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

#func move_to(target_pos: Vector2) -> void:	
	#var tween = create_tween()
	#tween.tween_property(self, "position", target_pos, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
func move_to(positions: Array[Vector2]) -> void:
	var hop_height: float = 40.0
	var duration: float = 0.4
	
	for target_pos in positions:
		AudioSystem.play_audio(hop_audio)
		
		var tween = create_tween()
		var mid_point = position.lerp(target_pos, 0.5)
		mid_point.y -= hop_height 
		
		tween.tween_property(self, "position", mid_point, duration / 2.0) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		tween.tween_property(self, "position", target_pos, duration / 2.0) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			
		await tween.finished
		await get_tree().create_timer(0.05).timeout

# DEBUG
func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		on_token_clicked.emit(self)
