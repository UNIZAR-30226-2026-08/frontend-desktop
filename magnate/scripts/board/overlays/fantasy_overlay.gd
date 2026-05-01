extends BlurryBgOverlay

signal card_action_resolved(front_chosen: bool)

# Referencias a los nodos hijos (cartas)
@onready var front_card: Control = $HBoxContainer/FrontFantasyCard
@onready var back_card: Control = $HBoxContainer/BackFantasyCard

const TIEMPO_ESPERA_CIERRE: float = 4.0
const TIEMPO_DESVANECIMIENTO: float = 1.0

var result: Dictionary
var front_card_chosen = true
var front_card_blocked = false

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
	if not front_card_chosen:
		back_card.setup_content(card)
		await _fadeout_card(front_card)
		_move_card_to_center(back_card)
	else:
		await _fadeout_card(back_card)
		_move_card_to_center(front_card)
	await get_tree().create_timer(TIEMPO_ESPERA_CIERRE).timeout
	_close_overlay()

func setup_card(card_data: Dictionary) -> void:
	front_card.setup_content(card_data)
	if ModelManager.get_player().balance < card_data["card_cost"]:
		front_card_blocked = true
		front_card.block()

func _on_back_fantasy_card_pressed() -> void:
	Utils.debug("Mazo pulsado, revelando y desvaneciendo frontal...")
	_block_input()
	front_card_chosen = false
	WsClient.ws_action_choose_fantasy_card(false)

func _on_front_fantasy_card_pressed() -> void:
	if front_card_blocked: return
	Utils.debug("Carta frontal elegida, desvaneciendo mazo...")
	_block_input()
	WsClient.ws_action_choose_fantasy_card(true)

func _fadeout_card(card: Control) -> void:
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_method(card.set_opacity, 1.0, 0.0, 1.0)
	await tween.finished

func _move_card_to_center(card) -> void:
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(card, "position:x", 760, 1)

func _block_input() -> void:
	back_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	front_card.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _close_overlay() -> void:
	card_action_resolved.emit(result)
	queue_free()
