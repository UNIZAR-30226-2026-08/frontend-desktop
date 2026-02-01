extends Container

# Children references
@onready var child_property_color: ColorRect = $VerticalAlign/PropertyColor
@onready var child_property_name: Label = $VerticalAlign/PropertyName
@onready var child_property_price: Label = $VerticalAlign/PropertyPrice

# Exported values
@export_multiline var property_name: String = "Property\nname"
@export var property_color: Color = Globals.BLACK
@export_range(0, 1000000) var property_price: int = 999

# Initializes children values to external
func init_children() -> void:
	child_property_color.color = property_color
	child_property_name.text = property_name
	child_property_price.text = "$" + str(property_price)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	init_children()
