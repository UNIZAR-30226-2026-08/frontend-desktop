extends PanelContainer

# Señal para cuando el usuario hace clic en "SELECCIONAR"
signal skin_selected(item_id: String)

# Definimos los 3 estados claros
enum State { IN_USE, SELECTED, SELECTABLE }

@export var item_id: String = ""
@export var item_name: String = ""
@export var item_icon: Texture2D

# Al cambiar el estado, se actualiza la visual automáticamente
@export var current_state: State = State.SELECTABLE:
	set(value):
		current_state = value
		_update_state()

@onready var item_icon_rect: TextureRect = %ItemIcon
@onready var name_label: Label = %NameLabel
@onready var action_button: Button = %ActionButton

func _ready() -> void:
	name_label.text = item_name
	if item_icon:
		item_icon_rect.texture = item_icon
	action_button.pressed.connect(_on_action_button_pressed)
	_update_state()

func _update_state() -> void:
	if not is_node_ready(): return
	
	match current_state:
		State.IN_USE:
			action_button.text = "EN USO"
			action_button.disabled = true
			# Usamos "font_disabled_color" porque el botón está inactivo
			action_button.add_theme_color_override("font_disabled_color", Color("c4c4c4")) # Gris claro
			
		State.SELECTED:
			action_button.text = "SELECCIONADO"
			action_button.disabled = true
			# Asumiendo que el botón se vuelve verde en tu diseño, ponemos el texto blanco
			action_button.add_theme_color_override("font_disabled_color", Color.WHITE)
			
		State.SELECTABLE:
			action_button.text = "SELECCIONAR"
			action_button.disabled = false
			# Usamos "font_color" normal porque el botón está activo
			action_button.add_theme_color_override("font_color", Color.WHITE)

func _on_action_button_pressed() -> void:
	if current_state == State.SELECTABLE:
		skin_selected.emit(item_id)

# Función de configuración similar a la que ya usas
func setup_profile_item(data: Dictionary) -> void:
	item_id = data.get("id", "")
	item_name = data.get("name", "Unknown")
	var icon_path = data.get("icon_path", "")
	if icon_path != "":
		item_icon = load(icon_path)
		item_icon_rect.texture = item_icon
	name_label.text = item_name
	
	# El estado inicial vendrá de tu lógica de guardado
	current_state = data.get("state", State.SELECTABLE)
