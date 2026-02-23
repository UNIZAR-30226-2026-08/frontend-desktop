extends PanelContainer

@onready var property_price: Label = $VerticalAlign/InteriorAlign/PropertyPrice
@onready var property_name: Label = $VerticalAlign/InteriorAlign/PropertyName
@onready var property_color: ColorRect = $VerticalAlign/PropertyColor

func set_property_name(name: String) -> void:
	property_name.text = name

func set_property_price(price: int) -> void:
	property_price.text = str(price)

func set_property_color(color: Color) -> void:
	property_color.color = color
