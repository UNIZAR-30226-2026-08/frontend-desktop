extends PanelContainer

@onready var mortgage_price: Label = $VerticalAlign/InteriorAlign/MortgagePrice
@onready var property_name: Label = $VerticalAlign/InteriorAlign/PropertyName

func set_property_name(name: String) -> void:
	property_name.text = name

func set_mortgage_price(price: int) -> void:
	mortgage_price.text = str(price)
