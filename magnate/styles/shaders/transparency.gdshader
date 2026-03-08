shader_type canvas_item;

uniform float opacity : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	COLOR = vec4(COLOR[0], COLOR[1], COLOR[2], COLOR[3] * opacity);
}