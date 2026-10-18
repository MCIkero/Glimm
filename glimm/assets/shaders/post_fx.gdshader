shader_type canvas_item;
// Nachbearbeitung über das ganze Bild:
//  - Vignette, die bei wenig Licht stärker wird (passt zum Licht-Twist)
//  - kurze chromatische Aberration (Farbversatz) bei Bash und Tod

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.35;
uniform float aberration : hint_range(0.0, 0.05) = 0.0;
uniform vec3 tint = vec3(1.0, 1.0, 1.0);

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 offset = uv - 0.5;
	vec3 color;
	color.r = texture(screen_texture, uv + offset * aberration).r;
	color.g = texture(screen_texture, uv).g;
	color.b = texture(screen_texture, uv - offset * aberration).b;

	float dist = length(offset * vec2(1.0, 0.8));
	float vignette = smoothstep(0.8, 0.2, dist);
	color *= mix(1.0 - vignette_strength, 1.0, vignette);
	COLOR = vec4(color * tint, 1.0);
}
