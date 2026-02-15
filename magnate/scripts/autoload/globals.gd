# Global variables
extends Node

# This file defines constants that can be accessed globally by using:
# Globals.<identifier>
# Values are exported and a scene is created so they can be easily modified
# from the interface (Node "Globals" > Inspector)

@export_group('Colors')
@export var WHITE: Color = Color('FFFFFF')
@export var BLACK: Color = Color('222222')

@export_group('Dimensions')
@export var GAP_LENGTH: int = 40 # Número aleatorio, cambiará
@export var TILE_SHORT_SIDE_LENGTH: int = 80 # Número aleatorio, cambiará
@export var TILE_LONG_SIDE_LENGTH: int = 160 # Número aleatorio, cambiará
@export var BRIDGE_LONG_SIDE_LENGTH: int = 2 * 160 + GAP_LENGTH # Número aleatorio, cambiará
