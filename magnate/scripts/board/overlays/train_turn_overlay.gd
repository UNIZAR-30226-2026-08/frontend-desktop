extends BlurryBgOverlay

# Emitimos las señales enviando los datos necesarios al OverlayManager
signal confirm_travel(target_tile_id: String, cost: int)
signal cancel_travel()

@onready var title_label: Label = %TitleLabel
@onready var desc_label: Label = %SubtitleLabel
@onready var btn_primary: Button = %ConfirmButton
@onready var btn_secondary: Button = %RejectButton

# Variables para guardar los datos de este pop-up en concreto
var current_target_id: String = ""
var current_cost: int = 0

func _ready() -> void:
	super()
	_connect_buttons()

# ==========================================
# 🚂 CONFIGURACIÓN DEL POP-UP
# ==========================================

func setup_tram_selection(target_tile_id: String, is_same_station: bool, tile_name: String) -> void:
	current_target_id = target_tile_id
	
	if is_same_station:
		current_cost = 0
		title_label.text = "QUEDARSE EN ESTA ESTACIÓN"
		desc_label.text = "¿Quieres finalizar tu turno y quedarte en esta misma estación?"
		btn_primary.text = "CONFIRMAR (0M)"
	else:
		current_cost = 50
		title_label.text = "VIAJAR A " + tile_name.to_upper()
		desc_label.text = "Puedes tomar el tranvía hasta esta estación. ¿Deseas comprar el billete?"
		btn_primary.text = "VIAJAR (50M)"
		
	btn_secondary.text = "ELEGIR OTRA PARADA"
	btn_secondary.show()

# ==========================================
# 🎛️ CONEXIÓN DE BOTONES
# ==========================================

func _connect_buttons() -> void:
	if not btn_primary.pressed.is_connected(_on_primary_pressed):
		btn_primary.pressed.connect(_on_primary_pressed)
	if not btn_secondary.pressed.is_connected(_on_secondary_pressed):
		btn_secondary.pressed.connect(_on_secondary_pressed)

func _on_primary_pressed() -> void:
	confirm_travel.emit(current_target_id, current_cost)
	queue_free()

func _on_secondary_pressed() -> void:
	cancel_travel.emit()
	queue_free()
