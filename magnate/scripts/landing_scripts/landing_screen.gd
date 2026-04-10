extends Control

func _ready() -> void:
	var music = AudioResource.from_type(Globals.AUDIO_MENUMUSIC, AudioResource.AudioResourceType.MUSIC)
	AudioSystem.play_audio(music)
	RestClient.login.connect(SceneTransition.change_scene.bind(
		"res://scenes/UI/home_screen.tscn"
	))

func _on_login_button_pressed() -> void:
	SceneTransition.change_scene("res://scenes/UI/login_screen.tscn")

func _on_signup_button_pressed() -> void:
	SceneTransition.change_scene("res://scenes/UI/signup_screen.tscn")
