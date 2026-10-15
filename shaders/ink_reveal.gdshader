shader_type canvas_item;
// The dialogue box spreads in like ink from its left end: a ragged edge (noise) sweeps across it.
// (On a NinePatchRect, UV.x still runs left to right across the whole box.)

uniform sampler2D noise_tex : filter_linear, repeat_enable;
uniform float reveal = 1.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float n = texture(noise_tex, UV * vec2(2.5, 1.2)).r;
	float edge = UV.x * 0.85 + n * 0.3;
	c.a *= smoothstep(edge - 0.06, edge, reveal * 1.2);
	COLOR = c;
}
