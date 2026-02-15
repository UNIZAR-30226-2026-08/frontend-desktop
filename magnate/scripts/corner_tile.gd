extends PanelContainer

func init_dimensions() -> void:
	self.size = Vector2(
		Globals.TILE_LONG_SIDE_LENGTH,
		Globals.TILE_LONG_SIDE_LENGTH
	)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	init_dimensions()
