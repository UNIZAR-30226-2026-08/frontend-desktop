extends Control
class_name DiceRollerOverlay

signal roll_finished

@onready var dice_roller_3d: DiceRoller = $DiceRoller

# Variables de estado auxiliares
var has_rolled: bool = false
var forced_roll_throw: Array[int]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if dice_roller_3d:
		dice_roller_3d.roll_finnished.connect(_on_3d_roll_finished)

func _gui_input(event: InputEvent) -> void:
	# Para evitar BUGS: clicks invisibles, etc.
	if not visible:
		return
	if has_rolled or not dice_roller_3d or dice_roller_3d.rolling or not dice_roller_3d.interactive:
		return
		
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			dice_roller_3d.prepare()
		elif not event.pressed and (event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT):
			roll_the_dice(forced_roll_throw)
			# Audio
			var audio = AudioResource.from_type(Globals.AUDIO_DICE_ROLL, AudioResource.AudioResourceType.SFX)
			AudioSystem.play_audio(audio)

# Guardamos el resultado de los dados que nos envia el back para usarlo
func force_values_in_dice_and_show_dice(forced_values: Array[int]) -> void:
	forced_roll_throw = forced_values
	# Al final ya mostramos los dados para que el usuario haga click
	show_overlay()

# Lanzar dados con valor forzado
func roll_the_dice(forced_values: Array[int]) -> void:
	show_overlay() # Cambiado de show() a show_overlay()
	dice_roller_3d.roll(forced_values)
	# Marcamos que ya se han tirado para no permitir más clicks
	has_rolled = true

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
	roll_finished.emit()
