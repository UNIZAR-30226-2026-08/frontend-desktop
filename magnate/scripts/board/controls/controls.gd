extends CanvasLayer
class_name ControlsHUD

signal open_settings_requested
signal roll_dice_requested
signal bankrupt_requested
signal trade_requested
signal admin_requested

@onready var slide_container: Control = $SlideContainer

@onready var roll_button: Button = %RollButton
@onready var admin_button: Button = %AdminButton
@onready var trade_button: Button = %TradeButton
@onready var finish_button: Button = %FinishButton
@onready var bankrupt_button: Button = %BankruptButton
@onready var settings_button: Button = %SettingsButton

var is_hidden: bool = false
var base_x_pos: float = 0.0

func _ready() -> void:
	base_x_pos = slide_container.position.x
	
	settings_button.pressed.connect(func(): open_settings_requested.emit())
	roll_button.pressed.connect(func(): roll_dice_requested.emit())
	admin_button.pressed.connect(func(): admin_requested.emit())
	bankrupt_button.pressed.connect(func(): bankrupt_requested.emit())
	trade_button.pressed.connect(func(): trade_requested.emit())
	finish_button.pressed.connect(WsClient.ws_action_end_current_phase)

func toggle_hud_visibility(to_hide: bool) -> void:
	if is_hidden == to_hide: return
	is_hidden = to_hide
	
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	var target_x = base_x_pos - 400.0 if to_hide else base_x_pos
	var target_alpha = 0.0 if to_hide else 1.0
	
	tween.tween_property(slide_container, "position:x", target_x, 0.5)
	tween.parallel().tween_property(slide_container, "modulate:a", target_alpha, 0.5)
	
	slide_container.mouse_filter = Control.MOUSE_FILTER_IGNORE if to_hide else Control.MOUSE_FILTER_PASS

func set_roll_disabled(disabled: bool) -> void: _set_btn_state(roll_button, disabled)
func set_admin_disabled(disabled: bool) -> void: _set_btn_state(admin_button, disabled)
func set_trade_disabled(disabled: bool) -> void: _set_btn_state(trade_button, disabled)
func set_finish_disabled(disabled: bool) -> void: _set_btn_state(finish_button, disabled)
func set_bankrupt_disabled(disabled: bool) -> void: _set_btn_state(bankrupt_button, disabled)

func _set_btn_state(btn: Button, disabled: bool) -> void:
	btn.modulate.a = 0.5 if disabled else 1.0
	
	if disabled:
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
