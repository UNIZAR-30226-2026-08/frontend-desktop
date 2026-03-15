extends Control

enum CardSide {FRONT, BACK}

@export var side_to_show: CardSide = CardSide.BACK

signal pressed;

@onready var fantasy_card_back: Panel = $SubViewportContainer/SubViewport/FantasyCardBack
@onready var fantasy_card_front: PanelContainer = $SubViewportContainer/SubViewport/FantasyCardFront
@onready var sub_viewport_container: SubViewportContainer = $SubViewportContainer

var flipped = false;

func _ready() -> void:
	pivot_offset = size
	if side_to_show == CardSide.BACK:
		fantasy_card_back.show()
		fantasy_card_front.hide()
	else:
		fantasy_card_back.hide()
		fantasy_card_front.show()

func change_side_smooth(_s: CardSide) -> void:
	if _s != side_to_show: flip_smooth()

func change_side(_s: CardSide) -> void:
	if _s != side_to_show: flip()

func flip() -> void:
	match side_to_show:
		CardSide.BACK:
			side_to_show = CardSide.FRONT
			fantasy_card_back.hide()
			fantasy_card_front.show()
		CardSide.FRONT:
			side_to_show = CardSide.BACK
			fantasy_card_back.show()
			fantasy_card_front.hide()

func _set_y_rot(value: float) -> void:
	sub_viewport_container.material.set_shader_parameter("y_rot", value)

func flip_smooth() -> void:
	var audio = AudioResource.from_type(Globals.AUDIO_CARDFLIP, AudioResource.AudioResourceType.SFX)
	AudioSystem.play_audio_with_position(audio, global_position)
	
	# Animate
	var start_rotation = sub_viewport_container.material.get_shader_parameter("y_rot")
	var tween = create_tween()
	tween.tween_method(_set_y_rot, start_rotation, 90, 0.25)
	tween.play()
	await tween.finished
	# flip
	flip()
	# Animate
	_set_y_rot(-90)
	tween.kill()
	tween = create_tween()
	tween.tween_method(_set_y_rot, -90, 0, 0.25)
	tween.play()
	await tween.finished

func _on_sub_viewport_container_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and not flipped:
		flipped = true
		pressed.emit()
		flip_smooth()

func set_opacity(o: float) -> void:
	sub_viewport_container.material.set_shader_parameter("opacity", o)
