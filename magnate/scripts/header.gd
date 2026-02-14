extends ColorRect

signal back_action_requested

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
	
	if %BackButton.has_signal("pressed"):
		%BackButton.pressed.connect(_on_back_button_pressed)
	else:
		push_error("The node %BackButton does not have a 'pressed' signal!")

func _on_back_button_pressed():
	back_action_requested.emit()
