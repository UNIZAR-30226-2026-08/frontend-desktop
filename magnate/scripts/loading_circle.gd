extends TextureRect

var rotation_tween: Tween

func _ready() -> void:
	start_loading_animation()

func start_loading_animation():
	if rotation_tween: rotation_tween.kill()
	rotation_tween = create_tween().set_loops()
	rotation_tween.tween_property(self, "rotation_degrees", 360, 2.0).from(0)

func stop_loading_animation():
	if rotation_tween:
		rotation_tween.kill()
		self.rotation_degrees = 0
