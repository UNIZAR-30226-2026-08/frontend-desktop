extends Panel

@onready var round_count: Label = %RoundCount

func _ready() -> void:
	ModelManager.turn_updated.connect(func():
		round_count.text = str(ModelManager.game.current_turn)
	)
