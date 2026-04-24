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

func _ready() -> void:
	super()

func _update_ui() -> void:
	var owns_all = ModelManager.owns_full_group(property.group_id, property.owner_id)
	var base_can_mortgage = ModelManager.can_mortgage(property.id, property.owner_id)
	mortgage_button.visible = base_can_mortgage and (index == 0) and (property.house_count == 0)
	
	# Build buttons activation
	if not owns_all or is_mortgaged or property.is_bridge or property.is_server:
		add_house_button.disabled = true
		remove_house_button.disabled = true
	else:
		add_house_button.disabled = index == max_houses_allowed
		remove_house_button.disabled = index == min_houses_allowed

	# Button text
	if is_mortgaged and not property.is_mortgaged:
		@warning_ignore("integer_division")
		animated_button.text = "HIPOTECAR (" + Utils.to_currency_text(property.buy_price / 2) + ")"
	elif not is_mortgaged and property.is_mortgaged:
		@warning_ignore("integer_division")
		animated_button.text = "PAGAR HIPOTECA (" + Utils.to_currency_text(-property.buy_price / 2) + ")"
	elif index < property.house_count:
		@warning_ignore("integer_division")
		var profit = (property.build_price * (property.house_count - index)) / 2
		animated_button.text = "VENDER CASAS (" + Utils.to_currency_text(profit) + ")"
	elif index > property.house_count:
		var cost = property.build_price * (index - property.house_count)
		animated_button.text = "COPRAR CASAS (" + Utils.to_currency_text(-cost) + ")"
	else:
		animated_button.text = "CERRAR"

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
