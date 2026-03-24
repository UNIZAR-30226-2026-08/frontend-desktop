extends Control

enum CardSide {FRONT, BACK}

@export var side_to_show: CardSide = CardSide.BACK

signal pressed;

# Referencias a los nodos internos de la carta
@onready var fantasy_card_back: Panel = $SubViewportContainer/SubViewport/FantasyCardBack
@onready var fantasy_card_front: PanelContainer = $SubViewportContainer/SubViewport/FantasyCardFront
@onready var sub_viewport_container: SubViewportContainer = $SubViewportContainer

# --- NUEVOS NODOS DE TEXTO (Asegúrate de que los nombres coincidan en tu escena) ---
# Usamos % para Scene Unique Names si los has configurado así, o la ruta completa
@onready var title_label: Label = %CardTitle 
@onready var description_label: Label = %CardDescription

var flipped = false;

func _ready() -> void:
	pivot_offset = size / 2.0 # Centro del pivote para que rote bien
	_update_visual_side()

# ==========================================
# CONFIGURACIÓN DE DATOS (Step 4)
# ==========================================
func setup_content(data: Dictionary) -> void:
	# Esta función rellena la carta con los datos del JSON/Diccionario
	if title_label:
		title_label.text = data.get("name", "Fantasía")
	
	if description_label:
		description_label.text = data.get("description", "Ha ocurrido algo inesperado...")
	
	# Si tienes iconos según el tipo de acción:
	# var action_type = data.get("action", {}).get("type", "")
	# _update_icon(action_type)

func set_deck_type(type: String) -> void:
	# Cambia el color o estilo del dorso (Suerte vs Caja)
	if type == "suerte":
		fantasy_card_back.modulate = Color.GOLD
	else:
		fantasy_card_back.modulate = Color.MEDIUM_PURPLE

# ==========================================
# LÓGICA DE VOLTEO Y ANIMACIÓN
# ==========================================

func _update_visual_side() -> void:
	fantasy_card_back.visible = (side_to_show == CardSide.BACK)
	fantasy_card_front.visible = (side_to_show == CardSide.FRONT)

func flip() -> void:
	side_to_show = CardSide.FRONT if side_to_show == CardSide.BACK else CardSide.BACK
	_update_visual_side()

func flip_smooth() -> void:
	# 1. Audio (Ya corregido en el AudioSystem)
	var audio = AudioResource.from_type(Globals.AUDIO_CARDFLIP, AudioResource.AudioResourceType.SFX)
	AudioSystem.play_audio_with_position(audio, global_position)
	
	# 2. Primera mitad de la rotación (hasta 90 grados, donde se queda "de canto")
	var tween = create_tween()
	tween.tween_method(_set_y_rot, 0.0, 90.0, 0.2)
	await tween.finished
	
	# 3. Cambio de textura a mitad del giro
	flip()
	
	# 4. Segunda mitad de la rotación (de -90 a 0)
	_set_y_rot(-90.0)
	var tween2 = create_tween()
	tween2.tween_method(_set_y_rot, -90.0, 0.0, 0.2)
	await tween2.finished

func _set_y_rot(value: float) -> void:
	if sub_viewport_container.material:
		sub_viewport_container.material.set_shader_parameter("y_rot", value)

func set_opacity(o: float) -> void:
	if sub_viewport_container.material:
		sub_viewport_container.material.set_shader_parameter("opacity", o)

# ==========================================
# INPUT
# ==========================================

func _on_sub_viewport_container_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		# SOLO girar si la carta está mostrando el dorso (BACK)
		if side_to_show == CardSide.BACK and not flipped:
			flipped = true
			pressed.emit()
			flip_smooth()
		else:
			# Si ya está de frente, solo avisamos que ha sido pulsada
			# (Esto servirá para que el Overlay sepa que debe esperar 3s y cerrarse)
			pressed.emit()
