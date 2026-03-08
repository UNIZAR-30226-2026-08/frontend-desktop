extends CanvasLayer

@onready var front_fantasy_card: Control = $HBoxContainer/FrontFantasyCard
@onready var back_fantasy_card: Control = $HBoxContainer/BackFantasyCard

func _ready() -> void:
	front_fantasy_card.flipped = true

func _on_front_fantasy_card_pressed() -> void:
	pass # Replace with function body.


func _on_back_fantasy_card_pressed() -> void:
	var tween = create_tween()
	tween.tween_property(front_fantasy_card, "scale", Vector2(.9, .9), .1)
	tween.tween_method(front_fantasy_card.set_opacity, 1.0, .5, .1)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.play()
	await tween.finished
