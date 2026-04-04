extends Button

func _ready() -> void:
	pivot_offset = size / 2.0
	
	text = "MUTED" if button_pressed else "MUTE"
	
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_exit)
	pressed.connect(_on_pressed)
	toggled.connect(_on_toggled)

func _on_hover() -> void:
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.15)

func _on_exit() -> void:
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.15)

func _on_pressed() -> void:
	var audio = AudioResource.from_type(Globals.AUDIO_CLICK, AudioResource.AudioResourceType.UI)
	AudioSystem.play_audio(audio)
	
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.1)
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)

func _on_toggled(toggled_on: bool) -> void:
	text = "MUTED" if toggled_on else "MUTE"
