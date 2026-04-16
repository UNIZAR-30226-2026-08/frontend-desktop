# Global variables
extends Node

# This file defines constants that can be accessed globally by using:
# Globals.<identifier>
# Values are exported and a scene is created so they can be easily modified
# from the interface (Node "Globals" > Inspector)

@export_group('Colors')
@export var WHITE: Color = Color('FFFFFF')
@export var BLACK: Color = Color('222222')

@export_group('Symbols')
@export var SYMBOL_CURRENCY: String = "M"

@export_group('Build')
@export var BUILD_TYPE: BuildType = BuildType.DEV

@export_group('Audio')
@export_subgroup('UI')
@export var AUDIO_CLICK = preload("uid://dv18pd6ydtscm")
@export var BUTTON_BACK = preload("uid://c4fu6i4iyerwh")
@export_subgroup('SFX')
@export var AUDIO_CARDFLIP = preload("uid://cmr3nua1ihvr3")
@export var AUDIO_FANTASY = preload("uid://bqdmfnsvr8hjv")
@export var AUDIO_TRAM = preload("uid://tl68fssfd15t")
@export var AUDIO_TOKEN_MOVE = preload("uid://ckr1ila7b38qf")
@export var AUDIO_DICE_ROLL = preload("uid://b5qpsxiqhbtcf")
@export var AUDIO_PLAYER_HOP = preload("uid://ckr1ila7b38qf")
@export var AUDIO_PARKING = preload("uid://chbctadlkgd30")
@export_subgroup('Music')
@export var AUDIO_MENUMUSIC = preload("uid://cgqfmnsjmcjqc")
@export var AUDIO_BOARDMUSIC = preload("uid://dqwe63a21r68t")

@export_group('Backend URLs')
@export_subgroup('REST')
@export var REST_BASE_URL = "http://127.0.0.1:8000"
@export_subgroup('WS')
@export var WS_BASE_URL = "ws://127.0.0.1:8000/ws"

enum BuildType {
	DEV,
	PROD,
}

const BOARD_JSON_FILEPATH = "res://assets/game_info/board.json"
enum TileType {
	PROPERTY,
	FANTASY,
	START,
	SERVER,
	TRAM,
	BRIDGE,
	GO_TO_JAIL,
	JAIL,
	PARKING,
}

var tokens = {}
var emojis = {}

# Universal behaviours
func _ready() -> void:
	# On logout go to landing page
	RestClient.logout.connect(SceneTransition.change_scene.bind("res://scenes/UI/landing_screen.tscn"))
	# On login go to home page
	RestClient.login.connect(SceneTransition.change_scene.bind("res://scenes/UI/home_screen.tscn"))
	# Load tokens and emojis
	var json_string = FileAccess.get_file_as_string("res://assets/game_info/items.json")
	var data = JSON.parse_string(json_string)
	for t in data.get("token", []):
		t["icon"] = "res://assets/icons/characters/" + t["icon"]
		tokens[t["id"]] = t
	for e in data.get("emoji", []):
		e["icon"] = "res://assets/icons/emotes/" + e["icon"]
		emojis[e["id"]] = e
