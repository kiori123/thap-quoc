shader_type canvas_item;
// Final grade drawn under the UI: the HD-2D diorama blur (top and bottom of the frame soft, a sharp band
// through the middle, on top of the camera's depth of field), split toning (cool shadows / warm highlights),
// gentle contrast, a touch of lens fringing toward the corners and fine film grain.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform vec3 shadow_tint : source_color = vec3(0.92, 0.97, 1.08);
uniform vec3 high_tint : source_color = vec3(1.07, 1.01, 0.92);
uniform float split = 0.6;
uniform float contrast = 1.04;
uniform float lift = 0.015;
uniform float fringe = 0.0;
uniform float grain = 0.0;
uniform float tilt = 1.0;           // strength of the diorama blur (0 = off)
uniform float tilt_centre = 0.56;   // where the sharp band sits, 0 top .. 1 bottom
uniform float tilt_band = 0.2;      // half-height of the sharp band
// a touch of ink-wash painting (the title only: scripts/world/vista.gd sets it; 0 = off, as everywhere else)
uniform float ink = 0.0;
uniform sampler2D paper_tex : filter_linear_mipmap, repeat_enable;   // (assets/tex/cloud_noise.png: fibres, blots)
uniform vec3 paper : source_color = vec3(0.93, 0.9, 0.82);           // xuyến chỉ paper
uniform vec3 sumi : source_color = vec3(0.06, 0.06, 0.08);           // ink

vec3 soft(vec2 uv, float lod, vec2 off) {
	// a few taps on the blurred mip so the softness has no blocky steps
	vec2 px = (0.6 + lod) / vec2(textureSize(screen_tex, 0));
	vec3 c = vec3(0.0);
	c.r = textureLod(screen_tex, uv + off, lod).r;
	c.g = textureLod(screen_tex, uv, lod).g;
	c.b = textureLod(screen_tex, uv - off, lod).b;
	if (lod > 0.05) {
		c *= 0.4;
		c += textureLod(screen_tex, uv + vec2(px.x, px.y), lod).rgb * 0.15;
		c += textureLod(screen_tex, uv + vec2(-px.x, px.y), lod).rgb * 0.15;
		c += textureLod(screen_tex, uv + vec2(px.x, -px.y), lod).rgb * 0.15;
		c += textureLod(screen_tex, uv + vec2(-px.x, -px.y), lod).rgb * 0.15;
	}
	return c;
}

float luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

vec3 inked(vec2 uv, vec3 col) {
	// The picture taken a little toward ink on paper: its tones toward washes of ink on cream paper (the warm lights
	// kept, as a painting keeps its one red seal), the outlines of its big shapes drawn in a dry brush (found on a
	// soft copy of the picture, so the grain of the rock does not draw), the paper's fibre in the light, and the
	// corners going back to bare paper like the margin of a scroll.
	vec2 res = vec2(textureSize(screen_tex, 0));
	vec2 px = 1.4 / res;
	float tl = luma(textureLod(screen_tex, uv + vec2(-px.x, -px.y), 1.25).rgb);
	float tc = luma(textureLod(screen_tex, uv + vec2(0.0, -px.y), 1.25).rgb);
	float tr = luma(textureLod(screen_tex, uv + vec2(px.x, -px.y), 1.25).rgb);
	float ml = luma(textureLod(screen_tex, uv + vec2(-px.x, 0.0), 1.25).rgb);
	float mr = luma(textureLod(screen_tex, uv + vec2(px.x, 0.0), 1.25).rgb);
	float bl = luma(textureLod(screen_tex, uv + vec2(-px.x, px.y), 1.25).rgb);
	float bc = luma(textureLod(screen_tex, uv + vec2(0.0, px.y), 1.25).rgb);
	float br = luma(textureLod(screen_tex, uv + vec2(px.x, px.y), 1.25).rgb);
	float gx = (tr + 2.0 * mr + br) - (tl + 2.0 * ml + bl);
	float gy = (bl + 2.0 * bc + br) - (tl + 2.0 * tc + tr);
	vec2 puv = uv * vec2(res.x / res.y, 1.0);
	float fibre = texture(paper_tex, puv * 4.0).b * 0.6 + texture(paper_tex, puv * 1.3 + 0.3).a * 0.4;
	float blot = texture(paper_tex, puv * 0.6 + 0.17).g;
	float line = smoothstep(0.12, 0.42, length(vec2(gx, gy))) * smoothstep(0.25, 0.6, fibre + 0.15);   // dry brush: broken
	float l = luma(col);
	line *= 1.0 - smoothstep(0.45, 0.8, l);   // the ink lies on the dark side of an edge, not round the bright cloud
	float sat = (max(col.r, max(col.g, col.b)) - min(col.r, min(col.g, col.b))) / max(max(col.r, max(col.g, col.b)), 1e-3);
	vec3 wash = mix(sumi, paper, smoothstep(0.02, 0.92, l));
	wash *= 1.0 - 0.12 * smoothstep(0.55, 0.85, blot) * (1.0 - l);   // ink pooling a little in the dark washes
	col = mix(col, wash, ink * 0.55 * (1.0 - smoothstep(0.35, 0.7, sat)));
	col *= 1.0 - line * 0.5 * ink;
	col *= mix(1.0, 0.95 + 0.09 * fibre, ink * smoothstep(0.3, 0.9, l));
	vec2 dd = uv - 0.5;
	float margin = smoothstep(0.32, 0.5, length(dd * vec2(1.0, 0.8)));
	col = mix(col, paper * 0.94, margin * 0.35 * ink);
	return col;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 d = uv - 0.5;
	vec2 off = d * dot(d, d) * fringe * 4.0;
	// the far top of the frame goes softer than the near bottom
	float dy = uv.y - tilt_centre;
	float blur = smoothstep(tilt_band, tilt_band + 0.3, abs(dy)) * tilt * (dy < 0.0 ? 1.0 : 0.75);
	vec3 col = soft(uv, blur * 2.4, off);
	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	vec3 tint = mix(shadow_tint, high_tint, smoothstep(0.12, 0.7, lum));
	col *= mix(vec3(1.0), tint, split);
	col = (col - 0.5) * contrast + 0.5;
	col += lift * (1.0 - col);
	vec2 gp = floor(uv * vec2(640.0, 360.0));
	float n = fract(sin(dot(gp + fract(TIME * 7.13) * 91.7, vec2(12.9898, 78.233))) * 43758.5453);
	col += (n - 0.5) * grain * (1.0 - lum * 0.5);
	if (ink > 0.0) {
		col = inked(uv, col);
	}
	COLOR = vec4(col, 1.0);
}
