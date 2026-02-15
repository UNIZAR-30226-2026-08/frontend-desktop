extends Control

# archivos .tres almacenados en styles/tips/ (Arrastrar al inspector)
@export var tips_data: Array[TipData] = []
@export var card_scene: PackedScene # tip_card.tscn

# Configuración visual
@export var card_spacing: float = 250.0
@export var scale_min: float = 0.7
@export var scale_max: float = 1.1
@export var alpha_min: float = 0.5 # Opacidad de cartas adyacentes
@export var anim_speed: float = 0.3
@export var center_padding: float = 8.0 # Espacio para "empujar" las de los lados

var current_index: int = 0
var cards: Array = []

func _ready():
	# Instanciamos todas las tarjetas
	for i in range(tips_data.size()):
		var card = card_scene.instantiate()
		add_child(card)
		card.setup(tips_data[i], i)
		card.card_clicked.connect(_on_card_clicked)
		cards.append(card)
	
	update_carousel(false) # false = sin animación al inicio

func _on_card_clicked(index: int):
	if index != current_index:
		current_index = index
		update_carousel(true)

func update_carousel(animate: bool):
	var center_x = size.x / 2
	var center_y = size.y / 2 + 50
	
	for i in range(cards.size()):
		var card = cards[i]
		var diff = i - current_index
		
		var extra_push = 0.0
		if diff != 0:
			# Si la carta está a la derecha (diff > 0), empujamos +padding
			# Si la carta está a la izquierda (diff < 0), empujamos -padding
			# sign(diff) nos devuelve 1 o -1 dependiendo del lado
			extra_push = sign(diff) * center_padding
		
		var target_x = center_x + (diff * card_spacing) + extra_push
		
		var target_scale = Vector2.ONE * scale_min
		var target_alpha = alpha_min
		
		if i == current_index:
			target_scale = Vector2.ONE * scale_max
			target_alpha = 1.0
			card.visible = true  # La mostramos si es vecina o centro
			card.move_to_front()
		elif abs(diff) == 1:
			card.visible = true  # La mostramos si es vecina o centro
			pass 
		else:
			card.visible = false # Ocultamos la carta completamente para que no moleste
			target_alpha = 0.0 
		
		
		if animate:
			var tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			tween.tween_property(card, "position", Vector2(target_x - (card.size.x * target_scale.x / 2), center_y - (card.size.y * target_scale.y / 2)), anim_speed)
			tween.tween_property(card, "scale", target_scale, anim_speed)
			tween.tween_property(card, "modulate:a", target_alpha, anim_speed)
		else:
			card.scale = target_scale
			card.modulate.a = target_alpha
			card.position = Vector2(target_x - (card.size.x * target_scale.x / 2), center_y - (card.size.y * target_scale.y / 2))
