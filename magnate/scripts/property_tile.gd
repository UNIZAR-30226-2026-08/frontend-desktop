extends PanelContainer

@onready var property_price: Label = %PropertyPrice
@onready var property_name: Label = %PropertyName
@onready var property_color: ColorRect = %PropertyColor
@onready var building_container: HBoxContainer = %BuildingContainer

const HOTEL = preload("uid://dxkynolj2rhdd")
const HOUSE = preload("uid://bs68kpgc7sid4")

var number_of_houses: int = 0 # [0, 5], 5 = hotel

func set_property_name(_name: String) -> void:
	property_name.text = _name

func set_property_price(price: int) -> void:
	property_price.text = Utils.to_currency_text(price)

func set_property_color(color: Color) -> void:
	property_color.color = color

func set_number_of_houses(n: int) -> void:
	if n == number_of_houses: return # trivial
	
	# n != number_of_houses
	# hotel cases
	if n == 5:
		add_hotel()
		number_of_houses = n
		return
	elif number_of_houses == 5:
		remove_hotel()
		number_of_houses -= 1
		if n == 4:
			return
	
	# Now only houses are left
	var diff = n - number_of_houses # != 0
	if diff < 0:
		remove_houses(abs(diff))
	else:
		add_houses(abs(diff))

func add_houses(n: int = 1) -> void:
	for i in range(n):
		var instance = HOUSE.instantiate()
		building_container.add_child(instance)

func remove_houses(n: int = 1) -> void:
	var children = building_container.get_children()
	var count = min(n, children.size())
	for i in range(count):
		children[i].queue_free()

func add_hotel() -> void:
	remove_houses(4)
	var instance = HOTEL.instantiate()
	building_container.add_child(instance)

func remove_hotel() -> void:
	remove_houses()
	add_houses(4)
