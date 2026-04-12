extends MagnateTweenButton

@export var icon_texture: Texture2D

@onready var icon_rect: TextureRect = $TextureRect

func set_icon(icon: Texture2D):
	if icon:
		icon_rect.texture = icon

func _ready() -> void:
	set_icon(icon_texture)
	super()
