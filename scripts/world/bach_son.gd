extends "res://scripts/world/world.gd"
## Bạch Sơn (docs/N_bach_son.md): the white city on its limestone mountain, seen from below.
## South to north: the Bãi Tro (ash-white ground, porcelain people along the road, all facing the gate), the
## camp outside the gate (Trại Ngoài Cổng) by the stream of the city's used water, the Rãnh Sứ where Trắng Tay
## walks, the old stone gate's footing under the lime; the climb to the Sân Tro (ash yard, Lò Thanh) and the
## Cổng Trắng; inside, the first street of the Tầng Rửa; above it, tier on tier, the city up to the Bạch Điện.
## Everything else (hero, camera, HUD, dialogue, interactions, time of day) is the valley's world, reused.

const GATE := Vector3(0, 0, -24)          # centre of the gateway, on the wall line
const CAMP := Vector3(-8, 0, 12)          # the cook fire in the middle of the camp
const YARD_H := 4.0                       # the ash yard and the Tầng Rửa street are a plateau at this height

var gate_open := false
var _gate_l: Node3D
var _gate_r: Node3D
var _fire_light: OmniLight3D
var _fire_sprite: Sprite3D


func _ready() -> void:
	_build_environment()
	_build_terrain()
	_build_bs_backdrop()
	_build_wall_and_gate()
	_build_yard()
	_build_inside()
	_build_plaza()
	_build_tiers()
	_build_camp()
	_build_road()
	_build_grass()
	_build_bs_atmosphere()
	_define_markers()
	rig = CameraRig.new()
	add_child(rig)
	rig.bounds = Rect2(-40, -95, 80, 155)
	hud = Hud.new()
	add_child(hud)
	dialogue = Dialogue.new()
	add_child(dialogue)
	hero = spawn("hero", "res://assets/sprites/chars/hero.png", markers["arrive"], "up", true)
	hero.act_sheet = "res://assets/sprites/chars/hero_act_sword.png"   # the old sword ông gave when they left the valley
	rig.follow(hero)
	_place_statues()
	set_time("highland", true)
	# half the shade light from a plain grey rather than all from the blue sky, or the white streets go blue
	env.ambient_light_sky_contribution = 0.55
	env.tonemap_exposure = 0.94   # a white city: a touch less exposure than the valley, so the lime keeps its texture
	env.adjustment_contrast = 1.12   # more contrast than the valley: high sun, deep shade, nothing soft and plastic
	env.ambient_light_color = Color(0.8, 0.79, 0.77)


# ===================================================================== ground
func height_at(x: float, z: float) -> float:
	# the plain below (the camp, the Bãi Tro), the climb, the plateau of the ash yard and the lowest tier
	var up := smoothstep(6.0, -10.0, z)
	var h := YARD_H * up
	# tiers of the city stepping up the mountain, inside the walls
	h += 6.0 * smoothstep(-42.0, -45.0, z)
	h += 7.0 * smoothstep(-55.0, -58.0, z)
	h += 9.0 * smoothstep(-68.0, -72.0, z)
	h += 18.0 * smoothstep(-80.0, -100.0, z)
	# the mountain closing in on either side
	var side := absf(x) - 30.0 - 6.0 * smoothstep(-20.0, 30.0, z)
	if side > 0.0:
		var sh := pow(side, 1.25) * 0.75
		# ridges and gullies, larger the higher the flank climbs (fractal noise, not a smooth ramp)
		sh += _mn().get_noise_2d(x, z) * clampf(side / 6.0, 0.0, 1.0) * (5.0 + side * 0.4)
		# and here and there the limestone shows its beds as short ledges
		var bed := 3.4 + 0.9 * sin(z * 0.07 + x * 0.05)
		var q := sh / bed
		var ledges: float = (floor(q) + smoothstep(0.6, 0.95, q - floor(q))) * bed
		h += lerpf(sh, ledges, clampf(side / 5.0, 0.0, 1.0) * clampf(-0.2 + 0.45 * sin(z * 0.09 + x * 0.05), 0.0, 0.25))   # ledges only in a few places
	# the plain outside: low swells, and the shallow bed of the stream of used water
	if z > -9.0:
		var k := clampf((z + 9.0) / 10.0, 0.0, 1.0)
		h += (sin(x * 0.29) * cos(z * 0.23) * 0.3 + sin(x * 0.07 + z * 0.05) * 0.4) * k
		var ds := _stream_dist(x, z)
		if ds < 1.6:
			h -= 0.35 * (1.0 - ds / 1.6) * k
	return h


var _mnoise: FastNoiseLite


func _mn() -> FastNoiseLite:
	if _mnoise == null:
		_mnoise = FastNoiseLite.new()
		_mnoise.seed = 9
		_mnoise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		_mnoise.frequency = 0.03
		_mnoise.fractal_type = FastNoiseLite.FRACTAL_RIDGED
		_mnoise.fractal_octaves = 4
	return _mnoise


func _stream_dist(x: float, z: float) -> float:
	var p := Vector2(x, z)
	return minf(minf(_dist_seg(p, Vector2(18, -10), Vector2(10, 0)), _dist_seg(p, Vector2(10, 0), Vector2(0, 6))),
		_dist_seg(p, Vector2(0, 6), Vector2(-14, 26)))


const BS_PATHS := [
	[Vector2(10, 50), Vector2(5, 38), Vector2(2, 28), Vector2(-2, 20), Vector2(-4, 14)],   # up from the Bãi Tro
	[Vector2(-4, 14), Vector2(2, 6), Vector2(5, -2), Vector2(2, -8), Vector2(0, -11)],       # the climb to the yard
	[Vector2(-8, 12), Vector2(-16, 8)], [Vector2(-8, 12), Vector2(-14, 18)], [Vector2(-8, 12), Vector2(-1, 9)],
	[Vector2(2, 6), Vector2(13, 7)],                                                         # to the old stone gate
]


func _path_weight(x: float, z: float) -> float:
	var best := 99.0
	var p := Vector2(x, z)
	for path in BS_PATHS:
		for i in range(path.size() - 1):
			best = minf(best, _dist_seg(p, path[i], path[i + 1]))
	var wobble := sin(x * 1.7) * 0.25 + cos(z * 1.3) * 0.25
	var w := clampf(1.0 - (best - 1.0 - wobble) / 0.9, 0.0, 1.0)
	# the camp floor is trodden bare round the fire; the Bãi Tro to the south is all ash
	var dc := p.distance_to(Vector2(CAMP.x, CAMP.z))
	w = maxf(w, clampf(1.0 - (dc - 5.5) / 2.0, 0.0, 1.0) * 0.85)
	return maxf(w, smoothstep(24.0, 38.0, z) * (0.75 + 0.25 * sin(x * 0.4 + z * 0.3)))


func _yard_weight(x: float, z: float) -> float:
	# the paved ash yard, and the paved street inside
	var yard := float(absf(x) < 11.5 and z < -10.0 and z > -23.0)
	var street := float(absf(x) < 13.0 and z < -25.0 and z > -41.0)
	var tiers := float(z < -46.0 and absf(x) < 28.0)
	return maxf(maxf(yard, street), tiers * 0.8)


func _glaze_weight(x: float, z: float) -> float:
	## The Rãnh Sứ, where Trắng Tay walks: the ground is glazed white.
	var p := Vector2(x, z)
	var d := minf(_dist_seg(p, Vector2(-44, 40), Vector2(-26, 20)), _dist_seg(p, Vector2(-26, 20), Vector2(-17, 7)))
	var bare := clampf(1.0 - (d - 1.2 - sin(z * 0.9) * 0.6) / 1.6, 0.0, 1.0)
	return bare


func _build_terrain() -> void:
	var x0 := -90.0
	var z0 := -104.0
	var nx := 180
	var nz := 160
	var verts := PackedVector3Array()
	var cols := PackedColorArray()
	var norms := PackedVector3Array()
	var idx := PackedInt32Array()
	verts.resize((nx + 1) * (nz + 1))
	cols.resize(verts.size())
	norms.resize(verts.size())
	for j in nz + 1:
		for i in nx + 1:
			var x := x0 + i
			var z := z0 + j
			var h := height_at(x, z)
			var k := j * (nx + 1) + i
			verts[k] = Vector3(x, h, z)
			var hx := height_at(x + 0.5, z) - height_at(x - 0.5, z)
			var hz := height_at(x, z + 0.5) - height_at(x, z - 0.5)
			var n := Vector3(-hx, 1.0, -hz).normalized()
			norms[k] = n
			var slope := 1.0 - n.y
			var rock := clampf((slope - 0.3) * 3.0, 0.0, 1.0)   # moderate slopes keep their soil, and the forest on it
			if h > 16.0:
				rock = maxf(rock, clampf((h - 16.0) / 18.0, 0.0, 0.7))
			rock = maxf(rock, _glaze_weight(x, z))
			var path := _path_weight(x, z) if z > -10.5 else 0.0
			cols[k] = Color(path, _yard_weight(x, z), rock, 1.0)
	for j in nz:
		for i in nx:
			var a := j * (nx + 1) + i
			var b := a + 1
			var c := a + (nx + 1)
			var d := c + 1
			idx.append_array([a, b, c, b, d, c])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance3D.new()
	mi.mesh = am
	_terrain_mat = ShaderMaterial.new()
	_terrain_mat.shader = Assets.shader("res://shaders/terrain.gdshader")
	_terrain_mat.set_shader_parameter("tex_grass", Assets.tex("res://assets/tex/grass_high.png", true))
	_terrain_mat.set_shader_parameter("tex_dirt", Assets.tex("res://assets/tex/ash_soft.png", true))
	_terrain_mat.set_shader_parameter("tex_yard", Assets.tex("res://assets/tex/slab_pale.png", true))
	_terrain_mat.set_shader_parameter("tex_rock", Assets.tex("res://assets/tex/flank_lime.png", true))   # jointed limestone (tools/art/bs_rock.py)
	_terrain_mat.set_shader_parameter("tex_noise", Assets.tex("res://assets/tex/water_noise.png"))
	_terrain_mat.set_shader_parameter("tex_clouds", Assets.tex("res://assets/tex/clouds.png"))
	_terrain_mat.set_shader_parameter("tile", 0.72)
	_terrain_mat.set_shader_parameter("rock_scale", 0.42)   # 128 px over about 4 m: 30 px to a metre, beds that do not stripe the whole flank
	mi.material_override = _terrain_mat
	add_child(mi)


const DIEN_TOP := 27.2   # the granite platform of the Bạch Điện


func ground_at(p: Vector3) -> float:
	if absf(p.x) < 9.0 and p.z < -73.0 and p.z > -85.0:
		return DIEN_TOP
	return maxf(height_at(p.x, p.z), 0.0)


func is_walkable(p: Vector3) -> bool:
	if p.z > -22.6:   # outside the wall: the plain, the camp, the climb and the yard, not up the mountain sides
		var lim := 26.0 + 6.0 * smoothstep(-20.0, 30.0, p.z)
		if absf(p.x) > lim or p.z > 50.0:
			return false
		if p.z < -10.0 and absf(p.x) > 11.0:   # the yard's edges drop away
			return false
		for t in _tents:
			if Vector2(p.x, p.z).distance_to(t) < 1.4:
				return false
		return true
	if p.z > -25.6:   # the gateway
		return gate_open and absf(p.x) < 2.6
	# the Quảng Trường Rửa just inside the gate, round its great basin
	if p.z > -31.2:
		return absf(p.x) < 6.0 and Vector2(p.x, p.z + 28.3).length() > 1.9
	# the street of the Tầng Rửa
	if p.z > -40.5:
		return absf(p.x) < 4.1
	# the lane along the Tầng Giữa, and the alley back to the stair up to the Đền
	if p.z <= -45.3 and p.z >= -47.9:
		return absf(p.x) < 22.0
	if p.z < -47.9 and p.z > -54.2:
		return p.x > 0.8 and p.x < 3.2
	# the lane along the Tầng Đền
	if p.z <= -58.3 and p.z >= -60.9:
		return absf(p.x) < 20.0
	# the platform before the Điện
	if p.z <= -73.0 and p.z >= -76.0:
		return absf(p.x) < 8.0
	# inside the Điện: through the doorway, then the room, round the well, the stand and the table
	if p.z < -76.0 and p.z > HALL_BACK + 1.1:
		if p.z > HALL_FRONT - 0.5:
			return absf(p.x) < 0.9
		if Vector2(p.x, p.z).distance_to(Vector2(-3.6, -81.2)) < 1.25:
			return false
		if absf(p.x - 3.1) < 1.1 and absf(p.z + 80.9) < 0.65:
			return false
		return absf(p.x) < 5.2
	return false


# ===================================================================== materials
var _lime: StandardMaterial3D
var _lime_dim: StandardMaterial3D
var _cobalt: StandardMaterial3D
var _stone_old: StandardMaterial3D
var _cloth: StandardMaterial3D
var _cloth2: StandardMaterial3D
var _cloth3: StandardMaterial3D
var _front_wall: Array[Node3D] = []      # the wall and towers by the gate: see-through when the camera is inside
var _see_mats: Array[ShaderMaterial] = []
var _see_cache := {}
var _wood: StandardMaterial3D
var _wall_m: StandardMaterial3D
var _wall_old_m: StandardMaterial3D
var _plinth_m: StandardMaterial3D
var _ink_m: StandardMaterial3D
var _lattice_m: StandardMaterial3D
var _door_m: StandardMaterial3D
var _band_m: StandardMaterial3D
var _tent_m: Array[StandardMaterial3D] = []
var _street_lights: Array[OmniLight3D] = []   # the lantern by every door, lit from dusk
var _doors: Array[Vector3] = []               # kept clear of clutter
var _tents: Array[Vector2] = []


func _mats() -> void:
	if _lime:
		return
	# white walls under black tile: lime that is never quite clean, granite at the foot, black tile on every top
	# texel density as in the valley (walls and ground about 24 pixels to a metre, as the sprites are)
	_wall_m = B.mat("res://assets/tex/lime_wall.png", 0.75, Vector3.ONE, {"triplanar": true, "world": true, "tint": Color(0.9, 0.89, 0.87)})
	_wall_old_m = B.mat("res://assets/tex/lime_wall_old.png", 0.75, Vector3.ONE, {"triplanar": true, "world": true, "tint": Color(0.86, 0.85, 0.83)})
	for tint in [Color(1, 1, 1), Color(0.94, 0.9, 0.84), Color(0.88, 0.9, 0.95)]:
		var tm := B.mat("res://assets/tex/tent_cloth.png", 1.0, Vector3.ONE, {"tint": tint})
		tm.cull_mode = BaseMaterial3D.CULL_DISABLED
		_tent_m.append(tm)
	_plinth_m = B.mat("res://assets/tex/granite.png", 0.75, Vector3.ONE, {"triplanar": true, "world": true})
	_ink_m = B.mat("res://assets/tex/roof_ink.png", 0.9, Vector3.ONE, {"triplanar": true, "world": true})
	_lattice_m = B.mat("res://assets/tex/lattice.png", 1.0, Vector3.ONE)
	_door_m = B.mat("res://assets/tex/door_wood.png", 1.0, Vector3.ONE)
	_band_m = B.color_mat(Color(0.4, 0.43, 0.48))
	_lime = _wall_m
	_lime_dim = B.mat("res://assets/tex/lime_wall_old.png", 0.75, Vector3.ONE, {"triplanar": true, "world": true, "tint": Color(0.82, 0.82, 0.8)})
	_cobalt = B.color_mat(Color(0.2, 0.31, 0.58), 0.35)
	_stone_old = B.mat("res://assets/tex/rock.png", 0.8, Vector3.ONE, {"triplanar": true, "world": true, "tint": Color(0.78, 0.76, 0.72)})
	_cloth = B.color_mat(Color(0.56, 0.53, 0.49))
	_cloth2 = B.color_mat(Color(0.47, 0.42, 0.38))
	_cloth3 = B.color_mat(Color(0.42, 0.45, 0.5))
	_wood = B.mat("res://assets/tex/planks.png", 1.0, Vector3.ONE, {"triplanar": true, "tint": Color(0.72, 0.66, 0.6)})


# ===================================================================== the wall and the White Gate
func _build_wall_and_gate() -> void:
	## The White Gate as the glimpse at the pass showed it (scripts/fx/vision_gate.gd), so the place is recognised:
	## a long white wall with a dark coping and merlons along the top; two white piers, a beam, one great roof of
	## dark tile; two leaves of black iron bars, three rails across, opening inward.
	_mats()
	var top := YARD_H
	var wall_h := 6.2
	var iron := B.color_mat(Color(0.11, 0.1, 0.12), 0.6)
	for side in [-1.0, 1.0]:
		var x_in := 4.45
		var x_out := 46.0
		var wlen: float = x_out - x_in
		var cx: float = side * (x_in + x_out) * 0.5
		_front_wall.append(B.box(self, Vector3(wlen, wall_h + 0.5, 2.6), Vector3(cx, top + wall_h * 0.5 - 0.25, GATE.z), _wall_old_m, 0, false, 0.06))
		_front_wall.append(B.box(self, Vector3(wlen, 0.35, 2.9), Vector3(cx, top + wall_h + 0.175, GATE.z), _ink_m, 0, false, 0.04))
		var nm := int(wlen / 2.0)
		for k in nm:
			_front_wall.append(B.box(self, Vector3(1.0, 0.8, 2.6), Vector3(side * (x_in + 1.0 + k * 2.0), top + wall_h + 0.75, GATE.z), _wall_m, 0, false, 0.05))
		# a watchtower along each side of the wall, between the gate and the corner
		var tx: float = side * 26.0
		var th := wall_h + 3.6
		_front_wall.append(B.box(self, Vector3(4.6, th, 3.6), Vector3(tx, top + th * 0.5 - 0.25, GATE.z), _wall_m, 0, false, 0.06))
		_front_wall.append(B.box(self, Vector3(5.0, 0.3, 4.0), Vector3(tx, top + th, GATE.z), _ink_m, 0, false))
		_front_wall.append(B.roof(self, 6.2, 2.4, 2.4, top + th + 0.1, top + th + 1.9, Vector3(tx, 0, GATE.z), "res://assets/tex/roof_ink.png"))
		for wy in [wall_h - 1.2, wall_h + 1.6]:
			_front_wall.append(_quad(self, Vector2(0.8, 0.9), Vector3(tx, top + wy, GATE.z + 1.82), _lattice_m))
		# the wall turns and climbs the mountain on each flank
		B.box(self, Vector3(2.6, wall_h + 7.0, 40.0), Vector3(side * x_out, top + 5.0, GATE.z - 20.0), _wall_old_m, 0, false)
		B.box(self, Vector3(3.0, 0.35, 40.4), Vector3(side * x_out, top + 5.0 + (wall_h + 7.0) * 0.5 + 0.17, GATE.z - 20.0), _ink_m, 0, false)
		# the piers
		_front_wall.append(B.box(self, Vector3(1.4, 8.2, 3.0), Vector3(side * 3.75, top + 4.1, GATE.z), _wall_m, 0, false, 0.08))
	# the beam, and the great roof over it
	_front_wall.append(B.box(self, Vector3(9.0, 1.2, 3.0), Vector3(0, top + 8.6, GATE.z), _wall_old_m, 0, false, 0.08))
	_front_wall.append(B.roof(self, 11.5, 2.6, 2.6, top + 9.0, top + 11.0, Vector3(0, 0, GATE.z), "res://assets/tex/roof_ink.png"))
	# the leaves: black iron bars hinged on the piers, opening inward
	_gate_l = Node3D.new()
	_gate_l.position = Vector3(-3.05, top, GATE.z + 0.9)
	add_child(_gate_l)
	_gate_r = Node3D.new()
	_gate_r.position = Vector3(3.05, top, GATE.z + 0.9)
	add_child(_gate_r)
	for leaf in [[_gate_l, -1.0], [_gate_r, 1.0]]:
		var piv: Node3D = leaf[0]
		var sd: float = leaf[1]
		for b in 8:
			B.cylinder(piv, 0.07, 6.2, Vector3(-sd * (0.2 + b * 0.37), 3.1, 0), iron, false, 8)
		for ry in [0.5, 3.1, 5.9]:
			B.box(piv, Vector3(3.0, 0.2, 0.14), Vector3(-sd * 1.5, ry, 0), iron, 0, false)
	# the white basin on the gate step (Cỏ wants to wash in it once)
	props["gate_basin"] = _basin(self, Vector3(-2.3, top - 0.3, GATE.z + 2.6), 0.55, 0.6, _lime, 16)
	# the drain gate low in the wall: the city's used water runs out here, down to the camp
	B.box(self, Vector3(1.6, 1.2, 0.3), Vector3(18, top + 0.1, GATE.z + 1.35), B.color_mat(Color(0.12, 0.12, 0.13)), 0, false)
	for i in 5:
		B.box(self, Vector3(0.08, 1.2, 0.08), Vector3(17.4 + i * 0.3, top + 0.1, GATE.z + 1.5), B.color_mat(Color(0.3, 0.3, 0.32), 0.4), 0, false)
	for n in _front_wall + [_gate_l, _gate_r]:
		_make_see_through(n, YARD_H, GATE.z - 1.3)


func see_through_wall(on: bool) -> void:
	## Inside the city the follow camera looks from the south, through the wall: the part of the wall, towers and
	## gate between the camera and the hero thins out by points (as the canopy does), the rest stays standing.
	for m in _see_mats:
		m.set_shader_parameter("active", 1.0 if on else 0.0)


func _make_see_through(n: Node, ground := YARD_H, cut := INF, keep := 0.6) -> void:
	## The city's solids: thin out between the camera and the hero (inside the walls), and the lime walls weather,
	## grime rising from `ground` (the street or tier they stand on). `cut` (a z): the front wall and the gate, or
	## the front and roofs of the Điện, which dissolve away whole while the hero is inside (north of that z) and
	## the follow camera has backed out past it, as a cutaway (Q46), rather than framing the inside through bars.
	if n is MeshInstance3D and n.material_override is StandardMaterial3D:
		n.material_override = _see_through_mat(n.material_override, ground, cut, keep)
	for c in n.get_children():
		_make_see_through(c, ground, cut, keep)


func _see_through_mat(std: StandardMaterial3D, ground := YARD_H, cut := INF, keep := 0.6) -> ShaderMaterial:
	var key := "%d|%.1f|%.1f" % [std.get_instance_id(), ground, cut if cut < INF else 9999.0]
	if _see_cache.has(key):
		return _see_cache[key]
	var sm := ShaderMaterial.new()
	sm.shader = Assets.shader("res://shaders/see_through_solid.gdshader")
	sm.set_shader_parameter("use_tex", std.albedo_texture != null)
	if std.albedo_texture:
		sm.set_shader_parameter("albedo_tex", std.albedo_texture)
	sm.set_shader_parameter("tint", std.albedo_color)
	sm.set_shader_parameter("triplanar", std.uv1_triplanar)
	sm.set_shader_parameter("world_triplanar", std.uv1_world_triplanar)
	sm.set_shader_parameter("uv_scale", std.uv1_scale)
	sm.set_shader_parameter("roughness_v", std.roughness)
	if std == _wall_m or std == _wall_old_m or std == _lime_dim:
		sm.set_shader_parameter("weather", 1.0)
		sm.set_shader_parameter("ground_y", ground)
		sm.set_shader_parameter("stone_tex", Assets.tex("res://assets/tex/cobble.png", true))
		sm.set_shader_parameter("noise_tex", Assets.tex("res://assets/tex/water_noise.png"))
	if cut < INF:
		sm.set_shader_parameter("cutaway", 1.0)
		sm.set_shader_parameter("cut_z", cut)                   # the inner face of the wall
		sm.set_shader_parameter("cut_keep_y", ground + keep)    # a low stub stays, so the line of the wall still shows
	_see_cache[key] = sm
	_see_mats.append(sm)
	return sm


func set_gate(open: bool, t := 1.2) -> void:
	gate_open = open
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_gate_l, "rotation_degrees:y", 78.0 if open else 0.0, t)
	tw.tween_property(_gate_r, "rotation_degrees:y", -78.0 if open else 0.0, t)
	if t >= 0.5:   # (set at once while the scene is laid out: no sound)
		Audio.sfx("gate", -6.0, 0.04, 1.2 / clampf(t, 0.8, 1.6))   # hinges, bars, the knock as the swing ends
	await tw.finished


# ===================================================================== the ash yard
func _build_yard() -> void:
	_mats()
	var y := YARD_H
	# the Lò Thanh: where everything held unclean is burned; its ash is what the hands are rubbed with
	var kiln := Vector3(-7.0, y, -17.5)
	var soot := B.mat("res://assets/tex/rock_lime.png", 0.9, Vector3.ONE, {"triplanar": true, "world": true, "tint": Color(0.62, 0.6, 0.58)})
	B.box(self, Vector3(3.0, 0.5, 2.8), kiln + Vector3(0, 0.25, 0), _plinth_m, 0, false)
	B.cylinder(self, 1.15, 1.5, kiln + Vector3(0, 1.25, 0), soot, false, 12)
	var dome := MeshInstance3D.new()
	var dm := SphereMesh.new()
	dm.radius = 1.15
	dm.height = 1.4
	dm.radial_segments = 12
	dm.rings = 5
	dome.mesh = dm
	dome.material_override = soot
	dome.position = kiln + Vector3(0, 2.0, 0)
	add_child(dome)
	B.cylinder(self, 0.32, 2.4, kiln + Vector3(0.3, 3.4, -0.3), soot, false, 8)
	B.box(self, Vector3(0.9, 0.75, 0.2), kiln + Vector3(0, 0.9, 1.08), B.color_mat(Color(0.06, 0.04, 0.03)), 0, false)
	B.box(self, Vector3(1.2, 0.12, 0.3), kiln + Vector3(0, 1.32, 1.1), _plinth_m, 0, false)
	for px in [-1.7, 1.7]:
		for pz in [-1.6, 1.6]:
			B.box(self, Vector3(0.16, 3.3, 0.16), kiln + Vector3(px, 1.65, pz), _wood, 0, false)
	B.roof(self, 4.4, 2.0, 2.0, y + 3.2, y + 4.2, Vector3(kiln.x, 0, kiln.z), "res://assets/tex/roof_ink.png")
	var heap := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 0.6
	hm.height = 0.5
	hm.radial_segments = 10
	hm.rings = 4
	heap.mesh = hm
	heap.material_override = B.mat("res://assets/tex/ash_soft.png", 2.0, Vector3.ONE, {"triplanar": true, "tint": Color(0.85, 0.85, 0.86)})
	heap.position = kiln + Vector3(1.4, 0.12, 1.5)
	add_child(heap)
	var rake := B.box(self, Vector3(0.05, 1.6, 0.05), kiln + Vector3(2.0, 0.8, 1.2), _wood, 0, false)
	rake.rotation.z = 0.3
	props["kiln_smoke"] = B.particles(self, "res://assets/sprites/props/smoke.png", 16, 5.0, Vector3(0.3, 0.1, 0.3), Vector3(-7.0, y + 4.2, -18.2),
		{"dir": Vector3(0.2, 1, 0), "spread": 12.0, "vmin": 0.4, "vmax": 0.8, "size": 1.2, "color": Color(0.78, 0.78, 0.8, 0.5)})
	var glow := OmniLight3D.new()
	glow.light_color = Color(1.0, 0.55, 0.3)
	glow.light_energy = 1.4
	glow.omni_range = 3.5
	glow.position = Vector3(-7.0, y + 0.5, -15.8)
	add_child(glow)
	# the testing table: a tray of ash, a jar of water from the head spring
	var tbl := Vector3(2.8, y, -19.4)
	B.box(self, Vector3(2.3, 0.09, 1.05), tbl + Vector3(0, 0.82, 0), _wood, 0, true, 0.02)
	for lx in [-1.0, 1.0]:
		for lz in [-0.42, 0.42]:
			B.box(self, Vector3(0.1, 0.78, 0.1), tbl + Vector3(lx, 0.39, lz), _wood, 0, false)
		B.box(self, Vector3(0.08, 0.08, 0.84), tbl + Vector3(lx, 0.2, 0), _wood, 0, false)
	B.box(self, Vector3(2.0, 0.06, 0.08), tbl + Vector3(0, 0.2, 0), _wood, 0, false)
	var tray := tbl + Vector3(-0.35, 0.87, 0.05)
	B.box(self, Vector3(0.8, 0.08, 0.5), tray, _wood, 0, false, 0.01)
	var ash := MeshInstance3D.new()
	var am := SphereMesh.new()
	am.radius = 0.34
	am.height = 0.16
	am.radial_segments = 10
	am.rings = 4
	ash.mesh = am
	ash.scale = Vector3(1.0, 1.0, 0.62)
	ash.material_override = B.mat("res://assets/tex/ash_soft.png", 3.0, Vector3.ONE, {"triplanar": true, "tint": Color(0.86, 0.86, 0.88)})
	ash.position = tray + Vector3(0, 0.04, 0)
	add_child(ash)
	_basin(self, tbl + Vector3(0.55, 0.87, -0.05), 0.2, 0.14, _wall_m, 12)
	B.box(self, Vector3(0.34, 0.05, 0.26), tbl + Vector3(0.95, 0.89, 0.18), B.color_mat(Color(0.88, 0.86, 0.8)), 12.0, false)   # the book
	B.box(self, Vector3(0.36, 0.02, 0.28), tbl + Vector3(0.95, 0.865, 0.18), _cobalt, 12.0, false)
	props["test_jar"] = B.billboard(self, "res://assets/sprites/props/chum.png", Vector3(3.9, y + 0.4, -19.5), 0.024)
	# rope lines for the queue
	var rope := B.color_mat(Color(0.62, 0.55, 0.42))
	for sx in [-1.6, 1.6]:
		for i in 4:
			var pp := Vector3(sx, y, -12.0 - i * 2.0)
			B.box(self, Vector3(0.3, 0.12, 0.3), pp + Vector3(0, 0.06, 0), _plinth_m, 0, false)
			B.box(self, Vector3(0.12, 1.0, 0.12), pp + Vector3(0, 0.6, 0), _wood, 0, false)
			B.box(self, Vector3(0.18, 0.06, 0.18), pp + Vector3(0, 1.12, 0), _ink_m, 0, false)
			if i < 3:   # the rope to the next post, sagging
				for k in 4:
					var u0 := k / 4.0
					var u1 := (k + 1) / 4.0
					var a := pp + Vector3(0, 1.0 - 0.18 * sin(PI * u0), -2.0 * u0)
					var b := pp + Vector3(0, 1.0 - 0.18 * sin(PI * u1), -2.0 * u1)
					var seg := B.box(self, Vector3(0.03, 0.03, a.distance_to(b)), (a + b) * 0.5, rope, 0, false)
					seg.rotation.x = atan2(b.y - a.y, -(b.z - a.z))
	# the drop at the edge of the yard: a low lime parapet
	for side in [-1.0, 1.0]:
		B.box(self, Vector3(0.5, 0.9, 12.0), Vector3(side * 11.6, y + 0.1, -16.5), _wall_old_m, 0, false)
		B.box(self, Vector3(0.85, 0.14, 12.2), Vector3(side * 11.6, y + 0.62, -16.5), _ink_m, 0, false)


# ===================================================================== inside: the first street of the Tầng Rửa
func _quad(parent: Node3D, size: Vector2, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = size
	mi.mesh = q
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


func _hui_house(parent: Node3D, pos: Vector3, w: float, d: float, floors: int, rot: float, rng: RandomNumberGenerator,
		detail := true) -> Dictionary:
	## A house of the white city, after the white-wall, black-tile houses of the hills: lime walls on a granite
	## plinth; a black tile roof between stepped gable walls (mã đầu tường), each step capped in black tile and the
	## lowest ends kicked up; a tiled hood over the door; ice-crack lattice windows; a threshold basin; a porcelain
	## cup on the step. The front faces local +Z.
	_mats()
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = deg_to_rad(rot)
	parent.add_child(root)
	var wall: StandardMaterial3D = _wall_old_m if rng.randf() < 0.45 else _wall_m
	var hgt := 3.4 if floors == 1 else (5.6 if floors == 2 else 7.6)
	B.box(root, Vector3(w + 0.1, 0.6, d + 0.1), Vector3(0, 0.25, 0), _plinth_m, 0, false)
	B.box(root, Vector3(w + 0.18, 0.08, d + 0.18), Vector3(0, 0.58, 0), _plinth_m, 0, false)   # the ledge on the plinth
	B.box(root, Vector3(w, hgt, d), Vector3(0, hgt * 0.5, 0), wall, 0, false, 0.03)
	# a cornice of two courses under the eaves, front and back
	for fz2 in [d * 0.5, -d * 0.5]:
		var sg2 := 1.0 if fz2 > 0.0 else -1.0
		B.box(root, Vector3(w - 0.08, 0.12, 0.14), Vector3(0, hgt - 0.14, fz2 + sg2 * 0.07), _plinth_m, 0, false)
		B.box(root, Vector3(w - 0.24, 0.1, 0.1), Vector3(0, hgt - 0.28, fz2 + sg2 * 0.05), _band_m, 0, false)
	_strip_tips(B.roof(root, w - 0.1, d * 0.5 + 0.55, d * 0.5 + 0.55, hgt - 0.05, hgt + 1.45, Vector3.ZERO, "res://assets/tex/roof_ink.png"))
	var gw := 0.42
	for side in [-1.0, 1.0]:
		var gx: float = side * (w * 0.5 - gw * 0.5 + 0.03)
		for sg in [[-d * 0.5 - 0.1, -d / 6.0, hgt + 1.15], [-d / 6.0, d / 6.0, hgt + 2.25], [d / 6.0, d * 0.5 + 0.1, hgt + 1.15]]:
			var z0: float = sg[0]
			var z1: float = sg[1]
			var top: float = sg[2]
			var base := hgt - 0.3
			B.box(root, Vector3(gw, top - base, z1 - z0), Vector3(gx, (top + base) * 0.5, (z0 + z1) * 0.5), wall, 0, false)
			B.box(root, Vector3(gw + 0.3, 0.16, z1 - z0 + 0.2), Vector3(gx, top + 0.06, (z0 + z1) * 0.5), _ink_m, 0, false)
			B.box(root, Vector3(0.2, 0.14, z1 - z0 + 0.26), Vector3(gx, top + 0.2, (z0 + z1) * 0.5), _ink_m, 0, false)
		for zz in [-d * 0.5 - 0.15, d * 0.5 + 0.15]:
			var hd: MeshInstance3D = B.box(root, Vector3(0.22, 0.14, 0.46), Vector3(gx, hgt + 1.42, zz), _ink_m, 0, false)
			hd.rotation.x = -0.55 if zz > 0.0 else 0.55
	# the front: a door framed in granite, under a tiled hood
	var fz := d * 0.5
	var dx := rng.randf_range(-w * 0.18, w * 0.18)
	# the door in a frame of granite: two jambs and a lintel, standing proud of the wall
	_quad(root, Vector2(1.06, 2.12), Vector3(dx, 1.61, fz + 0.024), _door_m)
	for jx in [-0.64, 0.64]:
		B.box(root, Vector3(0.22, 2.3, 0.16), Vector3(dx + jx, 1.75, fz + 0.06), _plinth_m, 0, false)
	B.box(root, Vector3(1.6, 0.24, 0.2), Vector3(dx, 2.86, fz + 0.08), _plinth_m, 0, false)
	B.box(root, Vector3(1.7, 0.3, 0.55), Vector3(dx, 0.15, fz + 0.28), _plinth_m, 0, false)
	var info := {"root": root}
	if detail:
		_strip_tips(B.roof(root, 2.1, 0.75, 0.06, 2.95, 3.3, Vector3(dx, 0, fz), "res://assets/tex/roof_ink.png"))
		_quad(root, Vector2(w - 0.3, 0.26), Vector3(0, hgt - 0.42, fz + 0.012), _band_m)
		B.billboard(root, "res://assets/sprites/props/lantern_w.png", Vector3(dx + 0.95, 2.05, fz + 0.45), 0.022, false)
		var ll := OmniLight3D.new()
		ll.light_color = Color(1.0, 0.86, 0.66)
		ll.light_energy = 1.3
		ll.omni_range = 4.2
		ll.shadow_enabled = false
		ll.position = Vector3(dx + 0.95, 2.35, fz + 0.6)
		ll.visible = false
		root.add_child(ll)
		_street_lights.append(ll)
		_doors.append(root.to_global(Vector3(dx, 0, fz)))
		var bx := dx - 1.15 if dx > -w * 0.1 else dx + 1.15
		_basin(root, Vector3(bx, 0, fz + 0.38), 0.24, 0.46, _wall_m, 10)
		if rng.randf() < 0.7:
			# a porcelain cup on the step: for someone of the house put out, or for the Sứ Giả (docs/N_bach_son.md 3.5)
			B.billboard(root, "res://assets/sprites/props/cup_step.png", Vector3(dx + 0.35, 0.3, fz + 0.32), 0.014, false)
		info["basin"] = root.to_global(Vector3(bx, 0, fz + 0.38))
		info["door"] = root.to_global(Vector3(dx, 0, fz + 0.9))
	if floors >= 2:
		var xs: Array = [dx] if w < 5.0 else [-w * 0.26, w * 0.26]
		for wx in xs:
			_quad(root, Vector2(0.9, 1.0), Vector3(wx, hgt - 1.55, fz + 0.016), _lattice_m)
			_window_frame(root, Vector2(0.9, 1.0), Vector3(wx, hgt - 1.55, fz))
			if detail:
				B.box(root, Vector3(1.05, 0.08, 0.16), Vector3(wx, hgt - 2.1, fz + 0.07), _plinth_m, 0, false)
	elif detail:
		_quad(root, Vector2(0.6, 0.45), Vector3(dx + (1.5 if dx < 0.0 else -1.5), 2.55, fz + 0.016), _lattice_m)
		_window_frame(root, Vector2(0.6, 0.45), Vector3(dx + (1.5 if dx < 0.0 else -1.5), 2.55, fz))
	return info


func _clutter(parent: Node3D, rng: RandomNumberGenerator) -> void:
	## What each household keeps by its own door, in a small group against the wall (Octopath's lesson: sprites
	## look lonely in an empty set, and things scattered at random read as noise): a water corner (jar, bucket),
	## a work corner (crates, a sack of lime), a sitting corner (bench, broom against the wall, pots), or a pine in
	## a pot with the cup on the step. Never on the doorstep, never in the middle of the street.
	var y := YARD_H
	var planks := B.mat("res://assets/tex/planks.png", 1.4, Vector3.ONE, {"triplanar": true})
	var sack := B.color_mat(Color(0.86, 0.84, 0.78))
	for d in _doors:
		if absf(d.x) < 3.4 or absf(d.x) > 5.2 or d.z > -31.4 or d.z < -40.6:
			continue
		var side := signf(d.x)
		var wall_x := side * 3.95
		var along := 1.0 if rng.randf() < 0.5 else -1.0   # which side of the door the group stands
		var z := d.z + along * rng.randf_range(1.05, 1.3)
		if z > -31.6 or z < -40.4:
			z = d.z - along * 1.15
		var p := Vector3(wall_x, y, z)
		var tuck := Vector3(side * 0.22, 0, 0)            # a little further toward the wall
		match rng.randi_range(0, 3):
			0:   # water: the big jar, a bucket at its foot, a ladle hung over the rim
				B.billboard(parent, "res://assets/sprites/props/chum.png", p + tuck, 0.03)
				B.cylinder(parent, 0.17, 0.3, p + Vector3(-side * 0.2, 0.15, along * 0.42), planks, false, 10)
			1:   # work: two crates stacked crooked, a sack of lime leaning on them
				B.box(parent, Vector3(0.55, 0.45, 0.55), p + tuck + Vector3(0, 0.22, 0), planks, rng.randf_range(-8, 8), false, 0.03)
				B.box(parent, Vector3(0.44, 0.36, 0.44), p + tuck + Vector3(0, 0.63, 0), planks, rng.randf_range(-20, 20), false, 0.03)
				B.box(parent, Vector3(0.48, 0.36, 0.34), p + Vector3(-side * 0.25, 0.18, along * 0.5), sack, rng.randf_range(-25, 25), false, 0.08)
			2:   # sitting: the bench along the wall, the broom leaning beside it, pots at the end
				B.box(parent, Vector3(0.34, 0.42, 1.2), p + tuck + Vector3(0, 0.21, 0), planks, 0, false, 0.03)
				var br := B.billboard(parent, "res://assets/sprites/props/broom.png", p + Vector3(side * 0.32, 0, along * 0.78), 0.03)
				br.rotation.z = side * 0.22
				B.billboard(parent, "res://assets/sprites/props/pots.png", p + Vector3(0, 0, -along * 0.85), 0.026)
			3:   # a pine in a stone pot, and the porcelain cup on the step of the door itself
				B.cylinder(parent, 0.2, 0.3, p + tuck + Vector3(0, 0.15, 0), _plinth_m, false, 10)
				B.billboard(parent, "res://assets/sprites/props/tung.png", p + tuck + Vector3(0, 0.28, 0), 0.016)
				B.billboard(parent, "res://assets/sprites/props/cup_step.png", Vector3(d.x - side * 0.5, y, d.z + 0.45), 0.03)


func set_time(name: String, instant := false) -> void:
	super.set_time(name, instant)
	# a night up here is moonlit off the white stone and the snow: dark, but people and paths still read
	env.tonemap_exposure = 1.45 if name == "night" else 0.94
	if name == "night":
		env.ambient_light_energy = 0.55
		sun.light_energy = 0.55
	var lit := name == "highland_dusk" or name == "night" or name == "dread"
	for l in _street_lights:
		l.visible = lit


func _strip_tips(rf: Node3D) -> void:
	## Drop a roof's turned-up ridge tips and corner curls (village-temple flourishes; on a house between
	## stepped gables they read as black spikes from above).
	for c in rf.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).mesh is CylinderMesh:
			rf.remove_child(c)
			c.free()


func _basin(parent: Node3D, at: Vector3, r: float, h: float, body: Material, segs := 12) -> MeshInstance3D:
	## A basin standing on `at`: a body, a rounded lime lip, a cobalt band round its side (the Ty's glaze), and
	## clear water just under the lip, so from above it reads as water in a white bowl, not as a lid.
	var t := clampf(r * 0.12, 0.035, 0.12)
	B.cylinder(parent, r, h - t * 1.5, at + Vector3(0, (h - t * 1.5) * 0.5, 0), body, false, segs)
	var lip := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = r - t * 2.0
	tm.outer_radius = r + 0.01
	tm.rings = segs
	tm.ring_segments = 6
	lip.mesh = tm
	lip.material_override = _wall_m
	lip.position = at + Vector3(0, h - t, 0)
	parent.add_child(lip)
	B.cylinder(parent, r + 0.012, minf(0.08, h * 0.14), at + Vector3(0, h * 0.5, 0), _cobalt, false, segs)
	var disc := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r - t * 1.6
	cm.bottom_radius = r - t * 1.6
	cm.height = 0.02
	cm.radial_segments = segs
	disc.mesh = cm
	disc.material_override = _basin_water()
	disc.position = at + Vector3(0, h - t * 1.25, 0)
	parent.add_child(disc)
	return disc


var _basin_water_m: ShaderMaterial


func _basin_water() -> ShaderMaterial:
	## Clear water over a white bottom: pale, a little green-grey, with the same posterised glints as the valley's
	if _basin_water_m == null:
		_basin_water_m = ShaderMaterial.new()
		_basin_water_m.shader = Assets.shader("res://shaders/water.gdshader")
		_basin_water_m.set_shader_parameter("noise_tex", Assets.tex("res://assets/tex/water_noise.png"))
		_basin_water_m.set_shader_parameter("deep", Color(0.42, 0.55, 0.57))
		_basin_water_m.set_shader_parameter("shallow", Color(0.56, 0.68, 0.69))
		_basin_water_m.set_shader_parameter("glint", Color(0.9, 0.95, 0.95))
		_basin_water_m.set_shader_parameter("glint_amount", 0.4)
		_basin_water_m.set_shader_parameter("pixel", 24.0)
	return _basin_water_m


const HALL_FRONT := -76.1   # the Điện's front wall (inner face); behind it, the hall
const HALL_BACK := -83.1


func _build_dien_hall(dien: Node3D, hy: float) -> void:
	## The Bạch Điện (docs/N_bach_son.md 1.4, 6.1): one great empty room, walls of white glazed tile, a well (the
	## head spring), a basin on a stand, the low table where the Ty's reports are read and sealed, a mat, and on a
	## shelf against the back wall a small wooden box (the old bandage, 7.1). The servant leaves rice on the
	## threshold. The front wall, the porch pillars and both roofs dissolve while the hero is inside (Q46).
	var porc := _porc_m()
	var cut := Node3D.new()
	add_child(cut)
	var fz := HALL_FRONT
	var bz := HALL_BACK
	var mz := (fz + bz) * 0.5
	var lime := B.mat("res://assets/tex/lime_wall.png", 0.75, Vector3.ONE, {"triplanar": true, "world": true, "tint": Color(0.9, 0.9, 0.9)})
	var timber := B.mat("res://assets/tex/planks.png", 1.2, Vector3.ONE, {"triplanar": true, "world": true, "tint": Color(0.36, 0.28, 0.24)})
	B.box(dien, Vector3(12.0, 5.0, 0.4), Vector3(0, hy + 2.5, bz + 0.2), lime, 0, false)
	for sx in [-1.0, 1.0]:
		B.box(dien, Vector3(0.4, 5.0, 7.0), Vector3(sx * 5.8, hy + 2.5, mz), lime, 0, false)
	# a dado of white glazed tile, waist high, round the three walls, capped with a strip of cobalt
	B.box(dien, Vector3(11.2, 1.1, 0.05), Vector3(0, hy + 0.55, bz + 0.42), porc, 0, false)
	B.box(dien, Vector3(11.2, 0.06, 0.07), Vector3(0, hy + 1.12, bz + 0.43), _cobalt, 0, false)
	for sx in [-1.0, 1.0]:
		B.box(dien, Vector3(0.05, 1.1, 6.6), Vector3(sx * 5.58, hy + 0.55, mz), porc, 0, false)
		B.box(dien, Vector3(0.07, 0.06, 6.6), Vector3(sx * 5.57, hy + 1.12, mz), _cobalt, 0, false)
	# the frame of the hall in dark timber: posts along the walls, a beam round the top
	for x in [-5.45, -2.7, 2.7, 5.45]:
		B.box(dien, Vector3(0.24, 4.6, 0.24), Vector3(x, hy + 2.3, bz + 0.52), timber, 0, false)
	for sx in [-1.0, 1.0]:
		for z in [fz - 0.4, mz, bz + 0.5]:
			B.box(dien, Vector3(0.24, 4.6, 0.24), Vector3(sx * 5.48, hy + 2.3, z), timber, 0, false)
		B.box(dien, Vector3(0.2, 0.3, 6.8), Vector3(sx * 5.5, hy + 4.55, mz), timber, 0, false)
	B.box(dien, Vector3(11.2, 0.3, 0.2), Vector3(0, hy + 4.55, bz + 0.5), timber, 0, false)
	var floor_m := B.mat("res://assets/tex/slab_pale.png", 0.6, Vector3.ONE, {"triplanar": true, "world": true, "tint": Color(0.82, 0.83, 0.85)})
	B.box(dien, Vector3(11.2, 0.04, 6.6), Vector3(0, hy + 0.02, mz), floor_m, 0, false)
	# the front, with its doorway; the porch; the roofs: all of it cut away from inside
	for sx in [-1.0, 1.0]:
		B.box(cut, Vector3(4.9, 5.0, 0.4), Vector3(sx * 3.55, hy + 2.5, fz - 0.2), porc, 0, false)
	B.box(cut, Vector3(2.2, 2.0, 0.4), Vector3(0, hy + 4.0, fz - 0.2), porc, 0, false)
	for sx in [-1.0, 1.0]:
		B.box(cut, Vector3(0.18, 3.1, 0.5), Vector3(sx * 1.15, hy + 1.55, fz - 0.2), _cobalt, 0, false)
	B.box(cut, Vector3(2.5, 0.2, 0.5), Vector3(0, hy + 3.1, fz - 0.2), _cobalt, 0, false)
	for i in 6:
		var cx := -5.0 + i * 2.0
		B.cylinder(cut, 0.36, 0.3, Vector3(cx, hy + 0.15, -75.6), _plinth_m, false, 12)
		B.cylinder(cut, 0.24, 4.1, Vector3(cx, hy + 2.35, -75.6), _cobalt, false, 12)
		B.box(cut, Vector3(0.6, 0.22, 0.6), Vector3(cx, hy + 4.4, -75.6), B.mat("res://assets/tex/planks.png", 1.2, Vector3.ONE, {"triplanar": true, "tint": Color(0.36, 0.28, 0.24)}), 0, false)
	B.roof(cut, 14.6, 5.2, 5.2, hy + 4.8, hy + 6.2, Vector3(0, 0, -79.6), "res://assets/tex/roof_ink.png")
	B.box(cut, Vector3(8.4, 2.0, 4.6), Vector3(0, hy + 6.4, -79.6), porc, 0, false)
	B.roof(cut, 10.4, 3.4, 3.4, hy + 7.3, hy + 9.4, Vector3(0, 0, -79.6), "res://assets/tex/roof_ink.png")
	for sx in [-1.0, 1.0]:
		B.box(cut, Vector3(0.5, 0.7, 0.5), Vector3(sx * 4.8, hy + 9.55, -79.6), _cobalt, 0, false)
	var wood := B.mat("res://assets/tex/planks.png", 1.4, Vector3.ONE, {"triplanar": true, "tint": Color(0.5, 0.38, 0.3)})
	# the head spring: a granite well, a frame and a rope, a wooden bucket on the rim
	var well := Vector3(-3.6, hy, -81.2)
	_basin(dien, well, 0.8, 0.75, _plinth_m, 18)
	for sx in [-1.0, 1.0]:
		B.box(dien, Vector3(0.12, 2.0, 0.12), well + Vector3(sx * 0.95, 1.0, 0), wood, 0, false)
	B.box(dien, Vector3(2.1, 0.12, 0.12), well + Vector3(0, 1.95, 0), wood, 0, false)
	B.box(dien, Vector3(0.03, 0.9, 0.03), well + Vector3(0.2, 1.45, 0), B.color_mat(Color(0.55, 0.48, 0.38)), 0, false)
	B.cylinder(dien, 0.17, 0.3, well + Vector3(0.95, 0.15, 0.55), wood, false, 10)
	# the basin she washes at, on a stand, between the well and the door
	var stand := Vector3(-2.1, hy, -79.9)
	B.box(dien, Vector3(0.55, 0.72, 0.55), stand + Vector3(0, 0.36, 0), wood, 0, false, 0.03)
	_basin(dien, stand + Vector3(0, 0.72, 0), 0.36, 0.24, porc, 14)
	props["dien_basin"] = stand
	# the low table: the Ty's reports in two stacks, ink stone and brush, the Điện's seal; a mat before it
	var desk := Vector3(3.1, hy, -80.9)
	B.box(dien, Vector3(1.7, 0.36, 0.8), desk + Vector3(0, 0.18, 0), wood, 0, false, 0.03)
	var paper := B.color_mat(Color(0.93, 0.91, 0.85))
	B.box(dien, Vector3(0.5, 0.09, 0.36), desk + Vector3(-0.45, 0.405, -0.05), paper, 8.0, false)
	B.box(dien, Vector3(0.46, 0.05, 0.34), desk + Vector3(0.15, 0.385, 0.05), paper, -5.0, false)
	B.box(dien, Vector3(0.16, 0.05, 0.22), desk + Vector3(0.6, 0.385, -0.1), B.color_mat(Color(0.12, 0.11, 0.12)), 0, false)
	B.box(dien, Vector3(0.1, 0.1, 0.1), desk + Vector3(0.62, 0.41, 0.18), B.color_mat(Color(0.66, 0.18, 0.13)), 0, false)
	B.box(dien, Vector3(1.4, 0.03, 1.0), desk + Vector3(0, 0.015, 1.05), B.mat("res://assets/tex/mat.png", 1.2, Vector3.ONE, {"triplanar": true}), 0, false)
	# the shelf at the back, and on it the small wooden box
	var shelf := Vector3(0.0, hy, bz + 0.72)
	B.box(dien, Vector3(1.6, 0.78, 0.5), shelf + Vector3(0, 0.39, 0), timber, 0, false, 0.03)   # a low cabinet, dark
	B.box(dien, Vector3(1.7, 0.06, 0.56), shelf + Vector3(0, 0.8, 0), wood, 0, false)
	var box_m := B.mat("res://assets/tex/planks.png", 2.0, Vector3.ONE, {"triplanar": true, "tint": Color(0.68, 0.5, 0.36)})
	B.box(dien, Vector3(0.5, 0.24, 0.32), shelf + Vector3(0, 0.95, 0), box_m, 0, false, 0.02)
	B.box(dien, Vector3(0.07, 0.08, 0.02), shelf + Vector3(0, 0.97, 0.17), B.color_mat(Color(0.62, 0.48, 0.22), 0.4), 0, false)
	props["dien_box"] = shelf
	props["dien_desk"] = desk
	props["dien_well"] = well
	# a white lantern by the table; the light of the hall is cold, from the door and the high windows
	B.billboard(dien, "res://assets/sprites/props/lantern_w.png", desk + Vector3(1.1, 1.05, -0.3), 0.022, false)
	var warm := OmniLight3D.new()
	warm.light_color = Color(1.0, 0.86, 0.66)
	warm.light_energy = 1.1
	warm.omni_range = 4.0
	warm.position = desk + Vector3(1.0, 1.4, 0.0)
	add_child(warm)
	var cold := OmniLight3D.new()
	cold.light_color = Color(0.86, 0.9, 1.0)
	cold.light_energy = 0.55
	cold.omni_range = 8.0
	cold.shadow_enabled = false
	cold.position = Vector3(0, hy + 3.6, mz + 0.6)
	add_child(cold)
	# the rice on the threshold
	B.billboard(dien, "res://assets/sprites/props/bowl_rice.png", Vector3(0.7, hy, fz + 0.35), 0.022)
	_bake(cut)
	_make_see_through(cut, hy, fz, 0.04)   # nothing is left of the front but the line of its sill
	_no_shadow(cut)
	var shade_roof := B.box(dien, Vector3(12.6, 0.3, (fz - bz) + 1.6), Vector3(0, hy + 5.3, mz), lime, 0, false)
	shade_roof.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY


func _no_shadow(n: Node) -> void:
	if n is GeometryInstance3D:
		(n as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for c in n.get_children():
		_no_shadow(c)


var _porc_mat: StandardMaterial3D


func _porc_m() -> StandardMaterial3D:
	if _porc_mat == null:
		# (as bright as the lime walls: the glazed tile is a brighter texture, and at 0.94 the sun burnt its joints out)
		_porc_mat = B.mat("res://assets/tex/porc_tile.png", 0.75, Vector3.ONE, {"triplanar": true, "world": true, "tint": Color(0.83, 0.84, 0.86)})
	return _porc_mat


func _window_frame(parent: Node3D, size: Vector2, at: Vector3) -> void:
	## Dark timber round a window, a hand's width proud of the wall.
	var fm := _frame_m()
	var t := 0.08
	B.box(parent, Vector3(size.x + t * 2.0, t, 0.1), at + Vector3(0, size.y * 0.5 + t * 0.5, 0.05), fm, 0, false)
	B.box(parent, Vector3(size.x + t * 2.0, t, 0.12), at + Vector3(0, -size.y * 0.5 - t * 0.5, 0.06), fm, 0, false)
	for sx in [-1.0, 1.0]:
		B.box(parent, Vector3(t, size.y, 0.1), at + Vector3(sx * (size.x * 0.5 + t * 0.5), 0, 0.05), fm, 0, false)


var _frame_mat: StandardMaterial3D


func _frame_m() -> StandardMaterial3D:
	if _frame_mat == null:
		_frame_mat = B.mat("res://assets/tex/planks.png", 2.0, Vector3.ONE, {"triplanar": true, "tint": Color(0.42, 0.34, 0.28)})
	return _frame_mat


func _bake(root: Node3D) -> void:
	## Merge every box, roof and quad under `root` into one mesh per material: a street of these houses is several
	## hundred small meshes, and the laptop this is played on would rather draw a dozen.
	var groups := {}
	var mats := {}
	var inv := root.global_transform.affine_inverse()
	var olds: Array = []
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var m: Material = mi.material_override
		if m == null or mi.mesh == null:
			continue
		var key := _mat_key(m)
		if not groups.has(key):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			groups[key] = st
			mats[key] = m
		for si in mi.mesh.get_surface_count():
			groups[key].append_from(mi.mesh, si, inv * mi.global_transform)
		olds.append(mi)
	for mi in olds:
		mi.get_parent().remove_child(mi)
		mi.queue_free()
	for key in groups:
		var out := MeshInstance3D.new()
		out.mesh = groups[key].commit()
		out.material_override = mats[key]
		root.add_child(out)


func _mat_key(m: Material) -> String:
	if m is StandardMaterial3D:
		var sm := m as StandardMaterial3D
		var t := str(sm.albedo_texture.get_instance_id()) if sm.albedo_texture else "-"
		return "%s|%s|%s|%s|%s|%s" % [t, sm.albedo_color, sm.uv1_triplanar, sm.uv1_world_triplanar, sm.uv1_scale, sm.roughness]
	return str(m.get_instance_id())


func _build_inside() -> void:
	_mats()
	var y := YARD_H + 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var street := Node3D.new()
	add_child(street)
	# the houses of the Tầng Rửa face the street from both sides, fronts on x = ±5.3; alleys between them are
	# closed by low garden walls with a black tile coping
	for side in [-1.0, 1.0]:
		var z := -31.6
		var k := 0
		while true:
			var w := rng.randf_range(4.4, 6.2)
			var d := rng.randf_range(4.6, 5.4)
			if z - w < -40.8:
				break
			var floors := 1 if (k + (1 if side > 0.0 else 0)) % 3 == 1 else 2
			var info := _hui_house(street, Vector3(side * (4.4 + d * 0.5), y, z - w * 0.5), w, d, floors,
				90.0 if side < 0.0 else -90.0, rng)
			# the basin of the house nearest the middle of the street: the camera behind the hero stays clear of
			# the gate towers
			var bz: Vector3 = info["basin"]
			if side > 0.0 and (not props.has("street_basin") or absf(bz.z + 35.5) < absf((props["street_basin"] as Vector3).z + 35.5)):
				props["street_basin"] = bz
			if side < 0.0 and k == 1:
				# the Nhà Rửa: the laying-out wash house where Tâm once washed the grey, its vats steaming
				props["nha_rua"] = info["door"]
				var dp: Vector3 = info["door"]
				# the stone Tâm sat on to wash the grey, worn hollow (ông Sẹo shows it: 8.3)
				B.box(street, Vector3(0.95, 0.42, 0.62), Vector3(dp.x - 0.2, y + 0.21, dp.z - 2.9), _plinth_m, 0, false, 0.06)
				B.box(street, Vector3(0.6, 0.04, 0.4), Vector3(dp.x - 0.2, y + 0.41, dp.z - 2.9), B.color_mat(Color(0.42, 0.43, 0.45)), 0, false)
				props["nha_rua_seat"] = Vector3(dp.x - 0.2, y, dp.z - 2.9)
				for vz in [-1.5, 1.6]:
					B.cylinder(street, 0.62, 0.72, Vector3(dp.x - 0.6, y + 0.36, dp.z + vz), _wood, false, 12)
					B.cylinder(street, 0.56, 0.04, Vector3(dp.x - 0.6, y + 0.7, dp.z + vz), B.color_mat(Color(0.62, 0.66, 0.66), 0.2), false, 12)
					B.particles(self, "res://assets/sprites/props/smoke.png", 8, 3.0, Vector3(0.3, 0.05, 0.3), Vector3(dp.x - 0.6, y + 0.9, dp.z + vz),
						{"dir": Vector3(0, 1, 0), "spread": 10.0, "vmin": 0.2, "vmax": 0.4, "size": 0.9, "color": Color(0.95, 0.95, 0.95, 0.3)})
			var gap := rng.randf_range(0.6, 1.5)
			var gz := z - w - gap * 0.5
			B.box(street, Vector3(0.3, 2.4, gap + 0.1), Vector3(side * 5.5, y + 1.2, gz), _wall_old_m, 0, false)
			B.box(street, Vector3(0.6, 0.14, gap + 0.2), Vector3(side * 5.5, y + 2.45, gz), _ink_m, 0, false)
			if k % 2 == 0:
				B.billboard(street, "res://assets/sprites/props/mai.png" if side < 0.0 else "res://assets/sprites/props/mai_pink.png",
					Vector3(side * 6.2, y, gz), 0.05)
			z -= w + gap
			k += 1
	# the channel of running water down the street, lined in granite, out through the drain
	var wm := ShaderMaterial.new()
	wm.shader = Assets.shader("res://shaders/water.gdshader")
	wm.set_shader_parameter("noise_tex", Assets.tex("res://assets/tex/water_noise.png"))
	wm.set_shader_parameter("deep", Color(0.24, 0.31, 0.32))
	wm.set_shader_parameter("shallow", Color(0.34, 0.43, 0.43))
	wm.set_shader_parameter("glint", Color(0.84, 0.9, 0.89))
	wm.set_shader_parameter("pixel", 24.0)
	var ch := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(0.6, 15.0)
	ch.mesh = pm
	ch.material_override = wm
	ch.position = Vector3(1.8, y + 0.04, -34.0)
	add_child(ch)
	for ex in [1.4, 2.2]:
		B.box(street, Vector3(0.2, 0.16, 15.0), Vector3(ex, y + 0.04, -34.0), _plinth_m, 0, false)
	# washing lines across the street, white cloth hung out
	var rope := B.color_mat(Color(0.3, 0.27, 0.24))
	for i in 3:
		var z2 := -33.0 - i * 3.0
		# the line sags between the houses: short straight runs along a catenary
		var n := 8
		var sag := func(u: float) -> float: return y + 3.5 - 0.45 * (1.0 - pow(2.0 * u - 1.0, 2.0))
		for k in n:
			var u0 := float(k) / n
			var u1 := float(k + 1) / n
			var a := Vector3(-4.4 + 8.8 * u0, sag.call(u0), z2)
			var b := Vector3(-4.4 + 8.8 * u1, sag.call(u1), z2)
			var seg := B.box(street, Vector3(a.distance_to(b), 0.025, 0.025), (a + b) * 0.5, rope, 0, false)
			seg.rotation.z = atan2(b.y - a.y, b.x - a.x)
		# what hangs on it: a sheet, shirts, cloths folded over, bunched where the line is easiest to reach
		var u := 0.1 + rng.randf() * 0.08
		while u < 0.9:
			var kind := rng.randi_range(0, 4)
			var tex: String = ["sheet_w", "shirt_w", "shirt_w", "towel_w", "towel_w"][kind]
			var px := 0.03
			var hgt: float = [36.0, 24.0, 24.0, 16.0, 16.0][kind] * px
			var top_y: float = sag.call(u)
			var piece := B.billboard(self, "res://assets/sprites/props/%s.png" % tex, Vector3(-4.4 + 8.8 * u, top_y - hgt + 0.06, z2), px, true)
			piece.billboard = BaseMaterial3D.BILLBOARD_DISABLED
			piece.modulate = Color(0.84, 0.84, 0.83)   # (washed white, but under the sun the cloth's folds stay, not a burnt patch)
			piece.rotation.y = deg_to_rad(rng.randf_range(-14.0, 14.0))
			u += [0.11, 0.1, 0.1, 0.07, 0.07][kind] + (rng.randf_range(0.05, 0.22) if rng.randf() < 0.4 else 0.01)
	# the lime kiln smoking at the far end of the street
	B.cylinder(street, 1.2, 3.6, Vector3(-2.6, y + 1.6, -40.8), _wall_old_m, false, 14)
	B.cylinder(street, 1.3, 0.2, Vector3(-2.6, y + 3.45, -40.8), _ink_m, false, 14)
	B.particles(self, "res://assets/sprites/props/smoke.png", 18, 6.0, Vector3(0.6, 0.1, 0.6), Vector3(-2.6, y + 3.6, -40.8),
		{"dir": Vector3(0.15, 1, 0), "spread": 15.0, "vmin": 0.3, "vmax": 0.7, "size": 1.6, "color": Color(0.92, 0.92, 0.92, 0.45)})
	_clutter(street, rng)
	_bake(street)
	_make_see_through(street, YARD_H)


func _build_plaza() -> void:
	## The Quảng Trường Rửa, just inside the White Gate: everyone who comes in washes at its great basin, and the
	## Lễ Quét Vôi is held here. The Cửa Cống, the drain door, is in the wall at its east side.
	_mats()
	var y := YARD_H
	var sq := Node3D.new()
	add_child(sq)
	B.cylinder(sq, 1.95, 0.16, Vector3(0, y + 0.08, -28.3), _plinth_m, false, 24)   # the step all round
	_basin(sq, Vector3(0, y + 0.16, -28.3), 1.75, 0.7, _plinth_m, 24)
	B.box(sq, Vector3(0.5, 1.8, 0.5), Vector3(0, y + 0.9, -29.95), _plinth_m, 0, false)
	_bake(sq)
	props["big_basin"] = Vector3(0, y, -28.3)
	# the Cửa Cống: a low iron grille in the inside face of the wall (cut away with the wall, see _make_see_through)
	var cc := Node3D.new()
	add_child(cc)
	B.box(cc, Vector3(1.2, 1.5, 0.12), Vector3(7.2, y + 0.75, -25.36), B.color_mat(Color(0.1, 0.1, 0.11)), 0, false)
	for i in 5:
		B.box(cc, Vector3(0.06, 1.5, 0.06), Vector3(6.75 + i * 0.22, y + 0.75, -25.28), B.color_mat(Color(0.32, 0.32, 0.34), 0.4), 0, false)
	_make_see_through(cc, YARD_H, GATE.z - 1.3)
	props["cua_cong"] = Vector3(7.2, y, -26.4)


# ===================================================================== the tiers above
func _tier_face(z0: float, z1: float, y0: float, y1: float, x0: float, x1: float) -> void:
	## A retaining wall faced in lime, built in lengths (each a little set back, each its own height, so the face
	## is not one slab), dressed granite at its foot, a buttress at every joint, a parapet capped in black tile,
	## ivy hanging over here and there; and a stair climbing along its face from x0 to x1.
	var tiers := Node3D.new()
	add_child(tiers)
	var zc := (z0 + z1) * 0.5
	var depth := absf(z1 - z0)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(absf(z0) * 13.0)
	var xs := -30.0
	while xs < 30.0 - 0.1:
		var L := rng.randf_range(6.0, 11.5)
		if xs + L > 30.0 - 3.0:
			L = 30.0 - xs
		var jog := -rng.randf_range(0.0, 0.7)    # set back (north) only: the stair stands in front of it
		var cx := xs + L * 0.5
		var hb := y1 - y0 + 0.4 + rng.randf_range(-0.1, 0.35)
		var fz := z0 + jog
		B.box(tiers, Vector3(L + 0.02, hb, depth + 0.2 + jog), Vector3(cx, y0 + hb * 0.5 - 0.2, zc + jog * 0.5), _wall_old_m, 0, false)
		B.box(tiers, Vector3(L + 0.04, 1.25, 0.26), Vector3(cx, y0 + 0.62, fz + 0.1), _plinth_m, 0, false)
		B.box(tiers, Vector3(L, 0.9, 0.35), Vector3(cx, y0 + hb + 0.4, fz - 0.25), _wall_m, 0, false)
		B.box(tiers, Vector3(L + 0.2, 0.15, 0.75), Vector3(cx, y0 + hb + 0.92, fz - 0.25), _ink_m, 0, false)
		B.box(tiers, Vector3(L + 0.2, 0.12, 0.26), Vector3(cx, y0 + hb + 1.05, fz - 0.25), _ink_m, 0, false)
		if xs > -29.0:
			B.box(tiers, Vector3(0.8, hb - 0.3, 0.7), Vector3(xs, y0 + (hb - 0.3) * 0.5 - 0.2, maxf(fz, z0 - 0.7) + 0.3), _plinth_m, 0, false, 0.04)
		for k in rng.randi_range(0, 2):
			var ix := xs + rng.randf_range(0.8, L - 0.8)
			if absf(ix - (x0 + x1) * 0.5) > absf(x1 - x0) * 0.5 + 1.0:   # not over the stair
				var iv := B.billboard(tiers, "res://assets/sprites/props/ivy.png", Vector3(ix, y0 + hb - 1.9, fz + 0.06), 0.045, false)
				iv.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		xs += L
	var n := int((y1 - y0) / 0.3)
	var run := (x1 - x0) / n
	for i in n:
		var top := y0 + (i + 1) * 0.3
		B.box(tiers, Vector3(absf(run) + 0.02, top - y0 + 0.2, 1.1), Vector3(x0 + run * (i + 0.5), (top + y0) * 0.5 - 0.1, z0 + 0.6), _plinth_m, 0, false)
	# the stair's outer wall, in one slanted run, capped
	var sl := B.box(tiers, Vector3(Vector2(x1 - x0, y1 - y0).length(), 0.7, 0.25), Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5 + 0.55, z0 + 1.2), _wall_m, 0, false)
	sl.rotation.z = atan2(y1 - y0, x1 - x0)
	var cap := B.box(tiers, Vector3(Vector2(x1 - x0, y1 - y0).length() + 0.2, 0.12, 0.5), Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5 + 0.95, z0 + 1.2), _ink_m, 0, false)
	cap.rotation.z = atan2(y1 - y0, x1 - x0)
	_bake(tiers)
	_make_see_through(tiers, y0)


func _tier_rows(ty: float, rows: Array, skip: Array, rng: RandomNumberGenerator) -> void:
	## Rows of houses on one tier, fronts to the south; their black roofs overlap up the mountain.
	var tiers := Node3D.new()
	add_child(tiers)
	for r in rows.size():
		var front: float = rows[r]
		var x := -25.0 + (2.6 if r % 2 else 0.0)
		while x < 25.0:
			var w := rng.randf_range(3.8, 7.2)
			var d := rng.randf_range(4.0, 5.4)
			var cx := x + w * 0.5
			var blocked := false
			var tree := true
			for sk in skip:
				if absf(cx - sk[0]) < sk[1] + w * 0.5 and (sk.size() < 3 or sk[2] == r or sk[2] < 0):
					blocked = true
					if sk.size() > 3 and not sk[3]:
						tree = false
			if not blocked:
				var back := 0.0 if r == 0 else rng.randf_range(-1.4, 0.4)
				var lift := 0.0 if r == 0 else rng.randf_range(0.0, 1.6)
				var fl := 1 if rng.randf() < 0.3 else (2 if (r == 0 or rng.randf() < 0.75) else 3)
				var yaw := 0.0 if r == 0 else rng.randf_range(-7.0, 7.0)
				var at := Vector3(cx, ty + lift, front - d * 0.5 + back)
				if lift > 0.15:   # set up on its own footing, where the ground rises behind the street
					B.box(tiers, Vector3(w + 0.3, lift + 0.3, d + 0.3), Vector3(cx, ty + lift * 0.5 - 0.15, at.z), _plinth_m, yaw, false)
				_hui_house(tiers, at, w, d, fl, yaw, rng, false)
				if r > 0 and rng.randf() < 0.45:   # a tree in the gap behind
					B.billboard(tiers, ["res://assets/sprites/props/tung.png", "res://assets/sprites/props/mai.png", "res://assets/sprites/props/bamboo.png"][rng.randi() % 3],
						Vector3(cx + w * 0.5 + 0.4, ty + lift, at.z - d * 0.3), rng.randf_range(0.045, 0.06))
			elif tree and rng.randf() < 0.6:
				B.billboard(tiers, "res://assets/sprites/props/tung.png", Vector3(cx, ty, front - 1.5), 0.06)
			x += w + rng.randf_range(0.3, 1.2)
			if rng.randf() < 0.18:
				B.billboard(tiers, "res://assets/sprites/props/mai.png" if rng.randf() < 0.6 else "res://assets/sprites/props/tung.png",
					Vector3(x - 0.2, ty, front - 0.6), 0.05)
	_bake(tiers)
	_make_see_through(tiers, ty)


func _build_tiers() -> void:
	_mats()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	# the faces between the tiers, each with its stair, the stairs zigzagging up the city
	_tier_face(-42.0, -45.0, YARD_H, 10.0, -1.0, 10.0)
	_tier_face(-55.0, -58.0, 10.0, 17.0, 2.0, -10.0)
	_tier_face(-68.0, -72.0, 17.0, 26.0, -2.0, 11.0)
	# the houses (gaps where the stairs arrive, and for the Đền Thầy)
	_tier_rows(10.0, [-48.2, -53.0], [[11.0, 2.0, 0], [2.0, 1.4, -1, false], [-4.0, 3.4, 0, false], [-13.0, 4.2, 0, false]], rng)
	_tier_rows(17.0, [-61.2, -65.8], [[-11.0, 2.0, 0], [-14.0, 4.6, 0, false]], rng)
	# the Tầng Giữa's two houses of the chapter: the Y Viện (herbs drying), the Dinh Ty (cobalt at the door)
	var mid := Node3D.new()
	add_child(mid)
	var yv := _hui_house(mid, Vector3(-4.0, 10.0, -48.2 - 2.6), 6.4, 5.2, 2, 0.0, rng, true)
	props["y_vien"] = yv["door"]
	for i in 3:
		B.box(mid, Vector3(1.6, 0.08, 0.5), Vector3(-6.8 + i * 0.0, 10.0 + 0.7 + i * 0.5, -47.7), _wood, 0, false)
		B.billboard(mid, "res://assets/sprites/props/bush.png", Vector3(-6.8, 10.0 + 0.72 + i * 0.5, -47.7), 0.018, false)
	var dt := _hui_house(mid, Vector3(-13.0, 10.0, -48.2 - 2.8), 8.0, 5.6, 2, 0.0, rng, true)
	props["dinh_ty"] = dt["door"]
	var dtd: Vector3 = dt["door"]
	for sx in [-1.6, 1.6]:
		B.box(mid, Vector3(0.36, 3.0, 0.36), Vector3(dtd.x + sx, 10.0 + 1.5, -47.9), _cobalt, 0, false)
	B.box(mid, Vector3(3.8, 0.2, 0.5), Vector3(dtd.x, 10.0 + 3.05, -47.9), _cobalt, 0, false)
	_bake(mid)
	_make_see_through(mid, 10.0)
	# the Đền Thầy on the next tier: a wide hall, its doors open on the painting, a plum before it
	var den := Node3D.new()
	add_child(den)
	var dn := _hui_house(den, Vector3(-14.0, 17.0, -64.0), 8.0, 5.6, 1, 0.0, rng, true)
	props["den_thay"] = dn["door"]
	var pm := B.mat("res://assets/tex/tranh_tho.png", 1.0, Vector3.ONE)
	pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	var dnd: Vector3 = dn["door"]
	_quad(den, Vector2(0.95, 1.42), Vector3(dnd.x, 17.0 + 1.62, -61.2 + 0.04), pm)
	B.billboard(den, "res://assets/sprites/props/mai.png", Vector3(-10.4, 17.0, -60.2), 0.06)
	_bake(den)
	_make_see_through(den, 17.0)
	# the Bạch Điện on the summit tier: a granite platform, cobalt pillars, two eaves of black tile
	var top := 26.0
	var dien := Node3D.new()
	add_child(dien)
	B.box(dien, Vector3(18.0, 1.4, 12.0), Vector3(0, top + 0.5, -79.0), _plinth_m, 0, false)
	for i in 4:
		B.box(dien, Vector3(6.0 - i * 0.6, 0.35, 0.6), Vector3(0, top + 0.1 + i * 0.35, -72.7 - i * 0.5), _plinth_m, 0, false)
	_build_dien_hall(dien, top + 1.2)
	# the head spring's house beside it, and mountain pines
	_hui_house(dien, Vector3(10.5, top, -78.0), 4.4, 4.2, 1, 0.0, rng, false)
	_bake(dien)
	_make_see_through(dien, DIEN_TOP)
	for tp in [Vector3(-11.0, 0, -80.0), Vector3(15.5, 0, -74.0), Vector3(-17.5, 0, -73.0), Vector3(20.0, 0, -60.0),
			Vector3(-22.0, 0, -59.0), Vector3(23.0, 0, -47.0), Vector3(-24.0, 0, -48.5)]:
		tp.y = height_at(tp.x, tp.z)
		B.billboard(self, "res://assets/sprites/props/tung.png", tp, 0.07)


func _build_bs_backdrop() -> void:
	## Far white peaks behind the city, so the mountain does not end at the summit; pines on the near flanks.
	_mats()
	var prng := RandomNumberGenerator.new()
	prng.seed = 5
	for i in 26:
		var side := -1.0 if i % 2 == 0 else 1.0
		var px := side * prng.randf_range(32.0, 46.0)
		var pz := prng.randf_range(-70.0, 0.0)
		B.billboard(self, "res://assets/sprites/props/tung.png", Vector3(px, height_at(px, pz) - 0.3, pz), prng.randf_range(0.06, 0.09))
	# pines on the ledges of the near flanks, in clumps
	for i in 34:
		var side := -1.0 if i % 2 == 0 else 1.0
		var cx := side * prng.randf_range(34.0, 52.0)
		var cz := prng.randf_range(-80.0, 10.0)
		for k in prng.randi_range(1, 3):
			var px2 := cx + prng.randf_range(-2.0, 2.0)
			var pz2 := cz + prng.randf_range(-2.0, 2.0)
			B.billboard(self, "res://assets/sprites/props/tung.png", Vector3(px2, height_at(px2, pz2) - 0.3, pz2), prng.randf_range(0.07, 0.11))
	# the forest on the flanks: pines thick where the slope lets them hold, thin on the steep faces
	var tung_pts := PackedVector3Array()
	var pine_pts := PackedVector3Array()
	var tries := 0
	while tung_pts.size() + pine_pts.size() < 1500 and tries < 14000:
		tries += 1
		var fx := (1.0 if prng.randf() < 0.5 else -1.0) * prng.randf_range(31.0, 88.0)
		var fz := prng.randf_range(-100.0, 40.0)
		var side2 := absf(fx) - 30.0 - 6.0 * smoothstep(-20.0, 30.0, fz)
		if side2 < 1.5:
			continue
		var fh := height_at(fx, fz)
		var sl := absf(height_at(fx + 0.8, fz) - height_at(fx - 0.8, fz)) + absf(height_at(fx, fz + 0.8) - height_at(fx, fz - 0.8))
		if sl > 2.4 or prng.randf() < sl * 0.35:
			continue
		# in stands: keep a point more often where the noise says the ground is a hollow
		if _mn().get_noise_2d(fx * 2.0, fz * 2.0) < -0.25 and prng.randf() < 0.7:
			continue
		if prng.randf() < 0.6:
			tung_pts.append(Vector3(fx, fh - 0.2, fz))
		else:
			pine_pts.append(Vector3(fx, fh - 0.2, fz))
	var ftint := PackedColorArray([Color(0.82, 0.86, 0.82), Color(0.7, 0.76, 0.72), Color(0.9, 0.9, 0.84), Color(0.62, 0.68, 0.66)])
	B.scatter(self, "res://assets/sprites/props/tung.png", tung_pts, 0.085, 0.02, ftint)
	B.scatter(self, "res://assets/sprites/props/pine.png", pine_pts, 0.07, 0.02, ftint)
	# the far mountains: towers of limestone, three ranges, each farther one paler and bluer in the haze
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var haze := Color(0.74, 0.8, 0.88)
	for layer in 3:
		var k: float = [0.18, 0.45, 0.7][layer]
		# the title's limestone (fractured faces, beds, streaks), paler and bluer in each farther range; the haze lifts
		# the shadows of far things
		var mat := B.karst_mat(Color(0.86, 0.86, 0.84).lerp(haze, k), haze * (k * 0.45), 0.9)
		var zb: float = [-135.0, -185.0, -245.0][layer]
		var n: int = [9, 11, 13][layer]
		var span: float = [190.0, 280.0, 380.0][layer]
		for i in n:
			var x := -span * 0.5 + span * (i + rng.randf_range(0.1, 0.9)) / n
			var hgt: float = rng.randf_range(45.0, 75.0) * (1.0 + layer * 0.35)
			var r: float = rng.randf_range(11.0, 18.0) * (1.0 + layer * 0.3)
			_karst_tower(Vector3(x, -6.0, zb - rng.randf_range(0, 25)), r, hgt, mat, rng)


func _karst_tower(at: Vector3, r: float, h: float, mat: Material, rng: RandomNumberGenerator) -> void:
	## One tower of limestone (the far ranges): steep, a little leaning, stepped at its beds, a cleft or two down it, a
	## rounded crown (B.crag, in the title's limestone).
	for k in 202:   # (the numbers the old tower drew, so the towers after it stand where they stood)
		rng.randf()
	var own := RandomNumberGenerator.new()
	own.seed = hash(at)
	B.crag(self, at, r, r * 0.72, h, mat, own)


# ===================================================================== the camp outside the gate
var _tent_see_cache := {}


func _tent_see(std: StandardMaterial3D) -> ShaderMaterial:
	## The tent canvas in the see-through shader, always on (the camp is where the camera walks among tents).
	if _tent_see_cache.has(std):
		return _tent_see_cache[std]
	var sm := ShaderMaterial.new()
	sm.shader = Assets.shader("res://shaders/see_through_solid.gdshader")
	sm.set_shader_parameter("use_tex", true)
	sm.set_shader_parameter("albedo_tex", std.albedo_texture)
	sm.set_shader_parameter("tint", std.albedo_color)
	sm.set_shader_parameter("uv_scale", Vector3.ONE)
	sm.set_shader_parameter("roughness_v", 1.0)
	sm.set_shader_parameter("active", 1.0)
	sm.set_shader_parameter("radius", 1.8)
	_tent_see_cache[std] = sm
	return sm


func _tent(p: Vector2, rot: float, size := 1.0) -> void:
	## A camp tent: patched canvas sagging between the ridge pole and the ground, stones along its hem.
	_mats()
	var h := height_at(p.x, p.y)
	var root := Node3D.new()
	root.position = Vector3(p.x, h - 0.04, p.y)
	root.rotation.y = deg_to_rad(rot)
	add_child(root)
	var L := 2.8 * size
	var W := 1.35 * size
	var H := 1.75 * size
	var surf := func(x: float, t: float, sgn: float) -> Vector3:
		var x01 := x / L + 0.5
		var y := lerpf(H, 0.0, t) - 0.17 * sin(PI * t) * (0.55 + 0.45 * sin(PI * x01))
		return Vector3(x, y, sgn * W * t * (1.0 + 0.05 * sin(PI * x01)))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nx := 6
	var nt := 4
	for sgn in [1.0, -1.0]:
		for i in nx:
			for j in nt:
				var x0 := -L * 0.5 + L * i / nx
				var x1 := -L * 0.5 + L * (i + 1) / nx
				var t0 := float(j) / nt
				var t1 := float(j + 1) / nt
				var q := [[x0, t0], [x1, t0], [x1, t1], [x0, t0], [x1, t1], [x0, t1]]
				if sgn < 0.0:
					q = [[x0, t0], [x1, t1], [x1, t0], [x0, t0], [x0, t1], [x1, t1]]
				for v in q:
					st.set_uv(Vector2(v[0] * 0.5, v[1] * W * 0.5 * sgn))
					st.add_vertex(surf.call(v[0], v[1], sgn))
	# the ends: the back closed, the front with a dark doorway
	for xe in [-L * 0.5, L * 0.5]:
		# both windings: the canvas is seen from either side, and the shader culls back faces
		for v in [Vector3(xe, H, 0), Vector3(xe, 0, W), Vector3(xe, 0, -W), Vector3(xe, H, 0), Vector3(xe, 0, -W), Vector3(xe, 0, W)]:
			st.set_uv(Vector2(v.z * 0.5, v.y * 0.5))
			st.add_vertex(v)
	st.index()
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _tent_see(_tent_m[int(absf(rot)) % 3])
	root.add_child(mi)
	var door := MeshInstance3D.new()
	var dm := PrismMesh.new()
	dm.size = Vector3(1.1 * size, 1.2 * size, 0.02)
	door.mesh = dm
	door.material_override = B.color_mat(Color(0.12, 0.1, 0.09))
	door.position = Vector3(L * 0.5 + 0.02, 0.6 * size, 0)
	door.rotation.y = PI * 0.5
	root.add_child(door)
	# the ridge pole, and the front pole standing up past it
	var pole := B.cylinder(root, 0.045, L + 0.5, Vector3(0, H + 0.03, 0), _wood, false, 5)
	pole.rotation.z = PI * 0.5
	B.cylinder(root, 0.05, H + 0.5, Vector3(L * 0.5 + 0.15, (H + 0.5) * 0.5, 0), _wood, false, 5)
	for sgn in [1.0, -1.0]:
		for k in 3:
			B.box(root, Vector3(0.32, 0.18, 0.26), Vector3(-L * 0.35 + k * L * 0.35, 0.06, sgn * (W + 0.08)), _stone_old, k * 25.0, false, 0.04)
	_tents.append(p)


func _build_camp() -> void:
	_mats()
	var c := CAMP
	var ring := [[-14.5, 6.5, 30], [-16.0, 11.5, 80], [-14.0, 17.0, 120], [-9.5, 20.5, 170], [-5.5, 24.0, 200],
		[8.0, 3.5, 250], [-3.0, 5.5, 330], [6.5, 19.5, 210], [-9.0, 3.0, 15]]
	for t in ring:
		_tent(Vector2(t[0], t[1]), t[2], 0.9 + 0.15 * (int(t[2]) % 3) / 2.0)
	# the cook fire
	var fy := height_at(c.x, c.z)
	_fire_sprite = B.billboard(self, "res://assets/sprites/props/fire.png", Vector3(c.x, fy, c.z), 0.045, false, 4, 0)
	_fire_sprite.shaded = false
	_fire_light = OmniLight3D.new()
	_fire_light.light_color = Color(1.0, 0.6, 0.32)
	_fire_light.light_energy = 2.2
	_fire_light.omni_range = 8.0
	_fire_light.shadow_enabled = true
	_fire_light.position = Vector3(c.x, fy + 1.0, c.z)
	add_child(_fire_light)
	B.particles(self, "res://assets/sprites/props/smoke.png", 10, 4.0, Vector3(0.2, 0.1, 0.2), Vector3(c.x, fy + 1.4, c.z),
		{"dir": Vector3(0.1, 1, 0), "spread": 10.0, "vmin": 0.3, "vmax": 0.6, "size": 0.9, "color": Color(0.7, 0.68, 0.66, 0.45)})
	var bark := B.mat("res://assets/tex/bark.png", 1.6, Vector3.ONE, {"triplanar": true, "tint": Color(0.86, 0.82, 0.78)})
	for k in 6:   # logs to sit on round the fire: round, in their bark, laid round the ring
		var a := k * TAU / 6.0 + 0.3
		var lp := Vector3(c.x + cos(a) * 2.2, 0, c.z + sin(a) * 2.2)
		lp.y = height_at(lp.x, lp.z) + 0.15
		var lg: MeshInstance3D = B.cylinder(self, 0.16 + 0.02 * (k % 2), 1.05 + 0.12 * (k % 3), lp, bark, false, 9)
		lg.rotation = Vector3(0, -a + PI * 0.5 + 0.12 * ((k % 3) - 1), PI * 0.5)
	props["pots"] = B.billboard(self, "res://assets/sprites/props/pots.png", Vector3(c.x + 1.6, fy, c.z - 1.4), B.PX)
	props["nong"] = B.billboard(self, "res://assets/sprites/props/nong_the.png", Vector3(-4.2, height_at(-4.2, 8.6), 8.6), 0.03)
	# the well the camp dug: brackish water
	var wp := Vector3(-15.0, height_at(-15.0, 9.0), 9.0)
	B.cylinder(self, 0.8, 0.8, wp + Vector3(0, 0.3, 0), _stone_old, false, 12)
	props["camp_well"] = wp
	# rags drying on a line between two poles
	for i in 3:
		B.billboard(self, "res://assets/sprites/props/cloth_c.png", Vector3(-12.5 + i * 1.6, height_at(-12.5, 15.0) + 1.0, 15.0), 0.024, false)
	# the stream of the city's used water, whitish with lime
	var sm := ShaderMaterial.new()
	sm.shader = Assets.shader("res://shaders/water.gdshader")
	sm.set_shader_parameter("noise_tex", Assets.tex("res://assets/tex/water_noise.png"))
	sm.set_shader_parameter("deep", Color(0.11, 0.13, 0.13))
	sm.set_shader_parameter("shallow", Color(0.3, 0.33, 0.31))
	sm.set_shader_parameter("glint", Color(0.74, 0.78, 0.74))
	sm.set_shader_parameter("glint_amount", 0.35)
	sm.set_shader_parameter("pixel", 24.0)
	var pts := [Vector2(18, -10), Vector2(10, 0), Vector2(0, 6), Vector2(-14, 26)]
	# one strip that lies in its bed all the way down, not flat planes standing off the slope
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var along := 0.0
	for i in range(pts.size() - 1):
		var a2: Vector2 = pts[i]
		var b2: Vector2 = pts[i + 1]
		var dirv := (b2 - a2).normalized()
		var nrm := Vector2(-dirv.y, dirv.x)
		var steps := int(a2.distance_to(b2) / 0.8) + 1
		for k in steps:
			var p0 := a2.lerp(b2, float(k) / steps)
			var p1 := a2.lerp(b2, float(k + 1) / steps)
			var w0 := 0.38 + 0.1 * sin(along * 0.7)
			var w1 := 0.38 + 0.1 * sin((along + p0.distance_to(p1)) * 0.7)
			var corners := [p0 + nrm * w0, p0 - nrm * w0, p1 - nrm * w1, p1 + nrm * w1]
			var v := []
			for q in corners:
				v.append(Vector3(q.x, height_at(q.x, q.y) + 0.03, q.y))
			var u0 := along * 0.25
			var u1 := (along + p0.distance_to(p1)) * 0.25
			for pr in [[v[0], Vector2(0, u0)], [v[1], Vector2(1, u0)], [v[2], Vector2(1, u1)],
					[v[0], Vector2(0, u0)], [v[2], Vector2(1, u1)], [v[3], Vector2(0, u1)]]:
				st.set_uv(pr[1])
				st.add_vertex(pr[0])
			along += p0.distance_to(p1)
	st.generate_normals()
	var seg := MeshInstance3D.new()
	seg.mesh = st.commit()
	seg.material_override = sm
	add_child(seg)
	# stones along the banks
	var srng := RandomNumberGenerator.new()
	srng.seed = 9
	var banks := Node3D.new()
	add_child(banks)
	for i in range(pts.size() - 1):
		var sa: Vector2 = pts[i]
		var sb: Vector2 = pts[i + 1]
		var sd := (sb - sa).normalized()
		var sn := Vector2(-sd.y, sd.x)
		var n2 := int(sa.distance_to(sb) / 1.3)
		for k in n2:
			var q := sa.lerp(sb, (k + srng.randf()) / n2) + sn * (0.55 + srng.randf_range(0.0, 0.25)) * (1.0 if k % 2 == 0 else -1.0)
			B.box(banks, Vector3(srng.randf_range(0.25, 0.45), 0.16, srng.randf_range(0.2, 0.35)),
				Vector3(q.x, height_at(q.x, q.y) + 0.04, q.y), _stone_old, srng.randf_range(0, 180), false, 0.04)
	_bake(banks)
	# the footing of the old stone gate, under flaking lime, out to the east of the camp
	for k in 5:
		var bp := Vector3(13.0 + k * 1.3, 0, 6.0 + sin(k) * 0.8)
		bp.y = height_at(bp.x, bp.z) + 0.2
		B.box(self, Vector3(1.2, 0.7 + (k % 2) * 0.4, 1.0), bp, _stone_old, k * 17.0, false, 0.06)
	props["khe_stone"] = Vector3(15.6, height_at(15.6, 6.6), 6.6)


const STREAM := [Vector2(18, -10), Vector2(10, 0), Vector2(0, 6), Vector2(-14, 26)]


func _grass_spot(x: float, z: float, margin: float) -> bool:
	## Open grass outside the wall: off the paths, the yard, the glazed ground, the stream, the tents, the steep.
	if z < -21.0 or _path_weight(x, z) > 0.05 or _yard_weight(x, z) > 0.05 or _glaze_weight(x, z) > 0.05:
		return false
	var h := height_at(x, z)
	if absf(height_at(x + 0.5, z) - height_at(x - 0.5, z)) > 0.4 or absf(height_at(x, z + 0.5) - height_at(x, z - 0.5)) > 0.4:
		return false
	if h > YARD_H + 2.0:
		return false
	var p := Vector2(x, z)
	for t in _tents:
		if p.distance_to(t) < 1.7 + margin:
			return false
	for i in range(STREAM.size() - 1):
		if _dist_seg(p, STREAM[i], STREAM[i + 1]) < 1.1 + margin:
			return false
	return true


func _build_grass() -> void:
	## Tufts over all the open grass outside the wall, as dense as the valley's (world.gd), with bushes and pale
	## highland flowers in drifts, and reeds along the stream: the grass texture alone repeats into a checkerboard.
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var pts := PackedVector3Array()
	var tints := PackedColorArray([Color(0.74, 0.78, 0.68), Color(0.66, 0.72, 0.64), Color(0.82, 0.8, 0.62), Color(0.6, 0.66, 0.6)])
	var tries := 0
	while pts.size() < 4200 and tries < 40000:
		tries += 1
		var x := rng.randf_range(-36, 36)
		var z := rng.randf_range(-21, 50)
		if _grass_spot(x, z, 0.2):
			pts.append(Vector3(x, height_at(x, z), z))
	B.scatter(self, "res://assets/sprites/props/tuft.png", pts, 0.035, 0.06, tints)
	# bushes in clumps of two or three, flowers in drifts round them
	for i in 16:
		var cx := rng.randf_range(-30, 30)
		var cz := rng.randf_range(-18, 44)
		for k in rng.randi_range(1, 3):
			var x := cx + rng.randf_range(-1.6, 1.6)
			var z := cz + rng.randf_range(-1.2, 1.2)
			if _grass_spot(x, z, 1.2):
				B.plant(self, "res://assets/sprites/props/%s.png" % ("bush" if (i + k) % 2 else "bush2"), Vector3(x, height_at(x, z), z), B.PX, 0.04, 1.0)
		for k in rng.randi_range(3, 7):
			var x := cx + rng.randf_range(-3.0, 3.0)
			var z := cz + rng.randf_range(-2.4, 2.4)
			if _grass_spot(x, z, 0.6):
				B.plant(self, "res://assets/sprites/props/flowers.png", Vector3(x, height_at(x, z), z), B.PX, 0.03, 0.0, false)
	# reeds where the used water runs
	for i in range(STREAM.size() - 1):
		var a: Vector2 = STREAM[i]
		var b: Vector2 = STREAM[i + 1]
		var n := int(a.distance_to(b) / 2.2)
		for k in n:
			if rng.randf() < 0.55:
				continue
			var t := (k + rng.randf()) / n
			var q := a.lerp(b, t)
			var nrm := (b - a).normalized().orthogonal() * (1.0 if rng.randf() < 0.5 else -1.0)
			q += nrm * rng.randf_range(0.9, 1.4)
			B.plant(self, "res://assets/sprites/props/reeds.png", Vector3(q.x, height_at(q.x, q.y), q.y), B.PX, 0.06, 1.0, false)


func _build_road() -> void:
	pass


func _place_statues() -> void:
	## Porcelain people along the road up from the Bãi Tro and by the Rãnh Sứ, every one facing the gate: the
	## ones Trắng Tay touched all the way. They are dead.
	var sheets := ["statue_w", "statue_o", "dan_m_porc", "dan_w_porc", "dan_m_blind", "dan_w_blind"]
	var spots := [Vector2(6.5, 40.0), Vector2(2.0, 35.5), Vector2(9.5, 33.0), Vector2(-3.5, 30.0), Vector2(4.5, 27.0),
		Vector2(-6.0, 37.0), Vector2(12.0, 42.5), Vector2(-29.5, 20.5), Vector2(-23.0, 12.5), Vector2(-28.0, 30.0)]
	for i in spots.size():
		var sp: Vector2 = spots[i]
		var a = spawn("porc_%d" % i, "res://assets/sprites/chars/%s.png" % sheets[i % sheets.size()],
			Vector3(sp.x, height_at(sp.x, sp.y), sp.y), "up")
		a.set_meta("statue", true)
		# porcelain in a high sun: held a little below white, or the glaze burns out to a paper cut-out
		a.sprite.modulate = Color(0.8, 0.82, 0.87)


# ===================================================================== air
func _build_bs_atmosphere() -> void:
	var fv := FogVolume.new()
	fv.shape = RenderingServer.FOG_VOLUME_SHAPE_BOX
	fv.size = Vector3(140, 10, 120)
	fv.position = Vector3(0, 1.5, 0)
	_mist_mat = FogMaterial.new()
	_mist_mat.density = 0.0
	_mist_mat.height_falloff = 0.8
	_mist_mat.edge_fade = 0.3
	fv.material = _mist_mat
	add_child(fv)
	lights_night.append(_fire_light)
	_fire_light.set_meta("base_energy", _fire_light.light_energy)
	_lanterns.append(_fire_light)
	# lime dust and ash drifting in the light: pale specks, by day
	_motes = B.particles(self, "res://assets/sprites/props/firefly.png", 90, 9.0, Vector3(9.0, 2.6, 7.0), Vector3(0, 1.6, 0),
		{"spread": 180.0, "vmin": 0.02, "vmax": 0.08, "size": 0.075, "unshaded": true, "turb": 0.4,
		"color": Color(1.0, 0.97, 0.9, 0.75), "gravity": Vector3(0, -0.04, 0)})


const CAM_OUT := Vector3(0, 7.0, 10.6)
const CAM_IN := Vector3(0, 7.0, 10.6)   # the same as outside, and as in the valley: walls in the way thin out instead


func _animate_ambience() -> void:
	super._animate_ambience()
	if hero and rig and rig.target == hero:
		var want := CAM_IN if hero.global_position.z < -25.3 else CAM_OUT
		rig.offset = rig.offset.lerp(want, clampf(get_process_delta_time() * 2.5, 0.0, 1.0))
	if _fire_sprite:
		var t := Time.get_ticks_msec() / 1000.0
		_fire_sprite.frame = int(t * 9.0) % 4
		if _fire_light:
			_fire_light.light_energy = 2.2 * (0.85 + 0.15 * sin(t * 11.0) + 0.08 * sin(t * 23.0))


# ===================================================================== places
func _define_markers() -> void:
	markers = {
		"arrive": Vector3(9.0, height_at(9.0, 46.0), 46.0),
		"road_view": Vector3(2.0, height_at(2.0, 28.0), 28.0),
		"camp_edge": Vector3(-2.0, height_at(-2.0, 18.0), 18.0),
		"camp_center": CAMP + Vector3(0, height_at(CAMP.x, CAMP.z), 0),
		"lanh": Vector3(-5.0, height_at(-5.0, 9.6), 9.6),
		"co": Vector3(-11.5, height_at(-11.5, 18.5), 18.5),
		"co_tent": Vector3(-14.0, height_at(-14.0, 17.0), 17.0),
		"dieu": Vector3(-18.0, height_at(-18.0, 9.0), 9.0),
		"me_manh": Vector3(-9.5, height_at(-9.5, 14.4), 14.4),
		"fire_seat": CAMP + Vector3(1.4, height_at(CAMP.x + 1.4, CAMP.z + 1.6), 1.6),
		"glaze": Vector3(-24.0, height_at(-24.0, 19.0), 19.0),
		"fight": Vector3(-19.0, height_at(-19.0, 23.0), 23.0),
		"camp_road": Vector3(1.0, height_at(1.0, 9.0), 9.0),
		"yard_entry": Vector3(0.0, YARD_H, -11.5),
		"queue": Vector3(0.0, YARD_H, -15.0),
		"test_spot": Vector3(2.7, YARD_H, -17.95),   # before the middle of the table, clear of the rope lane
		"khamsu": Vector3(3.0, YARD_H, -20.3),
		"can": Vector3(-1.0, YARD_H, -21.6),
		"suong_wait": Vector3(-1.4, YARD_H, -17.0),
		"gate_in": Vector3(0.0, YARD_H, -27.5),
		"street": Vector3(0.0, YARD_H, -31.0),
		"basin_in": (props["street_basin"] as Vector3) + Vector3(-0.75, 0, 0) if props.has("street_basin") else Vector3(4.2, YARD_H, -29.0),
		# Part C onward (docs/N_bach_son.md 8.3 to 8.6)
		"plaza": Vector3(2.7, YARD_H, -27.2),   # beside the great basin, not on its step
		"big_basin": Vector3(-1.9, YARD_H, -28.3),
		"cua_cong": Vector3(5.6, YARD_H, -26.4),
		"maty": Vector3(-4.0, YARD_H, -29.6),
		"nha_rua": (props["nha_rua"] as Vector3) if props.has("nha_rua") else Vector3(-3.5, YARD_H, -36.0),
		"stair1_foot": Vector3(1.0, YARD_H, -39.8),
		"tier1_top": Vector3(9.0, 10.0, -46.4),
		"y_vien": (props["y_vien"] as Vector3) if props.has("y_vien") else Vector3(-4.0, 10.0, -47.4),
		"dinh_ty": (props["dinh_ty"] as Vector3) if props.has("dinh_ty") else Vector3(-13.0, 10.0, -47.4),
		"cart_spot": Vector3(15.0, 10.0, -46.6),
		"alley_top": Vector3(2.0, 10.0, -53.6),
		"tier2_top": Vector3(-9.0, 17.0, -59.4),
		"den_thay": (props["den_thay"] as Vector3) if props.has("den_thay") else Vector3(-14.0, 17.0, -60.2),
		"dien_hero": Vector3(0.0, DIEN_TOP, -73.8),
		"dien_tam": Vector3(-2.1, DIEN_TOP, -79.3),      # at her basin, washing, her back to the door
		"dien_door": Vector3(0.0, DIEN_TOP, -75.2),
		"dien_in": Vector3(0.2, DIEN_TOP, -78.0),
		"dien_stand": Vector3(-0.6, DIEN_TOP, -78.9),    # where she tells them to stand: a span away
		"dien_khiet": Vector3(1.6, DIEN_TOP, -74.6),
	}
