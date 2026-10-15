shader_type spatial;
render_mode diffuse_lambert, specular_disabled;
// Pixel-art terrain: grass / dirt path / packed-earth yard / rock blended by vertex colour (R, G, B),
// with a dithered threshold so the borders break into pixel clumps instead of smooth gradients.

uniform sampler2D tex_grass : source_color, filter_nearest_mipmap, repeat_enable;
uniform sampler2D tex_dirt : source_color, filter_nearest_mipmap, repeat_enable;
uniform sampler2D tex_yard : source_color, filter_nearest_mipmap, repeat_enable;
uniform sampler2D tex_rock : source_color, filter_nearest_mipmap, repeat_enable;
uniform sampler2D tex_noise : filter_linear, repeat_enable;
uniform sampler2D tex_clouds : filter_linear, repeat_enable;
uniform float tile = 0.7;
uniform float rock_scale = 0.6;   // rock's own tiling (Bạch Sơn maps its 128 px limestone larger, so its beds repeat less)
uniform vec3 tint : source_color = vec3(1.0);
global uniform float cloud_amount;

varying vec3 wpos;
varying vec3 wnrm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

float dither_w(float w, float n) {
	return smoothstep(n - 0.08, n + 0.08, w);
}

void fragment() {
	vec2 uv = wpos.xz * tile;
	vec2 snapped = floor(wpos.xz * 22.0) / 22.0;
	float n = texture(tex_noise, snapped * 0.35).r * 0.8 + 0.1;
	vec3 g = texture(tex_grass, uv).rgb;
	vec3 d = texture(tex_dirt, uv).rgb;
	vec3 y = texture(tex_yard, uv).rgb;
	vec3 bl = pow(abs(wnrm), vec3(4.0));
	bl /= (bl.x + bl.y + bl.z);
	vec3 r = texture(tex_rock, wpos.zy * tile * rock_scale).rgb * bl.x
		+ texture(tex_rock, wpos.xz * tile * rock_scale).rgb * bl.y
		+ texture(tex_rock, wpos.xy * tile * rock_scale).rgb * bl.z;
	vec4 w = COLOR;
	vec3 col = g;
	col = mix(col, d, dither_w(w.r, n));
	col = mix(col, y, dither_w(w.g, n));
	// break the rock's tiling with broad light/dark bands that follow the slope
	float rb = texture(tex_noise, vec2(wpos.x + wpos.z, wpos.y * 2.2) * 0.035).r;
	r *= mix(0.78, 1.12, rb);
	col = mix(col, r, dither_w(w.b, 1.0 - n));
	float macro = texture(tex_noise, wpos.xz * 0.018).r;
	col *= mix(0.86, 1.1, macro);
	// drifting cloud shadows
	float cl = texture(tex_clouds, wpos.xz * 0.011 + vec2(TIME * 0.0065, TIME * 0.0028)).r;
	col *= 1.0 - smoothstep(0.5, 0.66, cl) * cloud_amount;
	ALBEDO = col * tint;
	ROUGHNESS = 1.0;
}
