extends Button

@export var icon_texture: Texture2D

@onready var icon_rect: TextureRect = $TextureRect

func _ready() -> void:
	if icon_texture:
		icon_rect.texture = icon_texture
	
	pivot_offset = size / 2.0
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	pressed.connect(_on_pressed)

func _on_mouse_entered() -> void:
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.15)

func _on_mouse_exited() -> void:
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.15)

func _on_pressed() -> void:
	var audio = AudioResource.from_type(Globals.AUDIO_CLICK, AudioResource.AudioResourceType.UI)
	AudioSystem.play_audio(audio)

	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.1)
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
