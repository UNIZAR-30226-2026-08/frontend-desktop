extends BlurryBgOverlay

# Avisamos al tablero que queremos seleccionar. Le pasamos si es el Jugador 1 y los IDs válidos
signal request_board_selection(is_player_1: bool, available_ids: Array)

signal trade_cancelled
signal offer_sent(p1_props: Array[String], p2_props: Array[String], p1_money: int, p2_money: int)

const PROPERTY_ITEM_SCENE = preload("res://scenes/board/players/trade_property_item.tscn")

@onready var trade_ui = $TradeUI # El nodo padre que contiene ambos rectángulos
@onready var left_list = %LeftPropertiesList
@onready var right_list = %RightPropertiesList
@onready var add_left_btn = %AddPropertyButton1
@onready var add_right_btn = %AddPropertyButton2
@onready var offer_line_edit = %OfferLineEdit
@onready var request_line_edit = %RequestLineEdit
@onready var cancel_btn = %CancelTradeButton
@onready var send_btn = %SendOfferButton
@onready var player_name_2: Label = %PlayerName2
@onready var player_name_1: Label = %PlayerName1
@onready var player_color_2: Panel = %PlayerColor2
@onready var player_color_1: Panel = %PlayerColor1

# Guardamos el estado de las propiedades internamente
var _p1_available_props: Array[PropertyModel] = []
var _p2_available_props: Array[PropertyModel] = []
var _p1_selected_props: Array[String] = []
var _p2_selected_props: Array[String] = []

var regex = RegEx.new()
var old_text = ""

func _ready() -> void:
	super()
	
	cancel_btn.pressed.connect(trade_cancelled.emit)
	send_btn.pressed.connect(func():
		offer_sent.emit(_p1_selected_props, _p2_selected_props, int("0" + offer_line_edit.text), int("0" + request_line_edit.text))
	)

func setup_trade(p1: PlayerModel, p2: PlayerModel) -> void:	
	regex.compile("^[0-9]*$")
	offer_line_edit.text_changed.connect(_on_text_changed.bind(offer_line_edit))
	request_line_edit.text_changed.connect(_on_text_changed.bind(request_line_edit))
	# 1. Textos e inputs (asumiendo que tienes Labels para los nombres)
	player_name_1.text = "TÚ"
	player_name_2.text = p2.player_name
	offer_line_edit.placeholder_text = "Max. " + str(p1.balance)
	request_line_edit.placeholder_text = "Max. " + str(p2.balance)
	
	# 2. Copiamos las listas asegurando el tipado correcto de Godot 4
	_p1_available_props.assign(ModelManager.get_player_properties(p1.id))
	_p2_available_props.assign(ModelManager.get_player_properties(p2.id))
	
	player_color_1.modulate = p1.color
	player_color_2.modulate = p2.color
	
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
func _add_property_to_ui(target_list: VBoxContainer, prop_data: PropertyModel, is_player_1: bool) -> void:
	var item = PROPERTY_ITEM_SCENE.instantiate()
	target_list.add_child(item)
	item.setup_item(prop_data.id, prop_data.name, prop_data.color)
	if is_player_1:
		_p1_selected_props.append(prop_data.id)
	else:
		_p2_selected_props.append(prop_data.id)
	item.remove_requested.connect(_on_property_removed.bind(item, prop_data, is_player_1))

func _on_property_removed(_prop_id: String, item_node: Node, prop_data: PropertyModel, is_player_1: bool) -> void:	
	item_node.queue_free()
	
	# La devolvemos al pool correspondiente
	if is_player_1:
		_p1_selected_props.erase(_prop_id)
		_p1_available_props.append(prop_data)
	else:
		_p2_selected_props.erase(_prop_id)
		_p2_available_props.append(prop_data)
	_update_buttons_state()

func _on_text_changed(new_text: String, node: LineEdit):
	if regex.search(new_text):
		old_text = new_text
	else:
		node.text = old_text
		node.caret_column = node.text.length()
