extends CanvasLayer

# --- NODOS DE UI ---
@onready var dimmer = %Dimmer
@onready var card = %PropertyCard
@onready var server_card = %ServerCard

@onready var countdown_label: Label = %CountdownLabel
@onready var set_price_button: Button = %SetPriceButton
@onready var current_bid_label: Label = %CurentBidLabel
@onready var auction_price_input: LineEdit = %AuctionPriceContainer

# --- NUEVOS BOTONES ---
@onready var add_10_button: Button = %Add10Button
@onready var add_50_button: Button = %Add50Button
@onready var withdraw_button: Button = %WithdrawButton

# --- VARIABLES ---
var time_left: int = 15
var current_bid: int = 91 
var maxmoney: int = 1000 
var color_verde_puja: Color = Color("#008a5c") # Tu color personalizado

signal auction_finished
signal player_withdrawn 

func _ready() -> void:
	# 1. Inicializamos visibilidad de las cartas (Viene del script anterior)
	visible = false
	card.visible = false
	server_card.visible = false

	# 2. Forzamos el color verde inicial para la puja
	current_bid_label.add_theme_color_override("font_color", color_verde_puja)
	current_bid_label.text = Utils.to_currency_text(current_bid)
	update_placeholder()
	
	set_price_button.disabled = true
	
	# 3. Conectamos señales
	auction_price_input.text_changed.connect(_on_text_changed)
	auction_price_input.text_submitted.connect(_on_text_submitted)
	set_price_button.pressed.connect(_on_set_price_button_pressed)
	
	add_10_button.pressed.connect(_on_add_10_pressed)
	add_50_button.pressed.connect(_on_add_50_pressed)
	withdraw_button.pressed.connect(_on_withdraw_pressed)
	
	# Empezamos la subasta (el tablero llamará a abrir_carta al instanciarlo)
	start_auction(15)

# ==========================================
# INICIALIZACIÓN DE LA CARTA (Desde el Tablero)
# ==========================================
func abrir_carta(prop_data: Dictionary) -> void:
	var is_server = prop_data.get("type", "") == "server"
	
	if is_server:
		card.visible = false
		server_card.update_all_data(prop_data)
		aparecer(server_card)
	else:
		server_card.visible = false
		card.update_all_data(prop_data)
		aparecer(card)

func aparecer(tarjeta: Control) -> void:
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

func cerrar_y_destruir() -> void:
	queue_free()

# ==========================================
# LÓGICA DEL TIEMPO
# ==========================================
func start_auction(seconds: int) -> void:
	time_left = seconds
	update_label_text()
	countdown_label.add_theme_color_override("font_color", Color.BLACK)
	_tick()

func _tick() -> void:
	if time_left > 0:
		await get_tree().create_timer(1.0).timeout
		
		# Evita errores si la escena se destruye mientras el timer corría
		if not is_inside_tree(): return 
		
		time_left -= 1
		update_label_text()
		
		# El brillo del tiempo sigue funcionando independientemente de si te rindes
		if time_left <= 5 and time_left > 0:
			flash_warning()
			
		_tick()
	else:
		_on_timeout()

func update_label_text() -> void:
	countdown_label.text = str(time_left)

func flash_warning() -> void:
	countdown_label.add_theme_color_override("font_color", Color.RED)
	var tween = create_tween()
	tween.tween_property(countdown_label, "theme_override_colors/font_color", Color.BLACK, 0.5)

func _on_timeout() -> void:
	print("¡Tiempo agotado!")
	countdown_label.add_theme_color_override("font_color", Color.BLACK)
	desactivar_controles() 
	
	# Esperamos 2 segundos para que se vea la puja final
	await get_tree().create_timer(2.0).timeout
	if is_inside_tree():
		auction_finished.emit() # <--- AVISAMOS AHORA, JUSTO ANTES DE CERRAR
		cerrar_y_destruir()

# ==========================================
# LÓGICA CENTRAL DE PUJAS
# ==========================================
func intentar_pujar(nueva_puja: int) -> void:
	if nueva_puja > current_bid and nueva_puja <= maxmoney:
		current_bid = nueva_puja
		
		# Nos aseguramos de que siga siendo verde al pujar (por si acaso)
		current_bid_label.add_theme_color_override("font_color", color_verde_puja)
		current_bid_label.text = Utils.to_currency_text(current_bid)
		
		auction_price_input.text = ""
		set_price_button.disabled = true 
		
		update_placeholder()
		auction_price_input.grab_focus()
	else:
		print("Puja inválida.")
		auction_price_input.text = ""
		set_price_button.disabled = true

func update_placeholder() -> void:
	var min_bid = current_bid + 1
	auction_price_input.placeholder_text = "Min: " + Utils.to_currency_text(min_bid) + "   Max: " + Utils.to_currency_text(maxmoney)

# ==========================================
# EVENTOS DE LA UI
# ==========================================
func _on_text_changed(new_text: String) -> void:
	set_price_button.disabled = new_text.strip_edges().is_empty()

func _on_set_price_button_pressed() -> void:
	var input_text = auction_price_input.text.strip_edges()
	if input_text.is_valid_int():
		intentar_pujar(input_text.to_int())

func _on_text_submitted(_new_text: String) -> void:
	_on_set_price_button_pressed()

# ==========================================
# BOTONES RÁPIDOS Y RETIRADA
# ==========================================
func _on_add_10_pressed() -> void:
	intentar_pujar(current_bid + 10)

func _on_add_50_pressed() -> void:
	intentar_pujar(current_bid + 50)

func _on_withdraw_pressed() -> void:
	print("Te has retirado de la puja.")
	
	# Cambiamos texto a Fuera y color a rojo
	current_bid_label.text = "Fuera"
	current_bid_label.add_theme_color_override("font_color", Color.RED)
	
	# Solo bloqueamos los botones del jugador, EL TIEMPO SIGUE
	desactivar_controles()
	player_withdrawn.emit()

# Extraída a una función para no repetir código entre _on_timeout y _on_withdraw_pressed
func desactivar_controles() -> void:
	auction_price_input.editable = false 
	set_price_button.disabled = true
	add_10_button.disabled = true
	add_50_button.disabled = true
	withdraw_button.disabled = true
