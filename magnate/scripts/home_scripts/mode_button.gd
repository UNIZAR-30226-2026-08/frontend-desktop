extends Button

@export_group("Content")
@export var title_text: String = "TITLE"
@export var subtitle_text: String = "Subtitle"
@export var icon_texture: Texture2D
@export var bg_texture: Texture2D
@export_enum("Top Left", "Top Right", "Bottom Left", "Bottom Right") var bg_alignment: int = 0

@export_group("Animation")
@export var hover_scale: Vector2 = Vector2(1.05, 1.05)
@export var pressed_scale: Vector2 = Vector2(0.95, 0.95)

@onready var label_title = $TextContainer/Title
@onready var label_subtitle = $TextContainer/Subtitle
@onready var icon_rect = $Icon
@onready var bg_rect = $BgImage
@onready var sfx: AudioStreamPlayer = $ClickSFXStreamPlayer

func _ready() -> void:
	if label_title:
		label_title.text = title_text
	
	if label_subtitle:
		label_subtitle.text = subtitle_text
	
	if icon_texture and icon_rect:
		icon_rect.texture = icon_texture
		icon_rect.modulate = Color(1, 1, 1, 0.5)
	
	if bg_texture and bg_rect:
		bg_rect.texture = bg_texture

	mouse_entered.connect(_button_enter)
	mouse_exited.connect(_button_exit)
	focus_entered.connect(_button_enter)
	focus_exited.connect(_button_exit)
	pressed.connect(_button_pressed)
	
	resized.connect(_on_resized)
	
	call_deferred("_update_layout")

func _on_resized() -> void:
	_update_layout()

func _update_layout() -> void:
	pivot_offset = size / 2.0
	_set_bg_alignment()

func _set_bg_alignment():
	if !bg_rect: return

	bg_rect.anchor_left = 0
	bg_rect.anchor_top = 0
	bg_rect.anchor_right = 0
	bg_rect.anchor_bottom = 0
	
	bg_rect.size = size * 1.5
	
	var extra_space = bg_rect.size - size

	match bg_alignment:
		0: bg_rect.position = Vector2.ZERO
		1: bg_rect.position = Vector2(-extra_space.x, 0)
		2: bg_rect.position = Vector2(0, -extra_space.y)
		3: bg_rect.position = -extra_space

func _button_enter() -> void:
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "scale", hover_scale, 0.1)
	if icon_rect:
		tween.tween_property(icon_rect, "modulate:a", 1.0, 0.1)

func _button_exit() -> void:
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)
	if icon_rect:
		tween.tween_property(icon_rect, "modulate:a", 0.5, 0.1)

func _button_pressed() -> void:
	if sfx and sfx.stream:
		sfx.play()
	
	var tween = create_tween()
	tween.tween_property(self, "scale", pressed_scale, 0.06).set_trans(Tween.TRANS_SINE)
	
	if self.is_hovered():
		tween.tween_property(self, "scale", hover_scale, 0.12).set_trans(Tween.TRANS_SINE)
	else:
		tween.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_SINE)
