extends CanvasLayer

@onready var dimmer = %Dimmer
@onready var card = %PropertyCard
@onready var server_card = %ServerCard

func _ready() -> void:
	visible = false
	card.visible = false
	server_card.visible = false
	aparecer(server_card)

func aparecer(tarjeta: Control):
	tarjeta.visible = true
	show()
	dimmer.color.a = 0.0
	tarjeta.modulate.a = 0.0
	
	var pos_original = tarjeta.position.y
	tarjeta.position.y = pos_original + 20 

	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(dimmer, "color:a", 0.8, 0.4)
	tween.tween_property(tarjeta, "modulate:a", 1.0, 0.4)
	tween.tween_property(tarjeta, "position:y", pos_original, 0.4)
	
	#Esta función es la que se encarga de marcar la renta que paga el que ha caido ahí
	tarjeta.highlight_rent(0)
