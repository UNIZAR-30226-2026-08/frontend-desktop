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
@export_subgroup('SFX')
@export var AUDIO_CARDFLIP = preload("uid://cmr3nua1ihvr3")
@export var AUDIO_FANTASY = preload("uid://bqdmfnsvr8hjv")
@export var AUDIO_TRAM = preload("uid://tl68fssfd15t")
@export var AUDIO_TOKEN_MOVE = preload("uid://ckr1ila7b38qf")
@export var AUDIO_DICE_ROLL = preload("uid://b5qpsxiqhbtcf")
@export_subgroup('Music')
@export var AUDIO_MENUMUSIC = preload("uid://cgqfmnsjmcjqc")
@export var AUDIO_BOARDMUSIC = preload("uid://dqwe63a21r68t")

@export_group('Backend URLs')
@export_subgroup('REST')
@export var REST_BASE_URL = ""
@export_subgroup('WS')
@export var WS_BASE_URL = ""

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
