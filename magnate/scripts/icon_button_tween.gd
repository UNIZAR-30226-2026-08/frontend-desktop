extends MagnateTweenButton

@export var icon_texture: Texture2D

@onready var icon_rect: TextureRect = $TextureRect

func _ready() -> void:
	if icon_texture:
		icon_rect.texture = icon_texture
	
	super()
