extends PanelContainer

@onready var property_price: Label = %PropertyPrice
@onready var property_name: Label = %PropertyName
@onready var property_color: ColorRect = %PropertyColor

func set_property_name(prop_name: String) -> void:
	property_name.text = prop_name

func set_property_price(price: int) -> void:
	property_price.text = str(price)

func set_property_color(color: Color) -> void:
	property_color.color = color
