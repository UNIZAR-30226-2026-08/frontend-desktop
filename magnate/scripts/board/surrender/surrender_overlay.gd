extends BlurryBgOverlay

signal exit_game_confirmed
signal cancel_surrender

@onready var exit_button: Button = %ExitButton
@onready var back_to_game_button: Button = %BackToGameButton

func _ready() -> void:
	super() # Mantiene lo que haga BlurryBgOverlay
	
	exit_button.pressed.connect(func():
		exit_game_confirmed.emit()
	)
	
	back_to_game_button.pressed.connect(func():
		cancel_surrender.emit()
	)
