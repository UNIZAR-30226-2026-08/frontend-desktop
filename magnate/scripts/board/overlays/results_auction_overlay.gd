extends CanvasLayer

# Agrupamos los nodos en Arrays
@onready var dots: Array[Panel] = [%ColorDot1, %ColorDot2, %ColorDot3, %ColorDot4]
@onready var names: Array[Label] = [%Player1Label, %Player2Label, %Player3Label, %Player4Label]
@onready var bets: Array[Label] = [%Player1Bet, %Player2Bet, %Player3Bet, %Player4Bet]

# NUEVO: Referencia al botón
@onready var confirm_button: Button = %ConfirmButton

func _ready() -> void:
	# Ocultamos todo al principio por si hay menos de 4 jugadores
	for i in range(4):
		dots[i].visible = false
		names[i].visible = false
		bets[i].visible = false
		
	# Conectamos el botón para que ejecute la función al ser pulsado
	confirm_button.pressed.connect(_on_confirm_button_pressed)

# ==========================================
# INYECTAR DATOS DESDE EL BOARD
# ==========================================
func mostrar_resultados(resultados_ordenados: Array) -> void:
	# Se espera que 'resultados_ordenados' venga ya ordenado de mayor a menor puja
	for i in range(resultados_ordenados.size()):
		if i >= 4: 
			break # Por seguridad, máximo 4 jugadores en UI
			
		var data = resultados_ordenados[i]
		
		dots[i].visible = true
		names[i].visible = true
		bets[i].visible = true
		
		dots[i].modulate = data["color"]
		names[i].text = data["name"]
		bets[i].text = Utils.to_currency_text(data["bet"])

# ==========================================
# EVENTOS DE BOTONES
# ==========================================
func _on_confirm_button_pressed() -> void:
	print("Saliendo de la pantalla de resultados...")
	# Destruimos el overlay y volvemos a ver el tablero limpio
	queue_free()
