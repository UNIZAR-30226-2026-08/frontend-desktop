extends ColorRect

# Emitted when the back button is clicked. 
# Connect to this in your main scene to handle navigation (e.g., get_tree().change_scene...)
signal back_pressed

@export var title: String = "Title":
	set(value):
		title = value
		if %TitleLabel:
			%TitleLabel.text = value

@export var show_back_button: bool = true:
	set(value):
		show_back_button = value
		if %BackButton:
			%BackButton.visible = value

func _ready():
	# Initialize properties
	%TitleLabel.text = title
	%BackButton.visible = show_back_button

# --- Signal Connections ---

func _on_back_button_up():
	back_pressed.emit()

# --- Animations ---
# Replicates: transition-transform duration-200 ease-in-out hover:scale-110

func _on_back_button_mouse_entered():
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE) # Smooth ease
	tween.set_ease(Tween.EASE_OUT)
	# Scale up to 110% (1.1)
	tween.tween_property(%BackButton, "scale", Vector2(1.1, 1.1), 0.2)

func _on_back_button_mouse_exited():
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	# Scale back to normal (1.0)
	tween.tween_property(%BackButton, "scale", Vector2(1.0, 1.0), 0.2)
