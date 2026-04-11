extends PanelContainer

@export var custom_text: String = "Placeholder text"

@onready var _tooltip_text: Label = %TooltipText

const fade_default: float = 0.5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_tooltip_text.text = custom_text

func flash(fade_duration: float = fade_default, duration: float = 5) -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_duration)
	tween.tween_interval(duration)
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)

func fadein(fade_duration: float = fade_default) -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_duration)

func fadeout(fade_duration: float = fade_default) -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
