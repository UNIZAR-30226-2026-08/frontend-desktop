extends BlurryBgOverlay

# Avisamos al tablero que queremos seleccionar. Le pasamos si es el Jugador 1 y los IDs válidos
signal request_board_selection(is_player_1: bool, available_ids: Array)

const PROPERTY_ITEM_SCENE = preload("res://scenes/board/hud/trade_property_item.tscn")

@onready var trade_ui = $TradeUI # El nodo padre que contiene ambos rectángulos
@onready var left_list = %LeftPropertiesList
@onready var right_list = %RightPropertiesList
@onready var add_left_btn = %AddPropertyButton1
@onready var add_right_btn = %AddPropertyButton2
@onready var offer_line_edit = %OfferLineEdit # Donde se escribe el dinero
@onready var request_line_edit = %RequestLineEdit

# Guardamos el estado de las propiedades internamente
# Suponemos que cada prop es un diccionario: {"id": "p1", "name": "Sala", "color": Color.RED}
var _p1_available_props: Array[Dictionary] = []
var _p2_available_props: Array[Dictionary] = []

# ==========================================
# INICIO (Llamado desde el Board)
# ==========================================
func setup_trade(_p1_name: String, _p2_name: String, p1_money: int, p2_money: int, p1_props: Array[Dictionary], p2_props: Array[Dictionary]) -> void:	
	# 1. Textos e inputs (asumiendo que tienes Labels para los nombres)
	# %PlayerName1.text = p1_name 
	offer_line_edit.placeholder_text = "Max. " + str(p1_money)
	request_line_edit.placeholder_text = "Max. " + str(p2_money)
	
	# 2. Copiamos las listas asegurando el tipado correcto de Godot 4
	_p1_available_props.assign(p1_props)
	_p2_available_props.assign(p2_props)
	
	_update_buttons_state()

func _update_buttons_state() -> void:
	add_left_btn.disabled = _p1_available_props.is_empty()
	add_right_btn.disabled = _p2_available_props.is_empty()

# ==========================================
# BOTONES DE AÑADIR (Ir al Tablero)
# ==========================================
func _on_add_left_btn_pressed() -> void:
	self.visible = false # Ocultamos EL CANVASLAYER ENTERO
	var ids = _p1_available_props.map(func(p): return p["id"])
	request_board_selection.emit(true, ids) 

func _on_add_right_btn_pressed() -> void:
	self.visible = false # Ocultamos EL CANVASLAYER ENTERO
	var ids = _p2_available_props.map(func(p): return p["id"])
	request_board_selection.emit(false, ids)

# ==========================================
# RECIBIR SELECCIÓN (Volver del Tablero)
# ==========================================
func property_selected_from_board(is_player_1: bool, prop_id: String) -> void:
	self.visible = true # Volvemos a mostrar el CanvasLayer entero
	
	var pool = _p1_available_props if is_player_1 else _p2_available_props
	var target_list = left_list if is_player_1 else right_list
	
	# Buscamos la propiedad en el pool de disponibles
	var prop_data = null
	for i in range(pool.size()):
		if pool[i]["id"] == prop_id:
			prop_data = pool[i]
			pool.remove_at(i) # La quitamos de disponibles!
			break
			
	if prop_data:
		_add_property_to_ui(target_list, prop_data, is_player_1)
		_update_buttons_state()

# ==========================================
# CREAR UI Y ELIMINAR PROPIEDAD
# ==========================================
func _add_property_to_ui(target_list: VBoxContainer, prop_data: Dictionary, is_player_1: bool) -> void:
	var item = PROPERTY_ITEM_SCENE.instantiate()
	target_list.add_child(item)
	item.setup_item(prop_data["id"], prop_data["name"], prop_data["color"])
	
	# Le pasamos también de qué jugador era para saber a qué lista devolverla
	item.remove_requested.connect(_on_property_removed.bind(item, prop_data, is_player_1))

func _on_property_removed(_prop_id: String, item_node: Node, prop_data: Dictionary, is_player_1: bool) -> void:	
	item_node.queue_free()
	
	# La devolvemos al pool correspondiente
	if is_player_1:
		_p1_available_props.append(prop_data)
	else:
		_p2_available_props.append(prop_data)
		
	_update_buttons_state() # Reactivamos el botón si estaba deshabilitado
