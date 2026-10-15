shader_type canvas_item;
// A big name written with a brush that is running dry: the letters break into streaks along their length.

uniform sampler2D noise_tex : filter_linear, repeat_enable;

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float streak = texture(noise_tex, FRAGCOORD.xy / vec2(210.0, 9.0)).r;
	float grain = texture(noise_tex, FRAGCOORD.xy / 46.0).r;
	c.a *= smoothstep(0.16, 0.3, streak * 0.75 + grain * 0.45);
	COLOR = c;
}
