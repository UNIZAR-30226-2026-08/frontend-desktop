class_name PlayerHUD
extends CanvasLayer
const CARD_SCENE = preload("res://scenes/board/players/player_card.tscn")
signal player_selected(p_id: int)
var is_hidden: bool = false
var base_x_pos: float = 0.0
var container: VBoxContainer
var cards: Dictionary = {}
var emoji_data: Array = []

func update_turn_visuals() -> void:
	for card in cards.values():
		card.update_turn_visuals()

func _init() -> void:
	layer = 1 
	var screen_filler = Control.new()
	screen_filler.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_filler.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	add_child(screen_filler)
	
	container = VBoxContainer.new()
	container.name = "HUDCardStack"
	container.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	
	container.add_theme_constant_override("separation", 75)
	
	container.grow_horizontal = Control.GROW_DIRECTION_BEGIN 
	container.grow_vertical = Control.GROW_DIRECTION_BOTH    
	
	container.position.x -= 50 
	
	screen_filler.add_child(container)
	
func _ready() -> void:
	await get_tree().process_frame
	base_x_pos = container.position.x
	emoji_data = _load_emojis()
	WsClient.chat_message.connect(_on_chat_message_for_emoji)

func _load_emojis() -> Array:
	var file = FileAccess.open("res://assets/game_info/items.json", FileAccess.READ)
	if not file:
		return []
	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()
	if err != OK:
		return []
	var data = json.get_data()
	if not data is Dictionary or not data.has("emoji"):
		return []
	return data["emoji"]

func _on_chat_message_for_emoji(message: Dictionary) -> void:
	var text: String = message.get("msg", "")
	var p_name: String = message.get("user", "")
	
	if not text.begins_with("/emoji "):
		return
	
	var parts = text.split(" ")
	if parts.size() < 2 or not parts[1].is_valid_int():
		return
	
	var emoji_id = parts[1].to_int()
	
	var target_id = -1
	for id in cards:
		var card = cards[id]
		if card.get_player_name() == p_name:
			target_id = id
			break
	
	if target_id == -1:
		return
	
	var icon_path = ""
	for e in emoji_data:
		if e.get("id", -1) == emoji_id:
			icon_path = "res://assets/icons/emotes/" + e.get("icon", "")
			break
	
	if icon_path.is_empty() or not ResourceLoader.exists(icon_path):
		return
	
	_show_emoji_on_card(target_id, icon_path)

func _show_emoji_on_card(p_id: int, icon_path: String) -> void:
	var card = cards[p_id]
	
	var old = card.get_node_or_null("EmojiFloat")
	if is_instance_valid(old):
		old.queue_free()
	
	var img = TextureRect.new()
	img.name = "EmojiFloat"
	img.texture = load(icon_path)
	img.custom_minimum_size = Vector2(56, 56)
	img.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	img.z_index = 10
	img.position = Vector2(-card.size.x + 20, -60)
	
	card.add_child(img)
	_bounce_step(img, img.position.y, true, 0)

func _bounce_step(img: TextureRect, start_y: float, going_up: bool, count: int) -> void:
	if not is_instance_valid(img):
		return
	
	var max_bounces = 8
	if count >= max_bounces:
		var fade = img.create_tween()
		fade.tween_property(img, "modulate:a", 0.0, 0.5)
		fade.tween_callback(func():
			if is_instance_valid(img):
				img.queue_free()
		)
		return
	
	var target_y = start_y - 10 if going_up else start_y
	var tween = img.create_tween()
	tween.tween_property(img, "position:y", target_y, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		_bounce_step(img, start_y, not going_up, count + 1)
	)

func toggle_hud_visibility(to_hide: bool) -> void:
	if is_hidden == to_hide: return
	is_hidden = to_hide
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	var target_x = base_x_pos + 400.0 if to_hide else base_x_pos
	var target_alpha = 0.0 if to_hide else 1.0
	tween.tween_property(container, "position:x", target_x, 0.5)
	tween.parallel().tween_property(container, "modulate:a", target_alpha, 0.5)
	
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE if to_hide else Control.MOUSE_FILTER_PASS

func setup_players(players_data: Array[PlayerModel]) -> void:
	for child in container.get_children():
		child.queue_free()
	cards.clear()
		
	for model in players_data:
		var p_id: int = model.id
		var p_name = model.player_name
		
		Utils.debug("✅ Jugador creado -> Nombre: " + p_name + " | ID exacto: '" + str(p_id) + "'")
		
		var p_color: Color = model.color
		var p_balance: int = model.balance
		
		var card = CARD_SCENE.instantiate()
		container.add_child(card)
		
		card.setup(p_id, p_name, p_color, p_balance)
		card.clicked.connect(func(id): player_selected.emit(id))
		cards[p_id] = card
		model.player_updated.connect(update_player_stats)

func update_player_stats(p_id: int) -> void:
	if not cards.has(p_id): return
	var card = cards[p_id]
	if ModelManager.get_player(p_id).surrendered:
		card.queue_free()
		return
	var new_balance: int = ModelManager.get_player_balance(p_id)
	var property_count: int = len(ModelManager.get_player_properties(p_id))
	card.update_balance(new_balance)
	card.update_properties(property_count)

func set_selection_mode(active: bool) -> void:
	if active:
		layer = 100
		for id in cards:
			var card = cards[id]
			if id == ModelManager.game.my_id:
				card.modulate.a = 0.5 
				card.mouse_filter = Control.MOUSE_FILTER_IGNORE
				card.mouse_default_cursor_shape = Control.CURSOR_ARROW
			else:
				card.modulate.a = 1.0
				card.mouse_filter = Control.MOUSE_FILTER_STOP
				card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	else:
		layer = 1
		for card in cards.values():
			card.modulate.a = 1.0
			card.mouse_filter = Control.MOUSE_FILTER_STOP
			card.mouse_default_cursor_shape = Control.CURSOR_ARROW
