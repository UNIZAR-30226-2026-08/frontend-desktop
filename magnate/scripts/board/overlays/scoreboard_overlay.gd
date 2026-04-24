extends BlurryBgOverlay

signal button_pressed

@onready var category_name = %TitleLabel
@onready var unnamed_scores = [%ScoreboardEntry, %ScoreboardEntry2, %ScoreboardEntry3, %ScoreboardEntry4]
@onready var confirm_button: Button = %ConfirmButton
var named_scores = {}

func _ready() -> void:
	super()
	confirm_button.pressed.connect(button_pressed.emit)
	for player in ModelManager.game.players.values():
		add_player(player.player_name, player.color)
	for entry in unnamed_scores:
		entry.hide()

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
	
	unnamed_scores[0].show()
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
	var order = []
	order.resize(len(named_scores))
	var y_positions = []
	y_positions.resize(len(named_scores))
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
