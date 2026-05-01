class_name MagnateModelManager
extends Node2D

signal game_initialized
signal parking # Emited when parking updated

# Señales útiles para que la UI reaccione instantáneamente a los cambios
signal property_updated(property_id: int)
signal player_balance_changed(player_id: int, new_balance: int)
signal turn_updated

# Modelos
var game: GameModel

func initialize_game(game_state: Dictionary) -> void:
	game = GameModel.new(game_state["id"], game_state["active_turn_player"])
	
	# Initialize PlayerModels
	var json_text = FileAccess.open("res://assets/game_info/board.json", FileAccess.READ).get_as_text()
	var board_info = JSON.parse_string(json_text)
	var player_colors: Array = board_info["playerColors"]
	for idx in len(game_state["ordered_players"]):
		var color = Color(player_colors[idx])
		var player_name = (await RestClient.fetch_user_name_and_piece(game_state["ordered_players"][idx])).get("username", "Desconocido")
		var player = PlayerModel.new(game_state["ordered_players"][idx], player_name, color)
		game.add_player(player)
		set_player_balance(player.id, int(game_state["money"][str(player.id)]))
		player.current_tile_id = game_state["positions"][str(player.id)]
		player.is_in_jail = game_state["jail_remaining_turns"].has(str(player.id)) # TODO
		player.jail_turn_count = 3 - game_state["jail_remaining_turns"].get(str(player.id), 3) # TODO
	
	# Initialize PropertyModels
	json_text = FileAccess.open("res://assets/game_info/money.json", FileAccess.READ).get_as_text()
	var property_list = JSON.parse_string(json_text)["tiles"]
	var property_info = {}
	for p in property_list: property_info[p["id"]] = p
	for tile in board_info["tiles"]:
		if not tile["type"] in ["property", "server", "bridge"]: continue
		var property_model = PropertyModel.new(tile["id"])
		game.add_property(property_model)
		property_model.name = tile["name"]
		property_model.rent_prices = property_info[tile["id"]].rent_prices
		property_model.buy_price = property_info[tile["id"]].buy_price
		if tile["type"] == "server": property_model.group_id = 13
		elif tile["type"] == "bridge": property_model.group_id = 14
		else:
			property_model.group_id = tile["group"]
			property_model.build_price = property_info[tile["id"]].build_price
			for group in board_info["groups"]:
				if group["group"] != tile["group"]: continue
				property_model.color = Color(group["color"])
				break
	for p in game_state["property_relationships"]:
		var _owner = get_player(p["owner"])
		var property = get_property(p["square"])
		set_property_owner(property.id, _owner.id)
		set_property_houses(property.id, clampi(p["houses"], 0, 5))
		set_property_mortgaged(property.id, p["mortgage"])
	
	# Initialize GameModel
	game.my_id = WsClient.player_id
	game.current_phase = game_state["phase"]
	set_parking_money(game_state["parking_money"])
	set_turn(game_state["current_turn"])
	game.current_phase_player_id = game_state["active_phase_player"]
	game.recovered_fantasy_event = game_state["fantasy_event"]
	game.recovered_trade = game_state["proposal"]
	game.recovered_destinations = game_state["possible_destinations"]
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
	
	if prop and prop.owner_id != -1:
		var old_owner = get_player(prop.owner_id)
		if old_owner and old_owner.owned_properties.has(property_id):
			old_owner.owned_properties.erase(property_id)
			old_owner.emit_update()
	prop.owner_id = new_owner_id
	property_updated.emit(property_id)
	prop.send_update()
	if new_owner and not new_owner.owned_properties.has(property_id):
		new_owner.owned_properties.append(property_id)
		new_owner.emit_update()

func set_property_houses(property_id: String, houses: int) -> void:
	var prop = get_property(property_id)
	if houses == prop.house_count: return
	if prop:
		prop.house_count = houses
		property_updated.emit(property_id)
		prop.send_update()

func update_property_houses(property_id: String, house_diff: int) -> void:
	if house_diff == 0: return
	var prop = get_property(property_id)
	if prop: set_property_houses(property_id, prop.house_count + house_diff)

func set_property_mortgaged(property_id: String, is_mortgaged: bool) -> void:
	var prop = get_property(property_id)
	if prop.is_mortgaged == is_mortgaged: return
	if prop:
		prop.is_mortgaged = is_mortgaged
		property_updated.emit(property_id)
		prop.send_update()

func update_player_balance(player_id: int, amount: int) -> void:
	if amount == 0: return
	var player = get_player(player_id)
	if player:
		player.balance += amount
		player.emit_update()
		player_balance_changed.emit(player_id, player.balance)

func set_player_balance(player_id: int, amount: int) -> void:
	var player = get_player(player_id)
	if player.balance == amount: return
	if player:
		player.balance = amount
		player.emit_update()
		player_balance_changed.emit(player_id, player.balance)

func update_player_position(player_id: int, new_tile_id: String, path: Array[Vector2]) -> void:
	var player = get_player(player_id)
	if player.current_tile_id == new_tile_id: return
	if player:
		player.move_to_tile(new_tile_id, path)
		player.emit_update()
		player.is_in_jail = new_tile_id == "201"
		

func set_player_surrender(player_id: int) -> void:
	var player = get_player(player_id)
	if player:
		player.surrendered = true
		player.emit_update()

func set_parking_money(amount: int) -> void:
	if amount == game.parking_money: return
	game.parking_money = amount
	parking.emit()

func update_parking_money(diff: int) -> void:
	if diff == 0: return
	set_parking_money(game.parking_money + diff)

func set_turn(turn: int) -> void:
	if game.current_turn == turn: return
	game.current_turn = turn
	turn_updated.emit()

func update_turn(diff: int = 1) -> void:
	if diff == 0: return
	set_turn(game.current_turn + diff)

# ==========================================
# ⚖️ VALIDACIONES DE REGLAS (Monopoly Estricto)
# ==========================================

func _get_properties_in_group(group_id: int) -> Array[PropertyModel]:
	var result: Array[PropertyModel] = []
	for prop in game.board_properties.values():
		if prop.group_id == group_id:
			result.append(prop)
	return result

func get_max_addable_houses(prop_id: String) -> int:
	var target_prop = get_property(prop_id)
	if not target_prop or target_prop.house_count >= 5: 
		return 0
		
	var street = _get_properties_in_group(target_prop.group_id)
	var min_other_houses = 5
	
	for p in street:
		if p.is_mortgaged: return 0
		if p.id == prop_id: continue
		if p.house_count < min_other_houses:
			min_other_houses = p.house_count
				
	var max_by_rule = (min_other_houses + 1) - target_prop.house_count
	
	return clampi(max_by_rule, 0, 5 - target_prop.house_count)

func get_max_removable_houses(prop_id: String) -> int:
	var target_prop = get_property(prop_id)
	if not target_prop or target_prop.house_count <= 0: 
		return 0
		
	var street = _get_properties_in_group(target_prop.group_id)
	var max_other_houses = 0
	
	for p in street:
		if p.id == prop_id: continue
		if p.house_count > max_other_houses:
			max_other_houses = p.house_count

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

func owns_full_group(group_id: int, player_id: int) -> bool:
	var street = _get_properties_in_group(group_id)
	if street.is_empty(): return false
	
	for prop in street:
		if prop.owner_id != player_id:
			return false
	return true
