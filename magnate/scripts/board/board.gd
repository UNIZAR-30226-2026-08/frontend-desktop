extends Node2D

@onready var camera_system: MagnateCameraSystem = $CameraSystem

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	BoardSpawner.spawn_board(self)
	camera_system.init_camera_system(self)
