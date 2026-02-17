extends Control

@export var player_row_scene: PackedScene

# Medallas
const MEDAL_GOLD = preload("res://assets/icons/medals/gold.png")
const MEDAL_SILVER = preload("res://assets/icons/medals/silver.png")
const MEDAL_BRONZE = preload("res://assets/icons/medals/bronze.png")

# Ahora usamos valores numéricos para los puntos para poder ordenarlos
var fake_players = [
	{"name": "Luquinpadawan", "points": 14967},
	{"name": "NdRivas", "points": 69},
	{"name": "MangelRoyo", "points": 18500},
	{"name": "CrisEnvy", "points": 8900}
]

func _ready():
	load_players()

func load_players():
	# 1. Limpiar la lista existente
	var player_list = $VBoxContainer/MarginContainer/PlayerList
	for child in player_list.get_children():
		child.queue_free()
	
	# 2. Ordenar el array de mayor a menor
	fake_players.sort_custom(func(a, b): return a["points"] > b["points"])
	
	# 3. Instanciar las filas ya ordenadas
	for i in range(fake_players.size()):
		var data = fake_players[i]
		var new_row = player_row_scene.instantiate()
		player_list.add_child(new_row)
		
		# Determinamos la medalla según la posición (i)
		var medal_tex = null
		if i == 0: medal_tex = MEDAL_GOLD
		elif i == 1: medal_tex = MEDAL_SILVER
		elif i == 2: medal_tex = MEDAL_BRONZE
		
		# Pasamos la medalla al setup (puede ser null)
		new_row.setup(data["name"], data["points"], medal_tex)
