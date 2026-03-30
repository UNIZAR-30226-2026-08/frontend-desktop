extends MagnateTweenButton

@export_category("Texto")
@export var titulo: String = ""
@export var descripcion: String = ""

@onready var title: Label = $Margin/MainVBox/Title
@onready var description: Label = $Margin/MainVBox/Description

func _ready() -> void:	
	# Set text
	title.text = titulo
	description.text = descripcion
	
	super()
