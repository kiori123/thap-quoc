shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
// One layer of the mist under the cloud sea on the title (scripts/world/vista.gd). The layers are stacked from just
// under the cloud down into the deep, each darker and bluer than the one above, so what shows when the cut parts
// the cloud is depth: the pillars go down through veils of mist into the dark, never to a bare foot. Behind the blow
// as it runs out along the cut, light falls in along it, strongest in the upper layers.

uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 col : source_color = vec4(0.36, 0.42, 0.52, 0.5);
uniform vec2 scale = vec2(3.0, 2.4);
uniform vec2 drift = vec2(0.004, 0.002);
uniform vec2 offset = vec2(0.0);
uniform float glow_k = 1.0;                // how much of the light reaches this veil
uniform float cut_t = -1.0;                // seconds since the blade landed
uniform float reach = 900.0;
uniform float spend = 1.4;
uniform vec3 split_n = vec3(1.0, 0.0, 0.0);
uniform vec3 split_o = vec3(0.0);
varying vec3 wp;

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = UV * scale + offset + drift * TIME;
	float n = texture(tex, uv).a * 0.6 + texture(tex, uv * 1.9 + 0.37).a * 0.4;
	float veil = 0.55 + 0.45 * smoothstep(0.15, 0.75, n);   // never quite clear: a veil with denser drifts in it
	float lit = 0.0;
	if (cut_t > 0.0) {
		vec3 rel = wp - split_o;
		float nl = max(length(split_n.xz), 0.05);
		vec2 nh = split_n.xz / nl;
		vec2 fh = vec2(nh.y, -nh.x);
		fh = fh.y > 0.0 ? -fh : fh;
		float d = dot(rel.xz, fh);
		float side = abs(dot(rel, split_n)) / nl;
		float behind = smoothstep(0.0, 40.0, reach * (1.0 - exp(-cut_t / spend)) - d);   // where the blow has passed
		float ahead = smoothstep(-2.0, 10.0, d);
		lit = min(cut_t / 0.8, 1.0) * glow_k * behind * ahead * (1.0 - smoothstep(0.0, 3.0 + max(d, 0.0) * 0.1, side));
	}
	ALBEDO = col.rgb + vec3(0.2, 0.24, 0.32) * lit * n;
	ALPHA = clamp(col.a * veil + lit * 0.12, 0.0, 1.0);
}
