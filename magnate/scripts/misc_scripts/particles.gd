extends Node2D

@onready var gpu_particles_2d: GPUParticles2D = %GPUParticles2D

func set_emit(value: bool) -> void:
	gpu_particles_2d.emitting = value
