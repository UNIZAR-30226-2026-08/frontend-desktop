class_name PlayerHUDCard
extends MarginContainer

@onready var name_label = $MainVBox/TopRow/NameVBox/NameLabel
@onready var balance_label = $MainVBox/TopRow/BalancePanel/BalanceHBox/BalanceMargin/BalanceLabel
@onready var props_label = $MainVBox/BottomRow/PropsLabel
@onready var id_label = $MainVBox/BottomRow/IDLabel

var base_color: Color = Color.WHITE

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

func setup(p_id: String, p_name: String, p_color: Color, p_balance: int) -> void:
	base_color = p_color
	name_label.text = p_name.to_upper()
	id_label.text = "#" + p_id.right(4)
	
	update_balance(p_balance)
	queue_redraw()

func update_balance(amount: int) -> void:
	var formatted_money = str(amount)
	if amount >= 1000:
		var s = str(amount)
		formatted_money = s.left(s.length() - 3) + "," + s.right(3)
	
	balance_label.text = formatted_money

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
