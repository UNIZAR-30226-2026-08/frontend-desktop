extends CanvasLayer

@onready var dimmer = $Dimmer
@onready var anchor = %ContentAnchor # Para mostar la Tile

@onready var CARD_SIZE = Vector2(400, 600)
@onready var CORNER_CARD_SIZE = Vector2(600, 600)

@onready var CARD_OFFSET_X = 0
@onready var CARD_OFFSET_Y = -100

@onready var CORNER_CARD_OFFSET_X = -300
@onready var CORNER_CARD_OFFSET_Y = -350

@export var default_card_scene: PackedScene
@export var test_mode: bool = true

func _ready():
	if test_mode and default_card_scene:
		setup_with_scene(default_card_scene)

func setup_with_scene(card_scene: PackedScene, data: Dictionary = {}):
	var card_instance = card_scene.instantiate()
	_prepare_and_add_card(card_instance, data)

func setup_overlay(card_scene_path: String, data: Dictionary = {}):
	var card_resource = load(card_scene_path)
	var card_instance = card_resource.instantiate()
	_prepare_and_add_card(card_instance, data)

# Función interna para evitar repetir código
func _prepare_and_add_card(card: Control, data: Dictionary):
	var offset_x = CORNER_CARD_OFFSET_X
	var offset_y = CORNER_CARD_OFFSET_Y
	var card_size = CORNER_CARD_SIZE
	
	# 1. Limpiar previo
	for child in anchor.get_children():
		child.queue_free()
	
	# 2. Configurar tamaño y anclaje de la tarjeta ANTES de añadirla
	card.custom_minimum_size = card_size
	card.size = card_size
	
	# Centrar el pivot para que si escalas o mueves sea desde su centro
	card.pivot_offset = (card_size / 2)
	
	# 3. Añadir al anchor
	anchor.add_child(card)
	
	# 4. Posicionar en el centro del anchor manualmente
	card.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	
	# DESPLAZAMIENTO HACIA ARRIBA:
	# Restamos píxeles a la posición Y. Por ejemplo, 50px hacia arriba.
	# Cuanto más alto sea el número, más subirá la carta.
	card.position.y += offset_y
	card.position.x += offset_x
	
	# 5. Datos
	if card.has_method("populate_data"):
		card.populate_data(data)
	
	aparecer()

func aparecer():
	show()
	
	var tarjeta = anchor.get_children().front()
	
	# Estado inicial
	dimmer.color.a = 0.0
	if tarjeta:
		tarjeta.modulate.a = 0.0
	
	var tween = create_tween().set_parallel(true)
	
	# Animación de opacidad
	tween.tween_property(dimmer, "color:a", 0.8, 0.6).set_trans(Tween.TRANS_SINE)
	
	if tarjeta:
		tween.tween_property(tarjeta, "modulate:a", 1.0, 0.6)

func desaparecer():
	var tween = create_tween()
	# Desvanecemos todo el CanvasLayer para simplificar
	tween.tween_property(self, "offset:y", 50, 0.2) # Pequeño efecto de caída opcional
	tween.parallel().tween_property(dimmer, "color:a", 0.0, 0.2)
	
	await tween.finished
	queue_free()

func _on_confirm_button_pressed() -> void:
	pass # Replace with function body.
