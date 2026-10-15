shader_type sky;
// Painted sky: gradient, sun glow, drifting pixel clouds and stars. Clouds are left out of the
// radiance cubemap so ambient light stays steady.

uniform vec3 top_color : source_color = vec3(0.33, 0.52, 0.8);
uniform vec3 horizon_color : source_color = vec3(0.78, 0.84, 0.88);
uniform vec3 ground_color : source_color = vec3(0.3, 0.3, 0.28);
uniform vec3 cloud_lit : source_color = vec3(1.0, 0.98, 0.95);
uniform vec3 cloud_shade : source_color = vec3(0.62, 0.68, 0.78);
uniform float cloud_cover = 0.45;
uniform float stars = 0.0;
uniform float sun_glow = 1.0;
uniform sampler2D noise_tex : filter_linear, repeat_enable;
uniform float pix = 180.0;   // how fine the clouds' pixels are (the title's wide sky wants them finer)
// the title's cut (scripts/world/vista.gd): the blow runs out along a plane through the camera (split_n its normal) and
// shoves the clouds aside from it, the cloud overhead (near) first, the cloud low over the horizon (far) last; what
// was on the line is heaped on the edges of the gap
uniform float cut_t = -1.0;
uniform float reach = 900.0;
uniform float spend = 1.4;
uniform vec3 split_n = vec3(1.0, 0.0, 0.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void sky() {
	vec3 dir = EYEDIR;
	float h = dir.y;
	vec3 col = mix(horizon_color, top_color, smoothstep(0.0, 0.5, h));
	if (h < 0.0) {
		col = mix(horizon_color * 0.9, ground_color, smoothstep(0.0, -0.25, h));
	}
	float sd = max(dot(dir, LIGHT0_DIRECTION), 0.0);
	if (LIGHT0_ENABLED) {
		col += LIGHT0_COLOR * (pow(sd, 6.0) * 0.22 + pow(sd, 60.0) * 0.5) * sun_glow * min(LIGHT0_ENERGY, 1.5);
		col += LIGHT0_COLOR * smoothstep(0.9993, 0.9997, sd) * 4.0 * sun_glow;
	}
	if (!AT_CUBEMAP_PASS && h > 0.0) {
		float sp = dot(dir, split_n);
		float a = abs(sp);
		float shift = 0.0;
		float bank = 0.0;
		float G = 0.0;
		if (cut_t > 0.0) {
			float tau = cut_t + spend * log(max(1.0 - min(60.0 / max(h, 0.05), reach) / reach, 1e-4));
			if (tau > 0.0) {
				G = 0.15 * (1.0 - exp(-tau / 0.3) + 0.04 * tau);   // half the gap (as a sine of the angle)
				float s0 = sqrt(max(a * a - G * G, 0.0));
				shift = a - s0;
				float soft = 0.3 * G + 0.006;
				bank = clamp(a / sqrt(s0 * s0 + soft * soft) - 1.0, 0.0, 1.8);
			}
		}
		vec2 cuv = dir.xz / (h + 0.15) * 0.22 + vec2(TIME * 0.0035, TIME * 0.0012);
		cuv -= split_n.xz * sign(sp) * shift * 0.22 / (h + 0.15);   // the cloud here came from nearer the line
		cuv = floor(cuv * pix) / pix;
		float n = texture(noise_tex, cuv).r * 0.62 + texture(noise_tex, cuv * 2.7 + 0.31).r * 0.38;
		n += bank * 0.12;
		float edge = 1.0 - cloud_cover;
		float c = smoothstep(edge, edge + 0.06, n);
		float dense = smoothstep(edge + 0.04, edge + 0.32, n);
		float toward_sun = pow(sd, 3.0);
		vec3 cc = mix(cloud_lit, cloud_shade, dense * 0.75);
		cc += LIGHT0_COLOR * toward_sun * 0.35 * (1.0 - dense);
		float parted = G > 0.0 ? smoothstep(G, G + 0.025, a + (n - 0.5) * 0.03) : 1.0;
		col = mix(col, cc, c * smoothstep(0.0, 0.1, h) * 0.92 * parted);
		col += cloud_lit * bank * c * 0.45 * parted;
		if (stars > 0.0) {
			vec2 g = floor(dir.xz / (h + 0.4) * 420.0);
			float s = step(0.996, hash(g)) * (0.5 + 0.5 * sin(TIME * 2.0 + hash(g + 3.1) * 40.0));
			col += vec3(s) * stars * (1.0 - c) * smoothstep(0.05, 0.3, h);
		}
	}
	COLOR = col;
}
