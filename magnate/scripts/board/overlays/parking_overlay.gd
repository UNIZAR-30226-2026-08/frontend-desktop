extends BasicCardOverlay

func _ready() -> void:
	super()
	var audio = AudioResource.from_type(Globals.AUDIO_PARKING, AudioResource.AudioResourceType.SFX)
	AudioSystem.play_audio(audio)
