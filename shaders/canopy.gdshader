shader_type spatial;
render_mode diffuse_lambert, specular_disabled;
// The forest on the top of a karst tower on the title (scripts/world/vista.gd _canopy): a dome laid over the rock,
// broken into the crowns of trees (round heads a few metres across, pushed out from the dome so its outline is
// lumpy), dark under them and lit on their tops, with the odd paler crown.

uniform sampler2D noise : filter_linear_mipmap, repeat_enable;   // assets/tex/cloud_noise.png (R: round heads)
uniform vec4 leaf_dark : source_color = vec4(0.1, 0.14, 0.12, 1.0);
uniform vec4 leaf_lit : source_color = vec4(0.27, 0.34, 0.24, 1.0);
uniform float crown_m = 3.2;     // how wide a tree's crown is
uniform float bump = 1.5;        // how far the crowns stand out
varying vec3 wp;

float crowns(vec2 p) {
	return textureLod(noise, p / (crown_m * 6.5), 0.0).r * 0.7 + textureLod(noise, p / (crown_m * 2.6) + 0.37, 0.0).r * 0.3;
}

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX += NORMAL * (crowns(w.xz + w.y * 0.7) - 0.45) * bump;
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = wp.xz + wp.y * 0.7;
	float c = crowns(p);
	float e = crown_m * 0.08;
	float cx = crowns(p + vec2(e, 0.0));
	float cz = crowns(p + vec2(0.0, e));
	vec3 wn = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	wn = normalize(wn + vec3(c - cx, 0.0, c - cz) * 6.0);
	NORMAL = normalize((VIEW_MATRIX * vec4(wn, 0.0)).xyz);
	float leaf = textureLod(noise, p / 3.0, 0.0).b;
	vec3 col = mix(leaf_dark.rgb, leaf_lit.rgb, smoothstep(0.25, 0.85, c));
	col *= 0.8 + 0.35 * leaf;
	col = mix(col, col * vec3(1.25, 1.2, 0.95), step(0.86, textureLod(noise, p / 40.0 + 0.5, 0.0).b));   // a paler crown here and there
	ALBEDO = col;
	ROUGHNESS = 1.0;
}
