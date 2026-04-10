extends BlurryBgOverlay

@onready var header = $CenterContainer/ModalPanel/ClipMask/VBox/Header

@onready var music_slider: HSlider = $CenterContainer/ModalPanel/ClipMask/VBox/ContentMargin/SlidersVBox/MusicRow/MusicSlider
@onready var music_mute_btn: Button = $CenterContainer/ModalPanel/ClipMask/VBox/ContentMargin/SlidersVBox/MusicRow/Top/MusicMuteBtn

@onready var sfx_slider: HSlider = $CenterContainer/ModalPanel/ClipMask/VBox/ContentMargin/SlidersVBox/SFXRow/SFXSlider
@onready var sfx_mute_btn: Button = $CenterContainer/ModalPanel/ClipMask/VBox/ContentMargin/SlidersVBox/SFXRow/Top/SFXMuteBtn

@onready var ui_slider: HSlider = $CenterContainer/ModalPanel/ClipMask/VBox/ContentMargin/SlidersVBox/UIRow/UISlider
@onready var ui_mute_btn: Button = $CenterContainer/ModalPanel/ClipMask/VBox/ContentMargin/SlidersVBox/UIRow/Top/UIMuteBtn

func _ready() -> void:
	super()
	blur_filter.gui_input.connect(_on_backdrop_gui_input)

	if header.has_signal("back_action_requested"):
		header.back_action_requested.connect(
			func():
				AudioSystem.save_settings()
				queue_free()
		)
	
	music_slider.value = AudioSystem.get_music_volume()
	sfx_slider.value = AudioSystem.get_sfx_volume()
	ui_slider.value = AudioSystem.get_ui_volume()
	
	_init_mute_state(music_mute_btn, music_slider, AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")))
	_init_mute_state(sfx_mute_btn, sfx_slider, AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")))
	_init_mute_state(ui_mute_btn, ui_slider, AudioServer.is_bus_mute(AudioServer.get_bus_index("UI")))

	music_slider.value_changed.connect(_on_music_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	ui_slider.value_changed.connect(_on_ui_slider_changed)
	
	music_mute_btn.toggled.connect(_on_music_mute_toggled)
	sfx_mute_btn.toggled.connect(_on_sfx_mute_toggled)
	ui_mute_btn.toggled.connect(_on_ui_mute_toggled)

func _init_mute_state(btn: Button, slider: HSlider, is_muted: bool) -> void:
	btn.set_pressed_no_signal(is_muted)
	btn.text = "MUTED" if is_muted else "MUTE"
	slider.editable = !is_muted

func _on_music_slider_changed(value: float) -> void:
	AudioSystem.set_music_volume(value)
	if value > 0 and music_mute_btn.button_pressed:
		music_mute_btn.button_pressed = false 

func _on_sfx_slider_changed(value: float) -> void:
	AudioSystem.set_sfx_volume(value)
	if value > 0 and sfx_mute_btn.button_pressed:
		sfx_mute_btn.button_pressed = false

func _on_ui_slider_changed(value: float) -> void:
	AudioSystem.set_ui_volume(value)
	if value > 0 and ui_mute_btn.button_pressed:
		ui_mute_btn.button_pressed = false

func _on_music_mute_toggled(toggled_on: bool) -> void:
	music_slider.editable = !toggled_on
	if toggled_on:
		AudioSystem.mute_music()
	else:
		AudioSystem.unmute_music()

func _on_sfx_mute_toggled(toggled_on: bool) -> void:
	sfx_slider.editable = !toggled_on
	if toggled_on:
		AudioSystem.mute_sfx()
	else:
		AudioSystem.unmute_sfx()

func _on_ui_mute_toggled(toggled_on: bool) -> void:
	ui_slider.editable = !toggled_on
	if toggled_on:
		AudioSystem.mute_ui()
	else:
		AudioSystem.unmute_ui()

func _on_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		AudioSystem.save_settings()
		queue_free()
