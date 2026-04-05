extends BlurryBgOverlay

@onready var category_name = %TitleLabel
@onready var unnamed_scores = [%ScoreboardEntry, %ScoreboardEntry2, %ScoreboardEntry3, %ScoreboardEntry4]
@onready var confirm_button = %ConfirmButton
var named_scores = {}

func _ready() -> void:
	super()
	
	# Working example
	add_player("Nico", Color("#f94144"))
	add_player("Luquín", Color("#f9c74f"))
	add_player("Cris", Color("#90be6d"))
	add_player("Julia", Color("#2c7da0"))

	await get_tree().create_timer(2).timeout
	await score_category("Más pasos dados", {
		"Nico": 100,
		"Luquín": 110,
		"Cris": 80,
		"Julia": 140
	})
	await score_category("Más transacciones", {
		"Nico": 70,
		"Luquín": 110,
		"Cris": 60,
		"Julia": 70
	})
	finish()

func finish() -> void:
	confirm_button.disabled = false
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(confirm_button, "scale", Vector2(1.1, 1.1), .1)
	tween.tween_property(confirm_button, "scale", Vector2.ONE, .1)

func add_player(_name: String, _color: Color) -> void:
	if len(unnamed_scores) == 0:
		Utils.debug("No score left to assign")
		return
	
	named_scores[_name] = unnamed_scores[0]
	unnamed_scores.pop_front()
	
	named_scores[_name].set_player_name(_name)
	named_scores[_name].set_color(_color)

func add_score_to_player(_name: String, score_to_add: int, max_final_score: int) -> void:
	if not named_scores.has(_name):
		Utils.debug("Name not found in scoreboard")
		return
	named_scores[_name].add_score(score_to_add, max_final_score)

func smooth_sort_entries(scores: Dictionary[String, int]) -> void:
	var order = [null, null, null, null]
	var y_positions = [null, null, null, null]
	for entry in named_scores.values():
		var i = 0
		while order[entry.rank - 1 + i] != null:
			i += 1
		order[entry.rank - 1 + i] = entry
		y_positions[entry.rank - 1 + i] = entry.position.y

	order.sort_custom(
		func(a, b):
			return a.current_score + scores[a.player_name] > b.current_score + scores[b.player_name]
	)
	for i in len(order):
		order[i].set_rank(i + 1)
	
	var tween = get_tree().create_tween().set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	for i in len(y_positions):
		tween.tween_property(order[i], "position:y", y_positions[i], 1)

## Expects a dictionary with names as keys and scores to add
## for this category as values.
## NOTE: Has to be awaited
func score_category(_category_name: String, scores: Dictionary[String, int]) -> void:
	var timer = get_tree().create_timer(2)
	
	category_name.text = _category_name
	var max_final_score = 100
	for _name in scores.keys():
		max_final_score = max(max_final_score, named_scores[_name].current_score + scores[_name])
	smooth_sort_entries(scores)
	for _name in scores.keys():
		add_score_to_player(_name, scores[_name], max_final_score)
	
	await timer.timeout
