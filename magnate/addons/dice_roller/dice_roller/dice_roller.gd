@icon("./dice_roller.svg")
extends Node3D
class_name DiceRoller

## Margin away from the walls when repositioning
const margin = 1.0
const launch_height := Dice.dice_size * 5.0
const default_set := {
	'red': {
		'color': Color.FIREBRICK,
	},
	'yellow': {
		'color': Color.GOLDENROD,
	},
}

@export var dice_set: Array[DiceDef] = []:
	set(new_value):
		if rolling:
			await roll_finnished
		dice_set = new_value
		reload_dices()

@export var roller_color := Color.DARK_GREEN:
	set(new_value):
		roller_color = new_value
		if $RollerBox/CSGBox3D:
			$RollerBox/CSGBox3D.material.albedo_color = new_value

@export var roller_size := Vector3(9, 12, 5):
	set(new_value):
		roller_size = new_value
		if $RollerBox/CSGBox3D:
			$RollerBox.width = new_value.x
			$RollerBox.height = new_value.y
			$RollerBox.depth = new_value.z
			reload_dices()
			
@export var interactive := false

## Emits the final value once the roll has finished
signal roll_finnished(value: int)
## Emits the final value when the roll starts
signal roll_started()

## Dices in the roller
var dices := []
## Accomulated result as a map dice name -> final value
var result := {}
## Wheter the dices are rolling
var rolling := false

func _ready() -> void:
	$RollerBox/CSGBox3D.material.albedo_color = roller_color
	$RollerBox.width = roller_size.x
	$RollerBox.height = roller_size.y
	$RollerBox.depth = roller_size.z

func per_dice_result() -> Dictionary:
	return result

var total_value:=0 :
	get:
		var total := 0
		for dice_name in result:
			total += result[dice_name]
		return total

func set_default_dice_set():
	var new_set: Array[DiceDef] = []
	for name in default_set:
		var dice = DiceDef.new()
		dice.name = name
		dice.color = default_set[name].color
		dice.shape = DiceShape.new("D6")
		new_set.append(dice)
	dice_set = new_set

func ensure_valid_and_unique_dice_names():
	var used_names: Dictionary = {}
	for dice in dice_set:
		var name_prefix := dice.name if dice.name and len(dice.name) else "dice"
		var dice_name := name_prefix
		for i in range(len(result)+1, 100):
			if dice_name not in used_names:
				break
			dice_name = name_prefix+"{0}".format([i])
		used_names[dice_name] = true
		dice.name = dice_name

func roll(forced_values: Array[int] = []):
	if rolling: return
	result = {}
	rolling = true
	for i in range(dices.size()):
		if forced_values.size() > i: # Vemos si hay un valor forzado para este dado
			dices[i].roll(forced_values[i])
		else:
			dices[i].roll()
	roll_started.emit()

func prepare():
	if rolling: return
	for dice in dices:
		dice.stop()

func _init() -> void:
	reload_dices()

func clear_dices():
	for dice in dices:
		remove_child(dice)
	dices = []

func reload_dices():
	if not dice_set:
		return set_default_dice_set()
	clear_dices()
	ensure_valid_and_unique_dice_names()
	for dice: DiceDef in dice_set:
		add_dice_escene(dice)
	reposition_dices()

func add_dice_escene(dice: DiceDef):
	var packed_scene: PackedScene
	if not dice.shape:
		push_warning("Shapeless dice def ", dice.name)
		packed_scene = DiceShape.new("D6").scene()
	else:
		packed_scene = dice.shape.scene()
	var scene = packed_scene.instantiate()
	scene.name = dice.name
	scene.dice_color = dice.color
	scene.roll_finished.connect(_on_finnished_dice_rolling.bind(dice.name))
	add_child(scene)
	dices.append(scene)

func dices_arrangement(ndices: int, width: float, height: float) -> Vector2i:
	var first_cols: int = ceil(sqrt(ndices*width/height))
	var rows: int = ceil(ndices/float(first_cols))
	var cols: int = ceil(ndices/float(rows))
	return Vector2i(cols, rows)

func reposition_dices():
	var span_x := roller_size.x - margin * 2
	var span_z := roller_size.z - margin * 2
	var arrangement: Vector2i = dices_arrangement(dices.size(), span_x, span_x)
	var cols: int = arrangement.x
	var rows: int = arrangement.y
	var last_row_cols: int = dices.size()%cols if dices.size()%cols else  cols
	for i in range(dices.size()):
		var dice = dices[i] 
		var col: int = i%cols
		var row: int = floor(i/cols)
		var actual_cols = last_row_cols if row == rows-1 else cols
		var dice_x : float = -span_x/2 + span_x/actual_cols * (0.5 + col)
		var dice_z : float = -span_z/2 + span_z/rows * (0.5 + row)
		dice.position = Vector3(dice_x, launch_height, dice_z)
		dice.original_position = dice.position

func _on_finnished_dice_rolling(number: int, dice_name: String):
	result[dice_name] = number
	if result.size() < dices.size():
		return
	rolling = false
	roll_finnished.emit(total_value)

func quick_roll():
	var values: Array[int] = []
	for dice: Dice in dices:
		var dice_values := dice.sides.keys()
		var chosen = dice_values[randi_range(0, dice_values.size()-1)]
		values.append(chosen)
	show_faces(values)
	roll_started.emit()

func show_faces(faces: Array[int]):
	if rolling: return
	assert(faces.size() == dices.size())
	result={}
	rolling = true
	for i in range(faces.size()):
		dices[i].show_face(faces[i])
