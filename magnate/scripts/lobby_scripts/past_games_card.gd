extends PanelContainer  # O el tipo de nodo raíz que sea tu PastGameCard, asumo que es PanelContainer por la forma redondeada

# === Referencias a Nodos con Nombres Únicos ===
# (¡Recuerda activar el check "Use as Unique Name" (%) en el editor para estos nodos!)

@onready var time_start_label: Label = %TimeStartLabel
@onready var position_label: Label = %PositionLabel
@onready var reward_amount_label: Label = %RewardAmountLabel
@onready var time_end_label: Label = %TimeEndLabel

@onready var name1_label: Label = %Name1
@onready var name2_label: Label = %Name2
@onready var name3_label: Label = %Name3
@onready var name4_label: Label = %Name4

# Puestos de los jugadores principales (PlaceContainers, no nombres)
# Estos contenedores contienen el label del número de puesto (ej: "1.") y el label del nombre
@onready var place1_container: HBoxContainer = %Place1
@onready var place2_container: HBoxContainer = %Place2
@onready var place3_container: HBoxContainer = %Place3
@onready var place4_container: HBoxContainer = %Place4

# === Función Principal para Configurar la Tarjeta con Datos ===
# game_data: Un diccionario que contiene toda la información de la partida.
func setup(game_data: Dictionary) -> void:
	# 1. Configurar los Labels de texto simples
	# get_node_or_null para mayor seguridad si los nodos no existen aún
	var _money = game_data["final_money"][RestClient.username]
	var player_names = game_data["final_money"].keys()
	player_names.sort_custom(func(a, b): return game_data["final_money"][a] > game_data["final_money"][b])
	var _position = player_names.find(RestClient.username)
	if time_start_label:
		time_start_label.text = game_data.get("start_date", "---")
	if position_label:
		position_label.text = "#" + str(_position)
	if reward_amount_label:
		reward_amount_label.text = str(_money)
	if time_end_label:
		time_end_label.text = "FIN: " + game_data.get("end_date", "---")

	# 2. Configurar la lista de jugadores y visibilidad de puestos
	var num_players = player_names.size()

	# Configurar los nombres para los puestos 1-4 (máximo)
	# Si hay menos jugadores, el label correspondiente tendrá un texto vacío por defecto.
	if name1_label:
		name1_label.text = player_names[0] if num_players >= 1 else ""
	if name2_label:
		name2_label.text = player_names[1] if num_players >= 2 else ""
	if name3_label:
		name3_label.text = player_names[2] if num_players >= 3 else ""
	if name4_label:
		name4_label.text = player_names[3] if num_players >= 4 else ""

	# 3. Ocultar los contenedores de puestos excedentes
	# Obtenemos un array de los contenedores de puestos para iterar sobre ellos
	var place_containers = [place1_container, place2_container, place3_container, place4_container]
	
	# Usamos un bucle para ocultar los puestos que no corresponden al número de jugadores
	for i in range(place_containers.size()):
		if place_containers[i]:
			if i < num_players:
				# Mostrar el puesto si el jugador está en la lista
				place_containers[i].visible = true
			else:
				# Ocultar el puesto si el jugador no está en la lista
				place_containers[i].visible = false


# === Función para configurar visibilidad de puestos dinámicamente ===
# Esta función es útil si quieres ocultar puestos de forma dinámica fuera de la función setup
func set_places_visibility(num_players: int) -> void:
	# Asegurarse de que el número de jugadores esté dentro del rango 0-4
	num_players = clamp(num_players, 0, 4)
	
	# Obtenemos un array de los contenedores de puestos
	var place_containers = [place1_container, place2_container, place3_container, place4_container]
	
	# Iterar sobre los contenedores y ocultar los excedentes
	for i in range(place_containers.size()):
		if place_containers[i]:
			place_containers[i].visible = (i < num_players)
