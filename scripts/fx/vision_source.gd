extends Node
## The second Duyên glimpse of Trắng Tay (docs/N_bach_son.md 8.3): touching its hand at the camp, the protagonist
## sees not the gate but where it begins. Staged live like the first (scripts/fx/vision_gate.gd), from the game's
## own pieces, through the same ink filter. No words. Three beats:
##   0. From the camp at night, looking up: the white wall with its coping and merlons, and above it the city's
##      windows lit, white houses under dark roofs.
##   1. Closer: behind the ice-crack lattice, people stand at the lamplit windows looking down at the camp. A mother
##      draws her child back from the sill.
##   2. The doorsteps below the windows: one after another a white cup is set out on each step. At the windows the
##      people step back; where each stood, a white shape of them stays, a cobalt band over its eyes.

const B = preload("res://scripts/world/builder.gd")
const SHEET_COLS := 19

var viewport: SubViewport
var root: Node3D
var cam: Camera3D
var _watchers: Array = []      # {spr, over, spot, col, t}
var _cups: Array = []
var _merlons: Array = []
var _child: Sprite3D
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
	_place(Vector3(0.6, 0.8, 16.0), Vector3(0, 6.0, 0))


func _environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.2, 0.22, 0.28)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.6, 0.75)
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.3, 0.32, 0.4)
	env.fog_density = 0.02
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-35, 30, 0)
	moon.light_energy = 0.4
	moon.light_color = Color(0.7, 0.78, 1.0)
	moon.shadow_enabled = true
	root.add_child(moon)


func _build() -> void:
	# the city's own materials (scripts/world/bach_son.gd): lime never quite clean, black tile, granite, the camp's ash
	var white := B.mat("res://assets/tex/lime_wall.png", 0.75, Vector3.ONE, {"triplanar": true, "world": true, "tint": Color(0.9, 0.89, 0.87)})
	var white_old := B.mat("res://assets/tex/lime_wall_old.png", 0.75, Vector3.ONE, {"triplanar": true, "world": true, "tint": Color(0.86, 0.85, 0.83)})
	var dark := B.mat("res://assets/tex/roof_ink.png", 0.9, Vector3.ONE, {"triplanar": true, "world": true})
	var granite := B.mat("res://assets/tex/granite.png", 0.75, Vector3.ONE, {"triplanar": true, "world": true})
	var lamp := StandardMaterial3D.new()
	lamp.albedo_color = Color(0.95, 0.78, 0.46)
	lamp.emission_enabled = true
	lamp.emission = Color(1.0, 0.76, 0.42)
	lamp.emission_energy_multiplier = 1.6
	var lattice := StandardMaterial3D.new()
	lattice.albedo_texture = Assets.tex("res://assets/tex/lattice.png")
	lattice.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	lattice.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED   # the paper lit from inside
	lattice.albedo_color = Color(1.0, 0.86, 0.62)
	# the camp ground, the slope, the city wall: dark coping, merlons (as at the gate)
	B.box(root, Vector3(80, 0.2, 40), Vector3(0, -0.1, 12), B.mat("res://assets/tex/ash_ground.png", 0.75, Vector3.ONE, {"triplanar": true, "world": true, "tint": Color(0.62, 0.6, 0.58)}), 0.0, false)
	B.box(root, Vector3(40.0, 4.8, 2.2), Vector3(0, 2.4 + 2.0, -1.0), white_old, 0.0, false, 0.06)
	B.box(root, Vector3(40.0, 0.3, 2.5), Vector3(0, 7.2 + 0.15, -1.0), dark, 0.0, false)
	for k in 20:
		_merlons.append(B.box(root, Vector3(1.0, 0.7, 2.2), Vector3(-19.0 + k * 2.0, 7.85, -1.0), white, 0.0, false))
	B.box(root, Vector3(40.0, 2.0, 6.0), Vector3(0, 1.0, 1.0), granite, 0.0, false)
	# the houses above, fronts to the camp: white walls, dark roofs, windows lit behind the lattice
	var fronts := [[-6.5, -4.0, 5.2], [0.0, -4.6, 6.0], [6.6, -4.0, 5.0]]
	for f in fronts:
		var x: float = f[0]
		var z: float = f[1]
		var w: float = f[2]
		B.box(root, Vector3(w, 6.0, 3.0), Vector3(x, 7.0 + 3.0, z), white, 0.0, false, 0.05)
		B.roof(root, w + 0.6, 2.0, 2.0, 13.0, 14.3, Vector3(x, 0, z), "res://assets/tex/roof_ink.png")   # (its own tiles)
		for wx in [-w * 0.25, w * 0.25]:
			var lit := MeshInstance3D.new()
			var q := QuadMesh.new()
			q.size = Vector2(1.1, 1.3)
			lit.mesh = q
			lit.material_override = lamp
			lit.position = Vector3(x + wx, 10.6, z + 1.52)
			root.add_child(lit)
			var lat := MeshInstance3D.new()
			var q2 := QuadMesh.new()
			q2.size = Vector2(1.1, 1.3)
			lat.mesh = q2
			lat.material_override = lattice
			lat.position = Vector3(x + wx, 10.6, z + 1.62)
			root.add_child(lat)
			var glow := OmniLight3D.new()
			glow.light_color = Color(1.0, 0.78, 0.5)
			glow.light_energy = 1.2
			glow.omni_range = 3.5
			glow.position = Vector3(x + wx, 10.6, z + 2.2)
			root.add_child(glow)
			# someone at the window, looking down: head and shoulders dark against the lamp, behind the lattice
			var tex := "res://assets/sprites/chars/bs_w.png" if int(x + wx) % 2 == 0 else "res://assets/sprites/chars/bs_m.png"
			# their shadow on the lamplit paper
			var s := _bust(tex, Vector3(x + wx, 10.45, z + 1.66))
			s.modulate = Color(0.26, 0.21, 0.18)
			_watchers.append({"spr": s, "spot": s.position, "tex": tex, "over": null})
		# the doorstep under each house, granite, waiting for its cup
		B.box(root, Vector3(1.6, 0.25, 0.7), Vector3(x, 7.1, z + 1.9), granite, 0.0, false)
		var cup := _sprite("res://assets/sprites/props/cup_step.png", 1, 0, Vector3(x + 0.2, 7.42, z + 1.9), 0.055)
		cup.visible = false
		_cups.append(cup)
	# a child at the sill of the middle house's right window (drawn back from it in beat 1)
	_child = _bust("res://assets/sprites/chars/co.png", Vector3(1.5 + 0.12, 10.3, -4.6 + 1.67))
	_child.modulate = Color(0.26, 0.21, 0.18)
	# the camp below in the foreground: three fires, tents
	for fp in [Vector3(-4.0, 0, 9.0), Vector3(3.0, 0, 8.0), Vector3(8.0, 0, 10.0)]:
		var fire := _sprite("res://assets/sprites/props/fire.png", 4, 0, fp + Vector3(0, 0.3, 0), 0.03)
		fire.shaded = false
		var fl := OmniLight3D.new()
		fl.light_color = Color(1.0, 0.6, 0.3)
		fl.light_energy = 2.0
		fl.omni_range = 5.0
		fl.position = fp + Vector3(0, 0.8, 0)
		root.add_child(fl)


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


func _bust(tex: String, centre: Vector3) -> Sprite3D:
	## Head and shoulders of a front-facing frame, cut to fit inside a window.
	var s := Sprite3D.new()
	s.texture = Assets.tex(tex)
	s.region_enabled = true
	s.region_rect = Rect2(5, 0, 22, 26)
	s.pixel_size = B.PX
	s.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.shaded = false
	s.position = centre
	root.add_child(s)
	return s


func _person(tex: String, feet: Vector3, row: int, col: int) -> Sprite3D:
	var s := _sprite(tex, SHEET_COLS, 0, feet + Vector3(0, 48 * B.PX * 0.5, 0), B.PX)
	s.vframes = 4
	s.frame = row * SHEET_COLS + col
	s.shaded = true
	return s


func beat(i: int) -> float:
	_beat = i
	_beat_t = 0.0
	match i:
		0:
			_move(Vector3(0.6, 0.8, 16.0), Vector3(0, 6.0, 0), Vector3(0.4, 1.4, 13.5), Vector3(0, 8.5, -2.0), 3.4)
			return 3.4
		1:
			_move(Vector3(1.6, 10.4, 4.2), Vector3(0.2, 10.2, -4.0), Vector3(1.2, 10.3, 3.2), Vector3(0.4, 10.1, -4.0), 4.4)
			return 4.4
		2:
			for mm in _merlons:   # from up here the steps, not the parapet
				(mm as Node3D).visible = false
			_move(Vector3(-1.6, 12.6, 4.6), Vector3(0.0, 8.4, -2.6), Vector3(-1.0, 12.2, 3.8), Vector3(0.0, 8.8, -2.6), 4.8)
			return 4.8
	return 1.0


func _place(pos: Vector3, look: Vector3) -> void:
	cam.global_transform = Transform3D(Basis(), pos).looking_at(look, Vector3.UP)


func _move(p0: Vector3, l0: Vector3, p1: Vector3, l1: Vector3, dur: float) -> void:
	_cam_from = Transform3D(Basis(), p0).looking_at(l0, Vector3.UP)
	_cam_to = Transform3D(Basis(), p1).looking_at(l1, Vector3.UP)
	_cam_dur = dur + 0.6
	cam.global_transform = _cam_from


func _process(delta: float) -> void:
	_beat_t += delta
	if _beat < 0:
		return
	var k := clampf(_beat_t / _cam_dur, 0.0, 1.0)
	cam.global_transform = _cam_from.interpolate_with(_cam_to, k)
	match _beat:
		1:   # a hand draws the child back from the sill
			var s := clampf((_beat_t - 1.6) / 1.0, 0.0, 1.0)
			_child.position.y = 10.3 - 0.35 * s
			_child.modulate.a = 1.0 - s
		2:   # a cup on each step; at the windows they step back, and white shapes with bound eyes stay
			for i in _cups.size():
				(_cups[i] as Sprite3D).visible = _beat_t > 0.6 + i * 0.7
			for i in _watchers.size():
				var w: Dictionary = _watchers[i]
				var dt := _beat_t - (1.6 + i * 0.35)
				if dt < 0.0:
					continue
				var spr: Sprite3D = w["spr"]
				spr.modulate.a = 1.0 - clampf(dt / 1.0, 0.0, 1.0)
				if w["over"] == null:
					var o := _bust((w["tex"] as String).replace(".png", "_blind.png"), (w["spot"] as Vector3) + Vector3(0, 0, 0.01))
					o.modulate = Color(1.1, 1.1, 1.15, 0.0)
					w["over"] = o
				(w["over"] as Sprite3D).modulate.a = clampf(dt / 1.4, 0.0, 1.0)
