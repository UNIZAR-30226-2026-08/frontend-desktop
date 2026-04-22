extends BasicCardOverlay

var _property: PropertyModel
@onready var animated_button: MagnateTweenButton = %AnimatedButton

func setup(property: PropertyModel) -> void:
	if property.is_server: card = %ServerCard
	elif property.is_bridge: card = %BridgeCard
	else: card = %PropertyCard
	card.show()
	_property = property

func _ready() -> void:
	card.update_all_data(_property)
	var price = Utils.to_currency_text(_property.rent_prices[_property.house_count])
	super()
	animated_button.set_btn_text("PAGAR " + price)
