class_name ModelManager
extends RefCounted

signal game_initialized

# Señales útiles para que la UI reaccione instantáneamente a los cambios
signal property_updated(property_id: String)
signal player_balance_changed(player_id: String, new_balance: int)

# Modelos
var game: GameModel

func initialize_game(game_id: String, raw_players: Array[Dictionary], properties_data: Array[Dictionary]) -> void:
	var player_models: Array[PlayerModel] = []
	for p_data in raw_players:
		var color = Color(p_data.get("color", "#FFFFFF"))
		player_models.append(PlayerModel.new(p_data["id"], p_data["name"], color))
		
	# Creamos el GameModel
	game = GameModel.new(game_id, player_models, [])
	
	# Creamos las propiedades con sus grupos
	for p in properties_data:
		var group_str = str(p.get("group", ""))
		game.board_properties[p["id"]] = PropertyModel.new(p["id"], group_str)
	
	game_initialized.emit()

# ==========================================
# 🙋‍♂️ CONSULTAS DE JUGADORES
# ==========================================

func get_player(player_id: String) -> PlayerModel:
	if game and game.players.has(player_id):
		return game.players[player_id]
	return null

func get_player_balance(player_id: String) -> int:
	var player = get_player(player_id)
	return player.balance if player else 0

func get_player_properties(player_id: String) -> Array[String]:
	var player = get_player(player_id)
	return player.properties if player else []

func get_player_position(player_id: String) -> String:
	var player = get_player(player_id)
	return player.current_tile_id if player else "000"

func get_current_turn_player_id() -> String:
	return game.current_turn_player_id if game else ""

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

func get_property_owner_id(property_id: String) -> String:
	var prop = get_property(property_id)
	return prop.owner_id if prop else ""

func is_property_owned(property_id: String) -> bool:
	var owner = get_property_owner_id(property_id)
	return owner != "" and owner != null

# ==========================================
# ✏️ MODIFICADORES (Para cuando el Backend te mande actualizaciones)
# ==========================================

func set_property_owner(property_id: String, new_owner_id: String) -> void:
	var prop = get_property(property_id)
	var new_owner = get_player(new_owner_id)
	
	if prop and new_owner:
		if prop.owner_id != "":
			var old_owner = get_player(prop.owner_id)
			if old_owner and old_owner.properties.has(property_id):
				old_owner.properties.erase(property_id)
				old_owner.emit_update()
		
		prop.owner_id = new_owner_id
		if not new_owner.properties.has(property_id):
			new_owner.properties.append(property_id)
			
		new_owner.emit_update()
		property_updated.emit(property_id)

func set_property_houses(property_id: String, houses: int) -> void:
	var prop = get_property(property_id)
	if prop:
		prop.house_count = houses
		property_updated.emit(property_id)

func set_property_mortgaged(property_id: String, is_mortgaged: bool) -> void:
	var prop = get_property(property_id)
	if prop:
		prop.is_mortgaged = is_mortgaged
		property_updated.emit(property_id)

func update_player_balance(player_id: String, new_balance: int) -> void:
	var player = get_player(player_id)
	if player:
		player.balance = new_balance
		player.emit_update()
		player_balance_changed.emit(player_id, new_balance)

## NUEVA FUNCIÓN: Para usar en el Overlay de forma segura (sumar o restar)
func add_player_balance(player_id: String, amount_to_add: int) -> void:
	var player = get_player(player_id)
	if player:
		player.balance += amount_to_add
		player.emit_update()
		player_balance_changed.emit(player_id, player.balance)

func update_player_position(player_id: String, new_tile_id: String) -> void:
	var player = get_player(player_id)
	if player:
		player.move_to_tile(new_tile_id)
		
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

func get_max_addable_houses(prop_id: String, player_id: String) -> int:
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

func can_mortgage(property_id: String, player_id: String) -> bool:
	var target = get_property(property_id)
	if not target or target.owner_id != player_id: return false
	
	var street = _get_properties_in_group(target.group_id)
	
	for prop in street:
		if prop.house_count > 0:
			return false # No puedes tocar la hipoteca si hay alguna casa en la calle
			
	return true

func owns_full_group(group_id: String, player_id: String) -> bool:
	var street = _get_properties_in_group(group_id)
	if street.is_empty(): return false
	
	for prop in street:
		if prop.owner_id != player_id:
			return false
	return true
