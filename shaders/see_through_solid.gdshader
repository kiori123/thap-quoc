shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
// An opaque surface (the city wall by the gate, its towers and roofs) that thins out, screen-door style, where it
// stands between the camera and the player: the same see-through as the foliage, so the wall stays in the picture
// and only the part in the way goes thin. Mirrors a StandardMaterial3D (UV or world triplanar mapping).

uniform sampler2D albedo_tex : source_color, filter_nearest_mipmap, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform bool use_tex = true;
uniform bool triplanar = false;
uniform bool world_triplanar = false;
uniform vec3 uv_scale = vec3(1.0);
uniform float roughness_v = 1.0;
uniform float active = 0.0;    // 1 = thin out between the camera and the player
uniform float radius = 2.3;    // metres around the line of sight
// the front wall of the city: with the hero inside and the camera backed out past the wall's inner face, the
// whole of it dissolves (a cutaway), fading back in as the camera comes inside
uniform float cutaway = 0.0;
uniform float cut_z = -25.3;
uniform float cut_keep_y = -1000.0;   // below this the cut wall stays, a stub along its foot
// lime walls weather (Bạch Sơn): grime and damp at the foot, rain streaks, plaster fallen away to the stone
// beneath; all on the same pixel grid as the textures (24 to a metre)
uniform float weather = 0.0;
uniform float ground_y = 4.0;
uniform sampler2D stone_tex : source_color, filter_nearest_mipmap, repeat_enable;
uniform sampler2D noise_tex : filter_linear, repeat_enable;
global uniform vec3 player_pos;
global uniform vec3 cam_pos;   // the gameplay camera (set by the camera rig every frame)

varying vec3 tri_pos;
varying vec3 tri_w;
varying vec3 v_wpos;
varying vec3 v_wnrm;

void vertex() {
	v_wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	if (triplanar) {
		vec3 n = world_triplanar ? normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz) : NORMAL;
		vec3 p = world_triplanar ? (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz : VERTEX;
		tri_w = abs(n);
		tri_w /= dot(tri_w, vec3(1.0));
		tri_pos = p * uv_scale * vec3(1.0, -1.0, 1.0);
	}
}

float hash2(vec2 c) {
	return fract(sin(dot(c, vec2(127.1, 311.7))) * 43758.5453);
}

float dither(vec2 p) {
	// interleaved gradient noise, as the foliage uses
	return fract(52.9829189 * fract(dot(p, vec2(0.06711056, 0.00583715))));
}

void fragment() {
	// only in the camera's own pass, so the wall still casts its whole shadow (the sun's shadow camera can stand close
	// enough to the gameplay camera to pass the distance test, so the shadow pass is named outright)
	if (active > 0.5 && !IN_SHADOW_PASS) {
		vec3 eye = INV_VIEW_MATRIX[3].xyz;
		if (distance(eye, cam_pos) < 0.6) {
			vec3 wp = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
			vec3 seg = player_pos + vec3(0.0, 0.9, 0.0) - eye;
			float L = max(length(seg), 0.001);
			vec3 dir = seg / L;
			float along = dot(wp - eye, dir);
			float perp = length(wp - eye - dir * along);
			float block = (1.0 - smoothstep(radius * 0.45, radius, perp)) * step(0.0, along)
				* (1.0 - smoothstep(L - 0.8, L - 0.2, along))
				* step(player_pos.y + 0.25, wp.y);   // nothing at the player's feet hides them: floors are never thinned
			if (block > dither(FRAGCOORD.xy)) {
				discard;
			}
			if (cutaway > 0.5 && player_pos.z < cut_z && v_wpos.y > cut_keep_y) {
				float gone = smoothstep(cut_z - 2.5, cut_z - 0.2, eye.z);
				if (gone > dither(FRAGCOORD.xy) * 0.98 + 0.01) {
					discard;
				}
			}
		}
	}
	vec4 c = vec4(1.0);
	if (use_tex) {
		if (triplanar) {
			c = texture(albedo_tex, tri_pos.xy) * tri_w.z + texture(albedo_tex, tri_pos.xz) * tri_w.y
				+ texture(albedo_tex, tri_pos.zy * vec2(-1.0, 1.0)) * tri_w.x;
		} else {
			c = texture(albedo_tex, UV * uv_scale.xy);
		}
	}
	vec3 col = c.rgb * tint.rgb;
	if (weather > 0.5) {
		vec3 ps = floor(v_wpos * 24.0) / 24.0;                 // snapped to the pixel grid
		float side = 1.0 - step(0.7, abs(v_wnrm.y));           // walls, not tops
		float h = ps.y - ground_y;
		float along = ps.x * abs(v_wnrm.z) + ps.z * abs(v_wnrm.x);
		// grime and damp at the foot, uneven
		float n1 = texture(noise_tex, vec2(along * 0.31, h * 0.6)).r;
		float foot = (1.0 - smoothstep(0.0, 1.1 + n1 * 0.8, h)) * side;
		col *= mix(1.0, 0.7 + 0.14 * n1, foot * 0.9);
		col *= mix(vec3(1.0), vec3(0.93, 0.97, 0.88), foot * 0.6);
		// rain streaks down from the tops: thin columns, strongest high up
		float sx = floor(along * 24.0 / 3.0);
		float streak = hash2(vec2(sx, 3.1));
		float run = texture(noise_tex, vec2(sx * 0.0517 + hash2(vec2(sx, 9.7)), h * 0.05)).r;
		col *= 1.0 - 0.13 * step(0.8, streak) * smoothstep(0.35, 0.75, run) * smoothstep(0.8, 2.6, h) * side;
		// plaster fallen away: the stone shows, with a dark rim of broken lime round it. A few patches scattered at
		// random (by chance per cell of about 1.7 by 1.3 metres, set anywhere in it), their edges ragged
		// with noise, so they never fall into rows
		vec2 q = vec2(along, h) / vec2(1.7, 1.3);
		vec2 cell = floor(q);
		float wob = (texture(noise_tex, vec2(along, h) * 1.3 + vec2(0.71, 0.29)).r - 0.5) * 0.9;
		float best = -9.0;
		for (int ox = -1; ox <= 1; ox++) {
			for (int oy = -1; oy <= 1; oy++) {
				vec2 cc = cell + vec2(float(ox), float(oy));
				// most where the damp rises, near the foot; few high up
				if (hash2(cc) < 0.03 + 0.13 * (1.0 - smoothstep(1.0, 4.5, (cc.y + 0.5) * 1.3))) {
					vec2 ctr = cc + 0.15 + 0.7 * vec2(hash2(cc + 17.3), hash2(cc + 41.7));
					float sz = 0.12 + 0.2 * hash2(cc + 7.1);
					float d = length((q - ctr) * vec2(1.0, 1.5)) / sz + wob;
					best = max(best, 1.0 - d);
				}
			}
		}
		float hole = step(0.0, best) * step(0.6, h) * side;
		float rim = (step(-0.22, best) - hole) * step(0.6, h) * side;
		vec3 stone = texture(stone_tex, vec2(along, ps.y) * 0.75).rgb * vec3(0.95, 0.93, 0.9);
		col = mix(col, stone, hole);
		col *= 1.0 - 0.24 * rim;
	}
	ALBEDO = col;
	ROUGHNESS = roughness_v;
	SPECULAR = 0.5;
}
