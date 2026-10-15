shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
// A layer of the cloud sea on the title (scripts/world/vista.gd): pale cloud drifting. When the protagonist cuts, the
// blow runs out along the cut (a plane through the camera, split_n its normal), fast and slowing till it is spent
// some way short of the horizon, and where it has got to, the cloud is shoved aside from the line of the cut: hard at
// first, then slower, drifting on after; less far out where the blow was already tiring.
// The cloud is carried, not rubbed out: what lay in the channel is heaped up against its walls (denser, brighter,
// churning), and ahead of the walls a shock runs out across the sea, spent as it goes.

uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D depth_tex : hint_depth_texture, filter_linear_mipmap;
uniform vec4 tint : source_color = vec4(0.8, 0.84, 0.9, 0.4);
uniform vec2 scale = vec2(5.0, 4.0);
uniform vec2 offset = vec2(0.0);
uniform vec2 drift = vec2(0.0025, 0.0012);
uniform vec2 plane_size = vec2(1000.0, 800.0);
uniform float rim_amount = 0.0;            // the lit crest of the heaped cloud (on the top layer only)
uniform float push_k = 1.0;                // how far this layer is shoved (the upper ones further: the walls lean back)
uniform float cut_t = -1.0;                // seconds since the blade landed (below 0: not cut)
uniform float reach = 900.0;               // how far out along the cut the blow carries before it is spent (m)
uniform float spend = 1.4;                 // how fast it slows (s)
uniform vec3 split_n = vec3(1.0, 0.0, 0.0);
uniform vec3 split_o = vec3(0.0);          // a point on the cut (the camera)
varying vec3 wp;

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float arrive(float d) {
	// when the blow gets d metres out along the cut (vista.gd _arrive)
	return -spend * log(max(1.0 - d / reach, 1e-4));
}

float push_at(float d, float tau) {
	// how far the cut has shoved the cloud aside, d metres out along it, tau seconds after the blow got there
	// (vista.gd _push)
	float k = (3.0 + d * 0.32) * (1.0 - 0.45 * clamp(d / reach, 0.0, 1.0)) * push_k;
	return k * (1.0 - exp(-tau / 0.35) + 0.12 * tau);
}

void fragment() {
	vec3 rel = wp - split_o;
	float nl = max(length(split_n.xz), 0.05);
	vec2 nh = split_n.xz / nl;                 // across the channel
	vec2 fh = vec2(nh.y, -nh.x);
	fh = fh.y > 0.0 ? -fh : fh;                // along it, out from the ledge
	float s = dot(rel, split_n) / nl;          // metres from the middle of the channel, at this layer's height
	float d = dot(rel.xz, fh);
	float a = abs(s);
	float shift = 0.0;   // how far the cloud now here has been carried out from the line
	float bank = 0.0;    // how much it is heaped
	float P = 0.0;
	float shock = 0.0;
	float flash = 0.0;
	if (cut_t > 0.0) {
		float ahead = smoothstep(-2.0, 8.0, d);
		float tau = cut_t - arrive(max(d, 0.0));
		if (tau > 0.0 && ahead > 0.0 && d < reach) {
			float rag = texture(tex, vec2(d * 0.0035, 0.37 + push_k * 0.13)).a;   // the walls are not ruled lines
			P = push_at(d, tau) * ahead * (0.8 + 0.4 * rag);
			float s0 = sqrt(max(a * a - P * P, 0.0));    // where it lay before the blow
			shift = a - s0;
			float soft = 0.3 * P + 0.5;
			bank = clamp(a / sqrt(s0 * s0 + soft * soft) - 1.0, 0.0, 1.8);
			// the shock: a ripple running out over the sea ahead of the walls, spent as it goes
			float w = 1.0 + max(d, 0.0) * 0.035;
			float r = P + 16.0 * w * tau;
			float amp = exp(-tau / 0.45) * smoothstep(0.0, 0.04, tau);
			shock = amp * exp(-pow((a - r) / (1.6 * w), 2.0));
			shift += shock * 1.2 * w;
			// the blow itself where it is now, lighting the walls as it passes
			float at = reach * (1.0 - exp(-cut_t / spend));
			flash = exp(-pow((d - at) / (6.0 + d * 0.08), 2.0)) * (1.0 - smoothstep(P, P + 4.0 + d * 0.12, a));
		}
	}
	vec2 src = wp.xz - nh * sign(s) * shift;
	// heaped cloud churns
	vec2 churn = vec2(texture(tex, src * 0.011 + TIME * 0.04).a, texture(tex, src * 0.011 + vec2(0.5, 0.2) - TIME * 0.035).a) - 0.5;
	src += churn * bank * (1.0 + max(d, 0.0) * 0.04) * 1.5;
	vec4 c = texture(tex, src / plane_size * scale + offset + drift * TIME);
	float open = 1.0;
	if (P > 0.0) {
		open = clamp((a - P) / (0.25 * P + 0.4) + (c.a - 0.5) * 1.2, 0.0, 1.0);
	}
	ALBEDO = c.rgb * tint.rgb * (1.0 + bank * 0.12) + vec3(0.3, 0.33, 0.38) * (bank * rim_amount * 0.5 + shock * 0.7)
		+ vec3(0.6, 0.68, 0.8) * flash * 0.6;
	float depth = texture(depth_tex, SCREEN_UV).x;
	vec4 sv = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	sv.xyz /= sv.w;
	float touch = smoothstep(0.0, 3.0, VERTEX.z - sv.z);   // soft where it meets rock
	ALPHA = clamp((c.a * tint.a * (1.0 + bank * 0.7 + shock * 1.0) + flash * 0.15) * open * touch, 0.0, 1.0);
}
