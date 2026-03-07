class_name PlayerHUD
extends CanvasLayer

const CARD_SCENE = preload("res://scenes/board/hud/PlayerHUDCard.tscn")

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
	
	container.add_theme_constant_override("separation", 30)
	
	container.grow_horizontal = Control.GROW_DIRECTION_BEGIN 
	container.grow_vertical = Control.GROW_DIRECTION_BOTH    
	
	container.position.x -= 50 
	
	screen_filler.add_child(container)

func setup_players(players_data: Array[Dictionary]) -> void:
	for child in container.get_children():
		child.queue_free()
	cards.clear()
		
	for p in players_data:
		var model = p["model"]
		
		var p_id: String = str(model.get("id")) if model.get("id") != null else "0"
		
		var raw_name = model.get("player_name") if model.get("player_name") != null else model.get("name")
		var p_name: String = str(raw_name) if raw_name != null else "Player"
		
		var p_color: Color = model.get("color") if model.get("color") != null else Color.WHITE
		
		var p_balance: int = int(model.get("balance")) if model.get("balance") != null else 0
		
		var card = CARD_SCENE.instantiate()
		container.add_child(card)
		
		card.setup(p_id, p_name, p_color, p_balance)
		
		cards[p_id] = card

func update_player_stats(p_id: String, new_balance: int, property_count: int) -> void:
	if cards.has(p_id):
		var card = cards[p_id]
		card.update_balance(new_balance)
		card.update_properties(property_count)
