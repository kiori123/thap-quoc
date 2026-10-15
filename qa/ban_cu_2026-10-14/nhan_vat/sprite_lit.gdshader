shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;
// A pixel character standing in the 3D world, lit as if it had a body (scripts/world/actor.gd), so it is not a paper
// cut-out pasted on the scene. The pixels stay as drawn; what changes is how the light falls on them:
// - a normal made up from the drawing itself: round across the body (where across its frame a pixel is) and turned
//   out at the silhouette's edge (the slope of the alpha there), a little toward the sky; so the sun and the lanterns
//   light one side and leave the other in shade, as they do the walls and trees round it;
// - a rim where the light comes from behind, as on everything else against the light;
// - the feet a little darker where they meet the ground;
// - turned to face the camera about the vertical (as Sprite3D's FIXED_Y); in the shadow pass it turns to the light, so
//   the shadow it casts is the figure's own shape and not a sliver.

uniform sampler2D tex : source_color, filter_nearest;
uniform vec2 frames = vec2(19.0, 4.0);   // hframes, vframes of the sheet
uniform float body = 0.6;                // how round the body turns to the light
uniform float edge_turn = 0.8;           // how sharply the silhouette's edge turns away
uniform float rim = 0.3;
uniform float albedo_k = 0.84;           // the drawing's whites a step down, into the range of the painted walls and ground
uniform float foot_shade = 0.28;
varying vec3 v_right;
varying vec3 v_up;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0),
		vec4(0.0, 1.0, 0.0, 0.0), vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0), MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	v_right = normalize(MODELVIEW_MATRIX[0].xyz);
	v_up = normalize(MODELVIEW_MATRIX[1].xyz);
}

void fragment() {
	vec4 c = texture(tex, UV) * COLOR;
	vec2 ts = 1.0 / vec2(textureSize(tex, 0));
	// the silhouette's slope here, over two texels so a one-pixel outline still turns
	float al = texture(tex, UV - vec2(ts.x, 0.0)).a + texture(tex, UV - vec2(2.0 * ts.x, 0.0)).a;
	float ar = texture(tex, UV + vec2(ts.x, 0.0)).a + texture(tex, UV + vec2(2.0 * ts.x, 0.0)).a;
	float au = texture(tex, UV - vec2(0.0, ts.y)).a + texture(tex, UV - vec2(0.0, 2.0 * ts.y)).a;
	float ad = texture(tex, UV + vec2(0.0, ts.y)).a + texture(tex, UV + vec2(0.0, 2.0 * ts.y)).a;
	vec2 edge = vec2(al - ar, ad - au) * 0.5;
	float fx = fract(UV.x * frames.x) - 0.5;   // across the frame, -0.5 .. 0.5 (a figure stands in its middle)
	float cyl = clamp(fx / 0.26, -1.0, 1.0);
	vec3 n = normalize(vec3(cyl * body + edge.x * edge_turn, 0.06 + edge.y * edge_turn * 0.6, 1.0));
	NORMAL = normalize(v_right * n.x + v_up * n.y + NORMAL * n.z);
	float fy = fract(UV.y * frames.y);         // 0 at the top of the frame, 1 at its foot
	ALBEDO = c.rgb * albedo_k * (1.0 - foot_shade * smoothstep(0.84, 0.97, fy));
	ALPHA = c.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ROUGHNESS = 1.0;
	RIM = rim;
	RIM_TINT = 0.3;
}
