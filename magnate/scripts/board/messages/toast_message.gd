extends CanvasLayer

@onready var toast_panel: PanelContainer = $Container/ToastPanel
@onready var message_label: Label = $Container/ToastPanel/MessageLabel

var current_tween: Tween

const BASE_Y_POS: float = 96.0 
const ANIM_OFFSET_Y: float = 32.0 

func _ready() -> void:
	toast_panel.modulate.a = 0.0
	toast_panel.hide()

func show_toast(message: String, duration: float = 3.0) -> void:
	if not is_node_ready():
		await ready

	if current_tween and current_tween.is_valid():
		current_tween.kill()

	message_label.text = message
	toast_panel.show()
	toast_panel.pivot_offset = toast_panel.size / 2.0

	current_tween = create_tween()
	
	toast_panel.modulate.a = 0.0
	toast_panel.scale = Vector2(0.95, 0.95)
	toast_panel.position.y = BASE_Y_POS - ANIM_OFFSET_Y
	
	current_tween.set_parallel(true)
	current_tween.tween_property(toast_panel, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	current_tween.tween_property(toast_panel, "position:y", BASE_Y_POS, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	current_tween.tween_property(toast_panel, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	if duration > 0.0:
		current_tween.set_parallel(false)
		current_tween.tween_interval(duration)
		current_tween.tween_callback(hide_toast)

func hide_toast() -> void:
	if current_tween and current_tween.is_valid():
		current_tween.kill()
		
	current_tween = create_tween().set_parallel(true)
	
	var target_y = BASE_Y_POS - ANIM_OFFSET_Y
	
	current_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	current_tween.tween_property(toast_panel, "position:y", target_y, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	current_tween.tween_property(toast_panel, "scale", Vector2(0.95, 0.95), 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	current_tween.chain().tween_callback(func(): toast_panel.hide())
