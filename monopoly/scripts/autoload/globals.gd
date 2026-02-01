# Global variables
extends Node

# This file defines constants that can be accessed globally by using:
# Globals.<identifier>
# Values are exported and a scene is created so they can be easily modified
# from the interface (Node "Globals" > Inspector)

@export_group('Colors')
@export var WHITE: Color = Color('FFFFFF')
@export var BLACK: Color = Color('000000')
