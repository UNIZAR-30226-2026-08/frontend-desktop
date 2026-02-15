shader_type canvas_item;

uniform float split_point : hint_range(0.0, 1.0) = 0.3;
uniform float smoothness : hint_range(0.0, 1.0) = 1;
uniform vec4 fade_color : source_color = vec4(0.0, 0.0, 0.0, 0.1);
uniform bool exclude_white = false;

void fragment() {
	vec4 white = vec4(1, 1, 1, 1);
	vec4 tex_color = COLOR;
	// Esto es para excluir el borde blanco del bigbutton, el 0.7 se ha
	// buscado a prueba y error, como mucho la distancia es la norma a la 2
	// 4 * 4 = 16
	if (!exclude_white || distance(tex_color, white) > 0.7) {
		float mask = smoothstep(split_point - smoothness, split_point + smoothness, 1.0 - UV.y);
		vec3 final_rgb = mix(fade_color.rgb, tex_color.rgb, mask);
		COLOR = vec4(final_rgb, tex_color.a);
	}
}
