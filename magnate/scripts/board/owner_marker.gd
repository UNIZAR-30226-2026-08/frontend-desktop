class_name OwnerMarker
extends Node2D

var marker_color: Color
var marker_width: float
var marker_height: float = 25.0
var cut_depth: float = 10.0

func _init(color: Color, width: float) -> void:
	marker_color = color
	marker_width = width
	
	show_behind_parent = true

func _draw() -> void:
	# Diseño del polígono hecho por Gema
	var points = PackedVector2Array([
		Vector2(0, 0),
		Vector2(marker_width, 0),
		Vector2(marker_width, marker_height),
		Vector2(marker_width / 2.0, marker_height - cut_depth),
		Vector2(0, marker_height)
	])
	
	draw_polygon(points, PackedColorArray([marker_color]))
	
	points.append(points[0]) 
	draw_polyline(points, Color.WHITE, 2.0, true)
