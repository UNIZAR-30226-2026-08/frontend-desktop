extends PanelContainer

@onready var server_price: Label = %ServerPrice
@onready var server_name: Label = %ServerName

func set_server_name(name: String) -> void:
	server_name.text = name

func set_property_price(price: int) -> void:
	server_price.text = Utils.to_currency_text(price)
