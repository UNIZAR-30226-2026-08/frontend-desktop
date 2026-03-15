class_name AudioResource
extends RefCounted

# Class to represent an audio track, can control pitch, randomness,
# autoplay and specific audio.

enum AudioResourceType {
	MUSIC,
	SFX,
	UI
}

var audio_track: AudioStream
var pitch: float = 1
var pitch_random_margin: float = 0
var volume_db: float = 0
var autoplay: bool
var bus: AudioResourceType

const MUSIC_PRESET: Dictionary = {
	"_pitch": 1.,
	"_pitch_random_margin": 0.,
	"_volume_db": 0.,
	"_autoplay": true,
	"_bus": AudioResourceType.MUSIC
}
const SFX_PRESET: Dictionary = {
	"_pitch": 1.,
	"_pitch_random_margin": 0.,
	"_volume_db": 0.,
	"_autoplay": false,
	"_bus": AudioResourceType.SFX
}

const UI_PRESET: Dictionary = {
	"_pitch": 1.,
	"_pitch_random_margin": 0.,
	"_volume_db": 0.,
	"_autoplay": false,
	"_bus": AudioResourceType.UI
}

const PRESETS: Dictionary[AudioResourceType, Dictionary] = {
	AudioResourceType.MUSIC: MUSIC_PRESET,
	AudioResourceType.SFX: SFX_PRESET,
	AudioResourceType.UI: UI_PRESET
}

static func from_type(_audio_track: AudioStream, type: AudioResourceType) -> AudioResource:
	var preset = PRESETS.get(type, SFX_PRESET)
	var instance = AudioResource.new(
		_audio_track,
		preset.get("_pitch", 1.),
		preset.get("_pitch_random_margin", 0.),
		preset.get("_volume_db", 0.),
		preset.get("_autoplay", false),
		preset.get("_bus", AudioResourceType.SFX)
	)
	return instance

func _init(_audio_track: AudioStream, _pitch: float, _pitch_random_margin: float,
		_volume_db: float, _autoplay: bool, _bus: AudioResourceType):
	audio_track = _audio_track
	pitch = _pitch
	pitch_random_margin = _pitch_random_margin
	volume_db = _volume_db
	autoplay = _autoplay
	bus = _bus
