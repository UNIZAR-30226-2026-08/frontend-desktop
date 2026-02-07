extends Button

@export_category("Animation")
@export var hover_scale: Vector2 = Vector2(1.1, 1.1)
@export var pressed_scale: Vector2 = Vector2(0.9, 0.9)

func _ready() -> void:
	# Connect signals
	mouse_entered.connect(_button_enter)
	mouse_exited.connect(_button_exit)
	focus_entered.connect(_button_enter)
	focus_exited.connect(_button_exit)
	pressed.connect(_button_pressed)
	
	# Set text
	$ButtonText.text = self.text
	$ButtonTextShadow.text = self.text
	
	call_deferred("_init_pivot")

func _init_pivot() -> void:
	pivot_offset = size / 2.0

func _button_enter() -> void:
	create_tween().tween_property(self, "scale", hover_scale, 0.1).set_trans(Tween.TRANS_SINE)


func _button_exit() -> void:
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_SINE)


func _button_pressed() -> void:
	# Audio
	$ClickSFXStreamPlayer.play()
	
	# Animation
	var button_press_tween: Tween = create_tween()
	button_press_tween.tween_property(self, "scale", pressed_scale, 0.06).set_trans(Tween.TRANS_SINE)
	button_press_tween.tween_property(self, "scale", hover_scale, 0.12).set_trans(Tween.TRANS_SINE)
