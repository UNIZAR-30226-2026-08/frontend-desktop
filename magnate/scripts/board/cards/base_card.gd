class_name MagnateBaseCard
extends Control

@onready var sub_viewport_container: SubViewportContainer = $SubViewportContainer

func set_opacity(opacity: float) -> void:
	sub_viewport_container.material.set_shader_parameter("opacity", opacity)
