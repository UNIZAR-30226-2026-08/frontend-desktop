shader_type canvas_item;

uniform vec4 ring_color : source_color = vec4(.89, 0.69, 0.42, 1.0);
uniform vec4 fill_color : source_color = vec4(0, .08, 0, 1);
uniform float thickness : hint_range(0.0, 0.1) = 0.01;
uniform float radius : hint_range(0.0, 0.5) = 0.5;

void fragment() {
	float dist = distance(UV, vec2(0.5));
	float ring = smoothstep(thickness, 0.0, abs(dist - radius));
	float fill = smoothstep(radius, radius - 0.01, dist);
	float glow = 1. - smoothstep(radius, radius + 10. * thickness, dist);
	glow = clamp(glow - fill - ring, 0.0, 1.0);
	vec4 final_color = ring_color * (ring + glow) + fill_color * fill;
	float alpha = clamp(ring + fill + (glow * .2), 0.0, 1.0);
	COLOR = vec4(final_color.rgb, alpha);
}