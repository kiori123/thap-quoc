extends "res://scripts/world/world.gd"
## The title screen's world, built from the game's own pieces (the author's concept, 2026-10-13, gave the
## composition only: "chỉ là concept chứ không lấy y nguyên"). The protagonist sits at the end of a ledge with their
## back to us, the sword in hand; below, a sea of cloud drifting, and out of it the ten countries rise as clusters of
## limestone pillars, each with a light or a shape of its own; the highest, Thiên Mệnh, under a pillar of light; a
## pale moon behind the storm. When play is chosen the protagonist stands and makes one cut (cut()); main.gd smears
## the screen along it and goes into the game.
## Which land looks like what is ĐỀ XUẤT (only Bạch Sơn has been designed).

const SEA := -16.0      # the top of the cloud sea

const CAM_POS := Vector3(0.3, 2.4, 4.6)
const CAM_LOOK := Vector3(0.0, -3.0, -100.0)
var hero_s: Sprite3D     # hero_title.png: 0-1 sitting, 2 drawing, 3 standing, 4 wind-up, 6-9 the cut, 10 at rest
var _trail_s: Sprite3D   # hero_title_trail.png: the light the blade leaves, over the hero, not darkened by the scene
var _clouds: Array[ShaderMaterial] = []
var _mists: Array[ShaderMaterial] = []   # the veils of mist under the cloud sea (shaders/abyss_mist.gdshader)
var _rays: Array[MeshInstance3D] = []    # light falling into the opened cut
var _hero_home := Vector3.ZERO
var _cut_n := Vector3.RIGHT      # the plane of the cut (through the camera): its normal
var _cut_o := Vector3.ZERO       # the camera when the blade landed (on the plane)
var _nh := Vector2.RIGHT         # across the channel, on the sea (x, z)
var _fh := Vector2.DOWN          # along it, out from the ledge (x, z)
var _wave_t := -1.0              # seconds since the blade landed, the blow's own clock (slowed in the hitch)
var _wave_f := 1.0
var _deck: ShaderMaterial        # the top of the cloud sea (shaders/cloud_deck.gdshader)
var _rocks: Array[Vector3] = []  # pillars standing up through the cloud: (x, z, radius at the cloud's top)
var _last_ring: Array = []       # the top edge of the last pillar made (for a forest laid on it)
var _canopy_m: ShaderMaterial
var _shape := RandomNumberGenerator.new()   # the shapes of the rock (the layout keeps to _rng)
var _look_cam: PackedFloat64Array = []
var _karst := {}                 # a material of the old kind -> the limestone (shaders/karst.gdshader) in its colours
var _lit: StandardMaterial3D     # paper lattice lit from inside: the windows of every house
var _timber: StandardMaterial3D
var _t := 0.0
var _cutting := false
var _rock: Material
var _rock_dark: Material
var _white: Material
var _lime: Material
var _ink_roof := "res://assets/tex/roof_ink.png"
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_active = false      # nothing moves: one picture is taken
	_rng.seed = 21
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--vista-cam="):
			_look_cam = PackedFloat64Array(Array(arg.substr(12).split(",")).map(func(x): return float(x)))
	_build_environment()
	_mist_mat = FogMaterial.new()
	_rock = B.mat("res://assets/tex/flank_lime.png", 0.3, Vector3.ONE, {"triplanar": true, "world": true, "tint": Color(0.58, 0.61, 0.68)})
	_rock_dark = B.mat("res://assets/tex/flank_lime.png", 0.5, Vector3.ONE, {"triplanar": true, "world": true, "tint": Color(0.2, 0.21, 0.25)})
	_white = B.mat("res://assets/tex/flank_lime.png", 0.3, Vector3.ONE, {"triplanar": true, "world": true, "tint": Color(0.98, 0.99, 1.0),
		"emission": Color(0.42, 0.44, 0.5), "emission_energy": 0.55})   # white even on its shaded side: the white city
	_lime = B.mat("res://assets/tex/lime_wall.png", 0.6, Vector3.ONE, {"triplanar": true, "world": true})
	_build_ledge()
	_build_sea()
	_build_lands()
	_build_sky_things()
	rig = CameraRig.new()
	add_child(rig)
	set_time("gloom", true)
	_grade()


func _grade() -> void:
	## Storm light: a cold dark sky, the light low behind the lands (their faces toward us in shade, layered paler
	## and paler into the haze), warm lamps here and there below.
	sun.rotation_degrees = Vector3(-22, 116, 0)   # from the right and a little behind: the rock's right flanks lit
	sun.light_color = Color(0.86, 0.9, 1.0)
	sun.light_energy = 1.5
	_deck.set_shader_parameter("sun_dir", sun.global_transform.basis.z)
	_sky_mat.set_shader_parameter("top_color", Color(0.06, 0.07, 0.1))
	_sky_mat.set_shader_parameter("horizon_color", Color(0.5, 0.54, 0.62))
	_sky_mat.set_shader_parameter("ground_color", Color(0.35, 0.37, 0.42))
	_sky_mat.set_shader_parameter("cloud_lit", Color(0.66, 0.7, 0.78))
	_sky_mat.set_shader_parameter("cloud_shade", Color(0.12, 0.14, 0.19))
	_sky_mat.set_shader_parameter("cloud_cover", 0.7)
	_sky_mat.set_shader_parameter("sun_glow", 0.0)   # one moon in this sky: the sun's disc and glow would be a second
	_sky_mat.set_shader_parameter("pix", 420.0)      # (the wide sky over the title: finer cloud pixels, no great steps)
	RenderingServer.global_shader_parameter_set("cloud_amount", 0.75)
	env.ambient_light_energy = 0.62
	env.fog_enabled = true
	env.fog_light_color = Color(0.5, 0.55, 0.64)
	env.fog_density = 0.0012
	env.fog_height = SEA + 6.0
	env.fog_height_density = 0.05
	env.adjustment_contrast = 1.22
	env.volumetric_fog_enabled = false
	env.adjustment_saturation = 0.85
	env.glow_intensity = 1.1
	set_diorama(0.1, 0.6)
	# a touch of ink-wash painting over the title (shaders/post.gdshader inked: off in the game's own worlds)
	_post_mat.set_shader_parameter("ink", 0.55)
	_post_mat.set_shader_parameter("paper_tex", Assets.tex("res://assets/tex/cloud_noise.png", true))


# ------------------------------------------------------------------ the near ledge
func _build_ledge() -> void:
	## A tongue of broken limestone running out over the drop, the protagonist sitting at its end; at the left, on its
	## own pillar, a small open shrine at the lookout, on a plinth of fitted stone (its near post and eave in the frame).
	for k in 42:   # (the numbers the old ledge drew for its boulders, so the lands still stand where they stood)
		_rng.randf()
	_ledge_rock()
	# the ledge and the shrine's shelf are the tops of pillars that go down into the dark (it shows when the cut
	# clears the mist)
	_spire(Vector3(0.3, -24.0, 3.2), 3.6, 23.4, _rock_dark, "flat", 0)
	_spire(Vector3(-4.4, -24.0, 1.6), 3.5, 23.8, _rock_dark, "flat", 0)
	# the shrine: a plinth on the top of its pillar (sunk into it), four posts on the plinth, the roof on the posts
	var shelf_top := 0.15
	var plinth := B.mat("res://assets/tex/plinth.png", 0.9, Vector3.ONE, {"triplanar": true, "world": true, "tint": Color(0.4, 0.41, 0.44)})
	B.box(self, Vector3(3.4, 0.6, 3.2), Vector3(-4.2, shelf_top - 0.3, 1.4), plinth, 0, false, 0.05)
	var post_m := B.color_mat(Color(0.1, 0.08, 0.07))
	for px in [-5.4, -3.0]:
		for pz in [0.2, 2.6]:
			B.box(self, Vector3(0.18, 2.7, 0.18), Vector3(px, shelf_top + 1.35, pz), post_m, 0, false)
	B.box(self, Vector3(2.9, 0.16, 0.2), Vector3(-4.2, shelf_top + 2.62, 0.2), post_m, 0, false)   # the beam
	B.box(self, Vector3(2.9, 0.16, 0.2), Vector3(-4.2, shelf_top + 2.62, 2.6), post_m, 0, false)
	_plain_roof(B.roof(self, 3.3, 1.6, 1.6, shelf_top + 2.7, shelf_top + 3.5, Vector3(-4.2, 0, 1.4), _ink_roof))
	# the protagonist
	hero_s = Sprite3D.new()
	hero_s.texture = Assets.tex("res://assets/sprites/chars/hero_title.png")
	hero_s.hframes = 11
	hero_s.pixel_size = B.PX
	hero_s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	hero_s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	hero_s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	hero_s.shaded = true
	hero_s.position = Vector3(0.3, (32 - 3) * B.PX, -0.55)   # 64 px frames, the feet 3 px above the bottom
	add_child(hero_s)
	# the trail of the blade is light, not cloth: drawn over the hero unshaded, frame for frame (empty outside the cut)
	_trail_s = Sprite3D.new()
	_trail_s.texture = Assets.tex("res://assets/sprites/chars/hero_title_trail.png")
	_trail_s.hframes = 11
	_trail_s.pixel_size = B.PX
	_trail_s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_trail_s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_trail_s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	_trail_s.shaded = false
	_trail_s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_trail_s.position = Vector3(0, 0, 0.02)   # (a hair nearer the camera than the hero, so the two never fight)
	hero_s.add_child(_trail_s)
	# the light of the cloud all round falls on the near side too: a soft cool fill, from the right like the sun,
	# reaching only the protagonist, the ledge and the shrine, so their side toward us is not lost in black
	var fill := OmniLight3D.new()
	fill.light_color = Color(0.74, 0.8, 0.94)
	fill.light_energy = 0.55
	fill.light_specular = 0.0
	fill.omni_range = 7.5
	fill.omni_attenuation = 1.4
	fill.shadow_enabled = false
	fill.position = Vector3(1.6, 2.2, 2.4)
	add_child(fill)
	# where they sit on the rock: a soft shade under them (the sun is behind; its shadow falls toward us, thin)
	var dc := Decal.new()
	var gt := GradientTexture2D.new()
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	var gr := Gradient.new()
	gr.set_color(0, Color(0, 0, 0, 0.55))
	gr.set_color(1, Color(0, 0, 0, 0.0))
	gt.gradient = gr
	dc.texture_albedo = gt
	dc.size = Vector3(1.3, 0.8, 1.0)
	dc.position = Vector3(0.3, 0.0, -0.5)
	dc.cull_mask = 1
	add_child(dc)


func _ledge_rock() -> void:
	## The ledge: a tongue of limestone running out over the drop, its top broken into slabs with cracks between them
	## (moss in the low places), its edges rounded off and falling away as cliff; level where the protagonist sits, at
	## its end.
	var nz := FastNoiseLite.new()
	nz.seed = 5
	nz.frequency = 0.5
	nz.fractal_octaves = 3
	var cells := FastNoiseLite.new()   # the cracks between the slabs: the edges of cells
	cells.seed = 9
	cells.noise_type = FastNoiseLite.TYPE_CELLULAR
	cells.frequency = 0.75
	cells.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
	var seat := Vector2(0.3, -0.55)
	var x0 := -2.9
	var z0 := -2.0
	var stp := 0.2
	var nx := 33
	var nzn := 56
	var pts: Array = []
	var sky: Array = []
	var inside: Array = []
	for iz in nzn:
		for ix in nx:
			var x := x0 + ix * stp
			var z := z0 + iz * stp
			var xc := 0.3 + 0.25 * sin(z * 0.6)
			var hw := 1.2 + 0.2 * maxf(z + 1.0, 0.0) + 0.3 * nz.get_noise_2d(z * 1.3, 11.0)
			var front := -1.25 + 0.5 * pow((x - xc) / hw, 2.0) + 0.2 * nz.get_noise_2d(x * 1.7, 31.0)
			var e := minf(hw - absf(x - xc), z - front)   # how far in from the edge
			var slab := nz.get_noise_2d(x * 0.8 + 5.0, z * 0.8)
			var y := roundf(slab * 3.0) / 3.0 * 0.2 + slab * 0.06 + nz.get_noise_2d(x * 3.0, z * 3.0) * 0.05
			var crack := 1.0 - smoothstep(0.0, 0.15, cells.get_noise_2d(x, z) + 1.0)
			y -= crack * 0.12
			y *= smoothstep(0.45, 1.25, Vector2(x, z).distance_to(seat))   # level where the protagonist sits
			if e > 0.0:
				y -= 0.9 * pow(1.0 - smoothstep(0.0, 0.55, e), 2.0)
			else:
				y -= minf(0.9 - e * 22.0, 7.5)
			pts.append(Vector3(x, y, z))
			sky.append(clampf(1.0 - crack * 0.55 - (0.3 if e < 0.0 else 0.0), 0.3, 1.0))
			inside.append(e > -0.3)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in nzn - 1:
		for ix in nx - 1:
			var i00 := iz * nx + ix
			var i10 := i00 + 1
			var i01 := i00 + nx
			var i11 := i01 + 1
			if not (inside[i00] or inside[i10] or inside[i01] or inside[i11]):
				continue
			for i in [i00, i10, i01, i10, i11, i01]:
				st.set_color(Color(sky[i], 1.0, 0.0))
				st.set_uv(Vector2.ZERO)
				st.set_uv2(Vector2.ONE)
				st.add_vertex(pts[i])
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var km := _karst_of(B.mat("res://assets/tex/flank_lime.png", 0.5, Vector3.ONE, {"tint": Color(0.32, 0.33, 0.37)}))
	km.set_shader_parameter("moss_amount", 0.6)
	mi.material_override = km
	add_child(mi)


func _plain_roof(rf: Node3D) -> void:
	## A roof without its turned-up ridge tips and corner curls: from far off they read as spikes in the air.
	for c in rf.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).mesh is CylinderMesh:
			rf.remove_child(c)
			c.free()


# ------------------------------------------------------------------ the sea of cloud
const ABYSS := -86.0     # far under the cloud sea: where the pillars go down into the dark


func _build_sea() -> void:
	## Layers of cloud lying at different heights between the pillars; far below them, the dark the pillars stand in
	## (it shows when the cut parts the cloud).
	var deep := MeshInstance3D.new()
	var dm := PlaneMesh.new()
	dm.size = Vector2(2400, 2400)
	deep.mesh = dm
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color(0.03, 0.035, 0.05)
	dmat.roughness = 1.0
	deep.material_override = dmat
	deep.position = Vector3(0, ABYSS, -500)
	add_child(deep)
	# veils of mist from just under the cloud down into the deep: each lower one darker, bluer, a little denser
	for k in 6:
		var t := float(k) / 5.0
		var veil := MeshInstance3D.new()
		var vm := PlaneMesh.new()
		vm.size = Vector2(1400, 1100)
		veil.mesh = vm
		var m := ShaderMaterial.new()
		m.shader = Assets.shader("res://shaders/abyss_mist.gdshader")
		m.set_shader_parameter("tex", Assets.tex("res://assets/tex/clouds.png", true))
		m.set_shader_parameter("col", Color(lerpf(0.3, 0.04, t), lerpf(0.35, 0.05, t), lerpf(0.45, 0.09, t), lerpf(0.3, 0.72, t)))
		m.set_shader_parameter("glow_k", 1.0 - t)   # the light from the cut reaches the upper veils, not the deep
		m.set_shader_parameter("scale", Vector2(3.0 + k * 0.7, 2.4 + k * 0.6))
		m.set_shader_parameter("offset", Vector2(k * 0.29, k * 0.17))
		m.set_shader_parameter("drift", Vector2(0.003, -0.0015) * (1.0 + k * 0.3))
		veil.material_override = m
		veil.position = Vector3(0, SEA - 4.5 - pow(t, 1.4) * 52.0, -450)
		veil.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(veil)
		_mists.append(m)
	_build_deck()
	# shafts of light that will fall into the channel the cut opens, out of sight till then (_plane_of_cut, _wave)
	for k in 7:
		var dd := 24.0 + k * k * 9.0
		var ray := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(2.4 + dd * 0.05, 40.0 + dd * 0.12)
		ray.mesh = qm
		var rm := StandardMaterial3D.new()
		rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		rm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		rm.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
		rm.albedo_texture = _ray_tex()
		rm.albedo_color = Color(0.75, 0.82, 0.95, 0.0)
		rm.cull_mode = BaseMaterial3D.CULL_DISABLED
		ray.material_override = rm
		ray.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ray.position = Vector3(0, SEA - 60.0, 0)
		ray.set_meta("d", dd)
		add_child(ray)
		_rays.append(ray)
	for k in 2:   # thin wisps drifting over it
		var plane := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(1000, 800)
		plane.mesh = pm
		var m := ShaderMaterial.new()
		m.shader = Assets.shader("res://shaders/cloud_sea.gdshader")
		m.set_shader_parameter("tex", Assets.tex("res://assets/tex/clouds.png", true))
		m.set_shader_parameter("scale", Vector2(6.0 + k * 2.0, 5.0 + k * 2.0))
		m.set_shader_parameter("offset", Vector2(k * 0.37, k * 0.21))
		m.set_shader_parameter("drift", Vector2(0.004, 0.0018) * (k + 1))
		m.set_shader_parameter("tint", Color(0.84, 0.87, 0.92, 0.16 - k * 0.06))
		m.set_shader_parameter("push_k", 1.1 + 0.1 * k)
		m.set_shader_parameter("plane_size", pm.size)
		m.render_priority = 3
		plane.material_override = m
		_clouds.append(m)
		plane.position = Vector3(0, SEA + 7.0 + k * 4.0, -350)
		plane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(plane)


func _build_deck() -> void:
	## The top of the cloud sea (shaders/cloud_deck.gdshader shapes and lights it): a grid fanned out from the ledge,
	## fine near and coarse far, out past where the fog closes.
	var o := Vector2(CAM_POS.x, CAM_POS.z)
	var nr := 150
	var nc := 200
	var verts := PackedVector3Array()
	for i in nr:
		var r := 3.0 * pow(1700.0 / 3.0, float(i) / (nr - 1))
		for j in nc:
			var a := deg_to_rad(lerpf(-85.0, 85.0, float(j) / (nc - 1)))
			verts.append(Vector3(o.x + sin(a) * r, SEA, o.y - cos(a) * r))
	var idx := PackedInt32Array()
	for i in nr - 1:
		for j in nc - 1:
			var v := i * nc + j
			idx.append_array([v, v + 1, v + nc, v + 1, v + nc + 1, v + nc])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.custom_aabb = AABB(Vector3(-1800, SEA - 30.0, -1800), Vector3(3600, 90, 3600))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_deck = ShaderMaterial.new()
	_deck.shader = Assets.shader("res://shaders/cloud_deck.gdshader")
	_deck.set_shader_parameter("noise", Assets.tex("res://assets/tex/cloud_noise.png", true))
	_deck.set_shader_parameter("sea", SEA)
	_deck.set_shader_parameter("reach", REACH)
	_deck.set_shader_parameter("spend", SPEND)
	_deck.render_priority = 2   # (over the veils of the deep, under the wisps)
	mi.material_override = _deck
	add_child(mi)


# ------------------------------------------------------------------ the pillars
var top_r := 0.0   # the radius of the flat top of the last pillar made (what can stand on it)


func _karst_of(mat: Material) -> ShaderMaterial:
	## The limestone (shaders/karst.gdshader) in the colours of mat (its tint, its grain, its glow).
	if _karst.has(mat):
		return _karst[mat]
	var src := mat as StandardMaterial3D
	var k := ShaderMaterial.new()
	k.shader = Assets.shader("res://shaders/karst.gdshader")
	k.set_shader_parameter("grain", src.albedo_texture)
	k.set_shader_parameter("noise", Assets.tex("res://assets/tex/clouds.png", true))
	k.set_shader_parameter("face", Assets.tex("res://assets/tex/karst_face.png", true))
	k.set_shader_parameter("face_n", Assets.tex("res://assets/tex/karst_face_n.png", true))
	k.set_shader_parameter("tint", src.albedo_color)
	if src.emission_enabled:
		k.set_shader_parameter("glow", src.emission * src.emission_energy_multiplier)
		k.set_shader_parameter("moss_amount", 0.35)
	k.set_shader_parameter("sea", SEA)
	k.set_shader_parameter("abyss", ABYSS)
	_karst[mat] = k
	return k


func _spire(at: Vector3, r: float, h: float, mat: Material, top := "round", shelves := -1) -> Vector3:
	## A pillar of limestone, a karst tower: it wanders a little going up, swelling and narrowing, stepping in at the
	## beds (a hard edge in the light at each joint, shrubs on the steps); fluted all round with grooves running down
	## it and cut by deep clefts; here and there a shelf standing out from it, undercut beneath, a pine on it and
	## creeper hanging off its lip. Its top "round" (rounded over and grown with forest), "sharp" (a broken point) or
	## "flat" (a table of rock: what is built on it stands on it); its foot far down in the dark under the cloud sea.
	## shelves: how many (-1: as it falls). Returns the middle of the top; top_r the radius of what can stand on it.
	for k in (191 if top == "flat" else 200):   # (the numbers the old pillar drew, so the lands stand where they stood)
		_rng.randf()
	_shape.seed = hash(at) ^ hash(h)
	var near := at.z > -320.0
	var seg := 22 if near else 14
	var lean := Vector3(_shape.randf_range(-0.05, 0.05), 0, _shape.randf_range(-0.03, 0.03))
	var bend_a := _shape.randf() * TAU
	var bend := Vector3(cos(bend_a), 0, sin(bend_a)) * r * _shape.randf_range(0.05, 0.14)
	var bend_f := _shape.randf_range(0.6, 1.6)
	var bend_p := _shape.randf() * TAU
	var swell: Array = []   # bulges and necks up its height: [how much, how often, where]
	for k in 3:
		swell.append([_shape.randf_range(0.03, 0.08), _shape.randf_range(1.5, 5.0), _shape.randf() * TAU])
	var steps: Array = []   # beds where it steps in going up: [how high, how much]
	for k in _shape.randi_range(1, 3):
		steps.append([_shape.randf_range(0.15, 0.78), _shape.randf_range(0.05, 0.1)])
	var lobes: Array = []   # its plan: [how many, how much, where, how it turns going up]
	for k in [2, 3, 5]:
		lobes.append([k, _shape.randf_range(0.04, 0.14), _shape.randf() * TAU, _shape.randf_range(-2.0, 2.0)])
	var fl_k := _shape.randi_range(8, 13)
	var fl_ph := _shape.randf() * TAU
	var clefts: Array = []  # [where, how deep, how wide]
	for c in _shape.randi_range(1, 3):
		clefts.append([_shape.randf() * TAU, _shape.randf_range(0.14, 0.3), _shape.randf_range(0.07, 0.14)])
	if shelves < 0:
		shelves = _shape.randi_range(0, 2) if h > 14.0 else 0
	var shelf: Array = []   # [how high, which way it faces, how far it stands out]
	for k in shelves:
		shelf.append([_shape.randf_range(0.28, 0.72), _shape.randf() * TAU, _shape.randf_range(0.14, 0.24)])
	# the rings: even steps up it; at each step of the beds one just under and one just over it (so the step is
	# level); at each shelf the undercut, the lip below and above, and back at the wall (so the shelf's top is level)
	var marks: Array = []
	for sp in steps:
		marks.append(sp[0] - 0.004)
		marks.append(sp[0] + 0.004)
	for sh in shelf:
		for dt in [-0.07, -0.035, 0.0, 0.004]:
			marks.append(sh[0] + dt)
	var ts: Array = marks.duplicate()
	var n_even := clampi(int(h / 2.4), 10, 34)
	for j in n_even + 1:
		var t := float(j) / n_even
		var clear := true
		for m in marks:
			if absf(t - m) < 0.012:
				clear = false
		if clear:
			ts.append(t)
	ts.sort()
	var forest := top == "round" and near and mat != _white and _shape.randf() < 0.5
	var crown := top == "sharp" or (top == "round" and not forest)
	var dome := forest   # (a level top rounded at its shoulder, the forest laid on it: _canopy)
	var gap := h / n_even
	var rings: Array = []   # [points, how much sky each sees, t, the middle]
	for t: float in ts:
		var q := clampf((t - 0.8) / 0.2, 0.0, 1.0) if crown else 0.0
		var shoulder := 1.0
		if q > 0.0:
			shoulder = (1.0 - q) if top == "sharp" else sqrt(maxf(1.0 - q * q, 0.0))
		elif dome and t > 0.84:
			shoulder = 1.0 - 0.18 * pow((t - 0.84) / 0.16, 2.0)
		var prof := 1.15 - 0.3 * t
		for sw in swell:
			prof *= 1.0 + sw[0] * sin(sw[1] * TAU * t + sw[2])
		for sp in steps:
			if t > sp[0]:
				prof *= 1.0 - sp[1]
		var rr: float = r * prof * maxf(shoulder, 0.06) * _shape.randf_range(0.97, 1.03)
		var even: bool = (top == "flat" or dome) and t > 0.86   # a table's edge kept even, so what stands on it stands
		var keep := 0.25 if even else 1.0
		var c := at + lean * h * t + bend * sin(bend_f * PI * t + bend_p) + Vector3(0, h * t, 0)
		var pts: Array = []
		var sky: Array = []
		for i in seg:
			var a := TAU * i / seg
			var f := 1.0
			for L in lobes:
				f += L[1] * sin(L[0] * a + L[2] + L[3] * t) * keep
			var groove := 0.035 * sin(fl_k * a + fl_ph + t * 2.0) * keep
			for cl in clefts:
				var da := wrapf(a - cl[0] - t * 0.3, -PI, PI)   # (a cleft wanders a little going up)
				groove -= cl[1] * exp(-da * da / (cl[2] * cl[2])) * keep
			var out := 0.0
			for sh in shelf:
				var face := pow(maxf(cos(a - sh[1]), 0.0), 1.4)
				var dt: float = t - sh[0]
				if dt > -0.036 and dt < 0.001:
					out += sh[2] * face
				elif dt > -0.071 and dt <= -0.036:
					groove -= 0.06 * face
			var jit := 1.0 if (even and t > 0.999) else _shape.randf_range(0.96, 1.04)
			var lift := 0.0
			if q > 0.0:   # the crown broken into knobs and gaps (never higher than the ring over it: no folds)
				jit *= _shape.randf_range(0.75, 1.1)
				lift = gap * 0.9 * q * _shape.randf()
			var rv := rr * (f + groove + out) * jit
			pts.append(c + Vector3(cos(a) * rv, lift, sin(a) * rv))
			sky.append(clampf(1.0 + groove * 4.0, 0.3, 1.0))
		rings.append([pts, sky, t, c])
	var foot: Array = []   # its foot, far down in the dark under the cloud sea
	for v in rings[0][0]:
		var o: Vector3 = v - at
		foot.append(at + Vector3(o.x * 1.25, ABYSS - 2.0 - at.y, o.z * 1.25))
	rings.insert(0, [foot, rings[0][1], -1.0, at])
	var girth := TAU * r
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var group := 0
	var since := 0
	for j in rings.size() - 1:
		# a joint between beds, a hard edge in the light: at a step's and a shelf's edges, and every few rings
		since += 1
		if marks.has(rings[j][2]) or since > _shape.randi_range(3, 6):
			group += 1
			since = 0
		st.set_smooth_group(group)
		var lo: Array = rings[j][0]
		var hi: Array = rings[j + 1][0]
		for i in seg:
			var i2 := (i + 1) % seg
			var quad := [[lo[i], float(i) / seg, rings[j][1][i]], [lo[i2], float(i + 1) / seg, rings[j][1][i2]],
				[hi[i], float(i) / seg, rings[j + 1][1][i]], [hi[i2], float(i + 1) / seg, rings[j + 1][1][i2]]]
			for qq in [0, 1, 2, 1, 3, 2]:
				var vv: Array = quad[qq]
				st.set_color(Color(vv[2], 0.0, 0.0))
				st.set_uv(Vector2(vv[1], (vv[0] as Vector3).y))
				st.set_uv2(Vector2(girth, 0.0))
				st.add_vertex(vv[0])
	var ring_top: Array = rings[rings.size() - 1][0]
	var ctr := Vector3.ZERO
	for v in ring_top:
		ctr += v
	ctr /= ring_top.size()
	if crown:
		ctr.y += gap * 0.5
	st.set_smooth_group(group + 1)
	for i in seg:
		for v in [ctr, ring_top[i], ring_top[(i + 1) % seg]]:
			st.set_color(Color(1.0, 1.0, 0.0))
			st.set_uv(Vector2.ZERO)
			st.set_uv2(Vector2(girth, 0.0))
			st.add_vertex(v)
	st.generate_normals()
	st.generate_tangents()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _karst_of(mat)
	add_child(mi)
	_last_ring = ring_top
	if dome:
		_canopy(ring_top, ctr, r)
	if near:
		_green_on(rings, shelf, steps, seg, top, r)
	if at.y < SEA and at.y + h > SEA:   # it stands up through the cloud: the cut's push stops against it
		_rocks.append(Vector3(at.x, at.z, r * 1.1))
	top_r = 0.0
	if top == "flat":   # the radius of a circle inside the table's edge
		var mn := INF
		for v in ring_top:
			mn = minf(mn, Vector2(v.x - ctr.x, v.z - ctr.z).length())
		top_r = mn * cos(PI / seg) * 0.95
	return ctr


func _ring_at(rings: Array, t: float) -> Array:
	for rg in rings:
		if is_equal_approx(rg[2], t):
			return rg
	return []


func _green_on(rings: Array, shelf: Array, steps: Array, seg: int, top: String, r: float) -> void:
	## What grows on a pillar, each thing standing on rock: a pine on a shelf (most of them) and creeper hanging off the
	## shelf's lip; shrubs on the steps of the beds where they are deep enough; on a crown of broken rock, shrubs and a
	## pine in among the knobs.
	for sh in shelf:
		var lip := _ring_at(rings, sh[0])
		var wall := _ring_at(rings, sh[0] + 0.004)
		if lip.is_empty() or wall.is_empty():
			continue
		var i := posmod(roundi(sh[1] / TAU * seg), seg)
		var o: Vector3 = lip[0][i]
		var w: Vector3 = wall[0][i]
		var deep := Vector2(o.x - w.x, o.z - w.z).length()
		if deep < 0.45:
			continue
		if _shape.randf() < 0.8:
			_plant("tung", (o * 0.4 + w * 0.6), deep * 2.2)
		var iv := _plant("ivy", o, deep * 1.5)   # hung from the lip: its mat of leaves on the lip, the strands below
		iv.position.y -= iv.texture.get_height() * iv.pixel_size - 3.0 * iv.pixel_size
	for sp in steps:
		var below := _ring_at(rings, sp[0] - 0.004)
		var above := _ring_at(rings, sp[0] + 0.004)
		if below.is_empty() or above.is_empty():
			continue
		for n in 2:
			var i := _shape.randi() % seg
			var o: Vector3 = below[0][i]
			var w: Vector3 = above[0][i]
			var deep := Vector2(o.x - w.x, o.z - w.z).length()
			if deep > 0.5:
				_plant("leafclump_dark" if n == 0 else "bush", Vector3((o.x + w.x) * 0.5, maxf(o.y, w.y), (o.z + w.z) * 0.5), deep * 1.7)


func _canopy(ring: Array, ctr: Vector3, r: float) -> void:
	## A forest on a pillar's top (shaders/canopy.gdshader breaks it into the crowns of trees): a low dome over the
	## rock, reaching a little past its edge and hanging down over the rim, so the trees stand on the rock.
	if _canopy_m == null:
		_canopy_m = ShaderMaterial.new()
		_canopy_m.shader = Assets.shader("res://shaders/canopy.gdshader")
		_canopy_m.set_shader_parameter("noise", Assets.tex("res://assets/tex/cloud_noise.png", true))
	var seg := ring.size()
	var hc := r * 0.32 + 1.0
	var rows: Array = []
	var skirt: Array = []   # hanging over the rim, outside the rock
	for v in ring:
		var o: Vector3 = v - ctr
		skirt.append(ctr + Vector3(o.x, 0, o.z) * 1.05 + Vector3(0, -r * 0.14, 0))
	rows.append(skirt)
	var k_n := 7
	for k in k_n + 1:
		var f := 1.0 - float(k) / k_n   # 1 at the rim, 0 in the middle
		var row: Array = []
		for v in ring:
			var o: Vector3 = v - ctr
			row.append(ctr + Vector3(o.x * f * 1.07, hc * sqrt(maxf(1.0 - f * f, 0.0)) - 0.1, o.z * f * 1.07))
		rows.append(row)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in rows.size() - 1:
		var lo: Array = rows[j]
		var hi: Array = rows[j + 1]
		for i in seg:
			var i2 := (i + 1) % seg
			for v in [lo[i], lo[i2], hi[i], lo[i2], hi[i2], hi[i]]:
				st.add_vertex(v)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _canopy_m
	add_child(mi)


func _plant(what: String, at: Vector3, width: float) -> Sprite3D:
	## A plant (assets/sprites/props/<what>.png) width metres across standing at at, sunk a little so it does not
	## hover; dark under the storm.
	var tex := Assets.tex("res://assets/sprites/props/%s.png" % what)
	var px := width / tex.get_width()
	var sp := B.billboard(self, "res://assets/sprites/props/%s.png" % what, at - Vector3(0, px * 2.0, 0), px, false)
	sp.modulate = Color(0.5, 0.56, 0.56)
	return sp


func _on_top(top: Vector3, reach := 0.6) -> Vector3:
	## A point on the flat top of the last pillar (within reach x its radius), a little sunk so nothing hovers.
	var a := _rng.randf() * TAU
	var d := sqrt(_rng.randf()) * top_r * reach
	return top + Vector3(cos(a) * d, -0.15, sin(a) * d)


func _cluster(at: Vector3, n: int, r: float, h: float, spread: float, mat: Material, top := "round", keep := -1) -> Vector3:
	## One tall pillar (its top as asked) and n lower ones round it, in front of it a little more than behind, rounded
	## or pointed; only the first keep of them built when keep is given (the rest drawn but not built, so the layout
	## after them holds). Returns the tall one's top; top_r stays the tall one's.
	var side_top := "sharp" if top == "sharp" else "round"
	for k in n:
		if keep >= 0 and k >= keep:
			for i in 205:
				_rng.randf()
			continue
		var a := _rng.randf() * TAU
		var d := _rng.randf_range(0.6, 1.0) * spread
		var p := at + Vector3(cos(a) * d, _rng.randf_range(-4, 0), absf(sin(a)) * d * 0.8)
		_spire(p, r * _rng.randf_range(0.4, 0.7), h * _rng.randf_range(0.35, 0.7), mat, side_top)
	var t := _spire(at, r, h, mat, top)
	return t


func _pine_on(top: Vector3, n: int) -> void:
	## Pines growing on the flat top of the last pillar, sized to it.
	var s := clampf(top_r * 0.012, 0.03, 0.14)
	for k in n:
		var t := B.billboard(self, "res://assets/sprites/props/tung.png", _on_top(top, 0.55), s, false)
		t.modulate = Color(0.5, 0.56, 0.56)


func _build_lands() -> void:
	# the rest of the sea: pillars everywhere, small and far, larger and nearer; the middle behind the protagonist open
	var placed := 0
	while placed < 70:
		var z := _rng.randf_range(-80.0, -460.0)
		var x := _rng.randf_range(-1.25, 1.25) * (-z) * 0.85
		if z > -190.0 and absf(x) < 30.0:
			continue
		if absf(x / (-z + 4.6)) < 0.1 and z > -380.0:   # the column of sky under the title
			continue
		placed += 1
		var r := _rng.randf_range(1.6, 4.2) * (-z / 110.0)
		var wooded := _rng.randf() < 0.4
		if _crowded(x, z, r):   # (its numbers drawn all the same, so everything after stands where it stood)
			_rng.randf()
			for k in (191 if wooded else 200):
				_rng.randf()
			if wooded:
				for k in _rng.randi_range(1, 3) * 2:
					_rng.randf()
			continue
		var top := _spire(Vector3(x, SEA - 8.0, z), r, r * _rng.randf_range(4.0, 8.0), _rock, "flat" if wooded else "round")
		if wooded:
			_pine_on(top, _rng.randi_range(1, 3))
			if z > -250.0:
				_canopy(_last_ring, top, r)
	# placed by where they fall in the frame (x across, from the left; the middle column kept for the title)
	_bach_son(Vector3(-112, SEA - 6.0, -220))     # 0.20
	_tang_thien(Vector3(-88, SEA - 6.0, -310))    # 0.33, far
	_thien_menh(Vector3(58, SEA - 6.0, -290))     # 0.62, the beam rising beside the title
	_hai_uyen(Vector3(-96, SEA, -128))            # 0.12, low
	_mong_trach(Vector3(-50, SEA, -165))          # 0.33, low
	_vo_dien(Vector3(-36, SEA - 6.0, -215))       # 0.40
	_van_thu(Vector3(70, SEA - 6.0, -185))        # 0.72
	_xich_hoang(Vector3(108, SEA - 6.0, -200))    # 0.82
	_thiet_son(Vector3(215, SEA - 6.0, -300))     # 0.93, far
	_kim_thanh(Vector3(66, SEA - 6.0, -104))      # 0.87, near
	# nearer pillars on the right, so the sea is not empty under the lands there (on the left the shrine and the menu
	# have the near ground, and pillars there only crowd the white city)
	for k in 3 * 204:   # (the left ones' numbers drawn all the same, so the right ones stand where they stood)
		_rng.randf()
	for side in [1.0]:
		for k in 3:
			var p := Vector3(side * _rng.randf_range(34.0, 60.0), SEA - 8.0, _rng.randf_range(-62.0, -85.0))
			_spire(p, _rng.randf_range(2.2, 3.4), _rng.randf_range(20.0, 30.0), _rock, "round", 1)


const ROOM := [   # the lands on the left, and how much clear sea is kept round each: (x, z, radius)
	Vector3(-112, -220, 62), Vector3(-80, -300, 50), Vector3(-36, -215, 36), Vector3(-50, -165, 30), Vector3(-96, -128, 36),
]


func _crowded(x: float, z: float, r: float) -> bool:
	## Whether a pillar of the field would stand in the room kept round a land on the left (or crowd the band between
	## them), where it would only muddle the lands' shapes.
	for c in ROOM:
		if Vector2(x - c.x, z - c.y).length() < c.z + r:
			return true
	return x < -20.0 and z > -340.0 and z < -110.0 and x > -150.0


func _lamp(at: Vector3, col: Color, energy: float, rng_m: float) -> void:
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = energy
	l.omni_range = rng_m
	l.position = at
	add_child(l)


func _glow(at: Vector3, col: Color, r: float, e := 3.0) -> void:
	## A point of lamplight seen from far off (a window, a lantern), set into what it lights.
	var m := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 6
	sm.rings = 3
	m.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = e
	m.material_override = mat
	m.position = at
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)


func _lit_m() -> StandardMaterial3D:
	## Windows: paper lattice lit from inside, the frame dark, the panes glowing warm (assets/tex/lattice.png).
	if _lit == null:
		_lit = B.mat("res://assets/tex/lattice.png", 1.4, Vector3.ONE, {"triplanar": true, "world": true, "tint": Color(0.7, 0.55, 0.42)})
		_lit.emission_enabled = true
		_lit.emission = Color(1.0, 0.7, 0.38)
		_lit.emission_energy_multiplier = 1.5
		_lit.emission_texture = Assets.tex("res://assets/tex/lattice.png", true)
	return _lit


func _timber_m() -> StandardMaterial3D:
	if _timber == null:
		_timber = B.mat("res://assets/tex/planks.png", 1.2, Vector3.ONE, {"triplanar": true, "world": true, "tint": Color(0.32, 0.25, 0.21)})
	return _timber


func _house(p: Vector3, w: float, h: float, wall: Material, lit: bool) -> void:
	## A hall standing at p, facing us: a stone podium a step high; low walls set back under the eaves, a row of timber
	## columns in front of them carrying a beam, the front between the columns latticed (glowing softly from inside
	## when lit); the gable ends closed with wall; and a big roof of dark tile reaching well out past the walls on every
	## side, so that from far off the roof is most of what is seen, as with the halls of the valley.
	var d := w * 0.7
	var hw := h * 0.72
	B.box(self, Vector3(w * 1.25, 0.4, d * 1.3), p + Vector3(0, 0.2, 0), _rock, 0, false)
	var base := p.y + 0.4
	var zf := p.z + d * 0.36   # the line of the columns
	B.box(self, Vector3(w, hw, d * 0.72), Vector3(p.x, base + hw * 0.5, p.z - d * 0.08), wall, 0, false)
	for i in 4:
		var x := p.x + w * (float(i) / 3.0 - 0.5) * 0.96
		B.box(self, Vector3(0.15, hw, 0.15), Vector3(x, base + hw * 0.5, zf), _timber_m(), 0, false)
	B.box(self, Vector3(w * 1.04, 0.2, 0.2), Vector3(p.x, base + hw + 0.06, zf), _timber_m(), 0, false)
	var front: Material = _lit_soft() if lit else _timber_m()
	B.box(self, Vector3(w * 0.9, hw * 0.6, 0.05), Vector3(p.x, base + hw * 0.46, p.z + d * 0.28), front, 0, false)
	var eave := base + hw + 0.12
	var ridge := eave + d * 0.55
	_gable(p.x - w * 0.5, p.z - d * 0.44, p.z + d * 0.28, base + hw, ridge - 0.12, p.z - d * 0.08, wall)
	_gable(p.x + w * 0.5, p.z - d * 0.44, p.z + d * 0.28, base + hw, ridge - 0.12, p.z - d * 0.08, wall)
	_plain_roof(B.roof(self, w * 1.5, d * 0.88, d * 0.88, eave, ridge, Vector3(p.x, 0, p.z - d * 0.08), _ink_roof))


func _gable(x: float, z0: float, z1: float, y0: float, y1: float, zc: float, mat: Material) -> void:
	## The triangle of wall closing a roof's end, at x, from the wall's top (y0) up to under the ridge (y1).
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a := Vector3(x, y0, z0)
	var b := Vector3(x, y0, z1)
	var c := Vector3(x, y1, zc)
	for v in [a, b, c, a, c, b]:   # both faces
		st.set_uv(Vector2(v.z, v.y))
		st.add_vertex(v)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	add_child(mi)


var _lit_s: StandardMaterial3D


func _lit_soft() -> StandardMaterial3D:
	## A latticed front lit from inside, softly: a warm band between the columns, not a hole of light.
	if _lit_s == null:
		_lit_s = _lit_m().duplicate()
		_lit_s.emission_energy_multiplier = 0.7
	return _lit_s


func _houses(top: Vector3, n: int, wall: Material, lit: Color, scale := 1.0, reach := 0.6, keep_clear := Rect2(), edge := -1.0) -> void:
	## A town on the flat top of the last pillar: halls facing us (south) as the halls of a town do, each on its
	## podium, none overlapping another (or keep_clear), each roof inside edge (default the table's edge); lit fronts
	## when lit has alpha. Fewer than n when they do not fit.
	if edge < 0.0:
		edge = top_r - 0.2
	for k in n * 4:   # (the numbers the old scatter drew, so what comes after stands where it stood)
		_rng.randf()
	_shape.seed = hash(top) ^ n
	var placed: Array = []
	if keep_clear.has_area():
		placed.append(keep_clear)
	var made := 0
	var tries := 0
	while made < n and tries < n * 30:
		tries += 1
		var w := _shape.randf_range(2.4, 3.6) * scale
		var h := _shape.randf_range(2.0, 2.8) * scale
		var a := _shape.randf() * TAU
		var rr := sqrt(_shape.randf()) * top_r * reach
		var c := Vector2(top.x + cos(a) * rr, top.z + sin(a) * rr)
		var half := Vector2(w * 0.76, w * 0.7 * 0.95)   # the roof's reach
		var rect := Rect2(c - half, half * 2.0).grow(0.25)
		var ok := true
		for cx in [-1.0, 1.0]:
			for cz in [-1.0, 1.0]:
				if (c + Vector2(cx * half.x, cz * half.y) - Vector2(top.x, top.z)).length() > edge:
					ok = false
		for q in placed:
			if (q as Rect2).intersects(rect):
				ok = false
		if not ok:
			continue
		placed.append(rect)
		made += 1
		_house(Vector3(c.x, top.y - 0.15, c.y), w, h, wall, lit.a > 0.0)


func _bach_son(at: Vector3) -> void:
	## The white city: white pillars standing in tiers, each table of rock carrying its white walls and black roofs.
	var top := _cluster(at, 4, 13.0, 78.0, 26.0, _white, "flat", 2)
	_houses(top, 5, _lime, Color(0, 0, 0, 0), 0.8, 0.9)
	_pine_on(top, 2)
	for tier in [[Vector3(-11, 0, 16), 8.0, 48.0], [Vector3(10, 0, 18), 8.5, 40.0], [Vector3(-1, 0, 24), 9.0, 30.0]]:
		var t := _spire(at + tier[0], tier[1], tier[2], _white, "flat")
		_houses(t, 3, _lime, Color(0, 0, 0, 0), 0.75, 0.9)


func _tang_thien(at: Vector3) -> void:
	## A colossal black stele half sunk in the sea of cloud, leaning; dark pillars round it.
	var black := B.mat("res://assets/tex/flank_lime.png", 0.4, Vector3.ONE, {"triplanar": true, "world": true, "tint": Color(0.1, 0.1, 0.12)})
	var s := B.box(self, Vector3(12, 86, 4), at + Vector3(0, 38, 0), black, 14, false, 0.8)
	s.rotation_degrees.z = -8.0
	_cluster(at + Vector3(14, 0, 18), 4, 6.0, 30.0, 16.0, _rock_dark, "round", 1)


func _thien_menh(at: Vector3) -> void:
	## The highest pillar, a palace on its table of rock, under a pillar of light that goes up into the clouds.
	var top := _cluster(at, 7, 15.0, 112.0, 30.0, _rock, "flat")
	var gold := B.mat("res://assets/tex/lime_wall.png", 0.6, Vector3.ONE, {"triplanar": true, "world": true, "tint": Color(1.0, 0.9, 0.72)})
	_houses(top, 4, gold, Color(1.0, 0.85, 0.55), 1.6, 0.4)
	var beam := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 3.0
	cm.bottom_radius = 1.6
	cm.height = 700.0
	beam.mesh = cm
	var bm := StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.albedo_color = Color(0.85, 0.92, 1.0, 0.8)
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	beam.material_override = bm
	beam.position = top + Vector3(0, 350, 0)
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(beam)
	_lamp(top + Vector3(0, 12, 14), Color(0.85, 0.92, 1.0), 7.0, 70.0)


func _hai_uyen(at: Vector3) -> void:
	## The sea: dark water open in the cloud, two sea stacks, a long stone bridge between them.
	var water := StandardMaterial3D.new()
	water.albedo_color = Color(0.1, 0.14, 0.19)
	water.roughness = 0.12
	water.metallic_specular = 0.9
	var disc := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 36
	cm.bottom_radius = 36
	cm.height = 0.2
	disc.mesh = cm
	disc.material_override = water
	disc.position = at + Vector3(0, 2.5, 0)
	add_child(disc)
	var a := _spire(at + Vector3(-15, -4, 4), 5.0, 28.0, _rock)
	var b := _spire(at + Vector3(16, -4, -6), 5.5, 32.0, _rock)
	var ya := a.y - 6.0
	var p0 := Vector3(a.x, ya, a.z)
	var p1 := Vector3(b.x, ya, b.z)
	var mid := (p0 + p1) * 0.5
	var br := B.box(self, Vector3(1.2, 1.2, p0.distance_to(p1)), mid, _lime, 0, false)
	br.look_at(p1, Vector3.UP)


func _mong_trach(at: Vector3) -> void:
	## The marsh of dreams: low flat islands in the cloud, reeds on them, a lamp on each.
	for k in 7:
		if k >= 3:   # (three islands; the others' numbers drawn all the same)
			for i in 4:
				_rng.randf()
			continue
		var p := at + Vector3(_rng.randf_range(-20, 20), 3.0, _rng.randf_range(-10, 10))
		var isl := B.cylinder(self, _rng.randf_range(3, 6), 1.4, p, _rock, false, 9)
		isl.scale = Vector3(1, 1, 0.6)
		var rd := B.billboard(self, "res://assets/sprites/props/reeds.png", p + Vector3(0, 0.6, 0), 0.08, false)
		rd.modulate = Color(0.55, 0.6, 0.55)
		_glow(p + Vector3(_rng.randf_range(-1.5, 1.5), 1.0, 0.8), Color(1.0, 0.72, 0.42), 0.35)
	_lamp(at + Vector3(0, 6, 0), Color(1.0, 0.72, 0.42), 5.0, 34.0)


func _vo_dien(at: Vector3) -> void:
	## The faceless country: grey towers all alike on a table of rock, no window in any of them.
	var top := _cluster(at, 3, 9.0, 44.0, 14.0, _rock, "flat")
	var grey := B.mat("res://assets/tex/lime_wall_old.png", 0.5, Vector3.ONE, {"triplanar": true, "world": true, "tint": Color(0.58, 0.6, 0.63)})
	for k in 7:
		if k >= 4:   # (four towers; the others' numbers drawn all the same)
			for i in 3:
				_rng.randf()
			continue
		var p := _on_top(top, 0.7)
		var h := _rng.randf_range(5, 11)
		B.box(self, Vector3(2.0, h, 2.0), p + Vector3(0, h * 0.5, 0), grey, 0, false)
		B.box(self, Vector3(2.3, 0.3, 2.3), p + Vector3(0, h + 0.15, 0), _timber_m(), 0, false)


func _van_thu(at: Vector3) -> void:
	## Ten thousand books: a tower of seven storeys on a table of rock; on every storey a gallery under its eaves,
	## timber posts, lattice lit all round from the lamps of the readers inside.
	var top := _cluster(at, 3, 9.0, 40.0, 14.0, _rock, "flat")
	var wall := B.mat("res://assets/tex/planks.png", 0.9, Vector3.ONE, {"triplanar": true, "world": true, "tint": Color(0.46, 0.34, 0.27)})
	var w0 := minf(6.0, top_r * 1.15)
	var y := top.y - 0.15
	B.box(self, Vector3(w0 + 1.2, 0.9, w0 + 1.2), Vector3(top.x, y + 0.45, top.z), _rock, 0, false)
	y += 0.9
	for k in 7:
		var w := w0 * (1.0 - k * 0.085)
		var hh := 3.0 if k == 0 else 2.4
		var c := Vector3(top.x, y + hh * 0.5, top.z)
		B.box(self, Vector3(w * 0.84, hh, w * 0.84), c, wall, 0, false)
		var e := w * 0.42 + 0.03
		for sd in [-1.0, 1.0]:
			B.box(self, Vector3(w * 0.56, hh * 0.46, 0.06), c + Vector3(0, 0.1, sd * e), _lit_m(), 0, false)
			B.box(self, Vector3(0.06, hh * 0.46, w * 0.56), c + Vector3(sd * e, 0.1, 0), _lit_m(), 0, false)
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				B.box(self, Vector3(0.22, hh, 0.22), c + Vector3(sx * w * 0.44, 0, sz * w * 0.44), _timber_m(), 0, false)
		B.box(self, Vector3(w * 1.02, 0.16, w * 1.02), Vector3(top.x, y + hh - 0.08, top.z), _timber_m(), 0, false)   # the gallery
		_plain_roof(B.roof(self, w * 1.42, w * 0.74, w * 0.74, y + hh, y + hh + 1.0, Vector3(top.x, 0, top.z), _ink_roof))
		y += hh + 1.0
	B.cylinder(self, 0.16, 3.0, Vector3(top.x, y + 1.2, top.z), _timber_m(), false, 6)   # the finial
	_lamp(Vector3(top.x, top.y + 12, top.z + 10), Color(1.0, 0.78, 0.5), 4.0, 30.0)


func _xich_hoang(at: Vector3) -> void:
	## The red waste: burnt pillars, fires on the table of the tallest, the glow red under the storm.
	var red := B.mat("res://assets/tex/flank_lime.png", 0.35, Vector3.ONE, {"triplanar": true, "world": true, "tint": Color(0.42, 0.24, 0.2)})
	var top := _cluster(at, 5, 12.0, 38.0, 20.0, red, "flat")
	_houses(top, 4, B.color_mat(Color(0.16, 0.1, 0.09)), Color(1.0, 0.35, 0.2), 1.1)
	for k in 6:
		var p := _on_top(top, 0.8)
		var f := B.billboard(self, "res://assets/sprites/props/fire.png", p + Vector3(0, 0.6, 0), 0.07, false, 4, k % 4)
		f.modulate = Color(2.0, 1.1, 0.7)
		_lamp(p + Vector3(0, 2, 0), Color(1.0, 0.32, 0.18), 3.0, 18.0)


func _thiet_son(at: Vector3) -> void:
	## The iron mountains: black pointed pillars; in front of them low tables of rock with forges, chimneys, fire.
	_cluster(at, 6, 13.0, 80.0, 26.0, _rock_dark, "sharp")
	for k in 4:
		var p := at + Vector3(-27 + k * 18 + _rng.randf_range(-3, 3), 0, 26 + _rng.randf_range(-2, 4))
		var t := _spire(p, 5.0, _rng.randf_range(18.0, 26.0), _rock_dark, "flat")
		B.box(self, Vector3(3.0, 2.0, 2.4), t + Vector3(0, 0.85, 0), _rock_dark, 0, false)
		B.cylinder(self, 0.6, 6.0, t + Vector3(0.8, 3.0, -0.4), _rock_dark, false, 6)
		_glow(t + Vector3(0, 0.9, 1.25), Color(1.0, 0.5, 0.2), 0.6, 4.0)
		_lamp(t + Vector3(0, 2, 3), Color(1.0, 0.5, 0.2), 3.0, 20.0)


func _kim_thanh(at: Vector3) -> void:
	## The golden city: a town walled round the edge of a broad table of rock, a hall of two roofs in its middle, lit
	## windows in every street, lanterns along the wall.
	var top := _cluster(at, 3, 14.0, 34.0, 18.0, _rock, "flat")
	var wall := B.mat("res://assets/tex/lime_wall.png", 0.6, Vector3.ONE, {"triplanar": true, "world": true, "tint": Color(0.84, 0.74, 0.58)})
	var R := top_r * 0.9
	var n := 18
	var seg := 2.0 * R * sin(PI / n) + 0.25
	for i in n:
		var a := TAU * i / n
		if absf(wrapf(a - PI * 0.5, -PI, PI)) < 0.2:   # the gate, toward us
			continue
		var at_w := top + Vector3(cos(a) * R, -0.15, sin(a) * R)
		B.box(self, Vector3(seg, 2.4, 0.7), at_w + Vector3(0, 1.2, 0), wall, -rad_to_deg(a) + 90.0, false)
		B.box(self, Vector3(seg + 0.1, 0.3, 0.95), at_w + Vector3(0, 2.55, 0), _timber_m(), -rad_to_deg(a) + 90.0, false)
		if i % 3 == 0:   # a lantern on a post standing on the wall
			B.box(self, Vector3(0.1, 1.3, 0.1), at_w + Vector3(0, 3.35, 0), _timber_m(), 0, false)
			B.box(self, Vector3(0.5, 0.08, 0.08), at_w + Vector3(0, 3.95, 0) + Vector3(cos(a), 0, sin(a)) * 0.2, _timber_m(), -rad_to_deg(a) + 90.0, false)
			var l := B.billboard(self, "res://assets/sprites/props/lantern.png", at_w + Vector3(0, 3.35, 0) + Vector3(cos(a), 0, sin(a)) * 0.42, 0.03, false, 5, 4)
			l.modulate = Color(1.5, 1.2, 0.85)
	_house(top + Vector3(0, -0.15, -1.5), 4.6, 3.0, wall, true)   # the hall, its upper roof over the lower
	_plain_roof(B.roof(self, 3.9, 1.7, 1.7, top.y + 5.0, top.y + 6.3, Vector3(top.x, 0, top.z - 1.75), _ink_roof))
	_houses(top, 12, wall, Color(1.0, 0.75, 0.4), 0.68, 0.95, Rect2(top.x - 3.9, top.z - 4.6, 7.8, 6.4), R - 0.6)
	for k in 5:
		_lamp(_on_top(top, 0.6) + Vector3(0, 3, 0), Color(1.0, 0.72, 0.4), 2.4, 12.0)


# ------------------------------------------------------------------ the sky
func _build_sky_things() -> void:
	## A pale moon behind the storm, a ring of light round the pillar where it meets the cloud, a few birds.
	var moon := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 70
	sm.height = 140
	moon.mesh = sm
	var mm := StandardMaterial3D.new()
	mm.albedo_texture = Assets.tex("res://assets/tex/clouds.png", true)
	mm.albedo_color = Color(0.72, 0.76, 0.82)
	mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	moon.material_override = mm
	moon.position = Vector3(330, 300, -760)
	add_child(moon)
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 30
	tm.outer_radius = 32
	ring.mesh = tm
	var rmat := StandardMaterial3D.new()
	rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rmat.albedo_color = Color(0.85, 0.92, 1.0, 0.6)
	rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	ring.material_override = rmat
	ring.position = Vector3(34, 200, -290)
	ring.rotation_degrees = Vector3(72, 0, 8)
	add_child(ring)
	for k in 3:
		var b := B.billboard(self, "res://assets/sprites/props/bird.png", Vector3(_rng.randf_range(-30, 20), _rng.randf_range(10, 26), _rng.randf_range(-50, -90)), 0.08, false)
		b.modulate = Color(0.8, 0.84, 0.9)


func _process(delta: float) -> void:
	## Alive while the menu waits: the cloud sea drifts, the camera breathes, the protagonist breathes. After the cut,
	## the blow runs on (its clock slowed with the rest in the hitch).
	_t += delta
	if _wave_t >= 0.0:
		_wave_t += delta / _wave_f
		_wave(_wave_t)
	_trail_s.frame = hero_s.frame
	if _cutting:
		return
	hero_s.frame = 0 if fmod(_t, 2.6) < 1.5 else 1
	if _look_cam.size() == 6:   # (--vista-cam=x,y,z,lx,ly,lz: a look at the rock from elsewhere, for checking it)
		rig.set_view(Vector3(_look_cam[0], _look_cam[1], _look_cam[2]), Vector3(_look_cam[3], _look_cam[4], _look_cam[5]))
		return
	rig.set_view(CAM_POS + Vector3(sin(_t * 0.21) * 0.06, sin(_t * 0.33) * 0.04, 0), CAM_LOOK)


func cut(on_cut: Callable, on_split := Callable()) -> void:
	## Play: the protagonist draws the sword up out of the rock as they rise, settles, winds up and holds, and cuts:
	## the blade comes over, lands (the frame holds for a beat, the body lunges after it, the camera punches in), carries
	## through low, and comes to rest. Where it went, a line lies across the sea of cloud to the horizon, and for about
	## a second nothing moves; then the cloud gives along the line (_wave), with a blow felt through the camera.
	## on_cut is called at the moment the blade lands, on_split when the cloud gives.
	_cutting = true
	var f := 0.35 if Game.fast else 1.0
	_hero_home = hero_s.position
	var tw := create_tween()
	# rise, drawing the sword: a small hop up out of the sitting
	hero_s.frame = 2
	Audio.sfx("title_draw", -3.0)   # stone rasping, the steel ringing free (tools/gen_title_audio.py)
	tw.tween_property(hero_s, "position:y", _hero_home.y + 0.06, 0.12 * f).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(hero_s, "position:y", _hero_home.y, 0.1 * f).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await get_tree().create_timer(0.24 * f).timeout
	hero_s.frame = 3
	await get_tree().create_timer(0.32 * f).timeout
	# the wind-up: down a little into the knees, back a little, and a breath held
	hero_s.frame = 4
	Audio.sfx("title_breath", -2.0)   # a low wind and a drone swelling while the breath is held
	var w := create_tween().set_parallel(true)
	w.tween_property(hero_s, "position", _hero_home + Vector3(0.02, 0, 0.03), 0.3 * f).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	w.tween_property(rig.cam, "fov", 48.5, 0.5 * f).set_trans(Tween.TRANS_SINE)
	AutoTest.shot("t02_raise")
	await get_tree().create_timer(0.5 * f).timeout
	# the blade comes over, fast
	hero_s.frame = 6
	Audio.sfx("title_slash", 0.0)   # air torn right to left, the crack as it lands (0.07 s in), the blade singing on
	await get_tree().create_timer(0.07 * f).timeout
	# lands: the cut
	hero_s.frame = 7
	_plane_of_cut()
	var sm := create_tween()   # the line on the cloud: struck, then brightening while it holds
	sm.tween_method(func(v): _deck.set_shader_parameter("seam", v), 0.0, 1.0, 0.05 * f)
	sm.tween_method(func(v): _deck.set_shader_parameter("seam", v), 1.0, 1.15, 1.0 * f).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	on_cut.call()
	var l := create_tween().set_parallel(true)
	l.tween_property(hero_s, "position", _hero_home + Vector3(-0.025, 0, -0.06), 0.06 * f)   # (the sprite lunges itself)
	l.tween_property(rig.cam, "fov", 45.0, 0.07 * f).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	rig.shake(0.1, 0.2)
	Engine.time_scale = 0.12   # the hitch: a beat where everything holds on the stroke
	await get_tree().create_timer(0.16 * f, true, false, true).timeout
	Engine.time_scale = 1.0
	hero_s.frame = 8
	await get_tree().create_timer(0.07 * f).timeout
	hero_s.frame = 9
	var r := create_tween().set_parallel(true)
	r.tween_property(rig.cam, "fov", 50.0, 0.9 * f).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	r.tween_property(hero_s, "position", _hero_home + Vector3(-0.015, 0, -0.04), 0.4 * f).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(0.38 * f).timeout
	hero_s.frame = 10
	# the held breath: the line lies there, nothing moves
	AutoTest.shot("t03a_line")
	await get_tree().create_timer(0.45 * f).timeout
	# and the cloud gives: a deep blow through everything, the line flares and the sea parts along it
	Audio.sfx("title_split", 1.0)   # a crack, a deep blow, thunder rolling, a roar of air spreading to both sides
	rig.shake(0.38, 0.6)
	var p := create_tween()
	p.tween_property(rig.cam, "fov", 47.0, 0.06 * f).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	p.tween_property(rig.cam, "fov", 50.0, 0.8 * f).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if sm.is_running():
		sm.kill()
	var fade := create_tween()
	fade.tween_method(func(v): _deck.set_shader_parameter("seam", v), 1.4, 0.0, 0.7 * f).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_wave_f = f
	_wave_t = 0.0
	if on_split.is_valid():
		on_split.call()


func _plane_of_cut() -> void:
	## The cut is a plane through the camera that holds the line of the stroke on screen (from the upper right down
	## through the protagonist): the blow runs out along it from the ledge, shoving aside the cloud of the sea and of
	## the sky (_wave).
	var a := blade_on_screen()
	var d := Vector2(-0.78, 0.62).normalized()
	var r1: Vector3 = rig.cam.project_ray_normal(a - d * 500.0)
	var r2: Vector3 = rig.cam.project_ray_normal(a + d * 150.0)
	_cut_n = r1.cross(r2).normalized()
	_cut_o = rig.cam.global_position
	_nh = Vector2(_cut_n.x, _cut_n.z).normalized()
	_fh = Vector2(_nh.y, -_nh.x)
	if _fh.y > 0.0:
		_fh = -_fh
	for m in _clouds + _mists:
		m.set_shader_parameter("split_n", _cut_n)
		m.set_shader_parameter("split_o", _cut_o)
	_sky_mat.set_shader_parameter("split_n", _cut_n)
	var fwd := Vector3(_fh.x, 0, _fh.y)
	# the shafts of light, set along the cut (made ahead with the sea, so nothing is built in the middle of the blow)
	for ray in _rays:
		var dd: float = ray.get_meta("d")
		var at := _cut_o + fwd * dd
		ray.position = Vector3(at.x, SEA - (ray.mesh as QuadMesh).size.y * 0.5 + 6.0, at.z)
	# the deck: the plane, and the pillars in reach of the push (across the channel, along it, radius), nearest first
	_deck.set_shader_parameter("split_n", _cut_n)
	_deck.set_shader_parameter("split_o", _cut_o)
	var nl := maxf(Vector2(_cut_n.x, _cut_n.z).length(), 0.05)
	var near: Array = []
	for rk in _rocks:
		var rel := Vector2(rk.x - _cut_o.x, rk.y - _cut_o.z)
		var sx := (rel.dot(Vector2(_cut_n.x, _cut_n.z)) + (SEA - _cut_o.y) * _cut_n.y) / nl
		var dk := rel.dot(_fh)
		if dk > -10.0 and dk < REACH and absf(sx) < _push(maxf(dk, 0.0), 4.0) * 1.6 + rk.z:
			near.append(Vector4(sx, dk, rk.z, 0.0))
	near.sort_custom(func(p, q): return p.y < q.y)
	var packed := PackedVector4Array()
	for k in mini(near.size(), 40):
		packed.append(near[k])
	_deck.set_shader_parameter("rocks", packed)
	_deck.set_shader_parameter("n_rocks", packed.size())


var _ray_t: ImageTexture


func _ray_tex() -> ImageTexture:
	## A shaft of light: bright at the top, gone at the bottom, soft at its sides.
	if _ray_t == null:
		var img := Image.create(32, 64, false, Image.FORMAT_RGBA8)
		for y in 64:
			var down := pow(1.0 - y / 63.0, 1.6)
			for x in 32:
				var side := 1.0 - absf(x / 31.0 - 0.5) * 2.0
				img.set_pixel(x, y, Color(1, 1, 1, side * side * down))
		_ray_t = ImageTexture.create_from_image(img)
	return _ray_t


const REACH := 900.0   # how far out along the cut the blow carries before it is spent, m (the shaders' reach)
const SPEND := 1.4     # how fast it slows, s (the shaders' spend)


func _arrive(d: float) -> float:
	## When the blow gets d metres out along the cut: fast at first, slowing, never past REACH.
	return -SPEND * log(maxf(1.0 - d / REACH, 1e-4))


func _push(d: float, tau: float, k := 1.0) -> float:
	## How far the cut has shoved the cloud aside, d metres out along it, tau seconds after the blow got there: hard at
	## first, then slower, drifting on after; less far where the blow was tiring (shaders/cloud_sea.gdshader push_at).
	return (3.0 + d * 0.32) * (1.0 - 0.45 * clampf(d / REACH, 0.0, 1.0)) * k * (1.0 - exp(-tau / 0.35) + 0.12 * tau)


func _on_line(d: float, y: float) -> Vector3:
	## The middle of the channel d metres out along the cut, at the height y.
	var nl := maxf(Vector2(_cut_n.x, _cut_n.z).length(), 0.05)
	var q := -(y - _cut_o.y) * _cut_n.y / nl
	var p := Vector2(_cut_o.x, _cut_o.z) + _nh * q + _fh * d
	return Vector3(p.x, y, p.y)


func _wave(t: float) -> void:
	## The blow, t seconds after the blade landed. In the shaders: the cloud of the sea and of the sky shoved aside along
	## the cut as the blow runs out (the near first, the far after), heaped on the walls and against the pillars in its
	## way, a swell running out over the sea ahead of them, the light let down into the deep behind the blow. Here: the
	## low mist thinning, the shafts of light coming on as the blow passes them.
	for m in _clouds + _mists:
		m.set_shader_parameter("cut_t", t)
	_deck.set_shader_parameter("cut_t", t)
	_sky_mat.set_shader_parameter("cut_t", t)
	# the low mist thins where the cloud has gone, so the opened channel goes down dark into the deep (the veils
	# under it keep it from going bare)
	env.fog_height_density = lerpf(0.05, 0.018, 1.0 - exp(-t / 0.8))
	for k in _rays.size():
		var dd: float = _rays[k].get_meta("d")
		var a := clampf((t - _arrive(dd)) * 1.5, 0.0, 1.0) * (0.09 - k * 0.007)
		(_rays[k].material_override as StandardMaterial3D).albedo_color.a = a


func part_and_go_in(on_going: Callable) -> void:
	## After the cut (the blow running out along it since the blade landed: _wave): a breath while the walls of cloud are
	## still going back, and the camera goes in along the opened channel, over the protagonist's head and down between
	## the walls of cloud.
	var f := 0.35 if Game.fast else 1.0
	await get_tree().create_timer(0.7 * f).timeout
	AutoTest.shot("t03b_parted")
	var fwd := Vector3(_fh.x, 0, _fh.y)
	var p0: Vector3 = rig.cam.global_position
	var d0: Vector3 = -rig.cam.global_basis.z * 50.0   # where it looks now: it turns from here into the channel
	on_going.call()
	Audio.sfx("title_dive", -3.0)   # wind rising past as the camera goes in
	var go := create_tween()
	go.tween_method(func(t: float):
		var e := t * t * (3.0 - 2.0 * t)
		var pos: Vector3 = p0 + fwd * 70.0 * e + Vector3(0, 2.2 * sin(PI * minf(t * 1.7, 1.0)) - 14.0 * t * t, 0)
		var d1: Vector3 = fwd * 50.0 + Vector3(0, -7.0 - 12.0 * t, 0)
		rig.set_view(pos, pos + d0.lerp(d1, smoothstep(0.0, 0.4, t)))
	, 0.0, 1.0, 2.1 * f).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await go.finished


func blade_on_screen() -> Vector2:
	## Where the cut passes, on screen: through the protagonist's shoulders.
	return rig.cam.unproject_position(hero_s.global_position + Vector3(0, 0.25, 0))


func frame_camera() -> void:
	## A 50 degree lens from behind the protagonist: they sit low in the middle, the horizon a little above it.
	rig.cam.fov = 50.0
	rig.cam.far = 2000.0   # (the gameplay camera stops at 260 m; the far lands and the moon are farther)
	rig.set_view(CAM_POS, CAM_LOOK)
	rig.attrs.dof_blur_far_enabled = false
	rig.attrs.dof_blur_near_enabled = false
