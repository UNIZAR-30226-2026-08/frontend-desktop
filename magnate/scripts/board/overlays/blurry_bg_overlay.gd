class_name BlurryBgOverlay
extends CanvasLayer

@export var target_blur = 1.5;
@export var fadein_duration = 2;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var dark_filter = ColorRect.new()
	var blur_filter = ColorRect.new()
	
	dark_filter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blur_filter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	dark_filter.color = Color("#000000CC")
	var mat = ShaderMaterial.new()
	mat.shader = load("res://styles/shaders/blur.gdshader")
	mat.set_shader_parameter("lod", target_blur)
	blur_filter.material = mat
	
	add_child(dark_filter)
	move_child(dark_filter, 0)
	add_child(blur_filter)
	move_child(blur_filter, 1)
	# var tween = get_tree().create_tween()
	# tween.tween_property(
	# 	blur_filter.material, "shader_parameter/lod", target_blur, blur_duration
	# ).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
