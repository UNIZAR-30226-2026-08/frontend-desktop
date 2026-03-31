extends PanelContainer

# Señal para avisar al overlay principal que esta propiedad debe quitarse
signal remove_requested(id: String)

# Referencias a los nodos clave
@onready var group_color_panel: Panel = %GroupColor
@onready var property_name_label: Label = %PropertyName
@onready var remove_button: Button = %RemoveButton

# Guardamos la ID real de la propiedad por seguridad
var _current_property_id: String = ""

# ==========================================
# FUNCIÓN PÚBLICA PARA INYECTAR DATOS (Step 4)
# ==========================================
func setup_item(property_id: String, property_name: String, color_group: Color) -> void:
	_current_property_id = property_id
	
	# 1. Cambiamos el texto
	# (Asegúrate de que propertyName_label tenga la opción 'Clip Text' o 'Overrun' activa 
	# por si el nombre es muy largo)
	property_name_label.text = property_name.to_upper() # Convertimos a mayúsculas como en la web
	
	# 2. Cambiamos el color del puntito
	# Para cambiar el color de un StyleBox individualmente sin afectar a los demás, 
	# tenemos que duplicarlo
	var current_stylebox = group_color_panel.get_theme_stylebox("panel").duplicate()
	current_stylebox.bg_color = color_group
	group_color_panel.add_theme_stylebox_override("panel", current_stylebox)

# ========
#  Events
# ========
func _on_remove_button_pressed() -> void:
	print("❌ Solicitando quitar propiedad: ", _current_property_id)
	# Avisamos al overlay principal. Él se encargará de borrar este nodo.
	remove_requested.emit(_current_property_id)
