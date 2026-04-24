extends BlurryBgOverlay

signal finished

# Agrupamos los nodos en Arrays
@onready var dots: Array[Panel] = [%ColorDot1, %ColorDot2, %ColorDot3, %ColorDot4]
@onready var names: Array[Label] = [%Player1Label, %Player2Label, %Player3Label, %Player4Label]
@onready var bets: Array[Label] = [%Player1Bet, %Player2Bet, %Player3Bet, %Player4Bet]
@onready var bidders: Array[Panel] = [%WinnerPanel, %SecondBidderPanel, %ThirdBidderPanel, %ForthBidderPanel]
@onready var other_bids_label: Label = %OtherBidsLabel

@onready var confirm_button: Button = %ConfirmButton
@onready var title_label: Label = %TitleLabel

func _ready() -> void:
	super()
	for i in range(4): bidders[i].hide()
	confirm_button.pressed.connect(_on_confirm_button_pressed)

func show_results(bids: Array) -> void:
	bids.sort_custom(func(a, b): return a["bid"] > b["bid"])
	var is_tie = len(bids) >= 2 and bids[0]["bid"] == bids[1]["bid"]
	if is_tie: title_label.text = "¡NADIE GANA!"
	if len(bids) > 1: other_bids_label.show()
	for idx in len(bids):
		bidders[idx].show()
		dots[idx].modulate = bids[idx]["player"].color
		names[idx].text = bids[idx]["player"].player_name
		bets[idx].text = Utils.to_currency_text(bids[idx]["bid"])

func _on_confirm_button_pressed() -> void:
	Utils.debug("Saliendo de la pantalla de resultados...")
	finished.emit()
	queue_free()
