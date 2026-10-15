shader_type canvas_item;
// Ink-blot screen transition: progress 0 = clear, 1 = fully covered.

uniform float progress = 0.0;
uniform sampler2D noise_tex : filter_linear, repeat_enable;

void fragment() {
	vec2 p = UV - 0.5;
	p.x *= 1.78;
	float n = texture(noise_tex, UV * 1.7).r;
	float r = length(p) * 0.9 + n * 0.35;
	float edge = progress * 1.35;
	float a = smoothstep(edge - 0.02, edge - 0.06, r);
	COLOR = vec4(0.04, 0.035, 0.05, a);
}
