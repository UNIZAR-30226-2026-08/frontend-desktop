extends Node2D

# The Audio System manages 3 audio Buses: General bus, SFX bus and Music bus
# These buses are connected as follows:
# Music ┐
#       ├─ General
#   SFX ┘
# That is the final volume of an SFX audio track is the volume of the SFX bus
# times the audio of the General bus.
# Music is treated somewhat differently, there can only be one music track
# playing at a time, and it will always play in the same AudioStreamPlayer.

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

const FADE_DELAY: float = 1.

var _next_ticket: int = 1
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

func _mute_bus(bus_name: String) -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_mute(bus_index, true)

func mute_sfx() -> void:
	_mute_bus(_SFX_BUS_NAME)

func mute_music() -> void:
	_mute_bus(_MUSIC_BUS_NAME)

func mute_ui() -> void:
	_mute_bus(_UI_BUS_NAME)

func mute_general() -> void:
	_mute_bus(_GENERAL_BUS_NAME)

func _unmute_bus(bus_name: String) -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_mute(bus_index, false)

func unmute_sfx() -> void:
	_unmute_bus(_SFX_BUS_NAME)

func unmute_music() -> void:
	_unmute_bus(_MUSIC_BUS_NAME)

func unmute_ui() -> void:
	_unmute_bus(_UI_BUS_NAME)

func unmute_general() -> void:
	_unmute_bus(_GENERAL_BUS_NAME)

func _toggle_mute_bus(bus_name: String) -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	if AudioServer.is_bus_mute(bus_index):
		AudioServer.set_bus_mute(bus_index, false)
	else:
		AudioServer.set_bus_mute(bus_index, true)

func toggle_mute_sfx() -> void:
	_toggle_mute_bus(_SFX_BUS_NAME)

func toggle_mute_music() -> void:
	_toggle_mute_bus(_MUSIC_BUS_NAME)

func toggle_mute_ui() -> void:
	_toggle_mute_bus(_UI_BUS_NAME)

func toggle_mute_general() -> void:
	_toggle_mute_bus(_GENERAL_BUS_NAME)

func _create_new_audio_player(audio: AudioResource) -> int:
	var ticket
	if audio.bus == AudioResource.AudioResourceType.MUSIC:
		ticket = 0
		if _audio_players.has(0) && audio.audio_track != _audio_players[0].stream:
			# We have to play new music, fadeout current and free space
			var tween = create_tween()
			tween.tween_property(_audio_players[0], "volume_db", -80.0, FADE_DELAY)
			tween.play()
			await tween.finished
			_audio_players[0].queue_free()
		elif _audio_players.has(0) && audio.audio_track == _audio_players[0].stream:
			return ticket # Dont create new music, its already playing
	else:
		ticket = _next_ticket
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
	return ticket

func _start_audio(player, fadein: bool) -> void:
	if fadein:
		player.volume_db = -80.0
	player.play()
	if fadein:
		var tween = create_tween()
		tween.tween_property(player, "volume_db", 0, FADE_DELAY)
		tween.play()
		await tween.finished

# Returns ticket number
func play_audio(audio: AudioResource) -> int:
	var ticket = await _create_new_audio_player(audio)
	_start_audio(_audio_players[ticket], audio.bus == AudioResource.AudioResourceType.MUSIC)
	
	return ticket

# Returns ticket number
func play_audio_with_position(audio: AudioResource, _position: Vector2) -> int:
	var ticket = await _create_new_audio_player(audio)
	_audio_players[ticket].position = _position
	_start_audio(_audio_players[ticket], audio.bus == AudioResource.AudioResourceType.MUSIC)
	
	return ticket
