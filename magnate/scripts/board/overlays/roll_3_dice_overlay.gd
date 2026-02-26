extends CanvasLayer

@onready var dimmer = $Dimmer

# --- CONFIGURACIÓN DE RESULTADOS (Simulación de Backend) ---
const RESULT_DICE_1 = 3  # El dado mostrará la cara 3 (índice 2)
const RESULT_DICE_2 = 5  # El dado mostrará la cara 5 (índice 4)
const RESULT_DICE_3 = 1  # El dado mostrará la cara 1 (índice 0)

# Arrastra tus 6 imágenes aquí desde el sistema de archivos
@export var dice_faces: Array[Texture2D] 

@onready var dice_nodes: Array[TextureRect] = [
	%Dice1,
	%Dice2,
	%Dice3
]

var rolling: bool = true
var roll_timer: float = 0.0
var wait_time: float = 0.05 # Velocidad de la animación

func _ready() -> void:
	aparecer()
	
func aparecer():
	show()
	
	# Estado inicial
	dimmer.color.a = 0.0
	
	var tween = create_tween().set_parallel(true)
	
	# Animación de opacidad
	tween.tween_property(dimmer, "color:a", 0.8, 0.6).set_trans(Tween.TRANS_SINE)
	
func _process(delta: float) -> void:
	if rolling:
		roll_timer += delta
		if roll_timer >= wait_time:
			_shuffle_dice_faces()
			roll_timer = 0.0

func _shuffle_dice_faces() -> void:
	for dice in dice_nodes:
		dice.texture = dice_faces.pick_random()

func _finalize_roll() -> void:
	# Aquí usamos las constantes en lugar de randi()
	# Restamos 1 porque el array dice_faces empieza en 0
	dice_nodes[0].texture = dice_faces[RESULT_DICE_1 - 1]
	dice_nodes[1].texture = dice_faces[RESULT_DICE_2 - 1]
	dice_nodes[2].texture = dice_faces[RESULT_DICE_3 - 1]
	
	print("Resultados fijados: ", [RESULT_DICE_1, RESULT_DICE_2, RESULT_DICE_3])

func _on_stop_dice_button_pressed() -> void:
	if rolling:
		rolling = false
		$StopDiceButton.text = "Aceptar"
		_finalize_roll()
