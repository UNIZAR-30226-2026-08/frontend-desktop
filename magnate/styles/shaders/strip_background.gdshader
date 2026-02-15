shader_type canvas_item;

// Color
uniform vec4 color_b : source_color = vec4(0.95, 0.95, 0.95, 1.0);
uniform vec4 color_a : source_color = vec4(1, 1, 1, 1.0);

// Geometry
uniform float divisions : hint_range(1.0, 100.0) = 20;
uniform float angle : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    vec2 pivot = vec2(0.5, 0.5);
    
    float cos_a = cos(angle);
    float sin_a = sin(angle);
    vec2 rotated_uv = vec2(
        cos_a * (UV.x - pivot.x) + sin_a * (UV.y - pivot.y) + pivot.x,
        cos_a * (UV.y - pivot.y) - sin_a * (UV.x - pivot.x) + pivot.y
    );
    
    float strip_pos = rotated_uv.x * divisions;
    
    if (step(0.5, fract(strip_pos)) == 1.0) {
        COLOR = color_a;
    } else {
        COLOR = color_b;
    }
}