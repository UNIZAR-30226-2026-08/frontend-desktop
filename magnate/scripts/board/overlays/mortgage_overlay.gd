extends BasicCardOverlay

@onready var mortgage_card: Control = %MortgageCard
@onready var animated_button: MagnateTweenButton = %AnimatedButton

var _property: PropertyModel

func _ready() -> void:
	super()
	mortgage_card.set_property_name(_property.name)
	@warning_ignore('integer_division')
	mortgage_card.set_mortgage_price(_property.buy_price / 2)
	animated_button.set_btn_text("ACEPTAR")

func setup(property: PropertyModel) -> void:
	_property = property
