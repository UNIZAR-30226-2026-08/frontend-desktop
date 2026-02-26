extends PanelContainer

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
		
	highlight_rent(3)

# --- Funciones de actualización Individuales ---

func set_property_name(p_name: String) -> void:
	property_name.text = p_name

func set_property_color(p_color: Color) -> void:
	property_color.color = p_color

func set_basic_rent(p_amount: int) -> void:
	property_basic_rent.text = "ALQUILERES {valor}€".format({"valor": p_amount})
	
func set_rent_1(p_amount: int) -> void:
	if(p_amount < 100):
		property_rent_1.text = "Con 1 Casa . . . . . . . . . . . {valor}€".format({"valor": p_amount})
	elif(p_amount < 1000):
		property_rent_1.text = "Con 1 Casa . . . . . . . . . . {valor}€".format({"valor": p_amount})
	else:
		property_rent_1.text = "Con 1 Casa . . . . . . . . . {valor}€".format({"valor": p_amount})

func set_rent_2(p_amount: int) -> void:
	if(p_amount < 100):
		property_rent_2.text = "Con 2 Casas . . . . . . . . . . {valor}€".format({"valor": p_amount})
	elif(p_amount < 1000):
		property_rent_2.text = "Con 2 Casas . . . . . . . . . {valor}€".format({"valor": p_amount})
	else:
		property_rent_2.text = "Con 2 Casas . . . . . . . . {valor}€".format({"valor": p_amount})
		
func set_rent_3(p_amount: int) -> void:
	if(p_amount < 100):
		property_rent_2.text = "Con 3 Casas . . . . . . . . . . {valor}€".format({"valor": p_amount})
	elif(p_amount < 1000):
		property_rent_2.text = "Con 3 Casas . . . . . . . . . {valor}€".format({"valor": p_amount})
	else:
		property_rent_2.text = "Con 3 Casas . . . . . . . . {valor}€".format({"valor": p_amount})
		
func set_rent_4(p_amount: int) -> void:
	if(p_amount < 100):
		property_rent_2.text = "Con 4 Casas . . . . . . . . . . {valor}€".format({"valor": p_amount})
	elif(p_amount < 1000):
		property_rent_2.text = "Con 4 Casas . . . . . . . . . {valor}€".format({"valor": p_amount})
	else:
		property_rent_2.text = "Con 4 Casas . . . . . . . . {valor}€".format({"valor": p_amount})
		
func set_rent_hotel(p_amount: int) -> void:
	if(p_amount < 100):
		property_rent_2.text = "Con HOTEL . . . . . . . . . . . {valor}€".format({"valor": p_amount})
	elif(p_amount < 1000):
		property_rent_2.text = "Con HOTEL . . . . . . . . . . {valor}€".format({"valor": p_amount})
	else:
		property_rent_2.text = "Con HOTEL . . . . . . . . . {valor}€".format({"valor": p_amount})
		
func set_house_price(p_amount: int) -> void:
	property_house_price.text = "Cada Casa cuesta {valor}€\n El Hotel cuesta 5 Casas".format({"valor": p_amount})

func set_mortgage_price(p_price: int) -> void:
	property_mortgage.text = "Valor de la Hipoteca {valor}€".format({"valor": p_price})

# --- Función Maestra ---

func update_all_data(data: Dictionary) -> void:
	# Esto permite actualizar toda la tarjeta pasando un diccionario de datos
	set_property_name(data.get("name", "Propiedad"))
	set_property_color(data.get("color", Color.WHITE))
	set_basic_rent(data.get("rent_0", 0))
	set_rent_1(data.get("rent_1", 0))
	set_rent_2(data.get("rent_2", 0))
	set_rent_3(data.get("rent_3", 0))
	set_rent_4(data.get("rent_4", 0))
	set_rent_hotel(data.get("rent_hotel", 0))
	set_house_price(data.get("house_price", 0))
	set_mortgage_price(data.get("mortgage", 0))

var flash_tween: Tween 

func highlight_rent(index: int) -> void:
	# 1. Limpiar cualquier animación previa
	if flash_tween:
		flash_tween.kill()
	
	# 2. Apagar todos los resaltadores
	for h in highlighters:
		h.visible = true
		h.self_modulate = Color("ffffff")
	
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
	# Ajusta el 0.6 y el 0.2 a tu gusto según cuánta intensidad quieras
	flash_tween.tween_property(node, "self_modulate:a", 0.7, 0.4).set_trans(Tween.TRANS_SINE)
	flash_tween.tween_property(node, "self_modulate:a", 0.3, 0.4).set_trans(Tween.TRANS_SINE)
