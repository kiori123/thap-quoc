shader_type canvas_item;
// Ink-painting look for the Duyên glimpse (a live 3D stage or a still): the image is pushed toward an ink wash
// on paper, edges get a soft ink line, a little of the true colour survives (porcelain cobalt, skin, straw),
// and the picture bleeds in from the middle as `reveal` goes 0 -> 1.

uniform float reveal = 1.0;

float luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	vec2 uv = UV;
	uv.x += sin(uv.y * 38.0 + TIME * 1.4) * 0.0006;
	uv.y += cos(uv.x * 30.0 + TIME * 1.1) * 0.0005;
	vec4 c = texture(TEXTURE, uv);
	float l = luma(c.rgb);
	// a soft ink line where the tone changes sharply
	vec2 px = TEXTURE_PIXEL_SIZE * 1.6;
	float lx = luma(texture(TEXTURE, uv + vec2(px.x, 0.0)).rgb) - luma(texture(TEXTURE, uv - vec2(px.x, 0.0)).rgb);
	float ly = luma(texture(TEXTURE, uv + vec2(0.0, px.y)).rgb) - luma(texture(TEXTURE, uv - vec2(0.0, px.y)).rgb);
	float edge = smoothstep(0.08, 0.35, length(vec2(lx, ly)));
	vec3 paper = vec3(0.93, 0.90, 0.84);
	vec3 ink = vec3(0.07, 0.065, 0.075);
	vec3 wash = mix(ink, paper, smoothstep(0.04, 0.82, l));
	float chroma = length(c.rgb - vec3(l));
	vec3 col = mix(wash, c.rgb * 0.92 + paper * 0.08, clamp(chroma * 1.8, 0.0, 0.6));
	col = mix(col, ink, edge * 0.55);
	float d = length((UV - 0.5) * vec2(1.0, 0.75));
	col = mix(col, paper * 0.88, smoothstep(0.42, 0.7, d) * 0.6);
	float a = smoothstep(reveal * 0.78, reveal * 0.78 - 0.25, d);
	COLOR = vec4(col, c.a * a);
}
