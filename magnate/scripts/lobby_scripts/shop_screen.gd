extends Control

const ITEM_CARD_SCENE = preload("res://scenes/components/shop_item_card.tscn") # ¡Cambia esta ruta!

@onready var budget_label: Label = %BudgetLabel
@onready var lose_money_label: Label = %LoseMoneyLabel

@onready var tokens_container: HBoxContainer = %TokensContainer
@onready var emotes_container: HBoxContainer = %EmotesContainer

@onready var tokens_scroll: Control = %TokensScroll
@onready var emotes_scroll: Control = %EmotesScroll

@onready var tokens_left_btn: Button = %TokensLeftBtn
@onready var tokens_right_btn: Button = %TokensRightBtn
@onready var emotes_left_btn: Button = %EmotesLeftBtn
@onready var emotes_right_btn: Button = %EmotesRightBtn
@onready var token_carrusel: HBoxContainer = %TokenCarrusel
@onready var emoji_carrusel: HBoxContainer = %EmojiCarrusel
@onready var token_tab_container: TabContainer = %TokenTabContainer
@onready var emoji_tab_container: TabContainer = %EmojiTabContainer

const VISIBLE_CARDS = 4
const CARD_WIDTH = 355 
const SPACING = 25
const SCROLL_STEP = CARD_WIDTH + SPACING

var player_money: int = -1

var items: Array = []

func _ready() -> void:
	# Conectamos pasándole el contenedor DIRECTO (ya no le pasamos el "Scroll")
	# direction: 1 es derecha, -1 es izquierda
	tokens_left_btn.pressed.connect(_scroll_custom_carousel.bind(tokens_container, -1))
	tokens_right_btn.pressed.connect(_scroll_custom_carousel.bind(tokens_container, 1))
	
	emotes_left_btn.pressed.connect(_scroll_custom_carousel.bind(emotes_container, -1))
	emotes_right_btn.pressed.connect(_scroll_custom_carousel.bind(emotes_container, 1))
	
	var user_info = await RestClient.user_get_info()
	if user_info != {}:
		player_money = user_info["points"]
	
	items = await RestClient.shop_get_items()
	# [{ "custom_id": 1.0, "itemType": "piece", "price": 100.0, "owned": true }]
	for item in items:
		var map
		if item["itemType"] == "piece":
			map = Globals.tokens
		else:
			map = Globals.emojis
		if map.has(item["custom_id"]):
			item["name"] = map[item["custom_id"]]["name"]
			item["icon_path"] = map[item["custom_id"]]["icon"]
		else:
			item["name"] = "Desconocido"
			item["icon_path"] = map[1]["icon"]
	
	_populate_shop(items)
	_update_budget_ui()
	_update_cards_affordability()

func _populate_shop(items_data: Array) -> void:
	token_tab_container.current_tab = 1
	emoji_tab_container.current_tab = 1
	var num_pieces = 0
	var num_emoji = 0
	for item_data in items_data:
		var card = ITEM_CARD_SCENE.instantiate()
		
		# Asignamos al carril correcto según la categoría
		if item_data["itemType"] == "piece":
			tokens_container.add_child(card)
			token_tab_container.current_tab = 2
			num_pieces += 1
			if num_pieces == VISIBLE_CARDS + 1:
				tokens_left_btn.modulate.a = 1
				tokens_right_btn.modulate.a = 1
		elif item_data["itemType"] == "emoji":
			emotes_container.add_child(card)
			emoji_tab_container.current_tab = 2
			num_emoji += 1
			if num_emoji == VISIBLE_CARDS + 1:
				emotes_left_btn.modulate.a = 1
				emotes_right_btn.modulate.a = 1
			
		# Le inyectamos los datos y conectamos su señal de compra
		card.setup_item(item_data)
		card.purchase_requested.connect(_on_item_purchase_requested)

func _on_item_purchase_requested(item_id: int, price: int) -> void:
	Utils.debug("El jugador quiere comprar: " + str(item_id) + " por " + Utils.to_currency_text(price))
	# Aquí meterás tu lógica: comprobar si el jugador tiene dinero suficiente,
	# avisar al backend, restar el dinero, y si todo sale bien, buscar
	# la tarjeta en el contenedor y ponerle su `is_purchased = true`
	buy_item(item_id, price)
	
func buy_item(item_id: int, price: int) -> void:
	Utils.debug("Intentando comprar: " + str(item_id) + " por " + Utils.to_currency_text(price))
	
	# 1. Comprobar si hay dinero suficiente
	if player_money >= price:
		var resp = await RestClient.shop_buy_item(item_id)
		if resp == {}: return
		player_money -= price
		Utils.debug("¡Compra exitosa! Nuevo saldo: " + Utils.to_currency_text(player_money))
		
		_update_card_to_purchased(item_id)
		lose_money_label.position = budget_label.position
		lose_money_label.rotation = 0
		lose_money_label.modulate.a = 1
		lose_money_label.text = "-" + Utils.to_currency_text(price)
		var tween = get_tree().create_tween().set_parallel(true)
		tween.tween_property(lose_money_label, "position:y", lose_money_label.position.y + 100, 1)
		tween.tween_property(lose_money_label, "modulate:a", 0, 1)
		tween.tween_property(lose_money_label, "rotation_degrees", 35, 1)
		_update_budget_ui()
		_update_cards_affordability()
	else:
		Utils.debug("No tienes suficiente dinero para comprar esto.")
		# Aquí en el futuro podrías mostrar un popup de error o hacer vibrar el dinero

# Función auxiliar que busca la tarjeta correcta y cambia su estado
func _update_card_to_purchased(target_id: int) -> void:
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

func _on_header_back_action_requested() -> void:
	SceneTransition.change_scene("res://scenes/UI/home_screen.tscn")

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
	
	var right_btn
	var left_btn
	if container == token_carrusel:
		right_btn = tokens_right_btn
		left_btn = tokens_left_btn
	else:
		right_btn = emotes_right_btn
		left_btn = emotes_left_btn
	if target_x == max_scroll_left:
		right_btn.modulate.a = 0
	elif target_x == 0:
		left_btn.modulate.a = 0
	if direction == 1:
		left_btn.modulate.a = 1
	else:
		right_btn.modulate.a = 1
	
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
