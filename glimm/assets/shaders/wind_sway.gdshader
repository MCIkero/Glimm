shader_type canvas_item;
// Wind: verschiebt die Vertices seitlich. Das verankerte Ende bleibt fest stehen.
// anchored_top = false -> Gras (unten fest), true -> Ranken (oben fest).

uniform float strength = 3.0;
uniform float speed = 1.6;
uniform bool anchored_top = false;

void vertex() {
	float weight = anchored_top ? UV.y : 1.0 - UV.y;
	float world_x = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).x;
	VERTEX.x += sin(TIME * speed + world_x * 0.05) * strength * weight;
}
