extends Control

@export var player_row_scene: PackedScene

# Ejemplo de datos (esto te llegaría de tu lógica de juego o servidor)
var fake_players = [
	{"name": "Evil Rabbit", "status": "Last seen 5 months ago", "icon": preload("res://assets/icons/pawn.svg")},
	{"name": "Mad Dog", "status": "Online", "icon": preload("res://assets/icons/pawn.svg")},
]

func _ready():
	load_players()

func load_players():
	# 1. Limpiamos la lista por si acaso había algo
	for child in $VBoxContainer/MarginContainer/PlayerList.get_children():
		child.queue_free()
	
	# 2. Creamos una fila por cada jugador
	for data in fake_players:
		var new_row = player_row_scene.instantiate()
		# Añadimos la fila al VBoxContainer de la lista
		$VBoxContainer/MarginContainer/PlayerList.add_child(new_row)
		# Pasamos los datos
		new_row.setup(data["name"], data["status"], data["icon"])
		
	var total_jugadores = $VBoxContainer/MarginContainer/PlayerList.get_child_count()
	$VBoxContainer/player_number.text = "Número de jugadores: " + str(total_jugadores)
