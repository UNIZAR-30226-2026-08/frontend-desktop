extends BlurryBgOverlay

signal administration_confirmed(final_house_index: int, is_mortgaged: bool)

@onready var animated_button: Button = %ConfirmButton
@onready var property_card = %PropertyCard
@onready var mortgage_button: Button = %MortgageProperty

@onready var add_house_button: Button = %AddHouseButton 
@onready var remove_house_button: Button = %RemoveHouseButton

var index: int = 0
var original_index: int = 0
var price_per_house: int = 50
var original_property_price: int = 300

# NUEVAS VARIABLES PARA CONTROLAR LA HIPOTECA LOCALMENTE
var is_mortgaged: bool = false
var original_is_mortgaged: bool = false

var property_id: String
var player_id: int
var model_manager: ModelManager

var max_houses_allowed: int = 5
var min_houses_allowed: int = 0

func setup(initial_data: Dictionary, houses: int, _prop_id: String, _player_id: int, _manager: ModelManager) -> void:
	if initial_data.has("color") and typeof(initial_data["color"]) == TYPE_COLOR:
		initial_data["color"] = "#" + initial_data["color"].to_html()
	
	original_property_price = initial_data.get("price", 300)
	
	property_card.update_all_data(initial_data)
	
	property_id = _prop_id
	player_id = _player_id
	model_manager = _manager
	
	index = houses
	original_index = houses
	price_per_house = initial_data.get("house_price", 50)
	
	# LEEMOS EL ESTADO DE LA HIPOTECA DEL MODELO
	if model_manager:
		var prop = model_manager.get_property(property_id)
		if prop:
			is_mortgaged = prop.is_mortgaged
			original_is_mortgaged = prop.is_mortgaged
	
	# CALCULAMOS LOS LÍMITES UNA ÚNICA VEZ
	var max_add = model_manager.get_max_addable_houses(property_id, player_id)
	var max_rem = model_manager.get_max_removable_houses(property_id)
	
	max_houses_allowed = original_index + max_add
	min_houses_allowed = original_index - max_rem
	
	_update_rent_highlight()
	_update_ui()

func _ready() -> void:
	super()

func _update_ui() -> void:
	if model_manager:
		var prop = model_manager.get_property(property_id)
		var owns_all = model_manager.owns_full_group(prop.group_id, player_id)
		
		var base_can_mortgage = model_manager.can_mortgage(property_id, player_id)
		# Solo permitimos tocar la hipoteca si no estamos construyendo/destruyendo casas
		mortgage_button.visible = base_can_mortgage and (index == 0) and (original_index == 0)
		
		# Si está hipotecada o va a estarlo, ocultamos los botones de casas
		if not owns_all or is_mortgaged:
			add_house_button.visible = false
			remove_house_button.visible = false
		else:
			var can_add_more = index < max_houses_allowed
			add_house_button.visible = (can_add_more and index >= original_index) or (index < original_index)
			
			var can_remove_more = index > min_houses_allowed
			remove_house_button.visible = (can_remove_more and index <= original_index) or (index > original_index)

	# 2. Toda la información de coste va al Animated Button
	if is_mortgaged != original_is_mortgaged:
		if is_mortgaged:
			@warning_ignore("integer_division")
			animated_button.text = "Hipotecar (+ " + Utils.to_currency_text(original_property_price / 2) + ")"
		else:
			animated_button.text = "Deshipotecar (- " + Utils.to_currency_text(original_property_price) + ")"
	elif index < original_index:
		@warning_ignore("integer_division")
		var profit = (price_per_house * (original_index - index)) / 2
		animated_button.text = "Vender casas (+ " + Utils.to_currency_text(profit) + ")"
	elif index > original_index:
		var cost = price_per_house * (index - original_index)
		animated_button.text = "Comprar casas (- " + Utils.to_currency_text(cost) + ")"
	else:
		animated_button.text = "Cerrar"

func _update_rent_highlight() -> void:
	if index != 0:
		property_card.highlight_rent(index)
	else:
		property_card.highlight_rent(property_card.highlighters.size())

func _on_remove_house_button_pressed() -> void:
	index = clamp(index - 1, 0, property_card.highlighters.size() - 1)
	_update_rent_highlight()
	_update_ui()

func _on_add_house_button_pressed() -> void:
	index = clamp(index + 1, 0, property_card.highlighters.size() - 1)
	_update_rent_highlight()
	_update_ui()

func _on_mortgage_property_pressed() -> void:
	# Solo simulamos el cambio (Toggle)
	is_mortgaged = !is_mortgaged
	_update_ui()

func _on_confirm_button_pressed() -> void:
	var has_changes = (index != original_index) or (is_mortgaged != original_is_mortgaged)
	
	if has_changes and model_manager:
		var net_money: int = 0
		
		# Cálculos finales para balance
		if index < original_index:
			@warning_ignore("integer_division")
			net_money += (price_per_house * (original_index - index)) / 2
		elif index > original_index:
			net_money -= (price_per_house * (index - original_index))
			
		if original_is_mortgaged == false and is_mortgaged == true:
			@warning_ignore("integer_division")
			net_money += original_property_price / 2
		elif original_is_mortgaged == true and is_mortgaged == false:
			net_money -= original_property_price
			
		# Aplicamos el dinero neto
		if net_money != 0:
			model_manager.add_player_balance(player_id, net_money)
			
		# Aplicamos las casas
		if index != original_index:
			model_manager.set_property_houses(property_id, index)
			
		# Aplicamos la hipoteca
		if is_mortgaged != original_is_mortgaged:
			model_manager.set_property_mortgaged(property_id, is_mortgaged)

	# Emitimos los DOS valores actualizados y cerramos
	administration_confirmed.emit(index, is_mortgaged) 
	queue_free()
