class_name BasicCardOverlay
extends CanvasLayer

@export var target_blur = 1.5
@export var target_dark = 0.5
@export var fade_duration = 0.5
@export var button_text: String = "Placeholder"
@export var card: Control
@export var button: Button = null

signal button_pressed

var _dark_filter: ColorRect = null
var _blur_filter: ColorRect = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if button == null:
		button = $AnimatedButton
	button.text = button_text
	button.connect("pressed", _button_press_handler)
	fadein()

func _button_press_handler():
	button_pressed.emit()
	fadeout()

func fadein() -> void:
	_dark_filter = ColorRect.new()
	_blur_filter = ColorRect.new()
	
	_dark_filter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_blur_filter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	_dark_filter.color = Color(0, 0, 0, 0)
	var mat = ShaderMaterial.new()
	mat.shader = load("res://styles/shaders/blur.gdshader")
	mat.set_shader_parameter("lod", 0)
	_blur_filter.material = mat
	card.set_opacity(0)
	var original_card_y = card.position.y
	card.position.y += 20
	
	add_child(_dark_filter)
	move_child(_dark_filter, 0)
	add_child(_blur_filter)
	move_child(_blur_filter, 1)
	
	var tween = get_tree().create_tween()\
		.set_parallel(true)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)
	tween.tween_method(
		func(value): _blur_filter.material.set_shader_parameter("lod", value),  
		0.0, target_blur, fade_duration
	);
	tween.tween_property(_dark_filter, "color:a", target_dark, fade_duration)
	tween.tween_property(card, "position:y", original_card_y, fade_duration)
	tween.tween_method(card.set_opacity, 0., 1., fade_duration)

func fadeout() -> void:
	var target_card_y = card.position.y + 20
	
	var tween = get_tree().create_tween()\
		.set_parallel(true)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_method(
		func(value): _blur_filter.material.set_shader_parameter("lod", value),  
		target_blur, 0., fade_duration
	);
	tween.tween_property(_dark_filter, "color:a", 0., fade_duration)
	tween.tween_property(card, "position:y", target_card_y, fade_duration)
	tween.tween_method(card.set_opacity, 1., 0., fade_duration)
	tween.connect("finished", queue_free)
