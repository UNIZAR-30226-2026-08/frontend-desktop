extends CanvasLayer


@onready var animated_button: Button = $AnimatedButton
@onready var property_card: PanelContainer = $HBoxContainer/PropertyCard

var index: int
var original_index: int
var price_per_house: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	index = 0 # TODO: Get real index from backend
	price_per_house = 50 # TODO: Get real prices from backend
	if index != 0:
		property_card.highlight_rent(index)
	original_index = index

func _update_button() -> void:
	if index < original_index:
		var price = price_per_house * (original_index - index) / 2 # TODO: Is it division by 2?
		animated_button.text = "Recibir {valor}€".format({"valor": price})
	elif index > original_index:
		var price = price_per_house * (index - original_index)
		animated_button.text = "Pagar {valor}€".format({"valor": price})
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
	index = clamp(index + 1, 0, property_card.highlighters.size() - 1)
	if index != 0:
		property_card.highlight_rent(index)
	else:
		property_card.highlight_rent(property_card.highlighters.size())
	_update_button()
