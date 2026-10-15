shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx;
// Pixel-snapped water: two scrolling noise layers, posterised into deep / shallow / glint bands.

uniform sampler2D noise_tex : filter_linear, repeat_enable;
uniform vec3 deep : source_color = vec3(0.10, 0.20, 0.23);
uniform vec3 shallow : source_color = vec3(0.24, 0.40, 0.40);
uniform vec3 glint : source_color = vec3(0.80, 0.90, 0.88);
uniform float speed = 0.04;
uniform float pixel = 14.0;
uniform float glint_amount = 0.6;

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = floor(wpos.xz * pixel) / pixel;
	float n1 = texture(noise_tex, p * 0.07 + vec2(TIME * speed, TIME * speed * 0.6)).r;
	float n2 = texture(noise_tex, p * 0.11 - vec2(TIME * speed * 0.7, -TIME * speed * 0.4)).r;
	float n = (n1 + n2) * 0.5;
	vec3 col = mix(deep, shallow, step(0.48, n));
	col = mix(col, glint, step(0.70, n) * glint_amount);
	// sparkle: a few glint pixels flash on and off, each on its own beat
	vec2 cell = floor(wpos.xz * pixel * 0.5);
	float tw = fract(sin(dot(cell + floor(TIME * 2.5 + fract(sin(dot(cell, vec2(3.1, 7.7))) * 9.0)), vec2(12.9898, 78.233))) * 43758.5453);
	float sparkle = step(0.72, n) * step(0.94, tw);
	ALBEDO = col;
	EMISSION = glint * sparkle * 0.55;
	ROUGHNESS = 0.22;
	SPECULAR = 0.55;
	NORMAL = normalize(NORMAL + vec3(n1 - 0.5, 0.0, n2 - 0.5) * 0.25);
}
