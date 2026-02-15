extends Button

@export var button_text: String = "Button"
@export var icon_texture: Texture2D

@onready var label = %Label
@onready var icon_rect = %Icon
@onready var sfx = $ClickSFXStreamPlayer

func _ready() -> void:
	if label:
		label.text = button_text
	
	if icon_texture and icon_rect:
		icon_rect.texture = icon_texture
	
	# Set pivot to center for scaling animation
	pivot_offset = size / 2.0
	
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_exit)
	pressed.connect(_on_pressed)

func _on_hover() -> void:
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.15)

func _on_exit() -> void:
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.15)

func _on_pressed() -> void:
	if sfx:
		sfx.play()
	
	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.1)
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)
