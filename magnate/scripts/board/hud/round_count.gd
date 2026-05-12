extends Panel

@onready var round_count: Label = %RoundCount
@onready var round_max: Label = %RoundMax

func _ready() -> void:
	ModelManager.turn_updated.connect(func():
		round_count.text = str(ModelManager.game.current_turn)
	)

func set_round_max(_round_max: int) -> void:
	round_max.text = str(int(_round_max))
