extends PanelContainer

@onready var property_price: Label = %PropertyPrice
@onready var property_name: Label = %PropertyName
@onready var property_color: ColorRect = %PropertyColor
@onready var building_container: HBoxContainer = %BuildingContainer

const HOTEL = preload("uid://dxkynolj2rhdd")
const HOUSE = preload("uid://bs68kpgc7sid4")

var number_of_houses: int = 0 # [0, 5], 5 = hotel
var original_price_value: int = 0 # Guarda el valor numérico original

func set_property_name(_name: String) -> void:
	property_name.text = _name

# MODIFICADA: Guardamos el precio numérico original antes de formatearlo.
func set_property_price(price: int) -> void:
	original_price_value = price
	property_price.text = Utils.to_currency_text(price)

func set_property_color(color: Color) -> void:
	property_color.color = color

# --- DENTRO DE TU PANELCONTAINER (LA CASILLA) ---

# --- NUEVAS FUNCIONES PARA LA HIPOTECA ---

# Calcula el valor de la hipoteca (la mitad del precio original)
func calculate_mortgage_value() -> int:
	@warning_ignore("integer_division")
	return original_price_value / 2

# Función principal que se llama cuando se pulsa el botón
func update_mortgage_visuals(is_mortgaged: bool) -> void:
	if is_mortgaged:
		# Casilla hipotecada: Fondo rojo, letras blancas
		self.self_modulate = Color(0.8, 0, 0, 1)
		property_name.set("theme_override_colors/font_color", Color.WHITE)
		property_price.set("theme_override_colors/font_color", Color.WHITE)
	else:
		# Casilla normal: Restauramos (ajusta estos colores a los tuyos por defecto)
		self.self_modulate = Color.WHITE 
		property_name.set("theme_override_colors/font_color", Color.BLACK)
		property_price.set("theme_override_colors/font_color", Color.BLACK)

# Función helper para cambiar el color de los textos
func set_labels_color(color: Color) -> void:
	# Usamos set() para sobrescribir la propiedad de color de la fuente en el tema
	property_name.set("theme_override_colors/font_color", color)
	property_price.set("theme_override_colors/font_color", color)

# --- FIN DE LAS NUEVAS FUNCIONES ---

func set_number_of_houses(n: int) -> void:
	if n == number_of_houses: return 
	
	Utils.debug("Renderizando " + str(n) + " construcciones en la casilla.")

	# 1. LIMPIEZA ABSOLUTA
	# Borramos todos los nodos visuales (casas u hoteles) que haya actualmente.
	# Nos da igual lo que hubiera antes, vamos a hacer lo que dice el Modelo.
	for child in building_container.get_children():
		child.queue_free()
	
	# 2. CONSTRUCCIÓN DESDE CERO SEGÚN EL MODELO
	if n == 5:
		# Pone 1 solo Hotel
		var instance = HOTEL.instantiate()
		building_container.add_child(instance)
	elif n > 0 and n < 5:
		# Pone tantas casas como diga 'n'
		for i in range(n):
			var instance = HOUSE.instantiate()
			building_container.add_child(instance)
	
	# 3. GUARDAMOS EL ESTADO
	number_of_houses = n
