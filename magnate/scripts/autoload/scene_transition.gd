extends CanvasLayer

@onready var transition_animation: AnimationPlayer = $TransitionAnimation

func change_scene(target_path) -> void:
	transition_animation.play("fade_in")
	await transition_animation.animation_finished
	
	get_tree().change_scene_to_file(target_path)
	
	transition_animation.play_backwards("fade_in")
