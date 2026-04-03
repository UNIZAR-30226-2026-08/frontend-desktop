extends CanvasLayer

@onready var banner_root = %BannerRoot
@onready var background = %Background
@onready var message_label = %MessageLabel

var current_tween: Tween

func _ready() -> void:
	visible = false

func show_banner(message: String, bg_color: Color = Color("008a5c"), duration: float = 2.5) -> void:
	if not is_node_ready():
		await ready

	if current_tween and current_tween.is_valid():
		current_tween.kill() 
		
	message_label.text = message
	background.color = bg_color
	
	var screen_width = get_viewport().get_visible_rect().size.x
	
	banner_root.position.x = -screen_width       
	
	visible = true
	
	current_tween = create_tween()
	
	current_tween.set_parallel(true)
	current_tween.tween_property(banner_root, "position:x", 0.0, 0.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	if duration > 0.0:
		current_tween.set_parallel(false) 
		current_tween.tween_interval(duration) 
		current_tween.tween_callback(hide_banner) 

func hide_banner() -> void:
	if current_tween and current_tween.is_valid():
		current_tween.kill()
		
	var screen_width = get_viewport().get_visible_rect().size.x
	
	current_tween = create_tween().set_parallel(true)
	current_tween.tween_property(banner_root, "position:x", screen_width, 0.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	
	current_tween.chain().tween_callback(func(): visible = false)
