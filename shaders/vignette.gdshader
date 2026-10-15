shader_type canvas_item;

uniform float strength = 0.42;

void fragment() {
	vec2 uv = UV - 0.5;
	float v = smoothstep(0.32, 0.86, length(uv * vec2(1.0, 0.82)));
	COLOR = vec4(0.03, 0.02, 0.04, v * strength);
}
