extends Control
class_name JailDiceRollerOverlay

signal roll_finished(total_value: int)

@onready var jail_dice_roller_3d: DiceRoller = $DiceRoller

# NUEVA VARIABLE: Controla si ya se ha hecho una tirada
# TODO: Quizá meter esto en un model para el juego
var has_rolled: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if jail_dice_roller_3d:
		jail_dice_roller_3d.roll_finnished.connect(_on_3d_roll_finished)

func _gui_input(event: InputEvent) -> void:
	# Si ya hemos tirado, o los dados están rodando, IGNORAMOS el click
	if has_rolled or not jail_dice_roller_3d or jail_dice_roller_3d.rolling or not jail_dice_roller_3d.interactive:
		return
		
	if event is InputEventMouseButton:
		if event.pressed:
			# Audio
			var audio = AudioResource.from_type(Globals.AUDIO_DICE_ROLL, AudioResource.AudioResourceType.SFX)
			AudioSystem.play_audio(audio)
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			jail_dice_roller_3d.prepare()
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			roll_the_dice()
		elif event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			jail_dice_roller_3d.quick_roll()
			has_rolled = true # Bloqueamos también si usa el botón derecho

func roll_the_dice(forced_values: Array[int] = [1, 3]) -> void:
	show()
	jail_dice_roller_3d.roll(forced_values)
	# Marcamos que ya se han tirado para no permitir más clicks
	has_rolled = true 

func hide_overlay() -> void:
	hide()

# Función para volver a habilitar los dados en el siguiente turno
func reset_dice() -> void:
	has_rolled = false
	show()

func _on_3d_roll_finished(total_value: int) -> void:
	roll_finished.emit(total_value)
