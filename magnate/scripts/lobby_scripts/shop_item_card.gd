extends PanelContainer

# Emitimos esta señal cuando el jugador hace clic para comprar
signal purchase_requested(item_id: String, price: int)

# Variables exportadas para configurar desde el Inspector
@export var item_id: int = 0
@export var item_name: String = "Desconocido"
@export var item_price: int = 10 
@export var item_icon: Texture2D

# Variable de estado. El "set(value)" hace que cada vez que cambies esta variable,
# se ejecute automáticamente la función _update_state()
@export var is_purchased: bool = false:
	set(value):
		is_purchased = value
		_update_state()
		
@export var is_affordable: bool = true:
	set(value):
		is_affordable = value
		_update_state()

@onready var item_icon_rect: TextureRect = %ItemIcon
@onready var name_label: Label = %NameLabel
@onready var price_label: Label = %PriceLabel
@onready var action_button: Button = %ActionButton

func _ready() -> void:
	# 1. Aplicamos los datos visuales al cargar la escena
	name_label.text = item_name
	price_label.text = Utils.to_currency_text(item_price)
	if item_icon:
		item_icon_rect.texture = item_icon
		
	# 2. Conectamos el botón
	action_button.pressed.connect(_on_action_button_pressed)
	
	# 3. Forzamos la actualización visual según su estado inicial
	_update_state()

# ==========================================
# LÓGICA DE ESTADOS
# ==========================================
func _update_state() -> void:
	if not is_node_ready():
		return
		
	if is_purchased:
		# ESTADO 1: Comprado
		action_button.text = "ADQUIRIDO"
		action_button.disabled = true 
		price_label.hide() 
		
	elif not is_affordable:
		# ESTADO 2: Sin saldo
		action_button.text = "SIN SALDO"
		action_button.disabled = true # Opcional: no dejarle ni clicar
		price_label.show()
		# Pintamos el texto del precio de rojo
		price_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2)) 
		
	else:
		# ESTADO 3: Disponible para comprar
		action_button.text = "ADQUIRIR"
		action_button.disabled = false
		price_label.show()
		# Quitamos el rojo para que vuelva a su color por defecto
		price_label.add_theme_color_override("font_color", Color("008a5cff"))
		
func _on_action_button_pressed() -> void:
	# Avisamos a la tienda principal de que alguien quiere comprar ESTE item
	purchase_requested.emit(item_id, item_price)
	
# Le pasamos un diccionario que simula lo que vendrá del JSON
func setup_item(data: Dictionary) -> void:
	item_id = data.get("custom_id", "")
	item_name = data.get("name", "Unknown")
	item_price = int(data.get("price", 0))
	is_purchased = data.get("owned", false)
	
	# Leemos la ruta del JSON (si no existe, devolvemos un texto vacío "")
	var icon_path = data.get("icon_path", "")
	
	# Si la ruta no está vacía, cargamos la imagen
	if icon_path != "":
		item_icon = load(icon_path)
		
	# Refrescamos la UI con los nuevos datos
	name_label.text = item_name
	price_label.text = Utils.to_currency_text(item_price)
	if item_icon:
		item_icon_rect.texture = item_icon # Asignamos la textura cargada a la imagen visual
		
	_update_state()
