extends PanelContainer

# Referencias a los nodos clave
@onready var group_color_panel: Panel = %GroupColor
@onready var property_name_label: Label = %PropertyName

# Guardamos la ID real de la propiedad por si en algún momento la necesitas
var _current_property_id: String = ""

# ==========================================
# FUNCIÓN PÚBLICA PARA INYECTAR DATOS
# ==========================================
func setup_item(property_id: String, property_name: String, color_group: Color) -> void:
	_current_property_id = property_id
	
	# 1. Cambiamos el texto
	# (Asegúrate de que property_name_label tenga la opción 'Clip Text' o 'Overrun' activa 
	# por si el nombre es muy largo)
	property_name_label.text = property_name.to_upper() # Convertimos a mayúsculas como en la web
	
	# 2. Cambiamos el color del puntito
	# Para cambiar el color de un StyleBox individualmente sin afectar a los demás, 
	# tenemos que duplicarlo
	var current_stylebox = group_color_panel.get_theme_stylebox("panel").duplicate()
	current_stylebox.bg_color = color_group
	group_color_panel.add_theme_stylebox_override("panel", current_stylebox)
