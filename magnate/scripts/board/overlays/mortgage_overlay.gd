extends BasicCardOverlay

@onready var mortgage_card: Control = %MortgageCard

func _ready() -> void:
	super()

func setup(property: PropertyModel) -> void:
	mortgage_card.set_property_name(property.name)
	@warning_ignore('integer_division')
	mortgage_card.set_mortgage_price(property.buy_price / 2)
