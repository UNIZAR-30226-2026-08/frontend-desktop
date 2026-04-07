extends BlurryBgOverlay

@onready var animated_button: Button = %AnimatedButton
@onready var property_card: Control = %PropertyCard

var index: int = 0
var original_index: int = 0
var price_per_house: int = 50

## <initial_data> must contain the following data:
## - "name": name of the property (String)
## - "color": color of the property (Color/String)
## - "basic_rent": rent without buildings (int)
## - "rent_<i>": rent for <i> houses (int)
## - "rent_hotel": rent with hotel (int)
## - "house_price": Price for a house (int)
## - "mortgage_price": Price received when mortgaged
## <houses>: number of houses in this property (5 if hotel)
func setup(initial_data: Dictionary, houses: int) -> void:
	if initial_data.has("color") and \
		typeof(initial_data["color"]) == TYPE_COLOR:
		initial_data["color"] = "#" + initial_data["color"].to_html()
	property_card.update_all_data(initial_data)
	index = houses
	if index != 0:
		property_card.highlight_rent(index)
	property_card.highlight_rent(houses)
	original_index = index
	price_per_house = initial_data.get("house_price", 50)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()

func _update_button() -> void:
	if index < original_index:
		var price = price_per_house * (original_index - index) / 2 # ignore warning
		animated_button.text = "Recibir " + Utils.to_currency_text(price)
	elif index > original_index:
		var price = price_per_house * (index - original_index)
		animated_button.text = "Pagar " + Utils.to_currency_text(price)
	else:
		animated_button.text = "Confirmar"

func _on_remove_house_button_pressed() -> void:
	index = clamp(index - 1, 0, property_card.highlighters.size() - 1)
	if index != 0:
		property_card.highlight_rent(index)
	else:
		property_card.highlight_rent(property_card.highlighters.size())
	_update_button()


func _on_add_house_button_pressed() -> void:
	index = clamp(
		index + 1,
		max(0, original_index - 1),
		min(property_card.highlighters.size() - 1, original_index + 1)
	)
	if index != 0:
		property_card.highlight_rent(index)
	else:
		property_card.highlight_rent(property_card.highlighters.size())
	_update_button()
