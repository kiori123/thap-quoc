shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
// The top of the cloud sea on the title (scripts/world/vista.gd _build_deck): one skin of cloud with round heads and
// creases between them, lit by the sun (heads bright, creases and the sides turned from the sun in cool shade, edges
// against the sun silvered), soft where rock stands up through it.
// When the protagonist cuts, the blow runs out along the cut (fast, slowing, spent short of the horizon) and shoves
// the cloud aside from the line of it. The skin is carried outwards, not rubbed out: the cloud from the channel is
// heaped into a bank along each wall, which rears up, then slumps and spreads as the push dies. Where a pillar stands
// in the way the bank stops against it and piles higher, and behind the pillar the cloud is left lying. A swell runs
// out over the sea ahead of the banks. The channel's walls go down through the cloud and open on the deep under it;
// the light let in by the cut falls on them.

uniform sampler2D noise : filter_linear_mipmap, repeat_enable;   // assets/tex/cloud_noise.png
uniform sampler2D depth_tex : hint_depth_texture, filter_linear_mipmap;
uniform float sea = -16.0;
uniform float thick = 11.0;      // how deep the cloud is, down to its underside (m)
uniform float heads = 9.0;       // how high its heads stand (m)
uniform vec3 sun_dir = vec3(0.6, 0.37, -0.7);   // toward the sun
uniform vec4 lit_col : source_color = vec4(0.8, 0.82, 0.87, 1.0);
uniform vec4 shade_col : source_color = vec4(0.36, 0.41, 0.51, 1.0);
uniform vec4 deep_col : source_color = vec4(0.22, 0.26, 0.35, 1.0);
uniform vec4 rim_col : source_color = vec4(1.0, 0.98, 0.94, 1.0);
uniform vec4 cut_col : source_color = vec4(0.72, 0.82, 1.0, 1.0);
uniform vec2 wind = vec2(0.6, 0.25);   // m/s
uniform float cut_t = -1.0;      // seconds since the cloud gave way (below 0: not yet)
uniform float seam = 0.0;        // the line of the cut lying on the cloud in the held breath before it gives
uniform float reach = 900.0;     // how far out along the cut the blow carries (m)
uniform float spend = 1.4;       // how fast it slows (s)
uniform vec3 split_n = vec3(1.0, 0.0, 0.0);
uniform vec3 split_o = vec3(0.0);
uniform vec4 rocks[64];          // pillars standing through the cloud: (across the channel, along it, radius, 0)
uniform int n_rocks = 0;

varying vec3 wp;
varying vec2 src;
varying float k_wall;
varying float heap;
varying float lit_cut;
varying vec3 nrm;
varying float along;
varying float across;

float arrive(float d) {
	return -spend * log(max(1.0 - d / reach, 1e-4));
}

float push_at(float d, float tau) {
	// how far the cut has shoved the cloud aside, d metres out along it, tau seconds after the blow got there
	// (vista.gd _push)
	float k = (3.0 + d * 0.32) * (1.0 - 0.45 * clamp(d / reach, 0.0, 1.0));
	return k * (1.0 - exp(-tau / 0.35) + 0.12 * tau);
}

float skin(vec2 p) {
	// the heads of the cloud over p, drifting on the wind
	vec2 q = p - wind * TIME;
	float a = textureLod(noise, q / 360.0, 0.0).r;
	float b = textureLod(noise, q / 140.0 + vec2(0.31, 0.57), 0.0).r;
	float sw = textureLod(noise, q / 900.0 + vec2(0.13, 0.71), 0.0).g;
	return (a * 0.6 + b * 0.4) * heads + (sw - 0.5) * heads * 0.8;
}

float deck(vec2 xz, float cap, out vec2 o_src, out float kw, out float hp, out float lc, out float along_d, out float across_s) {
	// the height of the cloud's top over xz, after the blow; cap: how far out a pillar lets the bank go here
	float nl = max(length(split_n.xz), 0.05);
	vec2 nh = split_n.xz / nl;
	vec2 fh = vec2(nh.y, -nh.x);
	fh = fh.y > 0.0 ? -fh : fh;
	vec2 rel = xz - split_o.xz;
	float s = (dot(rel, split_n.xz) + (sea - split_o.y) * split_n.y) / nl;   // across the channel, at the sea
	float d = dot(rel, fh);                                                   // out along it
	float shift = 0.0;
	float dy = 0.0;
	kw = 0.0;
	hp = 0.0;
	lc = 0.0;
	if (cut_t > 0.0 && d > -4.0 && d < reach) {
		float tau = cut_t - arrive(max(d, 0.0));
		if (tau > 0.0) {
			float ahead = smoothstep(-4.0, 6.0, d);
			float a = abs(s);
			float P0 = push_at(max(d, 0.0), tau) * ahead;
			// the walls are not ruled lines: they bulge and bite in, in big billows and small
			float rag = textureLod(noise, vec2(d / 260.0, 0.37 + sign(s) * 0.21), 0.0).g;
			float rag2 = textureLod(noise, vec2(d / 45.0, 0.61 + sign(s) * 0.17), 0.0).r;
			P0 *= 0.8 + 0.4 * rag + 0.3 * (rag2 - 0.5);
			float P = min(P0, cap);
			// squeezed against the wall, but only so far (a cloud is not crushed into a blade)
			float c = 0.4 * P + 2.0;
			// (inside the wall the skin goes on down with it, carried as a piece, not drawn out into streaks)
			float s0 = a >= P ? sqrt(a * a - P * P + c * c) - c : a - P;
			shift = a - s0;
			float u = a - P;                                         // out from the wall
			float W = (0.35 * P0 + 4.0) * (1.0 + 0.6 * tau);        // the bank spreads as it goes
			float V = P0 * thick * 0.35 * (1.0 + 1.5 * (P0 - P) / max(P0, 1.0));   // more where a pillar stopped it
			float H = min(V / W, 7.0) * exp(-tau / 3.0);
			// heaped in round billows along the wall, not a ruled bank
			H *= 0.6 + 0.8 * textureLod(noise, vec2(d / 70.0 + 0.5, 0.11 + sign(s) * 0.33), 0.0).g;
			float uc = u - W * 0.2;
			float prof = exp(-pow(uc / (W * (uc < 0.0 ? 0.5 : 0.8)), 2.0));
			hp = prof * min(H / 5.0, 1.4);
			dy = H * prof;
			// the swell running out over the sea ahead of the bank, spent as it goes
			float w = 1.0 + max(d, 0.0) * 0.035;
			dy += 1.6 * sqrt(w) * exp(-tau / 0.6) * exp(-pow((u - W - 18.0 * w * tau) / (2.0 * w), 2.0));
			// the wall, down through the cloud into the channel
			kw = smoothstep(0.0, -(0.35 * P + 4.0), u);
			lc = exp(-max(u, 0.0) / (W * 0.8)) * smoothstep(0.0, 0.3, tau) * ahead;
		}
	}
	o_src = xz - (split_n.xz / nl) * sign(s) * shift;
	along_d = d;
	across_s = s;
	float y = sea + skin(o_src) * (1.0 - 0.35 * min(hp, 1.0)) + dy;
	return mix(y, sea - thick, kw);
}

void vertex() {
	vec3 w0 = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// the pillars that stop the push here
	float cap = 1e6;
	if (cut_t > 0.0 && n_rocks > 0) {
		float nl = max(length(split_n.xz), 0.05);
		vec2 nh = split_n.xz / nl;
		vec2 fh = vec2(nh.y, -nh.x);
		fh = fh.y > 0.0 ? -fh : fh;
		vec2 rel = w0.xz - split_o.xz;
		float s = (dot(rel, split_n.xz) + (sea - split_o.y) * split_n.y) / nl;
		float d = dot(rel, fh);
		for (int i = 0; i < n_rocks && abs(s) < 420.0 && d > -10.0; i++) {
			vec4 rk = rocks[i];
			if (sign(rk.x) != sign(s) || abs(rk.x) < rk.z * 0.6) {
				continue;
			}
			float lane = 1.0 - smoothstep(0.75, 1.5, abs(d - rk.y) / rk.z);
			if (lane > 0.0) {
				cap = min(cap, max(abs(rk.x) - rk.z * 1.05, 0.0) + (1.0 - lane) * 60.0);
			}
		}
	}
	vec2 sc;
	float kw;
	float hp;
	float lc;
	vec2 d_src;
	float d_kw;
	float d_hp;
	float d_lc;
	float e = 0.35 + length(w0.xz - CAMERA_POSITION_WORLD.xz) * 0.006;
	float al;
	float d_al;
	float ac;
	float d_ac;
	float y0 = deck(w0.xz, cap, sc, kw, hp, lc, al, ac);
	float yx = deck(w0.xz + vec2(e, 0.0), cap, d_src, d_kw, d_hp, d_lc, d_al, d_ac);
	float yz = deck(w0.xz + vec2(0.0, e), cap, d_src, d_kw, d_hp, d_lc, d_al, d_ac);
	along = al;
	across = ac;
	nrm = normalize(vec3(y0 - yx, e, y0 - yz));
	src = sc;
	k_wall = kw;
	heap = hp;
	lit_cut = lc;
	VERTEX.y = y0 - MODEL_MATRIX[3].y;
	wp = vec3(w0.x, y0, w0.z);
}

void fragment() {
	vec2 q = src - wind * TIME;
	// the skin's fine knobbling
	float f0 = texture(noise, q / 70.0).b;
	vec3 n = normalize(normalize(nrm) + vec3(-dFdx(f0), 0.0, -dFdy(f0)) * 0.35 * (1.0 - k_wall));
	// on the steep of a wall or a bank, billows across it and down it
	float steep = 1.0 - clamp(n.y, 0.0, 1.0);
	vec2 wq = vec2(along / 14.0, wp.y / 6.0);
	float b0 = texture(noise, wq * 0.5).r;
	float b2 = texture(noise, wq * 0.5 + vec2(0.0, 0.02)).r;
	n = normalize(n + vec3(0.0, (b0 - b2) * 6.0, 0.0) * steep);
	float billow = mix(1.0, 0.82 + 0.3 * b0, smoothstep(0.2, 0.7, steep));
	vec3 L = normalize(sun_dir);
	vec3 V = normalize(CAMERA_POSITION_WORLD - wp);
	float wrap = clamp((dot(n, L) + 0.6) / 1.6, 0.0, 1.0);
	// a cloud is light where it stands up into the light and grey down in its folds: the height says more than the slope
	float hgt = smoothstep(-0.2, 1.1, (wp.y - sea) / heads);
	vec3 col = mix(shade_col.rgb, lit_col.rgb, clamp(wrap * 0.45 + hgt * 0.65, 0.0, 1.0)) * billow;
	// silver at the edges where the sun is behind the cloud
	float back = pow(clamp(dot(-V, L), 0.0, 1.0), 3.0);
	float edge = pow(1.0 - clamp(dot(n, V), 0.0, 1.0), 3.0);
	col += rim_col.rgb * back * edge * 0.3;
	// heaped cloud catches more light on its crest
	col += vec3(0.06, 0.065, 0.07) * heap * wrap;
	// the channel's walls: darker going down, lit by the light the cut let in
	col = mix(col, deep_col.rgb, k_wall * 0.75);
	col += cut_col.rgb * lit_cut * (0.08 + 0.25 * k_wall);
	// the line of the cut across the sea, from the ledge to the horizon: a hairline near, wider far, a glow round it
	if (seam > 0.0 && along > 2.0) {
		float lw = 0.12 + along * 0.005;
		float line = exp(-pow(abs(across) / lw, 2.0)) + 0.14 * exp(-abs(across) / (lw * 8.0));
		col += vec3(1.0, 0.98, 0.95) * line * seam * 1.4;
	}
	ALBEDO = col;
	// the wall thins into mist going down; low in its folds the cloud is thin enough to see the dark through
	float a = 1.0 - smoothstep(0.02, 0.45, k_wall + (texture(noise, q / 25.0).a - 0.5) * 0.3);
	a *= mix(0.95, 1.0, hgt);
	// soft where rock stands through it
	float depth = texture(depth_tex, SCREEN_UV).x;
	vec4 sv = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	sv.xyz /= sv.w;
	a *= smoothstep(0.0, 1.2, VERTEX.z - sv.z);
	ALPHA = a;
}
