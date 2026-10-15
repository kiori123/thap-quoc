shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;
// Y-billboarded pixel foliage (single plants or MultiMesh canopy clumps). Bends from the base with
// the same rolling gusts as the grass, leaves rustle by a pixel, drifting cloud shadows pass over.

uniform sampler2D tex : source_color, filter_nearest;
uniform sampler2D noise_tex : filter_linear, repeat_enable;
uniform float sway = 0.12;       // metres at the top
uniform float height = 3.0;      // quad height in metres (bend profile)
uniform float whole = 0.0;       // 1 = the whole quad drifts (canopy clumps), 0 = bend from the base
uniform float rustle = 1.0;      // pixel shimmer of the leaves
uniform float tex_w = 64.0;
uniform float light_wrap = 0.35; // keeps the shaded side from going black
global uniform float gust;
global uniform float cloud_amount;
global uniform vec3 player_pos;
global uniform vec3 cam_pos;     // the gameplay camera (set by the camera rig every frame)

varying vec3 v_origin;

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	v_origin = origin;
	float h = clamp(VERTEX.y / height, 0.0, 1.0);
	float bend = mix(h * h, 1.0, whole);
	float g = smoothstep(0.35, 0.8, texture(noise_tex, origin.xz * 0.028 + vec2(TIME * 0.06, TIME * 0.025)).r);
	float w = sin(TIME * 1.3 + origin.x * 0.31 + origin.z * 0.17) * 0.6 + sin(TIME * 2.7 + origin.z * 0.5) * 0.25 + 0.5;
	float amp = sway * (0.35 + 1.8 * g) * gust;
	VERTEX.x += w * amp * bend;
	VERTEX.y += whole * sin(TIME * 1.9 + origin.x) * amp * 0.25;
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)) * length(MODEL_MATRIX[0].xyz), 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
		vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))) * length(MODEL_MATRIX[2].xyz), 0.0),
		MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

float dither(vec2 p) {
	// interleaved gradient noise: an even screen-door pattern with no lookup table
	return fract(52.9829189 * fract(dot(p, vec2(0.06711056, 0.00583715))));
}

void fragment() {
	// Leaves between the camera and the player thin out (screen-door, so no sorting), and so do leaves right in
	// front of the lens: a canopy never blinds the view. Only in the camera's own pass, not in shadow passes.
	vec3 eye = INV_VIEW_MATRIX[3].xyz;
	if (distance(eye, cam_pos) < 0.6) {
		vec3 wp = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
		vec3 seg = player_pos + vec3(0.0, 0.9, 0.0) - eye;
		float L = max(length(seg), 0.001);
		vec3 dir = seg / L;
		float along = dot(wp - eye, dir);
		float perp = length(wp - eye - dir * along);
		float block = (1.0 - smoothstep(1.3, 2.1, perp)) * step(0.0, along) * (1.0 - smoothstep(L - 0.5, L - 0.05, along));
		float near_lens = 1.0 - smoothstep(1.6, 3.2, length(wp - eye));
		if (max(block, near_lens) * 0.85 > dither(floor(FRAGCOORD.xy * 0.5))) {
			discard;
		}
	}
	vec2 uv = UV;
	// rows of leaves slip by one texel now and then
	float row = floor(uv.y * tex_w * 0.5);
	uv.x += floor(sin(TIME * 2.3 + row * 1.7 + v_origin.x) * 0.5 + 0.5) / tex_w * rustle * step(0.05, 1.0 - uv.y);
	vec4 t = texture(tex, uv);
	vec3 col = t.rgb * COLOR.rgb;
	float cl = texture(noise_tex, v_origin.xz * 0.011 + vec2(TIME * 0.0065, TIME * 0.0028)).r;
	col *= 1.0 - smoothstep(0.5, 0.66, cl) * cloud_amount;
	ALBEDO = col;
	ALPHA = t.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 0.6, 0.8, 0.0)).xyz);
	ROUGHNESS = 1.0;
}

void light() {
	float nl = dot(NORMAL, LIGHT);
	float wrap = clamp((nl + light_wrap) / (1.0 + light_wrap), 0.0, 1.0);
	DIFFUSE_LIGHT += wrap * ATTENUATION * LIGHT_COLOR / PI;
}
