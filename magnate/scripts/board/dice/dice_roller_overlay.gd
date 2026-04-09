extends Control
class_name DiceRollerOverlay

signal roll_finished(total_value: int)

@onready var dice_roller_3d: DiceRoller = $DiceRoller
@onready var FORCED_ROLL_THROW: Array[int] = [6,6,3]

# NUEVA VARIABLE: Controla si ya se ha hecho una tirada
# TODO: Quizá meter esto en un model para el juego
var has_rolled: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if dice_roller_3d:
		dice_roller_3d.roll_finnished.connect(_on_3d_roll_finished)

func _gui_input(event: InputEvent) -> void:
	# CERROJO PARA EVITAR BUGS
	if not visible:
		return
		
	# Si ya hemos tirado, o los dados están rodando, IGNORAMOS el click
	if has_rolled or not dice_roller_3d or dice_roller_3d.rolling or not dice_roller_3d.interactive:
		return
		
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			dice_roller_3d.prepare()
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			roll_the_dice(FORCED_ROLL_THROW)
			# Audio
			var audio = AudioResource.from_type(Globals.AUDIO_DICE_ROLL, AudioResource.AudioResourceType.SFX)
			AudioSystem.play_audio(audio)
		elif event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			dice_roller_3d.quick_roll()
			has_rolled = true # Bloqueamos también si usa el botón derecho
			# Audio
			var audio = AudioResource.from_type(Globals.AUDIO_DICE_ROLL, AudioResource.AudioResourceType.SFX)
			AudioSystem.play_audio(audio)

func roll_the_dice(forced_values: Array[int] = [1, 3, 6]) -> void:
	show_overlay() # Cambiado de show() a show_overlay()
	dice_roller_3d.roll(forced_values)
	# Marcamos que ya se han tirado para no permitir más clicks
	has_rolled = true

# Función nueva para encender la capa 2D y el 3D a la vez
func show_overlay() -> void:
	show() # Muestra el Control (2D)
	if dice_roller_3d:
		dice_roller_3d.show() # Muestra los dados (3D)
		# ✅ DESPERTAMOS EL NODO 3D:
		dice_roller_3d.process_mode = Node.PROCESS_MODE_INHERIT 

# Modificamos esta para que apague ambas cosas
func hide_overlay() -> void:
	hide() # Oculta el Control (2D)
	if dice_roller_3d:
		dice_roller_3d.hide() # Oculta los dados (3D)
		# 🛑 APAGÓN TOTAL: Ignora inputs, físicas y código mientras esté oculto
		dice_roller_3d.process_mode = Node.PROCESS_MODE_DISABLED

# Función para volver a habilitar los dados en el siguiente turno
func reset_dice() -> void:
	has_rolled = false
	show_overlay() # Cambiado de show() a show_overlay()

func _on_3d_roll_finished(total_value: int) -> void:
	roll_finished.emit(total_value)
