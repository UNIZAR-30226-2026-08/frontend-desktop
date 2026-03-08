shader_type canvas_item;

uniform float dash_count = 9.0;
uniform float dash_ratio = 0.9;

void fragment() {
    vec4 color = COLOR;
    
    if (fract(UV.x * dash_count) > dash_ratio) {
        color.a = 0.0;
    }
    
    COLOR = color;
}