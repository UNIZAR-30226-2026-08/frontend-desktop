extends Control

@onready var mortgage_price: Label = %MortgagePrice
@onready var property_name: Label = %PropertyName

func set_property_name(prop_name: String) -> void:
	property_name.text = prop_name

func set_mortgage_price(price: int) -> void:
	mortgage_price.text = Utils.to_currency_text(price)
