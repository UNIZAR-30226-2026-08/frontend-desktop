extends Control

# ==========================================
# 1. CONFIGURACIÓN DEL CARRUSEL
# ==========================================
var user_games: Array = []
const VISIBLE_CARDS = 4
const CARD_WIDTH = 355 
const SPACING = 25
const SCROLL_STEP = CARD_WIDTH + SPACING 

const VISIBLE_SKINS = 4
const SCROLL_STEP_SKINS = CARD_WIDTH + SPACING

# ==========================================
# 2. REFERENCIAS A NODOS
# ==========================================
@onready var item_icon: TextureRect = %ItemIcon
@onready var skins_tab_container: TabContainer = %SkinsTabContainer
@onready var skins_circle_waiting: TextureRect = %skins_circle_waiting
@onready var username: Label = %Username
@onready var games_played_label: Label = %GamesPlayedLabel
@onready var total_points: Label = %TotalPoints
@onready var logout_button: Button = %LogoutButton
@onready var wins_label: Label = %WinsLabel
@onready var circle_waiting: TextureRect = %circle_waiting
@onready var tab_container: TabContainer = %TabContainer

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

# Variable para guardar la carta seleccionada temporalmente
var currently_selected_card: PanelContainer = null

# ==========================================
# 3. RUTAS A ESCENAS Y DATOS
# ==========================================
const PAST_GAME_CARD_SCENE = preload("res://scenes/components/past_games_card.tscn")
const PROFILE_SKIN_CARD_SCENE = preload("res://scenes/components/profile_skin_card.tscn")

var skins_data = []
var game_history = []

var get_skins_async = func():
	var result = await RestClient.shop_get_user_pieces()
	for r in result:
		skins_data.append(Globals.tokens[r["custom_id"]])
	_load_skins()

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
	
	# Establecer estado visual inicial (mostrar Face1)
	_switch_to_face1()
	
	var resp = await RestClient.user_get_games()
	if resp != {} and resp.has("games"):
		user_games = resp["games"]
		for i in user_games:
			var game_info = await RestClient.user_get_game_summary(i)
			if not game_info == {}:
				game_history.append(game_info)
	
	_load_game_history()
	
	user_info = await RestClient.user_get_info()
	if user_info == {}: return
	username.text = user_info["username"]
	games_played_label.text = str(user_info["num_played_games"])
	wins_label.text = str(user_info["num_won_games"])
	total_points.text = str(int(user_info["exp"]))
	if Globals.tokens.has(user_info["user_piece"]):
		item_icon.texture = load(Globals.tokens[user_info["user_piece"]]["icon"])
	
	get_skins_async.call()

# ==========================================
# 5. LÓGICA DE INTERFAZ (CARAS Y BOTONES)
# ==========================================
func _switch_to_face2() -> void:
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
		RestClient.user_change_piece(currently_selected_card.item_id)
		item_icon.texture = currently_selected_card.item_icon
		_clear_current_selection()
	else:
		Utils.debug("No hay ninguna skin seleccionada para confirmar")

# ==========================================
# 6. LÓGICA DE SELECCIÓN DE SKINS
# ==========================================
func _on_global_skin_selected(selected_id: int) -> void:
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
	
	circle_waiting.stop_loading_animation()
	if len(game_history) == 0:
		tab_container.current_tab = 1
		return
	elif len(game_history) < VISIBLE_CARDS:
		games_left_btn.hide()
		games_right_btn.hide()
	tab_container.current_tab = 2
	for game_data in game_history:
		var card_instance = PAST_GAME_CARD_SCENE.instantiate()
		games_container.add_child(card_instance)
		card_instance.setup(game_data)

func _load_skins() -> void:
	for child in skins_container.get_children():
		child.queue_free()

	skins_circle_waiting.stop_loading_animation()
	if len(skins_data) == 0:
		skins_tab_container.current_tab = 1
		confirm_btn.hide()
		return
	elif len(skins_data) < VISIBLE_CARDS:
		skins_left_btn.hide()
		skins_right_btn.hide()
	skins_tab_container.current_tab = 2
	confirm_btn.show()
	
	for skin_data in skins_data:
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
	if target_x == max_scroll_left:
		games_right_btn.modulate.a = 0
	elif target_x == 0:
		games_left_btn.modulate.a = 0
	
	if direction == 1:
		games_left_btn.modulate.a = 1
	else:
		games_right_btn.modulate.a = 1
	
	var tween = create_tween()
	tween.tween_property(games_container, "position:x", target_x, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _scroll_skins_carousel(direction: int) -> void:
	var total_items = skins_container.get_child_count()
	if total_items <= VISIBLE_SKINS: return 
		
	var max_scroll_left = -((total_items - VISIBLE_SKINS) * SCROLL_STEP_SKINS)
	var target_x = skins_container.position.x - (SCROLL_STEP_SKINS * direction)
	target_x = clamp(target_x, max_scroll_left, 0.0)
	if target_x == max_scroll_left:
		skins_right_btn.modulate.a = 0
	elif target_x == 0:
		skins_left_btn.modulate.a = 0
	
	if direction == 1:
		skins_left_btn.modulate.a = 1
	else:
		skins_right_btn.modulate.a = 1
	
	var tween = create_tween()
	tween.tween_property(skins_container, "position:x", target_x, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# (Tu función de salir del header que ya tenías)
func _on_header_back_action_requested() -> void:
	SceneTransition.change_scene("res://scenes/UI/home_screen.tscn")
