extends Control

@onready var coin_particles: Node2D = %CoinParticles

func emit_coins() -> void:
	coin_particles.set_emit(true)
	var timer = get_tree().create_timer(1)
	await timer.timeout
	coin_particles.set_emit(false)
