extends SubViewportContainer

func _ready() -> void:
	connect("gui_input", _on_gui_input)
	connect("mouse_exited", _on_mouse_exited)
	connect("mouse_entered", _on_mouse_entered)
	
	pivot_offset = size / 2

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var button_press_tween: Tween = create_tween()
		button_press_tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.06).set_trans(Tween.TRANS_SINE)
		button_press_tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.12).set_trans(Tween.TRANS_SINE)
	
	if not event is InputEventMouseMotion: return
	
	var mouse_pos: Vector2 = get_local_mouse_position()
	
	var lerp_val_x: float = mouse_pos.x / size.x
	var lerp_val_y: float = mouse_pos.y / size.y
	
	var  rot_x: float = rad_to_deg(lerp_angle(-0.1, 0.1, lerp_val_x))
	var  rot_y: float = rad_to_deg(lerp_angle(0.1, -0.1, lerp_val_y))
	
	self.material.set_shader_parameter("x_rot", rot_y)
	self.material.set_shader_parameter("y_rot", rot_x)


func _on_mouse_exited() -> void:
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_SINE)
	self.material.set_shader_parameter("x_rot", 0)
	self.material.set_shader_parameter("y_rot", 0)


func _on_mouse_entered() -> void:
	create_tween().tween_property(self, "scale", Vector2(1.1, 1.1), 0.1).set_trans(Tween.TRANS_SINE)
