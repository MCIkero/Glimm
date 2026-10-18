shader_type canvas_item;
// Lichttor: halbtransparentes Feld mit aufsteigenden Lichtlinien.

uniform vec4 field_color : source_color = vec4(0.55, 0.85, 1.0, 0.25);
uniform vec4 line_color = vec4(0.9, 1.4, 1.6, 1.0); // HDR-Wert (> 1) -> leuchtet mit Glow
uniform float line_count = 4.0;
uniform float scroll_speed = 0.35;

void fragment() {
	float band = fract(UV.y * line_count + TIME * scroll_speed);
	float line = smoothstep(0.0, 0.06, band) * (1.0 - smoothstep(0.06, 0.12, band));
	COLOR = mix(field_color, line_color, line);
}
