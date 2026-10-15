shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;
// Y-billboarded pixel tufts for MultiMesh scattering. Wind arrives in gusts that roll across the
// field (sway and a lighter sheen where it blows), plants part around the player, clouds drift over.

uniform sampler2D tex : source_color, filter_nearest;
uniform sampler2D noise_tex : filter_linear, repeat_enable;
uniform float sway = 0.06;
uniform float wind_speed = 1.6;
global uniform vec3 player_pos;
global uniform float gust;
global uniform float cloud_amount;

varying float v_wave;
varying vec3 v_origin;

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	v_origin = origin;
	float top = 1.0 - UV.y;
	float wave = texture(noise_tex, origin.xz * 0.028 + vec2(TIME * 0.06, TIME * 0.025)).r;
	wave = smoothstep(0.35, 0.8, wave);
	v_wave = wave * top;
	float amp = sway * (0.35 + 2.2 * wave) * gust;
	VERTEX.x += (sin(TIME * wind_speed + origin.x * 0.6 + origin.z * 0.45) * 0.5 + 0.6) * amp * top;
	// part around the player
	vec2 dp = origin.xz - player_pos.xz;
	float near = smoothstep(1.1, 0.15, length(dp)) * step(abs(origin.y - player_pos.y), 1.5);
	VERTEX.x += sign(dp.x + 0.001) * near * 0.16 * top;
	VERTEX.y *= 1.0 - near * 0.45;
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)) * length(MODEL_MATRIX[0].xyz), 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
		vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))) * length(MODEL_MATRIX[2].xyz), 0.0),
		MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec4 t = texture(tex, UV);
	vec3 col = t.rgb * COLOR.rgb;
	col *= 1.0 + v_wave * 0.22;
	float cl = texture(noise_tex, v_origin.xz * 0.011 + vec2(TIME * 0.0065, TIME * 0.0028)).r;
	col *= 1.0 - smoothstep(0.5, 0.66, cl) * cloud_amount;
	ALBEDO = col;
	ALPHA = t.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.25, 0.0)).xyz);
	ROUGHNESS = 1.0;
}
