extends PanelContainer

@export var rank: int = 1: set = set_rank
@export var player_name: String = "Placeholder": set = set_player_name
@export var max_score: int = 100: set = set_max_score
@export var current_score: int = 0: set = set_current_score
@export var player_color: Color = Color("ff4e7d"): set = set_color

@onready var _rank_label: Label = %Rank
@onready var _name_label: Label = %Name
@onready var _score_label: Label = %Score
@onready var _progress_bar: ProgressBar = %ProgressBar

func _ready() -> void:
	set_rank(rank)
	set_player_name(player_name)
	set_max_score(max_score)
	set_current_score(current_score)
	set_color(player_color)

func set_rank(_rank: int) -> void:
	rank = _rank
	_rank_label.text = "#" + str(rank)

func set_player_name(_name: String) -> void:
	player_name = _name
	_name_label.text = player_name

func set_max_score(_max_score: int) -> void:
	max_score = _max_score
	_progress_bar.max_value = _max_score

func set_current_score(_current_score: float) -> void:
	current_score = round(_current_score)
	_progress_bar.value = current_score
	_score_label.text = str(round(current_score))

func set_score(_current_score: int, _max_score: int) -> void:
	if _max_score != null:
		set_max_score(_max_score)
	set_current_score(_current_score)

func set_color(_color: Color) -> void:
	var stylebox: StyleBoxFlat = StyleBoxFlat.new()
	stylebox.bg_color = _color
	stylebox.set_corner_radius_all(30)
	_progress_bar.add_theme_stylebox_override("fill", stylebox)

func add_score(score_to_add: int, _max_score: int) -> void:
	var tween = get_tree().create_tween()
	tween.set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	if _max_score != null:
		tween.tween_method(set_max_score, max_score, _max_score, 1)
	tween.tween_method(set_current_score, current_score, current_score + score_to_add, 1)
