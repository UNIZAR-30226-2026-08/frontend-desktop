extends PanelContainer

@onready var property_price: Label = %PropertyPrice
@onready var property_name: Label = %PropertyName
@onready var property_color: ColorRect = %PropertyColor
@onready var building_container: HBoxContainer = %BuildingContainer

const HOTEL = preload("uid://dxkynolj2rhdd")
const HOUSE = preload("uid://bs68kpgc7sid4")

var number_of_houses: int = 0 # [0, 5], 5 = hotel
var original_price_value: int = 0 # Guarda el valor numérico original
var owner_id: int = -1
var is_mortgaged = false

func update(tile_id: String) -> void:
	var property = ModelManager.get_property(tile_id)
	update_mortgage_visuals(property.is_mortgaged)
	if number_of_houses != property.house_count:
		set_number_of_houses(property.house_count)
	set_property_owner(property.owner_id)

func set_property_owner(player_id: int) -> void:
	if owner_id == player_id: return
	owner_id = player_id
	var player = ModelManager.get_player(player_id)
	var tween
	for child in get_children():
		if child is OwnerMarker:
			tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(child, "position:y", size.y - child.marker_height, 0.5)
			await tween.finished
			child.queue_free()

	var marker = OwnerMarker.new(player.color, size.x)
	marker.position = Vector2(0, size.y - marker.marker_height)
	add_child(marker)
	tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(marker, "position:y", size.y, 0.5)

func set_property_name(_name: String) -> void:
	property_name.text = _name

func set_property_price(price: int) -> void:
	original_price_value = price
	property_price.text = Utils.to_currency_text(price)

func set_property_color(color: Color) -> void:
	property_color.color = color

# Calcula el valor de la hipoteca (la mitad del precio original)
func calculate_mortgage_value() -> int:
	@warning_ignore("integer_division")
	return original_price_value / 2

# Función principal que se llama cuando se pulsa el botón
func update_mortgage_visuals(_is_mortgaged: bool) -> void:
	if is_mortgaged == _is_mortgaged: return
	is_mortgaged = _is_mortgaged
	var tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE).set_parallel()
	var tween_duration = 1
	if is_mortgaged:
		# Casilla hipotecada: Fondo rojo, letras blancas
		tween.tween_property(self, "self_modulate", Color(0.8, 0, 0, 1), tween_duration)
		tween.tween_property(property_name, "theme_override_colors/font_color", Color.WHITE, tween_duration)
		tween.tween_property(property_price, "theme_override_colors/font_color", Color.WHITE, tween_duration)
	else:
		# Casilla normal: Restauramos (ajusta estos colores a los tuyos por defecto)
		tween.tween_property(self, "self_modulate", Color.WHITE, tween_duration)
		tween.tween_property(property_name, "theme_override_colors/font_color", Color.BLACK, tween_duration)
		tween.tween_property(property_price, "theme_override_colors/font_color", Color.BLACK, tween_duration)

# Función helper para cambiar el color de los textos
func set_labels_color(color: Color) -> void:
	# Usamos set() para sobrescribir la propiedad de color de la fuente en el tema
	property_name.set("theme_override_colors/font_color", color)
	property_price.set("theme_override_colors/font_color", color)

func set_number_of_houses(n: int) -> void:
	if n == number_of_houses: return 
	
	Utils.debug("Renderizando " + str(n) + " construcciones en la casilla.")

	for child in building_container.get_children():
		child.queue_free()
	
	if n == 5:
		var instance = HOTEL.instantiate()
		building_container.add_child(instance)
	elif n > 0 and n < 5:
		for i in range(n):
			var instance = HOUSE.instantiate()
			building_container.add_child(instance)
	
	# 3. GUARDAMOS EL ESTADO
	number_of_houses = n
