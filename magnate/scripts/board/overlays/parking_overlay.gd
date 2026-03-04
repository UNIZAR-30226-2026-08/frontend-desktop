extends CanvasLayer

@onready var dimmer = %Dimmer
@onready var card = %ParkingCard

func _ready() -> void:
	visible = false
	aparecer(card)

func aparecer(tarjeta: Control):
	show()
	dimmer.color.a = 0.0
	tarjeta.modulate.a = 0.0
	
	var pos_original = tarjeta.position.y
	tarjeta.position.y = pos_original + 20 

	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(dimmer, "color:a", 0.8, 0.4)
	tween.tween_property(tarjeta, "modulate:a", 1.0, 0.4)
	tween.tween_property(tarjeta, "position:y", pos_original, 0.4)
