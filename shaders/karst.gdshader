shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx;
// The limestone of the title's pillars and ledge (scripts/world/vista.gd: _spire, _ledge_rock). A pillar's mesh carries
// UV = (how far round it, 0..1; the height in metres, the world's, so the beds run level from pillar to pillar),
// UV2.x = its girth in metres, and COLOR.r = how much of the sky a point sees (dark down a groove or a cleft, under a
// shelf). COLOR.g = 1 marks rock laid on from the world (a table top, the ledge): the grain is put on from above and
// the sides. From these: the grain of the stone, beds of rock a few metres deep with dark joints between them, rain
// streaks running down, flutes catching the light, moss where the rock faces up, the foot gone dark into the deep.

uniform sampler2D grain : source_color, filter_nearest_mipmap, repeat_enable;
uniform sampler2D face : source_color, filter_nearest_mipmap, repeat_enable;   // assets/tex/karst_face.png: fractured rock
uniform sampler2D face_n : hint_normal, filter_linear_mipmap, repeat_enable;   // its relief
uniform float face_m = 14.0;     // metres to a tile of it, so its fragments read from far off
uniform sampler2D noise : filter_linear_mipmap, repeat_enable;   // (the alpha of assets/tex/clouds.png)
uniform vec4 tint : source_color = vec4(0.58, 0.61, 0.68, 1.0);
uniform vec4 moss : source_color = vec4(0.23, 0.29, 0.24, 1.0);
uniform vec4 glow : source_color = vec4(0.0, 0.0, 0.0, 1.0);   // white even in its shade (the white city)
uniform float moss_amount = 1.0;
uniform vec4 fill : source_color = vec4(0.4, 0.44, 0.52, 1.0);   // the light of the bright cloud all round, and up off the sea

uniform float bed_m = 9.0;
uniform float sea = -16.0;
uniform float abyss = -86.0;
varying vec3 wp;
varying vec3 wn;

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

float nz(vec2 p) {
	return texture(noise, p).a;
}

void fragment() {
	float laid = step(0.5, COLOR.g);
	float girth = max(UV2.x, 1.0);
	// round a pillar in whole tiles of each pattern, so no seam shows
	float u_g = UV.x * max(1.0, round(girth * 0.3));
	float u_s = UV.x * max(1.0, round(girth * 0.09));
	float u_f = UV.x * max(2.0, round(girth * 0.5));
	float v = UV.y;
	vec3 bl = pow(abs(wn), vec3(4.0));
	bl /= bl.x + bl.y + bl.z;
	float fm = 1.0 / face_m;
	vec3 g_laid = texture(face, wp.zy * fm).rgb * bl.x + texture(face, wp.xz * fm).rgb * bl.y + texture(face, wp.xy * fm).rgb * bl.z;
	vec2 fuv = vec2(UV.x * max(1.0, round(girth / face_m)), -v * fm);
	vec3 g = mix(texture(face, fuv).rgb, g_laid, laid);
	g = mix(g, texture(grain, vec2(u_g, v * 0.3)).rgb, 0.15 * (1.0 - laid));   // (the fine grain, for near)
	// streaks where the rain runs down; beds with their joints; flutes
	float streak = smoothstep(0.42, 0.85, nz(vec2(u_s, v * 0.0045)) * 0.55 + nz(vec2(u_s * 3.0 + 0.5, v * 0.017)) * 0.45);
	float bv = v / bed_m + 0.7 * sin(v * 0.19 + 1.3) + nz(vec2(u_s * 0.3, v * 0.008 + 0.3)) * 0.9;   // beds thick and thin
	float b = fract(bv);
	float js = 0.25 + 0.75 * fract(sin(floor(bv + 0.5) * 12.9898) * 43758.5);   // some joints open, some tight
	float jr = (1.0 - smoothstep(0.0, 0.07, b)) + smoothstep(0.94, 1.0, b);
	float joint = jr * js;
	float side = 1.0 - laid;
	vec3 col = tint.rgb * g * 1.3;
	col *= 1.0 - streak * 0.55 * side;
	col *= 1.0 - joint * 0.22 * side;
	col *= mix(0.22, 1.0, COLOR.r);
	float up = smoothstep(0.5, 0.82, wn.y + (nz(wp.xz * 0.05) - 0.5) * 0.6);
	col = mix(col, moss.rgb * (0.55 + 0.9 * g.g), up * moss_amount);
	float deep = smoothstep(abyss, sea + 4.0, wp.y);
	col *= mix(0.16, 1.0, deep);
	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.2;
	EMISSION = glow.rgb * mix(0.5, 1.0, COLOR.r) * (1.0 - joint * 0.25 * side) * deep * (1.0 - up * moss_amount * 0.6);
	// what the shade still gets: the cloud all round, more from the sea close above it (not down in the deep)
	float bounce = 0.3 + 0.45 * (1.0 - smoothstep(sea + 2.0, sea + 40.0, wp.y)) * smoothstep(sea - 14.0, sea, wp.y);
	EMISSION += col * fill.rgb * bounce * mix(0.6, 1.0, COLOR.r);
	// the flutes and the beds in relief (pillars only)
	float e = 0.015;
	float du = nz(vec2(u_f + e, v * 0.012)) - nz(vec2(u_f - e, v * 0.012));
	float b2 = fract(b + 0.02);
	float dv = (jr - (1.0 - smoothstep(0.0, 0.07, b2)) - smoothstep(0.94, 1.0, b2)) * js;
	vec3 fn = texture(face_n, fuv).rgb * 2.0 - 1.0;
	vec3 nm = normalize(vec3(fn.xy * 1.2 - vec2(du * 5.0, -dv * 0.3), fn.z));
	NORMAL_MAP = mix(nm, vec3(0.0, 0.0, 1.0), laid) * 0.5 + 0.5;
}
