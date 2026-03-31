extends Control

enum CardSide {FRONT, BACK}

@export var side_to_show: CardSide = CardSide.BACK

signal pressed;

# Referencias a los nodos internos de la carta
@onready var fantasy_card_back: Panel = %FantasyCardBack
@onready var fantasy_card_front: PanelContainer = %FantasyCardFront
@onready var sub_viewport_container: SubViewportContainer = %SubViewportContainer

@onready var title_label: Label = %CardTitle 
@onready var description_label: Label = %CardDescription

var flipped = false;

func _ready() -> void:
	pivot_offset = size / 2.0 # Center pivot for rotation
	_update_visual_side()

# ====================
#  Data configuration
# ====================

## Changes the contents displayed on the card
## Needs dictionary with "name" and "description" as keys
func setup_content(data: Dictionary) -> void:
	if title_label:
		title_label.text = data.get("name", "Fantasía")
	
	if description_label:
		description_label.text = data.get("description", "Ha ocurrido algo inesperado...")

# ================
#  Flip animation
# ================

func _update_visual_side() -> void:
	fantasy_card_back.visible = (side_to_show == CardSide.BACK)
	fantasy_card_front.visible = (side_to_show == CardSide.FRONT)

func flip() -> void:
	side_to_show = CardSide.FRONT if side_to_show == CardSide.BACK else CardSide.BACK
	_update_visual_side()

func flip_smooth() -> void:
	# 1. Audio
	var audio = AudioResource.from_type(Globals.AUDIO_CARDFLIP, AudioResource.AudioResourceType.SFX)
	AudioSystem.play_audio_with_position(audio, global_position)
	
	# 2. First half of the rotation (from 0 to 90 degrees)
	var tween = create_tween()
	tween.tween_method(_set_y_rot, 0.0, 90.0, 0.2)
	await tween.finished
	
	# 3. Change the texture
	flip()
	
	# 4. Sencond half of the rotation (from -90 to 0)
	_set_y_rot(-90.0)
	var tween2 = create_tween()
	tween2.tween_method(_set_y_rot, -90.0, 0.0, 0.2)
	await tween2.finished

func _set_y_rot(value: float) -> void:
	if sub_viewport_container.material:
		sub_viewport_container.material.set_shader_parameter("y_rot", value)

func set_opacity(o: float) -> void:
	if sub_viewport_container.material:
		sub_viewport_container.material.set_shader_parameter("opacity", o)

# ================
#  Input handling
# ================

func _on_sub_viewport_container_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		# Only flip back facing cards
		if side_to_show == CardSide.BACK and not flipped:
			flipped = true
			pressed.emit()
			flip_smooth()
		else:
			pressed.emit()
