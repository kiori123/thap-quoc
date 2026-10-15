shader_type canvas_item;
// The dialogue board opens from its middle outward, like a scroll unrolled (0 = shut, 1 = open).

uniform float reveal : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float d = abs(UV.x - 0.5) * 2.0;
	float edge = reveal * 1.08;
	COLOR = vec4(c.rgb, c.a * smoothstep(edge, edge - 0.06, d));
}
