extends CanvasLayer

@onready var container: Control = $HUDContainer
@onready var toggle_btn: Button = $HUDContainer/ToggleButton
@onready var chevron_icon: TextureRect = $HUDContainer/ToggleButton/BtnLayout/IconChevron
@onready var message_list: VBoxContainer = $HUDContainer/Panel/MarginContainer/VBoxContainer/ScrollContainer/MessageList
@onready var scroll_container: ScrollContainer = $HUDContainer/Panel/MarginContainer/VBoxContainer/ScrollContainer
@onready var input_field: LineEdit = $HUDContainer/Panel/MarginContainer/VBoxContainer/InputField
@onready var badge: Panel = %Notification

var is_open: bool = false
var panel_width: float = 320.0
var players_ref: Array[PlayerModel] = []

var chat_button_audio: AudioResource

func _ready() -> void:
	WsClient.chat_message.connect(add_player_message)
	
	container.position.x = -panel_width
	toggle_btn.pressed.connect(_on_toggle_pressed)
	input_field.text_submitted.connect(_on_text_submitted)
	
	chevron_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	chevron_icon.custom_minimum_size = Vector2(24, 24)
	chevron_icon.pivot_offset = Vector2(12, 12)
	
	chat_button_audio = AudioResource.from_type(Globals.BUTTON_BACK, AudioResource.AudioResourceType.UI)

func init_chat(players: Array[PlayerModel]) -> void:
	players_ref = players
	_build_message("¡Bienvenido al chat de Magnate! Construye tu imperio.", false, "Sistema", Color("9ca3af"))

func _on_toggle_pressed() -> void:
	badge.hide()
	is_open = !is_open
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var target_x = 0.0 if is_open else -panel_width
	tween.tween_property(container, "position:x", target_x, 0.5)
	
	var rotation_target = PI if is_open else 0.0
	tween.parallel().tween_property(chevron_icon, "rotation", rotation_target, 0.5)
	
	AudioSystem.play_audio(chat_button_audio)

func toggle_chat_visibility(should_show: bool) -> void:
	self.visible = should_show

func _on_text_submitted(new_text: String) -> void:
	if new_text.strip_edges() == "":
		return
	
	WsClient.ws_send_chat_message(new_text.strip_edges())
	# var local_id = WsClient.player_id
	# add_player_message(local_id, new_text, true)
	input_field.text = ""

func add_player_message(message: Dictionary) -> void:
	var text = message.get("msg", "")
	var p_name: String = message.get("user", "")
	var is_sender = p_name == RestClient.username
	var p_color: Color = Color.WHITE
	
	for model in players_ref:
		if str(model.player_name) == p_name:
			p_color = model.color
			break
	if not is_sender and not is_open:
		badge.show()
	
	_build_message(text, is_sender, p_name, p_color)

func _build_message(text: String, is_sender: bool, sender_name: String, sender_color: Color) -> void:
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var bubble = VBoxContainer.new()
	bubble.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if not is_sender else Control.SIZE_SHRINK_END
	
	var name_label = Label.new()
	name_label.text = sender_name.to_upper()
	name_label.add_theme_color_override("font_color", sender_color)
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if is_sender else HORIZONTAL_ALIGNMENT_LEFT
	
	var text_panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color.WHITE if not is_sender else Color("e0f2fe")
	style.border_width_bottom = 1
	style.border_width_top = 1
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_color = Color("e4e4e7")
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12 if is_sender else 0
	style.corner_radius_bottom_right = 0 if is_sender else 12
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	style.shadow_color = Color(0, 0, 0, 0.05)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	text_panel.add_theme_stylebox_override("panel", style)
	
	var msg_label = Label.new()
	msg_label.text = text
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_label.add_theme_color_override("font_color", Color("3f3f46"))
	msg_label.add_theme_font_size_override("font_size", 14)
	msg_label.custom_minimum_size = Vector2(220, 0)
	
	text_panel.add_child(msg_label)
	bubble.add_child(name_label)
	bubble.add_child(text_panel)
	
	if is_sender:
		hbox.add_child(spacer)
		hbox.add_child(bubble)
	else:
		hbox.add_child(bubble)
		hbox.add_child(spacer)
		
	message_list.add_child(hbox)
	call_deferred("_scroll_to_bottom")

func _scroll_to_bottom() -> void:
	await get_tree().process_frame
	var scrollbar = scroll_container.get_v_scroll_bar()
	scrollbar.value = scrollbar.max_value
