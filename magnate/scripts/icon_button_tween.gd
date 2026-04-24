extends MagnateTweenButton

@export var icon_texture: Texture2D

@onready var icon_rect: TextureRect = $TextureRect

func set_icon(_icon: Texture2D):
	if _icon:
		icon_rect.texture = _icon

func _ready() -> void:
	set_icon(icon_texture)
	super()
