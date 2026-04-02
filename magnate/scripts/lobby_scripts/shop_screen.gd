extends Control

const ITEM_CARD_SCENE = preload("res://scenes/components/shop_item_card.tscn") # ¡Cambia esta ruta!

@onready var budget_label: Label = %BudgetLabel

@onready var tokens_container: HBoxContainer = %TokensContainer
@onready var emotes_container: HBoxContainer = %EmotesContainer

@onready var tokens_scroll: Control = %TokensScroll
@onready var emotes_scroll: Control = %EmotesScroll

@onready var tokens_left_btn: Button = %TokensLeftBtn
@onready var tokens_right_btn: Button = %TokensRightBtn
@onready var emotes_left_btn: Button = %EmotesLeftBtn
@onready var emotes_right_btn: Button = %EmotesRightBtn

const VISIBLE_CARDS = 4
const CARD_WIDTH = 355 
const SPACING = 25
const SCROLL_STEP = CARD_WIDTH + SPACING # Esto da 280 exactos por saltoflecha

var player_money: int = 500 # Ponle el dinero que quieras para hacer pruebas

func _ready() -> void:
	# Conectamos pasándole el contenedor DIRECTO (ya no le pasamos el "Scroll")
	# direction: 1 es derecha, -1 es izquierda
	tokens_left_btn.pressed.connect(_scroll_custom_carousel.bind(tokens_container, -1))
	tokens_right_btn.pressed.connect(_scroll_custom_carousel.bind(tokens_container, 1))
	
	emotes_left_btn.pressed.connect(_scroll_custom_carousel.bind(emotes_container, -1))
	emotes_right_btn.pressed.connect(_scroll_custom_carousel.bind(emotes_container, 1))
	
	_load_shop_items()
	
	# Actualizamos el texto con el dinero inicial
	_update_budget_ui()
	_update_cards_affordability()
# Simula la llegada del JSON desde el backend
func _load_shop_items() -> void:
	var dummy_backend_json = [
		# --- SECCIÓN TOKENS ---
		{"id": "tkn_1", "name": "TOKEN 1", "price": 0, "is_purchased": true, "category": "token", "icon_path": "res://assets/icons/characters/sombrero_closeup.png"},
		{"id": "tkn_2", "name": "TOKEN 2", "price": 10, "is_purchased": false, "category": "token", "icon_path": "res://assets/icons/characters/sombrero_closeup.png"},
		{"id": "tkn_3", "name": "TOKEN 3", "price": 50, "is_purchased": false, "category": "token", "icon_path": "res://assets/icons/characters/sombrero_closeup.png"},
		{"id": "tkn_4", "name": "TOKEN 4", "price": 100, "is_purchased": false, "category": "token", "icon_path": "res://assets/icons/characters/sombrero_closeup.png"},
		{"id": "tkn_5", "name": "TOKEN 5", "price": 150, "is_purchased": false, "category": "token", "icon_path": "res://assets/icons/characters/sombrero_closeup.png"},
		{"id": "tkn_6", "name": "TOKEN 6", "price": 200, "is_purchased": false, "category": "token", "icon_path": "res://assets/icons/characters/sombrero_closeup.png"},
		{"id": "tkn_7", "name": "TOKEN 7", "price": 250, "is_purchased": false, "category": "token", "icon_path": "res://assets/icons/characters/sombrero_closeup.png"},
		{"id": "tkn_8", "name": "TOKEN 8", "price": 300, "is_purchased": false, "category": "token", "icon_path": "res://assets/icons/characters/sombrero_closeup.png"},

		# --- SECCIÓN EMOTICONOS ---
		{"id": "emo_1", "name": "RISA 1", "price": 0, "is_purchased": true, "category": "emote", "icon_path": "res://assets/icons/characters/sombrero_closeup.png"},
		{"id": "emo_2", "name": "RISA 2", "price": 50, "is_purchased": false, "category": "emote", "icon_path": "res://assets/icons/characters/sombrero_closeup.png"},
		{"id": "emo_3", "name": "RISA 3", "price": 100, "is_purchased": false, "category": "emote", "icon_path": "res://assets/icons/characters/sombrero_closeup.png"},
		{"id": "emo_4", "name": "RISA 4", "price": 150, "is_purchased": false, "category": "emote", "icon_path": "res://assets/icons/characters/sombrero_closeup.png"},
		{"id": "emo_5", "name": "RISA 5", "price": 200, "is_purchased": false, "category": "emote", "icon_path": "res://assets/icons/characters/sombrero_closeup.png"},
		{"id": "emo_6", "name": "RISA 6", "price": 250, "is_purchased": false, "category": "emote", "icon_path": "res://assets/icons/characters/sombrero_closeup.png"},
		{"id": "emo_7", "name": "RISA 7", "price": 300, "is_purchased": false, "category": "emote", "icon_path": "res://assets/icons/characters/sombrero_closeup.png"},
		{"id": "emo_8", "name": "RISA 8", "price": 350, "is_purchased": false, "category": "emote", "icon_path": "res://assets/icons/characters/sombrero_closeup.png"}
	]
	
	_populate_shop(dummy_backend_json)

func _populate_shop(items_data: Array) -> void:
	for item_data in items_data:
		var card = ITEM_CARD_SCENE.instantiate()
		
		# Asignamos al carril correcto según la categoría
		if item_data["category"] == "token":
			tokens_container.add_child(card)
		elif item_data["category"] == "emote":
			emotes_container.add_child(card)
			
		# Le inyectamos los datos y conectamos su señal de compra
		card.setup_item(item_data)
		card.purchase_requested.connect(_on_item_purchase_requested)

func _on_item_purchase_requested(item_id: String, price: int) -> void:
	Utils.debug("El jugador quiere comprar: " + item_id + " por " + Utils.to_currency_text(price))
	# Aquí meterás tu lógica: comprobar si el jugador tiene dinero suficiente,
	# avisar al backend, restar el dinero, y si todo sale bien, buscar
	# la tarjeta en el contenedor y ponerle su `is_purchased = true`
	buy_item(item_id, price)
	
func buy_item(item_id: String, price: int) -> void:
	Utils.debug("Intentando comprar: " + item_id + " por " + Utils.to_currency_text(price))
	
	# 1. Comprobar si hay dinero suficiente
	if player_money >= price:
		player_money -= price
		Utils.debug("¡Compra exitosa! Nuevo saldo: " + Utils.to_currency_text(player_money))
		
		# 2. Actualizar la tarjeta visualmente a "Adquirido"
		_update_card_to_purchased(item_id)
		
		# 3. Aquí en el futuro enviarás la petición a tu Backend:
		# MiBackend.send_purchase_request(item_id)
		
		_update_budget_ui()
		_update_cards_affordability()
	else:
		Utils.debug("No tienes suficiente dinero para comprar esto.")
		# Aquí en el futuro podrías mostrar un popup de error o hacer vibrar el dinero

# Función auxiliar que busca la tarjeta correcta y cambia su estado
func _update_card_to_purchased(target_id: String) -> void:
	# Buscamos primero en el carril de Tokens
	for card in tokens_container.get_children():
		if card.item_id == target_id:
			card.is_purchased = true # Esto dispara automáticamente el cambio visual del botón
			return # Salimos porque ya lo hemos encontrado
			
	# Si no estaba en Tokens, buscamos en el carril de Emotes
	for card in emotes_container.get_children():
		if card.item_id == target_id:
			card.is_purchased = true
			return

# (Tu función de salir del header que ya tenías)
func _on_header_back_action_requested() -> void:
	SceneTransition.change_scene("res://scenes/UI/home_screen.tscn")
	
# La nueva magia:
func _scroll_custom_carousel(container: HBoxContainer, direction: int) -> void:
	var total_items = container.get_child_count()
	
	# Si tenemos 4 items o menos, no hay nada que scrollear, abortamos
	if total_items <= VISIBLE_CARDS:
		return 
		
	# Calculamos cuánto es lo máximo que nos podemos desplazar hacia la izquierda (en negativo)
	# Si hay 8 items, sobran 4. 4 * 280px = 1120px de máximo desplazamiento.
	var max_scroll_left = -((total_items - VISIBLE_CARDS) * SCROLL_STEP)
	
	# Calculamos la nueva posición objetivo
	var target_x = container.position.x - (SCROLL_STEP * direction)
	
	# El clamp evita que vayamos más allá del máximo o que volvamos más allá del 0 (el inicio)
	target_x = clamp(target_x, max_scroll_left, 0.0)
	
	# Animamos la posición X del contenedor
	var tween = create_tween()
	tween.tween_property(container, "position:x", target_x, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _update_budget_ui() -> void:
	budget_label.text = "Saldo: " + Utils.to_currency_text(player_money)

# Esta función recorre todas las tarjetas y les dice si se pueden pagar o no
func _update_cards_affordability() -> void:
	# Juntamos todas las tarjetas de ambos contenedores en una sola lista
	var all_cards = tokens_container.get_children() + emotes_container.get_children()
	
	for card in all_cards:
		# Si la tarjeta no está comprada todavía...
		if not card.is_purchased:
			# Le decimos que es "asequible" solo si nuestro saldo es mayor o igual a su precio
			card.is_affordable = (player_money >= card.item_price)
