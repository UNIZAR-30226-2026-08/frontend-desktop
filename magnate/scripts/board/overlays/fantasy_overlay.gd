extends BlurryBgOverlay

signal card_action_resolved(front_chosen: bool)

# Referencias a los nodos hijos (cartas)
@onready var front_card: Control = $HBoxContainer/FrontFantasyCard
@onready var back_card: Control = $HBoxContainer/BackFantasyCard

const TIEMPO_ESPERA_CIERRE: float = 6.0
const TIEMPO_DESVANECIMIENTO: float = 1.0

var result: Dictionary
var front_card_chosen = true

func _ready() -> void:
	super()
	
	# Audio
	var audio = AudioResource.from_type(Globals.AUDIO_FANTASY, AudioResource.AudioResourceType.SFX)
	AudioSystem.play_audio(audio)
	
	WsClient.response_choose_fantasy.connect(_handle_response)

func _handle_response(response: Dictionary):
	result = response
	var fantasy_event = response["fantasy_result"]["fantasy_event"]
	var card
	if fantasy_event["value"]: card = Globals.fantasy[fantasy_event["fantasy_type"]][fantasy_event["value"]]
	else: card = Globals.fantasy[fantasy_event["fantasy_type"]][0.0]
	back_card.setup_content(card)
	if not front_card_chosen:
		_desvanecer_carta(front_card)
		await get_tree().create_timer(TIEMPO_ESPERA_CIERRE).timeout
		_finalizar_overlay()
	else:
		back_card.flip_smooth()
		await get_tree().create_timer(2 * TIEMPO_ESPERA_CIERRE / 3).timeout
		_desvanecer_carta(back_card)
		await get_tree().create_timer(TIEMPO_ESPERA_CIERRE / 3).timeout
		_finalizar_overlay()

func setup_card(card_data: Dictionary) -> void:	
	# Pasamos los textos a la carta delantera
	front_card.setup_content(card_data)

func _on_back_fantasy_card_pressed() -> void:
	Utils.debug("Mazo pulsado, revelando y desvaneciendo frontal...")
	
	_bloquear_todas_las_entradas()
	front_card_chosen = false
	WsClient.ws_action_choose_fantasy_card(false)

func _on_front_fantasy_card_pressed() -> void:
	Utils.debug("Carta frontal elegida, desvaneciendo mazo...")
	
	_bloquear_todas_las_entradas()
	WsClient.ws_action_choose_fantasy_card(true)

func _desvanecer_carta(carta_a_ocultar: Control) -> void:
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_method(carta_a_ocultar.set_opacity, 1.0, 0.0, 1.0)
	# tween.tween_callback(carta_a_ocultar.hide)

func _bloquear_todas_las_entradas() -> void:
	back_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	front_card.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _finalizar_overlay() -> void:
	card_action_resolved.emit(result)
	queue_free()
