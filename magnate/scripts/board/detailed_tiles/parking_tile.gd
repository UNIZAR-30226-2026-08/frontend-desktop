extends Control

@onready var coin_particles: Node2D = %CoinParticles
@onready var jackpot: Label = %Jackpot

func ready() -> void:
	ModelManager.parking.connect(set_jackpot)

func emit_coins() -> void:
	if ModelManager.game.parking_money == 0: return
	coin_particles.set_emit(true)
	var timer = get_tree().create_timer(1)
	await timer.timeout
	coin_particles.set_emit(false)

func set_jackpot() -> void:
	jackpot.text = Utils.to_currency_text(ModelManager.game.parking_money)
