# Global variables
extends Node

# This file defines constants that can be accessed globally by using:
# Globals.<identifier>
# Values are exported and a scene is created so they can be easily modified
# from the interface (Node "Globals" > Inspector)

@export_group('Colors')
@export var WHITE: Color = Color('FFFFFF')
@export var BLACK: Color = Color('222222')

@export_group('Build')
@export var BUILD_TYPE: BuildType = BuildType.DEV

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
