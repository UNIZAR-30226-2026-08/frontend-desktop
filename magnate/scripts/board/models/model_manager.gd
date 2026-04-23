class_name MagnateModelManager
extends Node2D

signal game_initialized

# Señales útiles para que la UI reaccione instantáneamente a los cambios
signal property_updated(property_id: int)
signal player_balance_changed(player_id: int, new_balance: int)

# Modelos
var game: GameModel

func initialize_game(game_state: Dictionary) -> void:
	# Initialize PlayerModels
	var json_text = FileAccess.open("res://assets/game_info/board.json", FileAccess.READ).get_as_text()
	var board_info = JSON.parse_string(json_text)
	var player_models: Array[PlayerModel] = []
	var player_colors: Array = board_info["playerColors"]
	for idx in len(game_state["ordered_players"]):
		var color = Color(player_colors[idx])
		var player_name = (await RestClient.fetch_user_name_and_piece(game_state["ordered_players"][idx])).get("username", "Desconocido")
		var player = PlayerModel.new(game_state["ordered_players"][idx], player_name, color)
		player.balance = int(game_state["money"][str(player.id)])
		player.current_tile_id = game_state["positions"][str(player.id)]
		player.is_in_jail = game_state["jail_remaining_turns"].has(str(player.id))
		player.jail_turn_count = 3 - game_state["jail_remaining_turns"].get(str(player.id), 3)
		player_models.append(player)
	
	# Initialize PropertyModels
	json_text = FileAccess.open("res://assets/game_info/money.json", FileAccess.READ).get_as_text()
	var property_list = JSON.parse_string(json_text)["tiles"]
	var property_info = {}
	for p in property_list: property_info[p["id"]] = p
	var property_models: Dictionary[String, PropertyModel] = {}
	for tile in board_info["tiles"]:
		if not tile["type"] in ["property", "server", "bridge"]: continue
		property_models[tile["id"]] = PropertyModel.new(tile["id"])
		property_models[tile["id"]].name = tile["name"]
		property_models[tile["id"]].rent_prices = property_info[tile["id"]].rent_prices
		property_models[tile["id"]].buy_price = property_info[tile["id"]].buy_price
		if tile["type"] == "server": property_models[tile["id"]].group_id = 13
		elif tile["type"] == "bridge": property_models[tile["id"]].group_id = 14
		else:
			property_models[tile["id"]].group_id = tile["group"]
			property_models[tile["id"]].build_price = property_info[tile["id"]].build_price
			for group in board_info["groups"]:
				if group["group"] != tile["group"]: continue
				property_models[tile["id"]].color = Color(group["color"])
				break
	for p in game_state["property_relationships"]:
		var _owner = get_player(p["owner"])
		owner.owned_properties.append(p["square"])
		var property = property_models[p["square"]]
		property.house_count = p["houses"]
		property.owner_id = p["owner"]
		property.is_mortgaged = p["mortgage"]
	
	# Initialize GameModel
	game = GameModel.new(game_state["id"], player_models, property_models.values())
	game.current_turn_player_id = game_state["active_turn_player"]
	game.my_id = WsClient.player_id
	game.current_phase = game_state["phase"]
	game.parking_money = game_state["parking_money"]
	game.current_turn = game_state["current_turn"]
	game.current_phase_player_id = game_state["active_phase_player"]
	game_initialized.emit()

# ==========================================
# 🙋‍♂️ CONSULTAS DE JUGADORES
# ==========================================
func is_my_turn() -> bool:
	return game.my_id == game.current_turn_player_id

func get_player(player_id: int = game.my_id) -> PlayerModel:
	if game and game.players.has(player_id):
		return game.players[player_id]
	return null

func get_player_balance(player_id: int) -> int:
	var player = get_player(player_id)
	return player.balance if player else 0

func solve_properties(property_ids: Array[String]) -> Array[PropertyModel]:
	var properties: Array[PropertyModel] = []
	for property_id in property_ids:
		properties.append(ModelManager.get_property(property_id))
	return properties

func get_player_properties(player_id: int) -> Array[PropertyModel]:
	var player = get_player(player_id)
	var property_ids = player.owned_properties if player else []
	return solve_properties(property_ids)

func get_player_position(player_id: int) -> String:
	var player = get_player(player_id)
	return player.current_tile_id if player else "000"

func get_current_turn_player_id() -> int:
	return game.current_turn_player_id if game else 0

# ==========================================
# 🏠 CONSULTAS DE PROPIEDADES
# ==========================================

func get_property(property_id: String) -> PropertyModel:
	if game and game.board_properties.has(property_id):
		return game.board_properties[property_id]
	return null

func get_property_houses(property_id: String) -> int:
	var prop = get_property(property_id)
	return prop.house_count if prop else 0

func is_property_mortgaged(property_id: String) -> bool:
	var prop = get_property(property_id)
	return prop.is_mortgaged if prop else false

func get_property_owner_id(property_id: String) -> int:
	var prop = get_property(property_id)
	return prop.owner_id if prop else -1

func is_property_owned(property_id: String) -> bool:
	var _owner = get_property_owner_id(property_id)
	return _owner != -1 and _owner != null

# ==========================================
# ✏️ MODIFICADORES (Para cuando el Backend te mande actualizaciones)
# ==========================================

func set_property_owner(property_id: String, new_owner_id: int) -> void:
	var prop = get_property(property_id)
	var new_owner = get_player(new_owner_id)
	
	if prop and new_owner:
		if prop.owner_id != -1:
			var old_owner = get_player(prop.owner_id)
			if old_owner and old_owner.owned_properties.has(property_id):
				old_owner.owned_properties.erase(property_id)
				old_owner.emit_update()
		
		prop.owner_id = new_owner_id
		if not new_owner.owned_properties.has(property_id):
			new_owner.owned_properties.append(property_id)
			
		new_owner.emit_update()
		property_updated.emit(property_id)
		prop.updated.emit(property_id)

func set_property_houses(property_id: String, houses: int) -> void:
	var prop = get_property(property_id)
	if prop:
		prop.house_count = houses
		property_updated.emit(property_id)
		prop.updated.emit(property_id)

func set_property_mortgaged(property_id: String, is_mortgaged: bool) -> void:
	var prop = get_property(property_id)
	if prop:
		prop.is_mortgaged = is_mortgaged
		property_updated.emit(property_id)
		prop.updated.emit(property_id)

func update_player_balance(player_id: int, amount: int) -> void:
	var player = get_player(player_id)
	if player:
		player.balance += amount
		player.emit_update()
		player_balance_changed.emit(player_id, player.balance)

func set_player_balance(player_id: int, amount: int) -> void:
	var player = get_player(player_id)
	if player:
		player.balance = amount
		player.emit_update()
		player_balance_changed.emit(player_id, player.balance)

func update_player_position(player_id: int, new_tile_id: String, path: Array[Vector2]) -> void:
	var player = get_player(player_id)
	if player:
		player.move_to_tile(new_tile_id, path)
		player.emit_update()

func set_player_surrender(player_id: int) -> void:
	var player = get_player(player_id)
	if player:
		player.surrendered = true
		player.emit_update()

# ==========================================
# ⚖️ VALIDACIONES DE REGLAS (Monopoly Estricto)
# ==========================================

func _get_properties_in_group(group_id: String) -> Array[PropertyModel]:
	var result: Array[PropertyModel] = []
	if group_id == "" or not game: return result
	
	for prop in game.board_properties.values():
		if prop.group_id == group_id:
			result.append(prop)
	return result

func get_max_addable_houses(prop_id: String, player_id: int) -> int:
	var target_prop = get_property(prop_id)
	if not target_prop or target_prop.house_count >= 5: 
		return 0
		
	var street = _get_properties_in_group(target_prop.group_id)
	var min_other_houses = 5
	
	# Buscamos el mínimo del RESTO de la calle
	for p in street:
		if p.is_mortgaged:
			return 0
		if p.id != prop_id:
			if p.house_count < min_other_houses:
				min_other_houses = p.house_count
				
	# Fórmula estricta: No puedes superar en más de 1 al que menos tiene
	var max_by_rule = (min_other_houses + 1) - target_prop.house_count
	
	var money = get_player_balance(player_id) 
	@warning_ignore("integer_division")
	var max_by_money = floor(money / 50) # HARCODEADO ESTE 50
	
	var final_max = min(max_by_rule, max_by_money)
	# clampi asegura que devolvemos entre 0 y el hueco que nos quede hasta 5
	return clampi(final_max, 0, 5 - target_prop.house_count)

func get_max_removable_houses(prop_id: String) -> int:
	var target_prop = get_property(prop_id)
	if not target_prop or target_prop.house_count <= 0: 
		return 0
		
	var street = _get_properties_in_group(target_prop.group_id)
	var max_other_houses = 0
	
	# Buscamos el máximo del RESTO de la calle
	for p in street:
		if p.id != prop_id:
			if p.house_count > max_other_houses:
				max_other_houses = p.house_count
				
	# Fórmula estricta: No puedes quedarte corto en más de 1 respecto al que más tiene
	var max_by_rule = target_prop.house_count - (max_other_houses - 1)
	
	return clampi(max_by_rule, 0, target_prop.house_count)

func can_mortgage(property_id: String, player_id: int) -> bool:
	var target = get_property(property_id)
	if not target or target.owner_id != player_id: return false
	
	var street = _get_properties_in_group(target.group_id)
	
	for prop in street:
		if prop.house_count > 0:
			return false # No puedes tocar la hipoteca si hay alguna casa en la calle
			
	return true

func owns_full_group(group_id: String, player_id: int) -> bool:
	var street = _get_properties_in_group(group_id)
	if street.is_empty(): return false
	
	for prop in street:
		if prop.owner_id != player_id:
			return false
	return true
