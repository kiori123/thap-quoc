shader_type canvas_item;
// The cut from the title into the game: a bright line across the screen where the blade went, and the whole picture
// smeared along it (as if the cut dragged it), washing pale. amount 0..1 the smear, cut 0..1 the line.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform float cut : hint_range(0.0, 1.0) = 0.0;
uniform vec2 dir = vec2(-0.78, 0.62);      // the stroke on screen: from the upper right down to the lower left
uniform vec2 origin = vec2(0.5, 0.5);      // a point the line goes through (the blade, on screen)
uniform vec4 wash : source_color = vec4(0.88, 0.89, 0.92, 1.0);

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 d = normalize(dir);
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 step_uv = d * vec2(1.0 / aspect, 1.0) * amount * 0.11;
	vec3 acc = vec3(0.0);
	float wsum = 0.0;
	for (int i = 0; i < 20; i++) {
		float t = float(i) / 19.0 - 0.5;
		float w = 1.0 - abs(t) * 1.4;
		acc += textureLod(screen_tex, uv + step_uv * t, amount * 3.5).rgb * w;
		wsum += w;
	}
	vec3 col = acc / wsum;
	col = mix(col, wash.rgb, amount * amount * 0.45);
	// the line of the cut, through the blade, along the stroke
	vec2 p = (uv - origin) * vec2(aspect, 1.0);
	vec2 n = vec2(-d.y, d.x);
	float dist = abs(dot(p, n));
	float core = 1.0 - smoothstep(0.0015, 0.004 + 0.004 * cut, dist);
	float glow = (1.0 - smoothstep(0.0, 0.02 + 0.03 * cut, dist)) * 0.32;   // (narrow: the hero and the roofs stay readable)
	col += vec3(1.0, 0.98, 0.94) * cut * (core + glow);
	COLOR = vec4(col, 1.0);
}
