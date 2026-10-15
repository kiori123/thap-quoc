extends Node
## The Duyên glimpse of where the Bạch Sơn Nghiệt was born, staged live in its own little world and shown
## through the ink filter (Overlay.vision_stage). Three beats, one per caption:
##   0. Outside the White Gate: the expelled stand before it as its barred doors swing shut.
##   1. Up against the bars: the people inside look out at them; a hand slides the bolt; then, one after
##      another, they turn their backs on the gate and go in. Where each one stood, a white shape of them rises
##      from the feet up, a cobalt band over its eyes, and stays, facing out. (The people are not turned to
##      porcelain: their fear stays at the gate in their shape. That is what Trắng Tay is made of.)
##   2. From the side: long porcelain arms crawl out under the gate. The expelled run; the arms catch the
##      slowest, and porcelain climbs them from where the hand closed. The others get away.
## Built from the game's own pieces (builder boxes and roof, the villagers' and refugees' sprites,
## the porcelain arm links from the battle), so it reads as the same world.

const B = preload("res://scripts/world/builder.gd")
const SHEET_COLS := 19

var viewport: SubViewport
var root: Node3D
var cam: Camera3D
var _doors: Array = []          # [pivot, closed_rot_y]
var _bolt: MeshInstance3D
var _bolt_hand: Sprite3D
var _outside: Array = []        # the expelled: {spr, home, dir, t_run, speed, catch, statue, col0, frozen}
var _inside: Array = []         # the people behind the gate
var _order: Array = []          # the order they turn to porcelain in
var _arms: Array = []
var _t := 0.0
var _beat := -1
var _beat_t := 0.0
var _cam_from: Transform3D
var _cam_to: Transform3D
var _cam_dur := 1.0


func _ready() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_2X
	add_child(viewport)
	root = Node3D.new()
	viewport.add_child(root)
	_environment()
	_build()
	cam = Camera3D.new()
	cam.fov = 38.0
	root.add_child(cam)
	_place_cam(Vector3(1.6, 1.75, 11.5), Vector3(0, 2.9, 0))


# ------------------------------------------------------------------ world
func _environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.64, 0.62, 0.58)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.8, 0.84)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.64, 0.62, 0.58)
	env.fog_light_energy = 1.0
	env.fog_density = 0.026
	env.fog_sky_affect = 1.0
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, -32, 0)
	sun.light_energy = 1.3
	sun.light_color = Color(1.0, 0.97, 0.92)
	sun.shadow_enabled = true
	root.add_child(sun)


func _build() -> void:
	var white := B.color_mat(Color(0.93, 0.93, 0.95))
	var white_dim := B.color_mat(Color(0.84, 0.85, 0.88))
	var iron := B.color_mat(Color(0.11, 0.1, 0.12), 0.6)
	# ground, outside and in, and the road to the gate
	B.box(root, Vector3(90, 0.2, 90), Vector3(0, -0.1, 0), B.color_mat(Color(0.5, 0.48, 0.46)), 0.0, false)
	B.box(root, Vector3(5.6, 0.04, 18), Vector3(0, 0.02, 9), B.color_mat(Color(0.6, 0.58, 0.56)), 0.0, false)
	# the long white wall either side of the gate, a dark coping and merlons along the top
	for side in [-1.0, 1.0]:
		var cx: float = side * 18.6
		B.box(root, Vector3(30.0, 6.2, 2.2), Vector3(cx, 3.1, -1.1), white, 0.0, false, 0.06)
		B.box(root, Vector3(30.0, 0.35, 2.5), Vector3(cx, 6.35, -1.1), B.color_mat(Color(0.2, 0.19, 0.21)), 0.0, false, 0.04)
		for k in 15:
			B.box(root, Vector3(1.0, 0.8, 2.2), Vector3(cx - 14.0 + k * 2.0, 6.9, -1.1), white, 0.0, false, 0.05)
	# the gate tower: two white piers, a beam, a curved tile roof with dark tiles
	for side in [-1.0, 1.0]:
		B.box(root, Vector3(1.4, 8.2, 2.8), Vector3(side * 3.75, 4.1, -1.1), white, 0.0, false, 0.08)
	B.box(root, Vector3(9.0, 1.2, 2.8), Vector3(0, 8.6, -1.1), white_dim, 0.0, false, 0.08)
	var roof := B.roof(root, 11.5, 2.6, 2.6, 9.0, 11.0, Vector3(0, 0, -1.1), "res://assets/tex/roof_tile.png")
	for c in roof.get_children():
		if c is MeshInstance3D:
			(c as MeshInstance3D).material_override = B.color_mat(Color(0.16, 0.15, 0.17))
	# inside: a shadowed court, so the faces behind the bars stand out pale
	B.box(root, Vector3(7.0, 8.0, 0.3), Vector3(0, 4.0, -12.0), B.color_mat(Color(0.32, 0.31, 0.34)), 0.0, false)
	# two barred door leaves, hinged on the piers, opening inward (toward -z)
	for side in [-1.0, 1.0]:
		var pivot := Node3D.new()
		pivot.position = Vector3(side * 3.05, 0, -0.2)
		root.add_child(pivot)
		for b in 8:
			var x: float = -side * (0.2 + b * 0.37)
			B.cylinder(pivot, 0.07, 6.2, Vector3(x, 3.1, 0), iron, false, 8)
		for y in [0.5, 3.1, 5.9]:
			B.box(pivot, Vector3(3.0, 0.2, 0.14), Vector3(-side * 1.5, y, 0), iron, 0.0, false)
		pivot.rotation.y = side * deg_to_rad(-78.0)
		_doors.append([pivot, 0.0])
	# the bolt, waiting inside to the right, and the pale hand that will slide it
	_bolt = B.box(root, Vector3(2.4, 0.26, 0.24), Vector3(3.6, 1.9, -0.55), B.color_mat(Color(0.24, 0.2, 0.18)), 0.0, false)
	_bolt_hand = _sprite("res://assets/sprites/fx/reach_hand.png", 2, 0, Vector3(4.9, 1.9, -0.5), 0.035)
	_bolt_hand.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bolt_hand.flip_h = true
	_bolt_hand.modulate = Color(1.0, 0.76, 0.6)   # a person's hand: the people shut the gate, not the Nghiệt
	_bolt_hand.visible = false
	# the people inside: pale, packed close, all facing out
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	for row in 4:
		var z := -1.3 - row * 1.3
		var n := 6 - (1 if row % 2 else 0)
		for i in n:
			var x := (i - (n - 1) * 0.5) * 1.05 + rng.randf_range(-0.2, 0.2)
			# the people of Bạch Sơn as the city shows them: undyed white, nón lá (assets/sprites/chars/bs_*.png)
			var tex := "res://assets/sprites/chars/bs_w.png" if (i + row) % 2 == 0 else "res://assets/sprites/chars/bs_m.png"
			var p := _person(tex, Vector3(x, 0, z + rng.randf_range(-0.3, 0.3)), 0, rng.randi_range(0, 3))
			p.modulate = Color(0.96, 0.96, 1.0)
			p.flip_h = rng.randf() < 0.5
			p.set_meta("col", p.frame % SHEET_COLS)
			p.set_meta("spot", p.position)
			p.set_meta("over", _climb_overlay(tex.replace(".png", "_blind.png"), p.flip_h))
			_inside.append(p)
	_order = range(_inside.size())
	_order.shuffle()
	# the expelled, outside, backs to us, facing the gate. In beat 2 they run (t_run, speed); the arms catch
	# three of them (catch = when) and they turn to porcelain (statue). The ones who get away are the ones the
	# hero meets at the pass a few days later: Lúa, the mother with the child, the old man, the young man
	# (so none of them may be caught here: the mother and the old man are taken at the pass instead).
	var outside := [
		["dan_w", Vector3(-1.6, 0, 4.2), 0.75, 2.2, 2.2, "dan_w_porc"],
		["dan_m", Vector3(0.7, 0, 4.8), 0.95, 0.9, 1.7, "dan_m_porc"],
		["refugee_m", Vector3(2.2, 0, 3.9), 0.55, 3.1, -1.0, ""],
		["dan_m", Vector3(-3.0, 0, 5.6), 0.7, 2.0, 2.7, "dan_m_porc"],
		["refugee_o", Vector3(3.6, 0, 6.0), 0.5, 1.7, -1.0, ""],
		["refugee_w", Vector3(-0.4, 0, 6.6), 0.62, 3.0, -1.0, ""],
		["lua", Vector3(1.6, 0, 5.6), 0.5, 3.2, -1.0, ""]]
	for o in outside:
		var feet: Vector3 = o[1]
		var col := rng.randi_range(0, 3)
		var s := _person("res://assets/sprites/chars/%s.png" % o[0], feet, 3, col)
		s.modulate = Color(0.78, 0.76, 0.76)
		_outside.append({"spr": s, "home": feet, "dir": Vector3(signf(feet.x) * 0.12, 0, 1).normalized(), "t_run": o[2],
			"speed": o[3], "catch": o[4], "statue": o[5], "col0": col, "frozen": 13})
	# mist drifting along the foot of the wall
	for k in 7:
		var m := _sprite("res://assets/sprites/props/smoke.png", 1, 0, Vector3(-12 + k * 4.0, 1.0 + (k % 3) * 0.4, 1.5 + (k % 2) * 2.0), 0.12)
		m.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		m.modulate = Color(1, 1, 1, 0.45)
		m.shaded = false


func _sprite(tex: String, hframes: int, frame: int, pos: Vector3, px: float) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = Assets.tex(tex)
	s.hframes = hframes
	s.frame = frame
	s.pixel_size = px
	s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.position = pos
	root.add_child(s)
	return s


func _person(tex: String, feet: Vector3, row: int, col: int) -> Sprite3D:
	var s := _sprite(tex, SHEET_COLS, 0, feet + Vector3(0, 48 * B.PX * 0.5, 0), B.PX)
	s.vframes = 4
	s.frame = row * SHEET_COLS + col
	s.shaded = true
	return s


# ------------------------------------------------------------------ beats
func beat(i: int) -> float:
	## Start beat i; returns how long it wants on screen.
	_beat = i
	_beat_t = 0.0
	match i:
		0:
			_move_cam(Vector3(1.6, 1.75, 11.5), Vector3(0, 2.9, 0), Vector3(1.1, 1.7, 9.6), Vector3(0, 2.8, 0), 3.4)
			return 3.4
		1:
			for d in _doors:
				(d[0] as Node3D).rotation.y = 0.0
			_bolt_hand.visible = true
			_move_cam(Vector3(1.1, 1.6, 2.7), Vector3(0.5, 1.4, -3.0), Vector3(0.8, 1.55, 1.8), Vector3(0.4, 1.35, -3.0), 5.2)
			return 5.2
		2:
			_bolt.position.x = 1.0
			_bolt_hand.visible = false
			# from the side: the gate on the right, the road running off to the left
			_move_cam(Vector3(8.6, 1.8, 5.0), Vector3(0.0, 0.9, 4.7), Vector3(8.0, 1.7, 5.5), Vector3(0.0, 0.85, 5.1), 4.6)
			_start_arms()
			return 4.6
	return 1.0


func _place_cam(pos: Vector3, look: Vector3) -> void:
	cam.global_transform = Transform3D(Basis(), pos).looking_at(look, Vector3.UP)


func _move_cam(p0: Vector3, l0: Vector3, p1: Vector3, l1: Vector3, dur: float) -> void:
	_cam_from = Transform3D(Basis(), p0).looking_at(l0, Vector3.UP)
	_cam_to = Transform3D(Basis(), p1).looking_at(l1, Vector3.UP)
	_cam_dur = dur + 0.6
	cam.global_transform = _cam_from


func _process(delta: float) -> void:
	_t += delta
	_beat_t += delta
	if _beat < 0:
		return
	var k := clampf(_beat_t / _cam_dur, 0.0, 1.0)
	cam.global_transform = _cam_from.interpolate_with(_cam_to, k)
	match _beat:
		0:   # the doors swing shut, a little after the beat starts
			var s := clampf((_beat_t - 0.7) / 1.5, 0.0, 1.0)
			s = s * s * (3.0 - 2.0 * s)
			for i in _doors.size():
				var side := -1.0 if i == 0 else 1.0
				(_doors[i][0] as Node3D).rotation.y = side * deg_to_rad(-78.0) * (1.0 - s)
		1:   # the hand slides the bolt home
			var s := clampf((_beat_t - 0.6) / 1.3, 0.0, 1.0)
			s = 1.0 - pow(1.0 - s, 3.0)
			_bolt.position.x = lerpf(3.6, 1.0, s)
			_bolt_hand.position = Vector3(_bolt.position.x + 1.25, 1.9, -0.45)
			# one after another they turn their backs on the gate and go in; where each one stood, a white shape
			# of them rises from the feet up, eyes bound, and stays there facing out
			for i in _inside.size():
				var p: Sprite3D = _inside[_order[i]]
				var dt := _beat_t - (1.3 + 2.1 * float(i) / _inside.size())
				if dt < 0.0:
					continue
				var spot: Vector3 = p.get_meta("spot")
				var col := int(p.get_meta("col"))
				var w := clampf(dt / 1.8, 0.0, 1.0)
				p.position = spot + Vector3(0, 0, -2.8 * w)
				p.frame = 3 * SHEET_COLS + (5 + int(dt * 9.0) % 8 if w < 1.0 else col)
				p.modulate = Color(0.96, 0.96, 1.0).lerp(Color(0.42, 0.42, 0.47), w)
				_climb_at(spot, p.get_meta("over"), 0, col, clampf((dt - 0.3) / 1.5, 0.0, 1.0))
		2:
			_update_runners()
			_update_arms()


# ------------------------------------------------------------------ the arms and the expelled (beat 2)
func _run_pos(r: Dictionary, t: float) -> Vector3:
	## Where runner r's feet are at beat time t: standing, then running off, picking up speed.
	var s := maxf(t - float(r["t_run"]), 0.0)
	var d := float(r["speed"]) * s * s / (s + 0.35)
	return (r["home"] as Vector3) + (r["dir"] as Vector3) * d


func _start_arms() -> void:
	## One arm for each of the three it catches (it closes on them exactly when they get there), and two that
	## fall short of ones who get away.
	var misses := [2, 5]
	for i in _outside.size():
		var r: Dictionary = _outside[i]
		var caught := float(r["catch"]) > 0.0
		if not caught and not misses.has(i):
			continue
		var t1: float = float(r["catch"]) if caught else 2.3 + i * 0.1
		var b := _run_pos(r, t1) + Vector3(0, 0.3, 0)
		var a := Vector3(clampf((r["home"] as Vector3).x * 0.6, -2.4, 2.4), 0.22, 0.05)
		var m := (a + b) * 0.5 + Vector3(0.9 if i % 2 else -0.9, 0.3 + (i % 3) * 0.12, 0.0)   # a low arch, coming down on them
		var hand := _sprite("res://assets/sprites/fx/reach_hand.png", 2, 0, Vector3.ZERO, 0.036)
		hand.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		hand.visible = false
		_arms.append({"p": [a, m, b], "t0": 0.1 + _arms.size() * 0.12, "t1": t1, "umax": 1.0 if caught else 0.7, "segs": [], "hand": hand})


func _update_runners() -> void:
	for r in _outside:
		var s: Sprite3D = r["spr"]
		var t := _beat_t
		var tc := float(r["catch"])
		var caught := tc > 0.0 and t >= tc
		s.position = _run_pos(r, minf(t, tc) if tc > 0.0 else t) + Vector3(0, 48 * B.PX * 0.5, 0)
		if caught:                                  # stopped dead mid-stride, and the porcelain climbs
			s.frame = SHEET_COLS + int(r["frozen"])
			_harden(r, t - tc)
		elif t >= float(r["t_run"]):                # turned from the gate, running (row 1: to the left of shot)
			var col := 13 + int((t - float(r["t_run"])) * 11.0) % 6
			s.frame = SHEET_COLS + col
			r["frozen"] = col
		else:                                       # still facing the gate (row 2: to the right of shot)
			s.frame = 2 * SHEET_COLS + int(r["col0"])


func _harden(r: Dictionary, dt: float) -> void:
	## A caught runner: porcelain rises from where the hand closed, at the feet, frozen mid-stride.
	var s: Sprite3D = r["spr"]
	if not r.has("over"):
		r["over"] = _climb_overlay("res://assets/sprites/chars/%s.png" % r["statue"], s.flip_h)
		(r["over"] as Sprite3D).modulate = Color(1.2, 1.2, 1.25)
	if r.get("done", false):
		return
	var k := clampf(dt / 1.1, 0.0, 1.0)
	_climb_at(s.position, r["over"], 1, int(r["frozen"]), k)
	if k >= 1.0:
		r["done"] = true
		s.texture = (r["over"] as Sprite3D).texture
		s.modulate = (r["over"] as Sprite3D).modulate


func _climb_overlay(tex: String, flip: bool) -> Sprite3D:
	var o := Sprite3D.new()
	o.texture = Assets.tex(tex)
	o.region_enabled = true
	o.pixel_size = B.PX
	o.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	o.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	o.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	o.flip_h = flip
	o.shaded = true
	o.visible = false
	root.add_child(o)
	return o


func _climb_at(centre: Vector3, o: Sprite3D, row: int, col: int, k: float) -> void:
	## Porcelain rising from the feet: the same frame cut from the porcelain sheet, k of the body tall, standing
	## where a person (centred at `centre`) stands or stood, a hair nearer the camera.
	o.visible = k > 0.0
	if not o.visible:
		return
	var hpx := maxi(1, int(round(48.0 * k)))
	o.region_rect = Rect2(col * 32, row * 48 + 48 - hpx, 32, hpx)
	var feet := centre - Vector3(0, 48 * B.PX * 0.5, 0)
	var to_cam := cam.global_position - feet
	to_cam.y = 0.0
	o.position = feet + Vector3(0, hpx * B.PX * 0.5, 0) + to_cam.normalized() * 0.03


func _arm_point(p: Array, u: float) -> Vector3:
	var a: Vector3 = p[0]
	var m: Vector3 = p[1]
	var b: Vector3 = p[2]
	return a.lerp(m, u).lerp(m.lerp(b, u), u)


func _face(s: Sprite3D, pos: Vector3, dir: Vector3) -> void:
	var cb := cam.global_transform.basis.orthonormalized()
	var ang := atan2(dir.dot(cb.y), dir.dot(cb.x))
	s.global_transform = Transform3D(Basis(cb.z, ang) * cb, pos)


func _update_arms() -> void:
	for arm in _arms:
		var t0 := float(arm["t0"])
		var t1 := float(arm["t1"])
		var k := clampf((_beat_t - t0) / (t1 - t0), 0.0, 1.0)
		var u := pow(k, 1.4) * float(arm["umax"])
		if _beat_t > t1 and float(arm["umax"]) < 1.0:          # fell short: it sags back a little
			u -= 0.08 * clampf((_beat_t - t1) / 1.0, 0.0, 1.0)
		var segs: Array = arm["segs"]
		var n := 24
		var used := 0
		var acc := 0.0
		var next := 0.0
		var prev := _arm_point(arm["p"], 0.0)
		for i in range(1, n + 1):
			var cur := _arm_point(arm["p"], u * float(i) / n)
			var L := prev.distance_to(cur)
			while L > 0.0001 and next <= acc + L:
				if used >= segs.size():
					var sg := _sprite("res://assets/sprites/fx/reach_segment.png", 2, 0, Vector3.ZERO, 0.034)
					sg.billboard = BaseMaterial3D.BILLBOARD_DISABLED
					segs.append(sg)
				var sgn: Sprite3D = segs[used]
				sgn.visible = true
				sgn.frame = 1 if used % 4 == 3 else 0
				_face(sgn, prev.lerp(cur, (next - acc) / L), cur - prev)
				used += 1
				next += 0.27
			acc += L
			prev = cur
		for j in range(used, segs.size()):
			(segs[j] as Sprite3D).visible = false
		var hand: Sprite3D = arm["hand"]
		hand.visible = u > 0.03
		hand.frame = 1 if _beat_t >= t1 else 0
		var tip := _arm_point(arm["p"], u)
		var back := _arm_point(arm["p"], maxf(u - 0.05, 0.0))
		_face(hand, tip + (tip - back).normalized() * 0.2, tip - back)
