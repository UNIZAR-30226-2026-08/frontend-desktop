class_name PlayerHUD
extends CanvasLayer

const CARD_SCENE = preload("res://scenes/board/players/player_card.tscn")

# Para hacerlo clickable
signal player_selected(p_id: String)

var is_hidden: bool = false
var base_x_pos: float = 0.0

var container: VBoxContainer
var cards: Dictionary = {}

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
	
func toggle_hud_visibility(to_hide: bool) -> void:
	if is_hidden == to_hide: return
	is_hidden = to_hide

	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	var target_x = base_x_pos + 400.0 if to_hide else base_x_pos
	var target_alpha = 0.0 if to_hide else 1.0

	tween.tween_property(container, "position:x", target_x, 0.5)
	tween.parallel().tween_property(container, "modulate:a", target_alpha, 0.5)
	
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE if to_hide else Control.MOUSE_FILTER_PASS

func setup_players(players_data: Array[Dictionary]) -> void:
	for child in container.get_children():
		child.queue_free()
	cards.clear()
		
	for p in players_data:
		var model = p["model"]
		var p_id: String = str(model.get("id")) if model.get("id") != null else "0"
		var raw_name = model.get("player_name") if model.get("player_name") != null else model.get("name")
		var p_name: String = str(raw_name) if raw_name != null else "Player"
		
		print("✅ Jugador creado -> Nombre: ", p_name, " | ID exacto: '", p_id, "'")
		
		var p_color: Color = model.get("color") if model.get("color") != null else Color.WHITE
		
		var p_balance: int = int(model.get("balance")) if model.get("balance") != null else 0
		
		var card = CARD_SCENE.instantiate()
		container.add_child(card)
		
		card.setup(p_id, p_name, p_color, p_balance)
		
		# 👇 Conectamos el clic de la tarjeta hacia el HUD general
		card.clicked.connect(func(id): player_selected.emit(id))
		
		cards[p_id] = card

func update_player_stats(p_id: String, new_balance: int, property_count: int) -> void:
	if cards.has(p_id):
		var card = cards[p_id]
		card.update_balance(new_balance)
		card.update_properties(property_count)

func set_selection_mode(active: bool, my_player_id: String = "") -> void:
	if active:
		layer = 100 # Lo ponemos por encima del BlurryBg
		
		# Recorremos todas las tarjetas usando sus IDs
		for id in cards:
			var card = cards[id]
			
			if id == my_player_id:
				# ❌ TU TARJETA: La oscurecemos y bloqueamos clics
				card.modulate.a = 0.5 
				card.mouse_filter = Control.MOUSE_FILTER_IGNORE
				card.mouse_default_cursor_shape = Control.CURSOR_ARROW
			else:
				# ✅ LAS DEMÁS: Brillantes y con la "manita" para hacer clic
				card.modulate.a = 1.0
				card.mouse_filter = Control.MOUSE_FILTER_STOP
				card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	else:
		layer = 1 # Lo devolvemos a su sitio
		
		# Restauramos todas las tarjetas a la normalidad
		for card in cards.values():
			card.modulate.a = 1.0
			card.mouse_filter = Control.MOUSE_FILTER_STOP
			card.mouse_default_cursor_shape = Control.CURSOR_ARROW
