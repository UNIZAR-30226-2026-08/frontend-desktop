extends BlurryBgOverlay
class_name TradeSelectionOverlay

signal cancel_selection

func _ready() -> void:
	super()
	
	# 1. Creamos un fondo invisible que atrape los clics
	var bg_clicker = Control.new()
	bg_clicker.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg_clicker)
	
	# Le conectamos su señal gui_input para detectar el clic
	bg_clicker.gui_input.connect(_on_bg_clicked)
	
func _on_bg_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		cancel_selection.emit()
