extends Node2D

# The Audio System manages 3 audio Buses: General bus, SFX bus and Music bus
# These buses are connected as follows:
# Music ┐
#       ├─ General
#   SFX ┘
# That is the final volume of an SFX audio track is the volume of the SFX bus
# times the audio of the General bus

# The Audio System plays Audio resources, this can vary in track, pitch,
# bus, volume, etc.

# To control if a given AudioResource has stopped playing you're
# returned an int when you play, this is your ticket, when your
# sound has finished playing the following signal will emit your
# ticket number:
signal audio_finished(int)

const _UI_BUS_NAME: String = "UI"
const _SFX_BUS_NAME: String = "SFX"
const _MUSIC_BUS_NAME: String = "Music"
const _GENERAL_BUS_NAME: String = "Master"

var _next_ticket: int = 0
var _audio_players: Dictionary = {}

func _get_busname_from_type(type: AudioResource.AudioResourceType) -> String:
	match type:
		AudioResource.AudioResourceType.MUSIC:
			return _MUSIC_BUS_NAME
		AudioResource.AudioResourceType.SFX:
			return _SFX_BUS_NAME
		AudioResource.AudioResourceType.UI:
			return _UI_BUS_NAME
		_:
			return ""

func _set_bus_volume(bus_name: String, percentage: float) -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_volume_linear(bus_index, percentage)

func set_sfx_volume(percentage: float) -> void:
	_set_bus_volume(_SFX_BUS_NAME, percentage)

func set_ui_volume(percentage: float) -> void:
	_set_bus_volume(_UI_BUS_NAME, percentage)

func set_music_volume(percentage: float) -> void:
	_set_bus_volume(_MUSIC_BUS_NAME, percentage)

func set_general_volume(percentage: float) -> void:
	_set_bus_volume(_GENERAL_BUS_NAME, percentage)

func _get_bus_volume(bus_name: String) -> float:
	var bus_index = AudioServer.get_bus_index(bus_name)
	return AudioServer.get_bus_volume_linear(bus_index)

func get_sfx_volume() -> float:
	return _get_bus_volume(_SFX_BUS_NAME)

func get_music_volume() -> float:
	return _get_bus_volume(_MUSIC_BUS_NAME)

func get_ui_volume() -> float:
	return _get_bus_volume(_UI_BUS_NAME)

func get_general_volume() -> float:
	return _get_bus_volume(_GENERAL_BUS_NAME)

# Returns ticket number
func play_audio(audio: AudioResource) -> int:
	var ticket = _next_ticket
	_next_ticket += 1
	var new_audio_player = AudioStreamPlayer.new()
	add_child(new_audio_player)
	
	new_audio_player.stream = audio.audio_track
	new_audio_player.pitch_scale = randf_range(
		audio.pitch - audio.pitch_random_margin,
		audio.pitch + audio.pitch_random_margin
	)
	new_audio_player.volume_db = audio.volume_db
	new_audio_player.autoplay = audio.autoplay
	new_audio_player.bus = _get_busname_from_type(audio.bus)
	_audio_players[ticket] = new_audio_player
	
	new_audio_player.finished.connect(func(): 
		audio_finished.emit(ticket)
		new_audio_player.queue_free()
	)
	new_audio_player.play()
	
	return ticket

# Returns ticket number
func play_audio_with_position(audio: AudioResource, _position: Vector2) -> int:
	var ticket = _next_ticket
	_next_ticket += 1
	var new_audio_player = AudioStreamPlayer2D.new()
	add_child(new_audio_player)
	
	new_audio_player.stream = audio.audio_track
	new_audio_player.pitch_scale = randf_range(
		audio.pitch - audio.pitch_random_margin,
		audio.pitch + audio.pitch_random_margin
	)
	new_audio_player.volume_db = audio.volume_db
	new_audio_player.autoplay = audio.autoplay
	new_audio_player.bus = _get_busname_from_type(audio.bus)
	new_audio_player.position = _position
	_audio_players[ticket] = new_audio_player
	
	new_audio_player.finished.connect(func(): 
		audio_finished.emit(ticket)
		new_audio_player.queue_free()
	)
	new_audio_player.play()
	
	return ticket
