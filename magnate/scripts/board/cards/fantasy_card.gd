extends Control

@onready var fantasy_card_back: PanelContainer = $SubViewportContainer/SubViewport/FantasyCardBack
@onready var fantasy_card_front: PanelContainer = $SubViewportContainer/SubViewport/FantasyCardFront
@onready var sub_viewport_container: SubViewportContainer = $SubViewportContainer

enum CardSide {FRONT, BACK}

var _side: CardSide = CardSide.BACK

func _ready() -> void:
	fantasy_card_back.show()
	fantasy_card_front.hide()

func change_side_smooth(_s: CardSide) -> void:
	if _s != _side: flip_smooth()

func change_side(_s: CardSide) -> void:
	if _s != _side: flip()

func flip() -> void:
	match _side:
		CardSide.BACK:
			_side = CardSide.FRONT
			fantasy_card_back.hide()
			fantasy_card_front.show()
		CardSide.FRONT:
			_side = CardSide.BACK
			fantasy_card_back.show()
			fantasy_card_front.hide()

func _set_y_rot(value: float) -> void:
	sub_viewport_container.material.set_shader_parameter("y_rot", value)

func flip_smooth() -> void:
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
	if event is InputEventMouseButton and event.is_pressed():
		flip_smooth()
