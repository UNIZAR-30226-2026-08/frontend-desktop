extends BlurryBgOverlay

# Emite estas señales para que el sistema principal sepa qué ha decidido el jugador
signal offer_accepted
signal offer_rejected

# === REFERENCIA AL COMPONENTE DE PROPIEDAD ===
# ¡Asegúrate de poner la ruta correcta a tu escena de la fila de propiedad!
const PROPERTY_ITEM_SCENE = preload("res://scenes/board/players/offer_property_item.tscn")

# === REFERENCIAS: COLUMNA IZQUIERDA (TÚ) ===
@onready var player_color_1 = %PlayerColor1
@onready var player_name_1: Label = %PlayerName1
@onready var money_1: Label = %Money1
@onready var left_properties_list: VBoxContainer = %LeftPropertiesList
@onready var cancel_trade_butt: Button = %CancelTradeButton

# === REFERENCIAS: COLUMNA DERECHA (PLAYER 1) ===
# (He inferido estos nombres. Revísalos con tu escena real)
@onready var player_color_2 = %PlayerColor2 
@onready var player_name_2: Label = %PlayerName2
@onready var money_2: Label = %Money2
@onready var right_properties_list: VBoxContainer = %RightPropertiesList
@onready var accept_trade_butt: Button = %AcceptTradeButton

func _ready() -> void:
	# Conectamos los botones a sus funciones
	cancel_trade_butt.pressed.connect(_on_cancel_pressed)
	accept_trade_butt.pressed.connect(_on_accept_pressed)

# ==========================================
# LÓGICA DE POBLACIÓN DE DATOS
# ==========================================

# Llama a esta función desde fuera pasándole los datos de la oferta.
# Puedes ver un ejemplo de la estructura esperada al final del script.
func setup_offer(left_player_data: Dictionary, right_player_data: Dictionary) -> void:
	_clear_lists()
	
	# 1. Rellenar datos del jugador izquierdo (Lo que entregas)
	_setup_player_column(
		left_player_data, 
		player_name_1, 
		player_color_1, 
		money_1, 
		left_properties_list
	)
	
	# 2. Rellenar datos del jugador derecho (Lo que recibes)
	_setup_player_column(
		right_player_data, 
		player_name_2, 
		player_color_2, 
		money_2, 
		right_properties_list
	)

# Función auxiliar para no repetir código en ambas columnas
func _setup_player_column(data: Dictionary, name_lbl: Label, color_rect, money_lbl: Label, list_container: VBoxContainer) -> void:
	# Nombres, colores y dinero
	name_lbl.text = data.get("name", "Unknown")
	money_lbl.text = str(data.get("money_offered", 0))
	
	# Dependiendo de si tu nodo de color es un ColorRect o un Panel con un StyleBox
	if color_rect is ColorRect:
		color_rect.color = data.get("color", Color.WHITE)
	elif color_rect is Panel or color_rect is PanelContainer:
		var style = color_rect.get_theme_stylebox("panel").duplicate()
		style.bg_color = data.get("color", Color.WHITE)
		color_rect.add_theme_stylebox_override("panel", style)

	# Instanciar propiedades
	var properties = data.get("properties", [])
	for prop_data in properties:
		var item_instance = PROPERTY_ITEM_SCENE.instantiate()
		list_container.add_child(item_instance)
		
		# ¡OJO AQUÍ! Comprueba que ponga "setup_item" en los dos sitios
		if item_instance.has_method("setup_item"):
			item_instance.setup_item(
				prop_data.get("id", "000"), 
				prop_data.get("name", "Unknown"), 
				prop_data.get("color", Color.WHITE)
			)
		else:
			# Añade este print temporal para detectar el error
			print("❌ ERROR: El item no tiene la función setup_item()")

# Limpia las listas antes de cargar una nueva oferta
func _clear_lists() -> void:
	for child in left_properties_list.get_children():
		child.queue_free()
	for child in right_properties_list.get_children():
		child.queue_free()

# ==========================================
# SEÑALES DE LOS BOTONES
# ==========================================

func _on_accept_pressed() -> void:
	print("Trato aceptado")
	offer_accepted.emit()
	hide() # O queue_free(), según cómo gestiones la UI

func _on_cancel_pressed() -> void:
	print("Trato rechazado")
	offer_rejected.emit()
	hide() # O queue_free()
