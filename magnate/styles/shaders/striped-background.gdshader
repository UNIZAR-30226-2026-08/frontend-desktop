shader_type canvas_item;

uniform vec4 color1 : source_color;
uniform vec4 color2 : source_color;
uniform float count = 10.0;

void fragment() {
    float line = fract((UV.x + UV.y) * count / 2.0);
    float stripe = smoothstep(0.5, 0.5, line);
    COLOR = mix(color1, color2, stripe);
}