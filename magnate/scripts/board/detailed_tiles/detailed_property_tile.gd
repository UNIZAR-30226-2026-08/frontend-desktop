extends MagnateBaseCard

@onready var property_color: ColorRect = %PropertyColor
@onready var property_name: Label = %PropertyName
@onready var property_basic_rent: Label = %BasicRent
@onready var property_rent_1: Label = %Rent1
@onready var property_rent_2: Label = %Rent2
@onready var property_rent_3: Label = %Rent3
@onready var property_rent_4: Label = %Rent4
@onready var property_rent_hotel: Label = %RentHotel
@onready var property_house_price: Label = %HousePrice
@onready var property_mortgage: Label = %MortgagePrice
@onready var highlighters: Array = [
	%HighlighterBasic,
	%Highlighter1,
	%Highlighter2,
	%Highlighter3,
	%Highlighter4,
	%HighlighterHotel
]

func _ready() -> void:
	# Inicializamos: todos los rectángulos con opacidad baja e invisibles
	for h in highlighters:
		h.visible = true
		h.self_modulate = Color("ffffff")

# --- Funciones de actualización Individuales ---

func set_property_name(p_name: String) -> void:
	property_name.text = p_name

func set_property_color(p_color: Color) -> void:
	property_color.color = p_color

func set_basic_rent(p_amount: int) -> void:
	property_basic_rent.text = "ALQUILERES " + Utils.to_currency_text(p_amount)
	
func set_rent_1(p_amount: int) -> void:
	property_rent_1.text = "Con 1 Casa . . . . . . . . . " + Utils.to_currency_text(p_amount)

func set_rent_2(p_amount: int) -> void:
	property_rent_2.text = "Con 2 Casas . . . . . . . . " + Utils.to_currency_text(p_amount)
		
func set_rent_3(p_amount: int) -> void:
	property_rent_3.text = "Con 3 Casas . . . . . . . . " + Utils.to_currency_text(p_amount)
		
func set_rent_4(p_amount: int) -> void:
	property_rent_4.text = "Con 4 Casas . . . . . . . . " + Utils.to_currency_text(p_amount)
		
func set_rent_hotel(p_amount: int) -> void:
	property_rent_hotel.text = "Con HOTEL . . . . . . . . . " + Utils.to_currency_text(p_amount)

func set_house_price(p_amount: int) -> void:
	property_house_price.text = "Cada Casa cuesta " + Utils.to_currency_text(p_amount) + "\n El Hotel cuesta 5 Casas"

func set_mortgage_price(p_amount: int) -> void:
	property_mortgage.text = "Valor de la Hipoteca " + Utils.to_currency_text(p_amount)

# --- Función Maestra ---

func update_all_data(property: PropertyModel) -> void:
	set_property_name(property.name)
	# Convertimos el string del JSON a un Color real
	set_property_color(property.color) 
	set_basic_rent(property.rent_prices[0])
	set_rent_1(property.rent_prices[1])
	set_rent_2(property.rent_prices[2])
	set_rent_3(property.rent_prices[3])
	set_rent_4(property.rent_prices[4])
	set_rent_hotel(property.rent_prices[5])
	set_house_price(property.build_price)
	set_mortgage_price(property.buy_price / 2)

var flash_tween: Tween 

func highlight_rent(index: int) -> void:
	# 1. Limpiar cualquier animación previa
	if flash_tween:
		flash_tween.kill()
	
	# 2. Apagar todos los resaltadores
	for h in highlighters:
		h.modulate = Color("ffffff")
	
	# 3. Validar índice y activar el elegido
	if index >= 0 and index < highlighters.size():
		var target = highlighters[index]
		target.visible = true
		_run_infinite_flash(target)

## Lógica del parpadeo infinito
func _run_infinite_flash(node: Control) -> void:
	flash_tween = create_tween().set_loops() # Bucle infinito
	node.modulate = Color(1.0, 1.0, 0.0, 1.0)
	# Animación: va de casi invisible a resaltar el color
	# Ajusta el 0.6 y el 0.2 según la intensidad
	flash_tween.tween_property(node, "self_modulate:a", 0.7, 0.4).set_trans(Tween.TRANS_SINE)
	flash_tween.tween_property(node, "self_modulate:a", 0.3, 0.4).set_trans(Tween.TRANS_SINE)
