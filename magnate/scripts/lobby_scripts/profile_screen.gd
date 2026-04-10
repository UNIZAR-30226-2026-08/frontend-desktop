extends Control

# ==========================================
# 1. CONFIGURACIÓN DEL CARRUSEL
# ==========================================
const VISIBLE_CARDS = 4
const CARD_WIDTH = 355 
const SPACING = 25
const SCROLL_STEP = CARD_WIDTH + SPACING 

const VISIBLE_SKINS = 4
const SCROLL_STEP_SKINS = CARD_WIDTH + SPACING

# ==========================================
# 2. REFERENCIAS A NODOS
# ==========================================
@onready var username: Label = %Username
@onready var games_played_label: Label = %GamesPlayedLabel
@onready var total_points: Label = %TotalPoints
@onready var logout_button: Button = %LogoutButton
@onready var wins_label: Label = %WinsLabel

# Botón general de confirmar
@onready var confirm_btn: Button = %ConfirmBtn 

# Partidas
@onready var games_left_btn: Button = %GamesLeftBtn
@onready var games_right_btn: Button = %GamesRightBtn
@onready var games_container: HBoxContainer = %GamesContainer

# Cambio de Caras
@onready var face1: Control = %Face1
@onready var face2: Control = %Face2
@onready var change_skin_btn1: Button = %ChangeSkinBtn1
@onready var change_skin_btn2: Button = %ChangeSkinBtn2

# Skins
@onready var skins_container: HBoxContainer = %SkinsContainer
@onready var skins_left_btn: Button = %SkinsLeftBtn
@onready var skins_right_btn: Button = %SkinsRightBtn

var user_info: Dictionary = {}
var user_tokens: Array = []

# Variable para guardar la carta seleccionada temporalmente
var currently_selected_card: PanelContainer = null

# ==========================================
# 3. RUTAS A ESCENAS Y DATOS
# ==========================================
const PAST_GAME_CARD_SCENE = preload("res://scenes/components/past_games_card.tscn")
const PROFILE_SKIN_CARD_SCENE = preload("res://scenes/components/profile_skin_card.tscn")

var dummy_skins_data = [
	{ "id": "skin_01", "name": "Token 1", "icon_path": "res://assets/icons/characters/sombrero_closeup.png", "state": 0 }, # IN_USE
	{ "id": "skin_02", "name": "Token 2", "icon_path": "res://assets/icons/characters/sombrero_closeup.png", "state": 2 }, # SELECTABLE
	{ "id": "skin_03", "name": "Token 3", "icon_path": "res://assets/icons/characters/sombrero_closeup.png", "state": 2 },
	{ "id": "skin_04", "name": "Token 4", "icon_path": "res://assets/icons/characters/sombrero_closeup.png", "state": 2 },
	{ "id": "skin_05", "name": "Token 5", "icon_path": "res://assets/icons/characters/sombrero_closeup.png", "state": 2 }
]

var dummy_history_json = [
	{ "time_start": "14/03/2026 10:20", "position": "#1", "player_names": ["Lucas", "Crist", "July", "Mike"], "reward_amount": 400, "time_end": "14/03/2026 22:05" },
	{ "time_start": "12/03/2026 15:30", "position": "#2", "player_names": ["July", "Lucas", "Ana"], "reward_amount": 100, "time_end": "12/03/2026 21:10" },
	{ "time_start": "10/03/2026 09:00", "position": "#4", "player_names": ["Maria", "Pedro", "Juan", "Lucas"], "reward_amount": 0, "time_end": "10/03/2026 10:30" },
	{ "time_start": "08/03/2026 18:45", "position": "#2", "player_names": ["Crist", "Lucas"], "reward_amount": 10, "time_end": "08/03/2026 20:00" },
	{ "time_start": "09/03/2026 18:45", "position": "#2", "player_names": ["Crist", "Lucas", "Jaimy"], "reward_amount": 40, "time_end": "09/03/2026 20:00" }
]

# ==========================================
# 4. FUNCIÓN INICIAL
# ==========================================
func _ready() -> void:
	# Conectar botones de partidas
	games_left_btn.pressed.connect(_scroll_custom_carousel.bind(-1))
	games_right_btn.pressed.connect(_scroll_custom_carousel.bind(1))
	
	# Conectar botones de skins
	skins_left_btn.pressed.connect(_scroll_skins_carousel.bind(-1))
	skins_right_btn.pressed.connect(_scroll_skins_carousel.bind(1))
	
	# Conectar botones de interfaz
	change_skin_btn1.pressed.connect(_switch_to_face2)
	change_skin_btn2.pressed.connect(_switch_to_face1)
	confirm_btn.pressed.connect(_on_confirm_pressed)
	
	logout_button.pressed.connect(RestClient.user_logout)
	
	# Cargar datos
	_load_game_history()
	_load_dummy_skins()
	
	# Establecer estado visual inicial (mostrar Face1)
	_switch_to_face1()
	
	user_info = await RestClient.user_get_info()
	if user_info == {}: return
	username.text = user_info["username"]
	games_played_label.text = str(user_info["num_played_games"])
	wins_label.text = str(user_info["num_won_games"])
	total_points.text = str(user_info["points"])

# ==========================================
# 5. LÓGICA DE INTERFAZ (CARAS Y BOTONES)
# ==========================================
func _switch_to_face2() -> void:
	user_tokens = await RestClient.shop_get_user_pieces()
	Utils.debug(str(user_tokens)) # TODO: Aún no sé lo que viene aquí exactamente
	change_skin_btn1.hide()
	change_skin_btn2.show()
	face1.hide()
	face2.show()

func _switch_to_face1() -> void:
	_clear_current_selection() # Limpiamos selección al salir de Face2
	change_skin_btn2.hide()
	change_skin_btn1.show()
	face2.hide()
	face1.show()

func _on_confirm_pressed() -> void:
	if currently_selected_card != null:
		Utils.debug("Guardando skin: " + str(currently_selected_card.item_id))
		# TODO: Aquí irá el guardado real en servidor
		_clear_current_selection()
	else:
		Utils.debug("No hay ninguna skin seleccionada para confirmar")

# ==========================================
# 6. LÓGICA DE SELECCIÓN DE SKINS
# ==========================================
func _on_global_skin_selected(selected_id: String) -> void:
	# Si ya había algo seleccionado, lo reseteamos
	if currently_selected_card != null:
		currently_selected_card.current_state = currently_selected_card.State.SELECTABLE
	
	# Buscamos la nueva carta y la marcamos
	for card in skins_container.get_children():
		if card.item_id == selected_id:
			card.current_state = card.State.SELECTED
			currently_selected_card = card
			break

func _clear_current_selection() -> void:
	if currently_selected_card != null:
		currently_selected_card.current_state = currently_selected_card.State.SELECTABLE
		currently_selected_card = null
		Utils.debug("Selección limpiada")

# ==========================================
# 7. CARGADORES DE CONTENIDO (INSTANCIAR)
# ==========================================
func _load_game_history() -> void:
	for child in games_container.get_children():
		child.queue_free()
		
	for game_data in dummy_history_json:
		var card_instance = PAST_GAME_CARD_SCENE.instantiate()
		games_container.add_child(card_instance)
		card_instance.setup(game_data)

func _load_dummy_skins() -> void:
	for child in skins_container.get_children():
		child.queue_free()
		
	for skin_data in dummy_skins_data:
		var card_instance = PROFILE_SKIN_CARD_SCENE.instantiate()
		skins_container.add_child(card_instance)
		card_instance.skin_selected.connect(_on_global_skin_selected)
		card_instance.setup_profile_item(skin_data)

# ==========================================
# 8. LÓGICA DE SCROLL (CARRUSELES)
# ==========================================
func _scroll_custom_carousel(direction: int) -> void:
	var total_items = games_container.get_child_count()
	if total_items <= VISIBLE_CARDS: return 
		
	var max_scroll_left = -((total_items - VISIBLE_CARDS) * SCROLL_STEP)
	var target_x = games_container.position.x - (SCROLL_STEP * direction)
	target_x = clamp(target_x, max_scroll_left, 0.0)
	
	var tween = create_tween()
	tween.tween_property(games_container, "position:x", target_x, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _scroll_skins_carousel(direction: int) -> void:
	var total_items = skins_container.get_child_count()
	if total_items <= VISIBLE_SKINS: return 
		
	var max_scroll_left = -((total_items - VISIBLE_SKINS) * SCROLL_STEP_SKINS)
	var target_x = skins_container.position.x - (SCROLL_STEP_SKINS * direction)
	target_x = clamp(target_x, max_scroll_left, 0.0)
	
	var tween = create_tween()
	tween.tween_property(skins_container, "position:x", target_x, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# (Tu función de salir del header que ya tenías)
func _on_header_back_action_requested() -> void:
	SceneTransition.change_scene("res://scenes/UI/home_screen.tscn")
