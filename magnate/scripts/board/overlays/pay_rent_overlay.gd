extends BasicCardOverlay

var _property: PropertyModel

func setup(property: PropertyModel) -> void:
	if property.is_server: card = %ServerCard
	elif property.is_bridge: card = %BridgeCard
	else: card = %PropertyCard
	card.show()
	_property = property

func _ready() -> void:
	card.update_all_data(_property)
	super()
