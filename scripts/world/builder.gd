extends RefCounted
## Static helpers that assemble the 2.5D world: textured 3D blocks + pixel billboard sprites.

const PX := 0.035  # world metres per sprite pixel (48 px character = 1.68 m)


static func mat(tex_path: String, uv_per_m := 0.75, size := Vector3.ONE, opts := {}) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = Assets.tex(tex_path, true)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	m.roughness = opts.get("roughness", 1.0)
	m.albedo_color = opts.get("tint", Color.WHITE)
	if opts.get("triplanar", false):
		m.uv1_triplanar = true
		m.uv1_world_triplanar = opts.get("world", false)
		m.uv1_scale = Vector3.ONE * uv_per_m
	else:
		m.uv1_scale = Vector3(size.x * uv_per_m, size.y * uv_per_m, 1.0)
	if opts.get("unshaded", false):
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if opts.has("emission"):
		m.emission_enabled = true
		m.emission = opts["emission"]
		m.emission_energy_multiplier = opts.get("emission_energy", 1.0)
	return m


static func color_mat(c: Color, rough := 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3) -> void:
	# Godot front faces wind clockwise as seen from the outside
	if (b - a).cross(c - a).dot(n) > 0.0:
		var t := b
		b = c
		c = t
	for v in [a, b, c]:
		st.set_normal(n)
		st.add_vertex(v)


static func bevel_box_mesh(size: Vector3, bev: float) -> ArrayMesh:
	## Box with chamfered edges so edges catch the light instead of ending in a hard line.
	var h := size * 0.5
	bev = minf(bev, minf(h.x, minf(h.y, h.z)) * 0.9)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var inner := h - Vector3(bev, bev, bev)
	for ax in 3:
		for sgn in [-1.0, 1.0]:
			var n := Vector3.ZERO
			n[ax] = sgn
			var j := (ax + 1) % 3
			var k := (ax + 2) % 3
			var corners := []
			for cj in [-1.0, 1.0]:
				for ck in [-1.0, 1.0]:
					var v := Vector3.ZERO
					v[ax] = sgn * h[ax]
					v[j] = cj * inner[j]
					v[k] = ck * inner[k]
					corners.append(v)
			_tri(st, corners[0], corners[1], corners[3], n)
			_tri(st, corners[0], corners[3], corners[2], n)
	# edge strips
	for ax in 3:
		var j := (ax + 1) % 3
		var k := (ax + 2) % 3
		for sj in [-1.0, 1.0]:
			for sk in [-1.0, 1.0]:
				var n := Vector3.ZERO
				n[j] = sj
				n[k] = sk
				n = n.normalized()
				var p0 := Vector3.ZERO
				var p1 := Vector3.ZERO
				p0[j] = sj * h[j]
				p0[k] = sk * inner[k]
				p1[j] = sj * inner[j]
				p1[k] = sk * h[k]
				var a0 := p0
				var a1 := p0
				var b0 := p1
				var b1 := p1
				a0[ax] = -inner[ax]
				a1[ax] = inner[ax]
				b0[ax] = -inner[ax]
				b1[ax] = inner[ax]
				_tri(st, a0, a1, b1, n)
				_tri(st, a0, b1, b0, n)
	# corners
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var n := Vector3(sx, sy, sz).normalized()
				_tri(st, Vector3(sx * h.x, sy * inner.y, sz * inner.z), Vector3(sx * inner.x, sy * h.y, sz * inner.z),
					Vector3(sx * inner.x, sy * inner.y, sz * h.z), n)
	return st.commit()


static func box(parent: Node3D, size: Vector3, pos: Vector3, material: Material, rot_y := 0.0, collide := true, bevel := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	if bevel > 0.0:
		mi.mesh = bevel_box_mesh(size, bevel)
	else:
		var bm := BoxMesh.new()
		bm.size = size
		mi.mesh = bm
	mi.material_override = material
	mi.position = pos
	mi.rotation.y = deg_to_rad(rot_y)
	parent.add_child(mi)
	if collide:
		var sb := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = size
		cs.shape = sh
		sb.add_child(cs)
		mi.add_child(sb)
	return mi


static func tri_box(parent: Node3D, size: Vector3, pos: Vector3, tex_path: String, uv := 0.75, rot_y := 0.0, collide := true, tint := Color.WHITE, bevel := 0.04) -> MeshInstance3D:
	## Box with world-scaled triplanar texture so walls of any size tile the same; edges softly chamfered.
	var m := mat(tex_path, uv, Vector3.ONE, {"triplanar": true, "tint": tint})
	return box(parent, size, pos, m, rot_y, collide, bevel)


static func cylinder(parent: Node3D, r: float, h: float, pos: Vector3, material: Material, collide := true, segs := 10) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = h
	cm.radial_segments = segs
	mi.mesh = cm
	mi.material_override = material
	mi.position = pos
	parent.add_child(mi)
	if collide:
		var sb := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := CylinderShape3D.new()
		sh.radius = r
		sh.height = h
		cs.shape = sh
		sb.add_child(cs)
		mi.add_child(sb)
	return mi


static func quad(parent: Node3D, size: Vector2, pos: Vector3, rot_deg: Vector3, material: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = size
	mi.mesh = qm
	mi.material_override = material
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi


static func sprite_mat_quad(parent: Node3D, tex_path: String, pos: Vector3, rot_deg: Vector3, px := PX, flat_shaded := true) -> MeshInstance3D:
	## A non-billboard textured quad sized from the sprite's pixels (fences, boards, decals).
	var t := Assets.tex(tex_path)
	var m := StandardMaterial3D.new()
	m.albedo_texture = t
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.5
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 1.0
	if not flat_shaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return quad(parent, Vector2(t.get_width(), t.get_height()) * px, pos, rot_deg, m)


static func gable_roof(parent: Node3D, length: float, depth_front: float, depth_back: float, eave_h: float, ridge_h: float, pos: Vector3, tex_path: String, under_tex := "res://assets/tex/beam.png", thickness := 0.18) -> MeshInstance3D:
	## Roof running along X. Ridge at local z = 0; front eave at +depth_front, back eave at -depth_back.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hl := length * 0.5
	var r := Vector3(0, ridge_h, 0)
	var ef := Vector3(0, eave_h, depth_front)
	var eb := Vector3(0, eave_h, -depth_back)
	var uvs := 0.9
	_quad_st(st, Vector3(-hl, r.y, 0), Vector3(hl, r.y, 0), Vector3(hl, ef.y, ef.z), Vector3(-hl, ef.y, ef.z), uvs)
	_quad_st(st, Vector3(hl, r.y, 0), Vector3(-hl, r.y, 0), Vector3(-hl, eb.y, eb.z), Vector3(hl, eb.y, eb.z), uvs)
	# fascia (thickness) along the eaves so the roof reads as a solid thatch slab
	_quad_st(st, Vector3(-hl, ef.y, ef.z), Vector3(hl, ef.y, ef.z), Vector3(hl, ef.y - thickness, ef.z), Vector3(-hl, ef.y - thickness, ef.z), uvs)
	_quad_st(st, Vector3(hl, eb.y, eb.z), Vector3(-hl, eb.y, eb.z), Vector3(-hl, eb.y - thickness, eb.z), Vector3(hl, eb.y - thickness, eb.z), uvs)
	st.generate_normals()
	var mesh := st.commit()
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var m := mat(tex_path, 1.0, Vector3.ONE, {"triplanar": false})
	m.uv1_scale = Vector3.ONE
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	mi.position = pos
	parent.add_child(mi)
	# gable end triangles (planks) closing each side
	var st2 := SurfaceTool.new()
	st2.begin(Mesh.PRIMITIVE_TRIANGLES)
	for sx in [-hl + 0.25, hl - 0.25]:
		var a := Vector3(sx, ef.y, min(ef.z, 0.9 * depth_front))
		var b := Vector3(sx, eb.y, -min(depth_back, 0.9 * depth_back))
		var c := Vector3(sx, r.y - 0.05, 0)
		var n := Vector3(sign(sx), 0, 0)
		for v in [a, c, b]:
			st2.set_normal(n)
			st2.set_uv(Vector2(v.z * 0.8, -v.y * 0.8))
			st2.add_vertex(v)
	var gm := MeshInstance3D.new()
	gm.mesh = st2.commit()
	var g := mat(under_tex, 1.0)
	g.uv1_scale = Vector3.ONE
	g.cull_mode = BaseMaterial3D.CULL_DISABLED
	gm.material_override = g
	mi.add_child(gm)
	return mi


static func roof(parent: Node3D, length: float, depth_front: float, depth_back: float, eave_h: float, ridge_h: float, pos: Vector3, tex_path: String, under_tex := "res://assets/tex/beam.png") -> Node3D:
	## Curved roof along X: slopes sag a little and kick up at the eaves; tile roofs curl up at the
	## corners (đầu đao) and get a ridge with turned-up ends, thatch gets a thick rolled eave and ridge.
	var tile := not tex_path.contains("thatch")
	var root := Node3D.new()
	root.position = pos
	parent.add_child(root)
	var hl := length * 0.5
	var sag := 0.16 if tile else 0.1
	var kick := 0.12 if tile else 0.05
	var curl := 0.38 if tile else 0.0
	var thick := 0.14 if tile else 0.3
	var nx := 14
	var nt := 7
	var uvs := 0.9
	var surf := func(x: float, t: float, depth: float, sgn: float) -> Vector3:
		var y := lerpf(ridge_h, eave_h, t) - sag * sin(PI * t) + kick * pow(t, 6.0)
		y += curl * pow(absf(x) / hl, 5.0) * t * t
		return Vector3(x, y, sgn * depth * t)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var edges := []   # [x0, x1, eave points] for fascia
	for side in [[depth_front, 1.0], [depth_back, -1.0]]:
		var depth: float = side[0]
		var sgn: float = side[1]
		for i in nx:
			var x0 := -hl + length * i / nx
			var x1 := -hl + length * (i + 1) / nx
			for j in nt:
				var t0 := float(j) / nt
				var t1 := float(j + 1) / nt
				var a: Vector3 = surf.call(x0, t0, depth, sgn)
				var b: Vector3 = surf.call(x1, t0, depth, sgn)
				var c: Vector3 = surf.call(x1, t1, depth, sgn)
				var d: Vector3 = surf.call(x0, t1, depth, sgn)
				var uv_a := Vector2(x0 * uvs, t0 * depth * uvs)
				var uv_b := Vector2(x1 * uvs, t0 * depth * uvs)
				var uv_c := Vector2(x1 * uvs, t1 * depth * uvs)
				var uv_d := Vector2(x0 * uvs, t1 * depth * uvs)
				for pr in [[a, uv_a], [b, uv_b], [c, uv_c], [a, uv_a], [c, uv_c], [d, uv_d]]:
					st.set_uv(pr[1])
					st.add_vertex(pr[0])
		# fascia: the thickness of the roof along the eave and the two verges
		for i in nx:
			var x0 := -hl + length * i / nx
			var x1 := -hl + length * (i + 1) / nx
			var a: Vector3 = surf.call(x0, 1.0, depth, sgn)
			var b: Vector3 = surf.call(x1, 1.0, depth, sgn)
			var c := b - Vector3(0, thick, 0)
			var d := a - Vector3(0, thick, 0)
			for pr in [[a, Vector2(x0 * uvs, 0)], [b, Vector2(x1 * uvs, 0)], [c, Vector2(x1 * uvs, thick * uvs)],
					[a, Vector2(x0 * uvs, 0)], [c, Vector2(x1 * uvs, thick * uvs)], [d, Vector2(x0 * uvs, thick * uvs)]]:
				st.set_uv(pr[1])
				st.add_vertex(pr[0])
		for xs in [-hl, hl]:
			for j in nt:
				var a: Vector3 = surf.call(xs, float(j) / nt, depth, sgn)
				var b: Vector3 = surf.call(xs, float(j + 1) / nt, depth, sgn)
				var c := b - Vector3(0, thick, 0)
				var d := a - Vector3(0, thick, 0)
				for pr in [[a, Vector2(a.z * uvs, 0)], [b, Vector2(b.z * uvs, 0)], [c, Vector2(b.z * uvs, thick * uvs)],
						[a, Vector2(a.z * uvs, 0)], [c, Vector2(b.z * uvs, thick * uvs)], [d, Vector2(a.z * uvs, thick * uvs)]]:
					st.set_uv(pr[1])
					st.add_vertex(pr[0])
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var m := mat(tex_path, 1.0, Vector3.ONE, {"triplanar": false})
	m.uv1_scale = Vector3.ONE
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	root.add_child(mi)
	# ridge
	var ridge_y: float = surf.call(0.0, 0.0, 1.0, 1.0).y
	if tile:
		var rm := mat(tex_path, 1.0, Vector3.ONE, {"triplanar": true, "tint": Color(0.82, 0.78, 0.76)})
		box(root, Vector3(length + 0.1, 0.22, 0.3), Vector3(0, ridge_y + 0.06, 0), rm, 0, false, 0.05)
		for xs in [-1.0, 1.0]:
			# turned-up ridge ends
			var tip := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.02
			cm.bottom_radius = 0.13
			cm.height = 0.62
			cm.radial_segments = 6
			tip.mesh = cm
			tip.material_override = rm
			tip.position = Vector3(xs * (hl + 0.1), ridge_y + 0.28, 0)
			tip.rotation = Vector3(0, 0, -xs * 0.75)
			root.add_child(tip)
		# corner curls
		for xs in [-1.0, 1.0]:
			for side in [[depth_front, 1.0], [depth_back, -1.0]]:
				var cpt: Vector3 = surf.call(xs * hl, 1.0, side[0], side[1])
				var curl_m := MeshInstance3D.new()
				var cm2 := CylinderMesh.new()
				cm2.top_radius = 0.015
				cm2.bottom_radius = 0.08
				cm2.height = 0.42
				cm2.radial_segments = 5
				curl_m.mesh = cm2
				curl_m.material_override = rm
				curl_m.position = cpt + Vector3(xs * 0.12, 0.12, side[1] * 0.12)
				curl_m.rotation = Vector3(side[1] * 0.6, 0, -xs * 0.6)
				root.add_child(curl_m)
	else:
		var tm := mat(tex_path, 1.0, Vector3.ONE, {"triplanar": true, "tint": Color(0.78, 0.72, 0.62)})
		var rc := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.2
		cyl.bottom_radius = 0.2
		cyl.height = length + 0.15
		cyl.radial_segments = 8
		rc.mesh = cyl
		rc.material_override = tm
		rc.rotation = Vector3(0, 0, PI * 0.5)
		rc.position = Vector3(0, ridge_y + 0.04, 0)
		root.add_child(rc)
		# rolled eaves
		for side in [[depth_front, 1.0], [depth_back, -1.0]]:
			var e: Vector3 = surf.call(0.0, 1.0, side[0], side[1])
			var roll := MeshInstance3D.new()
			var cyl2 := CylinderMesh.new()
			cyl2.top_radius = thick * 0.55
			cyl2.bottom_radius = thick * 0.55
			cyl2.height = length
			cyl2.radial_segments = 8
			roll.mesh = cyl2
			roll.material_override = tm
			roll.rotation = Vector3(0, 0, PI * 0.5)
			roll.position = Vector3(0, e.y - thick * 0.5, e.z)
			root.add_child(roll)
	# gable end triangles closing each side under the roof
	var st2 := SurfaceTool.new()
	st2.begin(Mesh.PRIMITIVE_TRIANGLES)
	for sx in [-hl + 0.3, hl - 0.3]:
		var a := Vector3(sx, eave_h, 0.88 * depth_front)
		var b := Vector3(sx, eave_h, -0.88 * depth_back)
		var c := Vector3(sx, ridge_y - 0.08, 0)
		var n := Vector3(sign(sx), 0, 0)
		for v in [a, c, b]:
			st2.set_normal(n)
			st2.set_uv(Vector2(v.z * 0.8, -v.y * 0.8))
			st2.add_vertex(v)
	var gm := MeshInstance3D.new()
	gm.mesh = st2.commit()
	var g := mat(under_tex, 1.0)
	g.uv1_scale = Vector3.ONE
	g.cull_mode = BaseMaterial3D.CULL_DISABLED
	gm.material_override = g
	root.add_child(gm)
	return root


static func _quad_st(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, uvs: float) -> void:
	var la := a.distance_to(b)
	var lb := b.distance_to(c)
	var uv_a := Vector2(0, 0)
	var uv_b := Vector2(la * uvs, 0)
	var uv_c := Vector2(la * uvs, lb * uvs)
	var uv_d := Vector2(0, lb * uvs)
	for pair in [[a, uv_a], [b, uv_b], [c, uv_c], [a, uv_a], [c, uv_c], [d, uv_d]]:
		st.set_uv(pair[1])
		st.add_vertex(pair[0])


static func karst_mat(tint: Color, glow := Color(0, 0, 0), moss := 0.8) -> ShaderMaterial:
	## The limestone of the title's pillars (shaders/karst.gdshader) for any crag: fractured faces, a tile 14 m, beds
	## running level, rain streaks, moss where it faces up. (Its fade into the deep is set far below, out of the way.)
	var k := ShaderMaterial.new()
	k.shader = Assets.shader("res://shaders/karst.gdshader")
	k.set_shader_parameter("grain", Assets.tex("res://assets/tex/flank_lime.png", true))
	k.set_shader_parameter("noise", Assets.tex("res://assets/tex/clouds.png", true))
	k.set_shader_parameter("face", Assets.tex("res://assets/tex/karst_face.png", true))
	k.set_shader_parameter("face_n", Assets.tex("res://assets/tex/karst_face_n.png", true))
	k.set_shader_parameter("tint", tint)
	k.set_shader_parameter("glow", glow)
	k.set_shader_parameter("moss_amount", moss)
	k.set_shader_parameter("sea", -1000.0)
	k.set_shader_parameter("abyss", -2000.0)
	return k


static func crag(parent: Node3D, at: Vector3, r0: float, r1: float, h: float, mat: Material, rng: RandomNumberGenerator, seg := 16, rings := 12) -> MeshInstance3D:
	## A crag of limestone standing at at, for shaders/karst.gdshader: r0 round at its foot, narrowing toward r1 near
	## its top, a little leaning, its girth stepping in here and there at a bed and bitten by a cleft or two down it, its
	## crown rounded off. UV is round it (0..1) and up it (the world's height), UV2.x its girth, COLOR.r how much sky a
	## point sees (dark down a cleft).
	var lean := Vector3(rng.randf_range(-0.1, 0.1), 0, rng.randf_range(-0.05, 0.05))
	var clefts: Array = []
	for c in rng.randi_range(1, 3):
		clefts.append([rng.randf() * TAU, rng.randf_range(0.1, 0.22), rng.randf_range(0.12, 0.25)])
	var lp := [rng.randf() * TAU, rng.randf() * TAU]
	var rows: Array = []
	for j in rings + 1:
		var t := float(j) / rings
		var crown := sqrt(maxf(1.0 - pow(t, 6.0), 0.0))
		var step := 1.06 if j % 3 == 0 else 1.0
		var rr := lerpf(r0, r1, t) * maxf(crown, 0.05) * step * rng.randf_range(0.95, 1.05)
		var row: Array = []
		for i in seg:
			var a := TAU * i / seg
			var f := 1.0 + 0.12 * sin(2.0 * a + lp[0] + t * 1.5) + 0.07 * sin(3.0 * a + lp[1])
			var g := 0.0
			for c in clefts:
				var da := wrapf(a - c[0], -PI, PI)
				g -= c[1] * exp(-da * da / (c[2] * c[2]))
			var rv := rr * (f + g) * rng.randf_range(0.93, 1.07)
			row.append([at + lean * h * t + Vector3(cos(a) * rv, h * t, sin(a) * rv), clampf(1.0 + g * 4.0, 0.35, 1.0)])
		rows.append(row)
	var girth := TAU * r0
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in rings:
		for i in seg:
			var i2 := (i + 1) % seg
			var q := [[rows[j][i], float(i) / seg], [rows[j][i2], float(i + 1) / seg], [rows[j + 1][i], float(i) / seg], [rows[j + 1][i2], float(i + 1) / seg]]
			for k in [0, 1, 2, 1, 3, 2]:   # (wound to face out, as the title's pillars)
				var v: Array = q[k]
				var pv: Vector3 = v[0][0]
				st.set_color(Color(v[0][1], 0.0, 0.0))
				st.set_uv(Vector2(v[1], pv.y))
				st.set_uv2(Vector2(girth, 0.0))
				st.add_vertex(pv)
	st.generate_normals()
	st.generate_tangents()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


static func lit_sprite(s: Sprite3D) -> void:
	## A figure's sprite drawn lit as if it had a body (shaders/sprite_lit.gdshader), as the characters are; its sheet
	## and frame grid as set on it now.
	var m := ShaderMaterial.new()
	m.shader = Assets.shader("res://shaders/sprite_lit.gdshader")
	m.set_shader_parameter("tex", s.texture)
	m.set_shader_parameter("frames", Vector2(s.hframes, s.vframes))
	s.material_override = m


static func billboard(parent: Node3D, tex_path: String, pos: Vector3, px := PX, shadow := true, hframes := 1, frame := 0) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = Assets.tex(tex_path)
	s.hframes = hframes
	s.frame = frame
	s.pixel_size = px
	s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.shaded = true
	s.double_sided = true
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var h := s.texture.get_height()
	s.position = pos + Vector3(0, h * px * 0.5 - px, 0)  # feet on the ground
	parent.add_child(s)
	return s


static func foliage_mat(tex_path: String, height: float, sway := 0.12, whole := 0.0, rustle := 1.0) -> ShaderMaterial:
	var t := Assets.tex(tex_path)
	var sm := ShaderMaterial.new()
	sm.shader = Assets.shader("res://shaders/foliage.gdshader")
	sm.set_shader_parameter("tex", t)
	sm.set_shader_parameter("noise_tex", Assets.tex("res://assets/tex/clouds.png"))
	sm.set_shader_parameter("sway", sway)
	sm.set_shader_parameter("height", height)
	sm.set_shader_parameter("whole", whole)
	sm.set_shader_parameter("rustle", rustle)
	sm.set_shader_parameter("tex_w", float(t.get_width()))
	return sm


static func plant(parent: Node3D, tex_path: String, pos: Vector3, px := PX, sway := 0.12, rustle := 1.0, shadow := true) -> MeshInstance3D:
	## A swaying billboard plant (bamboo, banana, areca, bushes): bends from its base in the wind.
	var t := Assets.tex(tex_path)
	var qm := QuadMesh.new()
	qm.size = Vector2(t.get_width(), t.get_height()) * px
	qm.center_offset = Vector3(0, qm.size.y * 0.5 - px, 0)
	qm.subdivide_depth = 6
	qm.material = foliage_mat(tex_path, qm.size.y, sway, 0.0, 0.0)
	var mi := MeshInstance3D.new()
	mi.mesh = qm
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = 2.0
	parent.add_child(mi)
	return mi


static func canopy(parent: Node3D, clumps: Array, px := 0.05, sway := 0.07) -> Array:
	## Leaf clumps for a 3D tree crown: clumps = [[tex_path, Vector3 pos, float scale, Color tint], ...].
	## One MultiMesh per texture, each clump drifting as a whole in the gusts.
	var by_tex := {}
	for c in clumps:
		by_tex.get_or_add(c[0], []).append(c)
	var out := []
	for tp in by_tex:
		var t := Assets.tex(tp)
		var qm := QuadMesh.new()
		qm.size = Vector2(t.get_width(), t.get_height()) * px
		qm.material = foliage_mat(tp, qm.size.y, sway, 1.0, 0.0)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = qm
		var list: Array = by_tex[tp]
		mm.instance_count = list.size()
		for i in list.size():
			var c: Array = list[i]
			var sc: float = c[2]
			mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(sc, sc, sc)), c[1]))
			mm.set_instance_color(i, c[3])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		parent.add_child(mmi)
		out.append(mmi)
	return out


static func trunk(parent: Node3D, a: Vector3, b: Vector3, r0: float, r1: float, material: Material, segs := 8) -> MeshInstance3D:
	## Tapered limb from a to b (radius r0 at a, r1 at b).
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.bottom_radius = r0
	cm.top_radius = r1
	cm.height = a.distance_to(b)
	cm.radial_segments = segs
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = material
	var up := (b - a).normalized()
	var basis := Basis()
	if absf(up.dot(Vector3.UP)) < 0.999:
		var axis := Vector3.UP.cross(up).normalized()
		basis = Basis(axis, Vector3.UP.angle_to(up))
	mi.transform = Transform3D(basis, (a + b) * 0.5)
	parent.add_child(mi)
	return mi


static func scatter(parent: Node3D, tex_path: String, points: PackedVector3Array, scale_px := PX, sway := 0.05, tints: PackedColorArray = PackedColorArray()) -> MultiMeshInstance3D:
	## Many small billboarded sprites (grass tufts, rice) in one draw call.
	var t := Assets.tex(tex_path)
	var qm := QuadMesh.new()
	qm.size = Vector2(t.get_width(), t.get_height()) * scale_px
	qm.center_offset = Vector3(0, qm.size.y * 0.5, 0)
	var sm := ShaderMaterial.new()
	sm.shader = Assets.shader("res://shaders/grass.gdshader")
	sm.set_shader_parameter("tex", t)
	sm.set_shader_parameter("sway", sway)
	sm.set_shader_parameter("noise_tex", Assets.tex("res://assets/tex/clouds.png"))
	qm.material = sm
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = qm
	mm.instance_count = points.size()
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in points.size():
		var s := rng.randf_range(0.8, 1.25)
		var tr := Transform3D(Basis().scaled(Vector3(s, s, s)), points[i])
		mm.set_instance_transform(i, tr)
		var c := Color(1, 1, 1)
		if tints.size() > 0:
			c = tints[i % tints.size()]
		mm.set_instance_color(i, c)
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mmi)
	return mmi


static func label3d(parent: Node3D, text: String, pos: Vector3, size := 48, color := Color.WHITE) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font = Assets.serif(true)
	l.font_size = size
	l.pixel_size = 0.008
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.modulate = color
	l.outline_size = 10
	l.outline_modulate = Color(0.05, 0.04, 0.05)
	l.position = pos
	l.render_priority = 10
	l.outline_render_priority = 9
	parent.add_child(l)
	return l


static func particles(parent: Node3D, tex_path: String, amount: int, lifetime: float, box_ext: Vector3, pos: Vector3, opts := {}) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF   # (smoke and dust cast a dithered blot of a shadow)
	p.amount = amount
	p.lifetime = lifetime
	p.preprocess = lifetime
	p.position = pos
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = box_ext
	pm.direction = opts.get("dir", Vector3(0, 1, 0))
	pm.spread = opts.get("spread", 20.0)
	pm.initial_velocity_min = opts.get("vmin", 0.1)
	pm.initial_velocity_max = opts.get("vmax", 0.4)
	pm.gravity = opts.get("gravity", Vector3.ZERO)
	pm.scale_min = opts.get("smin", 0.8)
	pm.scale_max = opts.get("smax", 1.4)
	if opts.has("turb"):
		pm.turbulence_enabled = true
		pm.turbulence_noise_strength = opts["turb"]
		pm.turbulence_noise_scale = 2.0
	var grad := Gradient.new()
	var col: Color = opts.get("color", Color.WHITE)
	grad.set_color(0, Color(col, 0.0))
	grad.set_color(1, Color(col, 0.0))
	grad.add_point(0.2, col)
	grad.add_point(0.75, col)
	var gt := GradientTexture1D.new()
	gt.gradient = grad
	pm.color_ramp = gt
	p.process_material = pm
	var qm := QuadMesh.new()
	var t := Assets.tex(tex_path)
	var sz: float = opts.get("size", 0.4)
	qm.size = Vector2(sz, sz * t.get_height() / float(t.get_width()))
	var m := StandardMaterial3D.new()
	m.albedo_texture = t
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if opts.get("unshaded", false) else BaseMaterial3D.SHADING_MODE_PER_PIXEL
	if opts.has("emission"):
		m.emission_enabled = true
		m.emission = opts["emission"]
		m.emission_energy_multiplier = opts.get("emission_energy", 2.0)
	qm.material = m
	p.draw_pass_1 = qm
	p.visibility_aabb = AABB(-box_ext - Vector3(4, 4, 4), box_ext * 2 + Vector3(8, 12, 8))
	parent.add_child(p)
	return p
