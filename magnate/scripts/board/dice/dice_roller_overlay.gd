extends Control
class_name DiceRollerOverlay

signal roll_finished

@onready var dice_roller_3d: DiceRoller = $DiceRoller

# Variables de estado auxiliares
var has_rolled: bool = false
var forced_roll_throw: Array[int]
var result: Dictionary

func _ready() -> void:
	hide_overlay()
	mouse_filter = Control.MOUSE_FILTER_STOP
	WsClient.response_throw_dices.connect(_handle_dice_result)
	if dice_roller_3d:
		dice_roller_3d.roll_finnished.connect(_on_3d_roll_finished)

func _gui_input(event: InputEvent) -> void:
	# Para evitar BUGS: clicks invisibles, etc.
	if not ModelManager.is_my_turn() or not visible or has_rolled or dice_roller_3d.rolling or not dice_roller_3d.interactive:
		return
	
	if event is InputEventMouseButton:
		if event.pressed and (event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT):
			dice_roller_3d.prepare()
		elif not event.pressed and (event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT):
			has_rolled = true
			WsClient.ws_action_throw_dice()

func _handle_dice_result(_result: Dictionary) -> void:
	if _result == {} or not visible: return
	result = _result
	roll_the_dice([_result["dice1"], _result["dice2"], _result["dice_bus"]])
	# Audio
	var audio = AudioResource.from_type(Globals.AUDIO_DICE_ROLL, AudioResource.AudioResourceType.SFX)
	AudioSystem.play_audio(audio)

# Guardamos el resultado de los dados que nos envia el back para usarlo
func force_values_in_dice_and_show_dice(forced_values: Array[int]) -> void:
	forced_roll_throw = forced_values
	# Al final ya mostramos los dados para que el usuario haga click
	show_overlay()
	
	# Si no es mi turno simulo lanzado de dados automático
	if not ModelManager.is_my_turn():
		roll_the_dice(forced_roll_throw)
	# else el juego esperará a que el usuario le de a los dados, no hay que hacer nada

# Lanzar dados con valor forzado
func roll_the_dice(forced_values: Array[int]) -> void:
	show_overlay()
	dice_roller_3d.roll(forced_values)

# Función para encender las capas 2D y 3D
func show_overlay() -> void:
	show()
	if dice_roller_3d:
		dice_roller_3d.show()
		dice_roller_3d.process_mode = Node.PROCESS_MODE_INHERIT 

# Función para apagar las capas 2D y 3D
func hide_overlay() -> void:
	hide()
	if dice_roller_3d:
		dice_roller_3d.hide()
		dice_roller_3d.process_mode = Node.PROCESS_MODE_DISABLED

# Función para volver a habilitar los dados en el siguiente turno
func reset_dice() -> void:
	has_rolled = false
	show_overlay() # Cambiado de show() a show_overlay()

# Función que envía señal de tirada de dados hacia arriba
func _on_3d_roll_finished() -> void:
	roll_finished.emit(result)
