extends CanvasLayer

@onready var dimmer = %Dimmer
@onready var card = %PropertyCard
@onready var server_card = %ServerCard

@onready var countdown_label: Label = %CountdownLabel
@onready var set_price_button: Button = %SetPriceButton

# Variable para controlar si es la primera puja
var first_bid_made: bool = false

@onready var current_bid_label: Label = %CurentBidLabel
@onready var current_bid_container: Control = %CurrentBidContainer
@onready var auction_price_input: LineEdit = %AuctionPriceContainer # Asumiendo que es un LineEdit o similar

var time_left: int = 10
var countdown_timer: SceneTreeTimer

# Señal para avisar cuando la subasta termine
signal auction_finished

func _ready() -> void:
	start_auction(10) # Ejemplo de inicio

func start_auction(seconds: int) -> void:
	time_left = seconds
	update_label_text()
	_tick()

func _tick() -> void:
	if time_left > 0:
		# Espera 1 segundo usando el SceneTree
		await get_tree().create_timer(1.0).timeout
		
		time_left -= 1
		update_label_text()
		
		# Efecto visual simple cuando queda poco tiempo (rojo)
		if time_left <= 3:
			countdown_label.modulate = Color.RED
			
		_tick() # Llamada recursiva para el siguiente segundo
	else:
		_on_timeout()

func update_label_text() -> void:
	countdown_label.text = str(time_left)

func _on_timeout() -> void:
	print("¡Tiempo agotado!")
	set_price_button.disabled = true # Desactivar botón al terminar
	auction_finished.emit()
	# Aquí podrías cerrar la ventana o ejecutar la lógica de quién ganó

func _on_set_price_button_pressed() -> void:
	# 1. Obtener el valor. Si está vacío, usamos "0" por defecto.
	var new_price = auction_price_input.text
	
	if new_price == "":
		new_price = "0"
	
	# 2. Actualizar el label con el valor (ya sea el escrito o el 0)
	current_bid_label.text = "Puja actual: " + new_price + "€"
	
	# 3. Lógica de animación con Tween (solo la primera vez)
	if not first_bid_made:
		animate_container_entry()
		first_bid_made = true

func animate_container_entry() -> void:
	var tween = create_tween()
	# Calculamos la posición final (200 píxeles hacia abajo)
	var target_position = current_bid_container.position + Vector2(0, 150)
	
	tween.tween_property(
		current_bid_container, 
		"position", 
		target_position, 
		0.5
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_text_submitted(new_text: String) -> void:
	_on_set_price_button_pressed()
