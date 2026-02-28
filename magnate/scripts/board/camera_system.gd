class_name MagnateCameraSystem
extends Node2D

signal stopped

var _moving_camera: Camera2D
var _additional_cameras: Array[Camera2D] # Stack of cameras, max length 2
var _main_camera: Camera2D # Main camera, sees whole board

var _is_transitioning: bool
var _tween: Tween

func init_camera_system(board: Node2D) -> void:
	_main_camera = Camera2D.new()
	board.add_child(_main_camera)
	_main_camera.position = Vector2(1920. / 2, 1080. / 2)
	_main_camera.make_current()
	_additional_cameras = [_main_camera]
	
	_moving_camera = Camera2D.new()
	board.add_child(_moving_camera)
	_moving_camera.ignore_rotation = false

func transition_camera(origin: Camera2D, destiny: Camera2D, duration: float = 1.) -> void:
	if _is_transitioning: return
	
	_moving_camera.zoom = origin.zoom
	_moving_camera.global_transform = origin.global_transform
	_moving_camera.global_rotation = origin.global_rotation
	
	_is_transitioning = true
	_moving_camera.make_current()
	
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_CUBIC)
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(_moving_camera, "global_transform", destiny.global_transform, duration)
	_tween.parallel().tween_property(_moving_camera, "zoom", destiny.zoom, duration)
	_tween.parallel().tween_property(_moving_camera, "global_rotation", destiny.global_rotation, duration)
	_tween.play()
	
	await _tween.finished
	
	destiny.make_current()
	_is_transitioning = false
	
	stopped.emit()

func follow_node(followed: Node2D, _zoom: Vector2 = Vector2(1, 1)) -> void:
	var new_camera = Camera2D.new()
	new_camera.ignore_rotation = false
	_additional_cameras.append(new_camera)
	followed.add_child(_additional_cameras[1])
	_additional_cameras[1].zoom = _zoom
	transition_camera(_additional_cameras[0], _additional_cameras[1])
	_additional_cameras.pop_front()

func main_camera() -> void:
	_additional_cameras.append(_main_camera)
	transition_camera(_additional_cameras[0], _additional_cameras[1])
	_additional_cameras.pop_front()

func zoom(_zoom: Vector2) -> void:
	var zoomed_camera = _additional_cameras[0].duplicate()
	zoomed_camera.zoom = _zoom
	_additional_cameras[0].get_parent().add_child(zoomed_camera)
	_additional_cameras.append(zoomed_camera)
	transition_camera(_additional_cameras[0], _additional_cameras[1])
	_additional_cameras.pop_front()
	
