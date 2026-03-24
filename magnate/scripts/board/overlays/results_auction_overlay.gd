extends CanvasLayer

# --- NODOS DE UI: GANADOR (PLAYER 1) ---
@onready var color_dot_1: Panel = %ColorDot1
@onready var player_1_label: Label = %Player1Label
@onready var player_1_bet: Label = %Player1Bet

# --- NODOS DE UI: PLAYER 2 ---
@onready var color_dot_2: Panel = %ColorDot2
@onready var player_2_label: Label = %Player2Label
@onready var player_2_bet: Label = %Player2Bet

# --- NODOS DE UI: PLAYER 3 ---
@onready var color_dot_3: Panel = %ColorDot3
@onready var player_3_label: Label = %Player3Label
@onready var player_3_bet: Label = %Player3Bet

# --- NODOS DE UI: PLAYER 4 ---
@onready var color_dot_4: Panel = %ColorDot4
@onready var player_4_label: Label = %Player4Label
@onready var player_4_bet: Label = %Player4Bet

func _ready() -> void:
	# Asignamos los valores iniciales (constantes de prueba)
	configurar_datos_mockup()

func configurar_datos_mockup() -> void:
	# --- DATOS DEL GANADOR ---
	color_dot_1.modulate = Color.RED
	player_1_label.text = "Lucas"
	player_1_bet.text = "180€"
	
	# --- DATOS DEL 2º PUESTO ---
	color_dot_2.modulate = Color.BLUE
	player_2_label.text = "Cris"
	player_2_bet.text = "179€"
	
	# --- DATOS DEL 3º PUESTO ---
	color_dot_3.modulate = Color.ORANGE 
	player_3_label.text = "Nic"
	player_3_bet.text = "30€"
	
	# --- DATOS DEL 4º PUESTO ---
	color_dot_4.modulate = Color.GREEN
	player_4_label.text = "Naud"
	player_4_bet.text = "10€"
