extends BlurryBgOverlay

signal administration_confirmed(final_house_index: int, is_mortgaged: bool)

@onready var animated_button: Button = %ConfirmButton

@onready var bridge_card: Control = %BridgeCard
@onready var server_card: Control = %ServerCard
@onready var property_card: Control = %PropertyCard
var card: Control = null

@onready var mortgage_button: Button = %MortgageProperty
@onready var add_house_button: Button = %AddHouseButton 
@onready var remove_house_button: Button = %RemoveHouseButton

var property: PropertyModel

# Internal state
var index: int = 0
var is_mortgaged: bool = false

var max_houses_allowed: int = 5
var min_houses_allowed: int = 0

func setup(_property: PropertyModel) -> void:
	property = _property
	if property.is_bridge: card = bridge_card
	elif property.is_server: card = server_card
	else: card = property_card
	card.show()
	card.update_all_data(property)
	
	index = property.house_count
	is_mortgaged = property.is_mortgaged
	
	var max_add = ModelManager.get_max_addable_houses(property.id)
	var max_rem = ModelManager.get_max_removable_houses(property.id)
	
	max_houses_allowed = property.house_count + max_add
	min_houses_allowed = property.house_count - max_rem
	
	_update_rent_highlight()
	_update_ui()

func _calculate_pay() -> int:
	var house_price_diff = 0
	if property.house_count > index:
		@warning_ignore('integer_division')
		house_price_diff = (property.build_price * (property.house_count - index)) / 2
	elif property.house_count < index:
		@warning_ignore('integer_division')
		house_price_diff = (property.build_price * (property.house_count - index))
	var mortgage_price_diff = 0
	if property.is_mortgaged and not is_mortgaged:
		@warning_ignore('integer_division')
		mortgage_price_diff = -property.buy_price / 2
	if not property.is_mortgaged and is_mortgaged:
		@warning_ignore('integer_division')
		mortgage_price_diff = property.buy_price / 2
	return house_price_diff + mortgage_price_diff

func _ready() -> void:
	super()

func _update_ui() -> void:
	var owns_all = ModelManager.owns_full_group(property.group_id, property.owner_id)
	var base_can_mortgage = ModelManager.can_mortgage(property.id, property.owner_id)
	mortgage_button.disabled = not base_can_mortgage or (index != 0) or (property.house_count != 0)
	var pay = _calculate_pay()
	var player_balance = ModelManager.get_player_balance(ModelManager.game.my_id)
	# Build buttons activation
	if not owns_all or is_mortgaged or property.is_bridge or property.is_server:
		add_house_button.disabled = true
		remove_house_button.disabled = true
	else:
		add_house_button.disabled = index == max_houses_allowed or pay + property.build_price > player_balance or is_mortgaged
		remove_house_button.disabled = index == min_houses_allowed or is_mortgaged
	mortgage_button.disabled = index != 0 or not is_mortgaged

	# Button text
	if pay < 0:
		animated_button.set_btn_text("PAGAR " + Utils.to_currency_text(pay))
	elif pay > 0:
		animated_button.set_btn_text("RECIBIR " + Utils.to_currency_text(pay))
	else:
		animated_button.set_btn_text("CERRAR")

func _update_rent_highlight() -> void:
	if index != 0: property_card.highlight_rent(index)
	else: property_card.highlight_rent(property_card.highlighters.size())

func _on_remove_house_button_pressed() -> void:
	index = clamp(index - 1, min_houses_allowed, property_card.highlighters.size() - 1)
	_update_rent_highlight()
	_update_ui()

func _on_add_house_button_pressed() -> void:
	index = clamp(index + 1, 0, max_houses_allowed)
	_update_rent_highlight()
	_update_ui()

func _on_mortgage_property_pressed() -> void:
	is_mortgaged = !is_mortgaged
	_update_ui()

func _on_confirm_button_pressed() -> void:
	if index != property.house_count or property.is_mortgaged != is_mortgaged:
		administration_confirmed.emit(index, is_mortgaged) 
	queue_free()
