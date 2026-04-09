extends Control

@onready var bridge_name: Label = %BridgeName
@onready var highlighters: Array = [
	%Highlighter1,
	%Highlighter2
]

var flash_tween: Tween 

func _ready() -> void:
	# Inicialización de highlighters
	for h in highlighters:
		h.visible = true
		h.self_modulate = Color("ffffff")

# --- Funciones de actualización ---

func set_bridge_name(p_name: String) -> void:
	bridge_name.text = p_name
	
# --- Función Maestra ---

func update_all_data(data: Dictionary) -> void:
	set_bridge_name(data.get("name", "Puente"))

# --- Lógica de Resaltado (Highlighter) ---

func highlight_rent(index: int) -> void:
	if flash_tween:
		flash_tween.kill()
	
	# El index 0 sería para 1 bridge, index 1 para 2 bridges
	if index >= 0 and index < highlighters.size():
		var target = highlighters[index]
		target.visible = true
		_run_infinite_flash(target)

func _run_infinite_flash(node: Control) -> void:
	flash_tween = create_tween().set_loops()
	# Color de resaltado (puedes cambiarlo a amarillo o verde según prefieras)
	node.modulate = Color(1.0, 1.0, 0.0, 1.0) 
	
	flash_tween.tween_property(node, "self_modulate:a", 0.8, 0.5).set_trans(Tween.TRANS_SINE)
	flash_tween.tween_property(node, "self_modulate:a", 0.2, 0.5).set_trans(Tween.TRANS_SINE)
