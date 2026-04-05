extends CanvasLayer

signal close_overlay
signal animation_complete

@onready var window_glass = $MainContainer/WindowGlass
@onready var cerrada_text = $MainContainer/WindowGlass/CerradaText

func _ready():
	visible = false

func play_animation():
	visible = true
	
	var screen_width = get_viewport().get_visible_rect().size.x
	window_glass.position.x = -screen_width
	cerrada_text.modulate.a = 0.0
	
	var sequence = create_tween()
	sequence.tween_interval(2.0)
	sequence.tween_callback(_animate_window)
	sequence.tween_interval(4.0)
	sequence.tween_callback(_on_animation_complete)

func _animate_window():
	var slide_tween = create_tween()
	slide_tween.tween_property(window_glass, "position:x", 0.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	var text_tween = create_tween()
	text_tween.tween_interval(0.5)
	text_tween.tween_property(cerrada_text, "modulate:a", 1.0, 0.5)

func _on_animation_complete():
	visible = false
	close_overlay.emit()
	animation_complete.emit()
