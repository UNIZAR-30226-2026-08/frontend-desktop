extends CanvasLayer

signal card_action_resolved

# Referencias a los nodos hijos (cartas)
@onready var front_card: Control = $HBoxContainer/FrontFantasyCard
@onready var back_card: Control = $HBoxContainer/BackFantasyCard

# --- CONSTANTES DE TIEMPO ---
const TIEMPO_ESPERA_CIERRE: float = 3.0
const TIEMPO_DESVANECIMIENTO: float = 1.0

func setup_card(card_data: Dictionary) -> void:
	# Pasamos el tipo de mazo a la carta trasera (el dorso)
	if back_card.has_method("set_deck_type"):
		back_card.set_deck_type(card_data["deck_type"])
	
	# Pasamos los textos a la carta delantera
	if front_card.has_method("setup_content"):
		front_card.setup_content(card_data)

# ==========================================
# LÓGICA DE CIERRE CON DESVANECIMIENTO
# ==========================================

# Se llama cuando pulsas la carta trasera (MAZO) para revelar
func _on_back_fantasy_card_pressed() -> void:
	print("Mazo pulsado, revelando y desvaneciendo frontal...")
	
	# 1. Bloqueamos clicks para evitar doble pulsación
	_bloquear_todas_las_entradas()
	
	# 2. Desvanecemos la carta CONTRARIA (la frontal que estaba a la vista)
	_desvanecer_carta(front_card)
	
	# 3. La carta trasera se gira sola (gracias al flip_smooth en su script)
	# y nosotros esperamos los 3 segundos para cerrar
	await get_tree().create_timer(TIEMPO_ESPERA_CIERRE).timeout
	_finalizar_overlay()

# Se llama cuando pulsas la carta frontal (la que ya está revelada)
func _on_front_fantasy_card_pressed() -> void:
	print("Carta frontal elegida, desvaneciendo mazo...")
	
	# 1. Bloqueamos clicks para evitar doble pulsación
	_bloquear_todas_las_entradas()
	
	# 2. Desvanecemos la carta CONTRARIA (el mazo oculto)
	_desvanecer_carta(back_card)
	
	# 3. Como ya está revelada, el script de la carta no hará animación de giro,
	# solo esperamos los 3 segundos para cerrar
	await get_tree().create_timer(TIEMPO_ESPERA_CIERRE).timeout
	_finalizar_overlay()

# ==========================================
# FUNCIONES AUXILIARES DE ANIMACIÓN
# ==========================================

func _desvanecer_carta(carta_a_ocultar: Control) -> void:
	var tween = create_tween()
	
	# En lugar de modulate, usamos tween_method para llamar a set_opacity 
	# que es la función que habla directamente con el Shader
	tween.tween_method(
		carta_a_ocultar.set_opacity, # El método a llamar
		1.0,                         # Valor inicial (opaco)
		0.0,                         # Valor final (transparente)
		1.0                          # Duración (1 segundo)
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Al terminar, ocultamos el nodo por completo
	tween.tween_callback(carta_a_ocultar.hide)

func _bloquear_todas_las_entradas() -> void:
	# Es VITAL bloquear ambas cartas para que el jugador no pueda pulsar
	# la carta que se está desvaneciendo durante la espera de 3 segundos.
	back_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	front_card.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _finalizar_overlay() -> void:
	card_action_resolved.emit()
	queue_free()
