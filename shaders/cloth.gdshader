shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;
// Laundry on a line: hangs from the top edge and billows with the gusts.

uniform sampler2D tex : source_color, filter_nearest;
uniform float phase = 0.0;
global uniform float gust;

void vertex() {
	float hang = 1.0 - UV.y;   // 0 at the line, 1 at the hem
	hang = 1.0 - hang;
	float w = sin(TIME * 3.1 + phase + VERTEX.x * 5.0) * 0.5 + sin(TIME * 5.3 + phase * 2.0) * 0.25;
	VERTEX.z += (w + 0.6) * 0.09 * UV.y * gust;
	VERTEX.x += sin(TIME * 2.2 + phase) * 0.015 * UV.y * gust;
}

void fragment() {
	vec4 t = texture(tex, UV);
	ALBEDO = t.rgb;
	ALPHA = t.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ROUGHNESS = 1.0;
}
