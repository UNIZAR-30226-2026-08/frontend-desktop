extends MagnateBaseCard

@onready var server_name: Label = %ServerName
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

func set_server_name(p_name: String) -> void:
	server_name.text = p_name
	
# --- Función Maestra ---

func update_all_data(server: PropertyModel) -> void:
	set_server_name(server.name)

# --- Lógica de Resaltado (Highlighter) ---

func highlight_rent(index: int) -> void:
	if flash_tween:
		flash_tween.kill()
	
	# El index 0 sería para 1 servidor, index 1 para 2 servidores
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
