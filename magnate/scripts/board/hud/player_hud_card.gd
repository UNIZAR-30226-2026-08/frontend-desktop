class_name PlayerHUDCard
extends MarginContainer

@onready var name_label = $MainVBox/TopRow/NameVBox/NameLabel
@onready var balance_label = $MainVBox/TopRow/BalancePanel/BalanceHBox/BalanceMargin/BalanceLabel
@onready var props_label = $MainVBox/BottomRow/PropsLabel
@onready var id_label = $MainVBox/BottomRow/IDLabel
@onready var bill_particles: Node2D = %BillParticles
@onready var balance_difference: Label = %BalanceDifference

# Para hacerlas clickables
signal clicked(id: int)
var player_id: int

const animation_duration: int = 2
const animation_label_offset: int = 40

var base_color: Color = Color.WHITE
var balance: int = 1500

func _ready() -> void:
	add_theme_constant_override("margin_left", 50)
	add_theme_constant_override("margin_right", 15)
	add_theme_constant_override("margin_top", 10)
	add_theme_constant_override("margin_bottom", 10)
	
	var font = balance_label.get_theme_font("font")
	if font is SystemFont:
		var variation = FontVariation.new()
		variation.base_font = font
		variation.opentype_features = {"tnum": 1, "zero": 1} # No parece funcionar
		balance_label.add_theme_font_override("font", variation)
	
	if has_node("MainVBox"):
		_ignore_mouse_on_children($MainVBox)

func setup(p_id: int, p_name: String, p_color: Color, p_balance: int) -> void:
	player_id = p_id # Guardamos el ID
	mouse_filter = Control.MOUSE_FILTER_STOP # ¡Vital para detectar clicks!
	
	base_color = p_color
	name_label.text = p_name.to_upper()
	id_label.text = "#" + str(p_id)
	
	_update_balance_label(p_balance)
	queue_redraw()
	
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		clicked.emit(player_id)

func _update_balance_label(amount: int) -> void:
	var formatted_money = str(amount)
	if amount >= 1000:
		var s = str(amount)
		formatted_money = s.left(s.length() - 3) + "," + s.right(3)
	balance_label.text = formatted_money

func update_balance(amount: int) -> void:
	var difference = amount - balance
	if difference == 0: return
	balance = amount
	var formatted_difference = Utils.to_currency_text(difference)

	var initial_y = balance_difference.position.y
	balance_difference.text = formatted_difference
	balance_difference.show()
	balance_difference.modulate.a = 0
	bill_particles.set_emit(true)
	
	var tween = get_tree().create_tween().set_parallel().set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(_update_balance_label, ModelManager.get_player_balance(player_id), amount, animation_duration)\
		.set_trans(Tween.TRANS_CUBIC)
	var target_y = balance_difference.position.y
	if difference > 0:
		balance_difference.add_theme_color_override("font_color", Color("#90be6d"))
		target_y -= animation_label_offset
	else:
		balance_difference.add_theme_color_override("font_color", Color("#f94144"))
		target_y += animation_label_offset
	tween.tween_property(balance_difference, "position:y", target_y, animation_duration)\
		.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(balance_difference, "modulate:a", 1, animation_duration)\
		.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	bill_particles.set_emit(false)
	balance_difference.hide()
	balance_difference.position.y = initial_y

func update_properties(count: int) -> void:
	props_label.text = str(count) + " PROPIEDADES"

func _draw() -> void:
	var w = size.x
	var h = size.y
	
	var points = PackedVector2Array([
		Vector2(0, 0), 
		Vector2(w, 0), 
		Vector2(w, h), 
		Vector2(0, h), 
		Vector2(30.0, h / 2.0) 
	])
	
	var colors = PackedColorArray([
		base_color, 
		base_color, 
		base_color, 
		base_color, 
		base_color
	])
	
	draw_polygon(points, colors)
	
	# Borde blanco para mejorar la visibilidad
	var border_points = points.duplicate()
	border_points.append(points[0])
	draw_polyline(border_points, Color.WHITE, 2.0, true)

# Esta función viaja por todos los hijos y les dice que ignoren el ratón
func _ignore_mouse_on_children(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignore_mouse_on_children(child) # Llamada recursiva para los "nietos"
