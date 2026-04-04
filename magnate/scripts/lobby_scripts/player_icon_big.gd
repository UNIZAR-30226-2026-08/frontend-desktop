extends Panel

enum State {WAITING, PLAYER, BOT}
var current_state = State.WAITING
var rotation_tween: Tween

const BOT_PHOTO = preload("res://assets/images/bg_city.jpg")

signal bot_added_locally
signal bot_removed_locally

func setup(name_text: String, player_type: String, custom_texture: Texture2D = null):
	if player_type == "waiting":
		set_state(State.WAITING)
	elif player_type.to_lower() == "bot":
		set_state(State.BOT)
		$VBoxContainer/Name.text = name_text
		$PlayerIcon.texture = BOT_PHOTO
		$PlayerIcon.scale = Vector2(1, 1)
	else:
		set_state(State.PLAYER)
		$VBoxContainer/Name.text = name_text
		# Si custom_texture es null, el icono se verá vacío o con la foto anterior
		$PlayerIcon.texture = custom_texture
		$PlayerIcon.scale = Vector2(0.7, 0.7)
func set_state(new_state):
	current_state = new_state
	
	var is_waiting = (new_state == State.WAITING)
	var is_bot = (new_state == State.BOT)
	
	# 1. Visibilidad de elementos comunes (Avatar y Nombre)
	$VBoxContainer.visible = !is_waiting
	$PlayerIcon.visible = !is_waiting
	$TopRightIcon.visible = !is_waiting
	$Gradient.visible = !is_waiting
	
	# 2. Elementos específicos de "Esperando"
	$circle_waiting.visible = is_waiting
	$waiting_label.visible = is_waiting
	
	# 3. Lógica de botones (Intercambio)
	$AddBotButton.visible = is_waiting
	# El botón de eliminar solo existe si el slot es un BOT
	if has_node("RemoveBotButton"):
		$RemoveBotButton.visible = is_bot
	
	# 4. Animación y Modulate
	if is_waiting:
		start_loading_animation()
		modulate = Color(1, 1, 1, 1)
	else:
		stop_loading_animation()
		modulate = Color(1, 1, 1, 1)
		
		# Actualizar icono de esquina (TopRightIcon)
		if is_bot:
			$TopRightIcon.texture = preload("res://assets/icons/ia.svg")
		else:
			$TopRightIcon.texture = preload("res://assets/icons/single_player.svg")

func start_loading_animation():
	if rotation_tween: rotation_tween.kill()
	rotation_tween = create_tween().set_loops()
	rotation_tween.tween_property($circle_waiting, "rotation_degrees", 360, 2.0).from(0)

func stop_loading_animation():
	if rotation_tween:
		rotation_tween.kill()
		$circle_waiting.rotation_degrees = 0

# --- SEÑALES DE BOTONES ---

func _on_add_bot_button_pressed():
	setup("", "bot")
	bot_added_locally.emit()

func _on_remove_bot_button_pressed():
	# Al eliminar, volvemos al estado de espera
	setup("", "waiting")
	bot_removed_locally.emit()
