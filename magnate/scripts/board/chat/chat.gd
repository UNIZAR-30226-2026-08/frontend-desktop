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
var emoji_data: Array = []

func _ready() -> void:
	WsClient.chat_message.connect(add_player_message)
	
	container.position.x = -panel_width
	toggle_btn.pressed.connect(_on_toggle_pressed)
	input_field.text_submitted.connect(_on_text_submitted)
	
	chevron_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	chevron_icon.custom_minimum_size = Vector2(24, 24)
	chevron_icon.pivot_offset = Vector2(12, 12)
	
	chat_button_audio = AudioResource.from_type(Globals.BUTTON_BACK, AudioResource.AudioResourceType.UI)
	
	emoji_data = _load_emojis()
	print("Emojis cargados: ", emoji_data.size())
	_build_emoji_picker()

func _load_emojis() -> Array:
	var file = FileAccess.open("res://assets/game_info/items.json", FileAccess.READ)
	if not file:
		push_error("Chat: No se pudo abrir items.json")
		return []
	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_error("Chat: Error parseando items.json: " + json.get_error_message())
		return []
	var data = json.get_data()
	if not data is Dictionary or not data.has("emoji"):
		push_error("Chat: items.json no tiene clave 'emoji'")
		return []
	return data["emoji"]

func _build_emoji_picker() -> void:
	if emoji_data.is_empty():
		return
	
	var vbox: VBoxContainer = input_field.get_parent()
	
	var sep = HSeparator.new()
	var sep_style = StyleBoxLine.new()
	sep_style.color = Color(0, 0, 0, 0.05)
	sep_style.thickness = 2
	sep.add_theme_stylebox_override("separator", sep_style)
	sep.add_theme_constant_override("separation", 16)
	vbox.add_child(sep)
	vbox.move_child(sep, input_field.get_index())
	
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, 52)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	for emoji in emoji_data:
		var icon: String = emoji.get("icon", "")
		var ename: String = emoji.get("name", "")
		var emoji_id: int = emoji.get("id", -1)
		
		if icon.is_empty() or emoji_id == -1:
			continue
		
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(40, 40)
		btn.flat = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.tooltip_text = ename
		
		var icon_path = "res://assets/icons/emotes/" + icon
		if ResourceLoader.exists(icon_path):
			btn.icon = load(icon_path)
			btn.expand_icon = true
		
		var style_hover = StyleBoxFlat.new()
		style_hover.bg_color = Color(0, 0, 0, 0.06)
		style_hover.corner_radius_top_left = 8
		style_hover.corner_radius_top_right = 8
		style_hover.corner_radius_bottom_left = 8
		style_hover.corner_radius_bottom_right = 8
		btn.add_theme_stylebox_override("hover", style_hover)
		
		var style_pressed = StyleBoxFlat.new()
		style_pressed.bg_color = Color(0, 0, 0, 0.12)
		style_pressed.corner_radius_top_left = 8
		style_pressed.corner_radius_top_right = 8
		style_pressed.corner_radius_bottom_left = 8
		style_pressed.corner_radius_bottom_right = 8
		btn.add_theme_stylebox_override("pressed", style_pressed)
		
		btn.pressed.connect(func(): _on_emoji_selected(emoji_id))
		hbox.add_child(btn)
	
	scroll.add_child(hbox)
	vbox.add_child(scroll)
	vbox.move_child(scroll, input_field.get_index())
	
	await get_tree().process_frame
	var hscroll = scroll.get_h_scroll_bar()
	hscroll.custom_minimum_size = Vector2(0, 4)
	
	var hscroll_track = StyleBoxFlat.new()
	hscroll_track.bg_color = Color("e4e4e7")
	hscroll_track.corner_radius_top_left = 2
	hscroll_track.corner_radius_top_right = 2
	hscroll_track.corner_radius_bottom_left = 2
	hscroll_track.corner_radius_bottom_right = 2
	hscroll.add_theme_stylebox_override("scroll", hscroll_track)
	
	var hscroll_grabber = StyleBoxFlat.new()
	hscroll_grabber.bg_color = Color("a1a1aa")
	hscroll_grabber.corner_radius_top_left = 2
	hscroll_grabber.corner_radius_top_right = 2
	hscroll_grabber.corner_radius_bottom_left = 2
	hscroll_grabber.corner_radius_bottom_right = 2
	hscroll.add_theme_stylebox_override("grabber_area", hscroll_grabber)
	
	var hscroll_grabber_hover = StyleBoxFlat.new()
	hscroll_grabber_hover.bg_color = Color("71717a")
	hscroll_grabber_hover.corner_radius_top_left = 2
	hscroll_grabber_hover.corner_radius_top_right = 2
	hscroll_grabber_hover.corner_radius_bottom_left = 2
	hscroll_grabber_hover.corner_radius_bottom_right = 2
	hscroll.add_theme_stylebox_override("grabber_area_highlight", hscroll_grabber_hover)

func _on_emoji_selected(emoji_id: int) -> void:
	var text = "/emoji %d" % emoji_id
	WsClient.ws_send_chat_message(text)

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
	if Globals.BUILD_TYPE == Globals.BuildType.DEV and new_text[0] == "/":
		_handle_cheat(new_text)
		input_field.text = ""
		return
	WsClient.ws_send_chat_message(new_text.strip_edges())
	input_field.text = ""

func add_player_message(message: Dictionary) -> void:
	Utils.debug("Voy a mostrar el mensaje " + str(message))
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
	
	bubble.add_child(name_label)
	
	if text.begins_with("/emoji "):
		var parts = text.split(" ")
		if parts.size() >= 2 and parts[1].is_valid_int():
			var emoji_id = parts[1].to_int()
			var emoji_info = _find_emoji(emoji_id)
			if emoji_info:
				var icon_path = "res://assets/icons/emotes/" + emoji_info.get("icon", "")
				if ResourceLoader.exists(icon_path):
					var img = TextureRect.new()
					img.texture = load(icon_path)
					img.custom_minimum_size = Vector2(48, 48)
					img.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
					img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
					img.size_flags_horizontal = Control.SIZE_SHRINK_END if is_sender else Control.SIZE_SHRINK_BEGIN
					bubble.add_child(img)
				else:
					_add_text_bubble(bubble, emoji_info.get("name", text), is_sender)
			else:
				_add_text_bubble(bubble, text, is_sender)
	else:
		_add_text_bubble(bubble, text, is_sender)
	
	if is_sender:
		hbox.add_child(spacer)
		hbox.add_child(bubble)
	else:
		hbox.add_child(bubble)
		hbox.add_child(spacer)
		
	message_list.add_child(hbox)
	call_deferred("_scroll_to_bottom")

func _add_text_bubble(bubble: VBoxContainer, text: String, is_sender: bool) -> void:
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
	bubble.add_child(text_panel)

func _find_emoji(emoji_id: int) -> Variant:
	for e in emoji_data:
		if e.get("id", -1) == emoji_id:
			return e
	return null

func _scroll_to_bottom() -> void:
	await get_tree().process_frame
	var scrollbar = scroll_container.get_v_scroll_bar()
	scrollbar.value = scrollbar.max_value

func _handle_cheat(cheat: String) -> void:
	var parts = cheat.split(" ")
	if cheat in ["/help", "/h"]:
		add_player_message({
			"user": RestClient.username,
			"msg": "/dice <d1> <d2> <d3>\n/tp <player_name> <tile_id>\n/money <player_name> <money>\n/property <player_name> <tile_id> <houses> <mortgage>\n/clearProperty <tile_id>"
		})
	elif parts[0] == "/dice":
		WsClient.ws_cheat_dice(int(parts[1]), int(parts[2]), int(parts[3]))
		add_player_message({"user": RestClient.username, "msg": "OK DICE"})
	elif parts[0] == "/tp":
		WsClient.ws_cheat_tp(parts[1], parts[2])
		add_player_message({"user": RestClient.username, "msg": "OK TP"})
	elif parts[0] == "/money":
		WsClient.ws_cheat_money(parts[1], int(parts[2]))
		add_player_message({"user": RestClient.username, "msg": "OK MONEY"})
	elif parts[0] == "/property":
		WsClient.ws_cheat_property(parts[1], parts[2], int(parts[3]), parts[4][0].to_lower() == "t")
		add_player_message({"user": RestClient.username, "msg": "OK PROPERTY"})
	elif parts[0] == "/clearProperty":
		WsClient.ws_cheat_deletehouse(parts[1])
		add_player_message({"user": RestClient.username, "msg": "OK REMOVEHOUSE"})
