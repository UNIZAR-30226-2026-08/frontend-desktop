extends BlurryBgOverlay

signal property_bought
signal property_auctioned

@onready var card = %PropertyCard
@onready var server_card = %ServerCard
@onready var bridge_card = %BridgeCard
@onready var buy_button = %BuyButton
@onready var auction_button = %AuctionButton
@onready var tooltip: PanelContainer = %Tooltip

func _ready() -> void:
	super()
	
	visible = false
	card.visible = false
	server_card.visible = false
	bridge_card.visible = false
	
	# Audio
	var audio = AudioResource.from_type(Globals.AUDIO_CARDFLIP, AudioResource.AudioResourceType.SFX)
	AudioSystem.play_audio(audio)
	
	buy_button.pressed.connect(_on_buy_button_pressed)
	auction_button.pressed.connect(_on_auction_button_pressed)

func setup(property: PropertyModel) -> void:
	var buy_price = property.buy_price
	buy_button.text = "Comprar por %d" % buy_price + Globals.SYMBOL_CURRENCY
	
	if property.is_server:
		server_card.update_all_data(property)
		aparecer(server_card)
	elif property.is_bridge:
		bridge_card.update_all_data(property)
		aparecer(bridge_card)
	else:
		card.update_all_data(property)
		aparecer(card)

# ==========================================
# ANIMACIÓN (Mantenemos tu código casi igual)
# ==========================================
func aparecer(tarjeta: Control):
	tarjeta.visible = true
	show()
	tarjeta.modulate.a = 0.0
	
	var pos_original = tarjeta.position.y
	tarjeta.position.y = pos_original + 20 

	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(tarjeta, "modulate:a", 1.0, 0.4)
	tween.tween_property(tarjeta, "position:y", pos_original, 0.4)

# =================
#  Button handlers
# =================
func _on_buy_button_pressed() -> void:
	property_bought.emit() # Avisamos al tablero
	queue_free()

func _on_auction_button_pressed() -> void:
	property_auctioned.emit()
	queue_free()

const fade_duration = 0.1

func _on_auction_button_mouse_entered() -> void:
	tooltip.fadein()

func _on_auction_button_mouse_exited() -> void:
	tooltip.fadeout()
