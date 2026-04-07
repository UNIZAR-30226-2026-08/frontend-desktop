extends BlurryBgOverlay

# Emitimos estas señales genéricas. El manager ya se encargará de traducirlas.
signal primary_action
signal secondary_action

@onready var title_label: Label = %TitleLabel
@onready var desc_label: Label = %SubtitleLabel
@onready var btn_primary: Button = %ConfirmButton
@onready var btn_secondary: Button = %RejectButton

func _ready() -> void:
	super()

# 1. CASO INICIAL: Pop-up nada más empezar el turno
func setup_initial(current_turn: int, max_turns: int) -> void:
	title_label.text = "¡VISITANDO SECRETARÍA!"
	desc_label.text = "Condena en curso: %d de %d." % [current_turn, max_turns]
	btn_primary.text = "TIRAR DADOS"
	btn_secondary.hide() # Solo hay un botón para avanzar
	
	_connect_buttons()

# 2. CASO CLIC EN CÁRCEL: Decidir quedarse
func setup_jail_selected(current_turn: int, max_turns: int) -> void:
	title_label.text = "QUEDARSE EN SECRETARÍA"
	desc_label.text = "Llevas %d de %d turnos. ¿Quieres confirmar y quedarte aquí este turno?" % [current_turn, max_turns]
	btn_primary.text = "CONFIRMAR"
	btn_secondary.text = "ELEGIR OTRA CASILLA"
	btn_secondary.show()
	
	_connect_buttons()

# 3. CASO CLIC EN OTRA CASILLA: Pagar fianza
func setup_pay_bail(bail_price: int) -> void:
	title_label.text = "PAGAR FIANZA"
	desc_label.text = "Si quieres moverte a esta casilla, debes pagar la fianza primero."
	btn_primary.text = "PAGAR %dM" % bail_price
	btn_secondary.text = "ELEGIR OTRA CASILLA"
	btn_secondary.show()
	
	_connect_buttons()

func _connect_buttons() -> void:
	# Nos aseguramos de no conectar múltiples veces si reutilizas el nodo
	if not btn_primary.pressed.is_connected(_on_primary_pressed):
		btn_primary.pressed.connect(_on_primary_pressed)
	if not btn_secondary.pressed.is_connected(_on_secondary_pressed):
		btn_secondary.pressed.connect(_on_secondary_pressed)

func _on_primary_pressed() -> void:
	primary_action.emit()
	queue_free()

func _on_secondary_pressed() -> void:
	secondary_action.emit()
	queue_free()
