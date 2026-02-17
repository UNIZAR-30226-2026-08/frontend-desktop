extends Control

@export var player_icon_big_scene: PackedScene 

func _ready():
	# Datos de prueba
	var datos_de_prueba = [
		{
			"name": "Luquinpadawan", 
			"type": "human", 
			"custom_texture": preload("res://assets/icons/characters/barco_closeup.png")
		},
		{
			"name": "NdRivas", 
			"type": "human", 
			"custom_texture": preload("res://assets/icons/characters/burguer_closeup.png")
		}
	]
	update_lobby(datos_de_prueba)

func update_lobby(players_connected: Array):
	var player_list = $VBoxContainer/MarginContainer/PlayerList
	
	# Limpiamos los slots antiguos
	for child in player_list.get_children():
		child.queue_free()
		
	# Creamos los 4 slots
	for i in range(4):
		var slot = player_icon_big_scene.instantiate()
		player_list.add_child(slot)
		
		# CONECTAMOS LAS SEÑALES: Esto es vital para que el contador responda a los botones
		slot.bot_added_locally.connect(update_player_count)
		slot.bot_removed_locally.connect(update_player_count)
		
		if i < players_connected.size():
			var p = players_connected[i]
			# Extraemos la textura del diccionario
			var tex = p.get("custom_texture", null) 
			# Pasamos los 3 parámetros: nombre, tipo y textura personalizada
			slot.setup(p.name, p.type, tex)
		else:
			# Estado de espera
			slot.setup("", "waiting")

	# Primera actualización del texto al cargar el lobby
	update_player_count()

# Nueva función que cuenta cuántos slots están ocupados realmente
func update_player_count():
	var player_list = $VBoxContainer/MarginContainer/PlayerList
	var count = 0
	
	# Esperamos un frame a que los nodos se procesen si es necesario, 
	# pero como contamos estados, podemos hacerlo directo:
	for slot in player_list.get_children():
		# Accedemos a la variable 'current_state' del script del slot
		# Si el estado es PLAYER (1) o BOT (2), sumamos. WAITING es (0).
		if slot.current_state != 0: 
			count += 1
	
	# Actualizamos el Label. Asegúrate de que la ruta sea la correcta:
	if has_node("VBoxContainer/player_count_label"):
		$VBoxContainer/player_count_label.text = "Número de jugadores: " + str(count)
	else:
		# Si te da este error, revisa si el nodo se llama 'player_number' o 'player_count_label'
		print("Error: No encuentro el nodo del contador en VBoxContainer")
