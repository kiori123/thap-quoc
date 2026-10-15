extends Node3D
## Village life that runs on its own: hens in the yard (they scatter when you walk at them),
## butterflies round the flowers, a flock crossing now and then with its shadow sweeping the ground,
## and two villagers going about their errands. Only out in the daytime.

const B = preload("res://scripts/world/builder.gd")

const YARD := Rect2(11.0, 1.2, 11.5, 5.8)   # x, z of the old man's yard where the hens roam
const DAY_TIMES := ["dawn", "day"]

var world
var _hens := []
var _flies := []
var _birds: Node3D
var _bird_list: Array[Sprite3D] = []
var _flock_t := 6.0
var _flock_dir := Vector3.ZERO
var _flock_on := false
var _walkers := []
var _rng := RandomNumberGenerator.new()


func setup(w) -> void:
	world = w
	_rng.seed = 404
	for i in 5:
		_add_hen(["brown", "white", "brown", "black", "brown"][i])
	var spots := [world.HOUSE + Vector3(-6.8, 0, 4.0), world.HOUSE + Vector3(6.6, 0, 7.0), world.VILLAGE + Vector3(4.5, 0, 1.5),
		world.VILLAGE + Vector3(-5.0, 0, 2.5), Vector3(-12, 0, 6.5), Vector3(4, 0, -3)]
	for i in spots.size():
		_add_butterfly(spots[i], i)
	_birds = Node3D.new()
	add_child(_birds)
	for i in 6:
		var s := Sprite3D.new()
		s.texture = Assets.tex("res://assets/sprites/props/bird.png")
		s.hframes = 2
		s.pixel_size = 0.07
		s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		s.shaded = false
		s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		s.position = Vector3((i % 2) * 1.6 - 0.8, i * 0.15, -i * 1.3)
		_birds.add_child(s)
		_bird_list.append(s)
	_birds.visible = false
	_add_walker("amb_w", "res://assets/sprites/chars/dan_w.png",
		[Vector3(-8.5, 0, -1.2), Vector3(-13, 0, 1.2), Vector3(-17.2, 0, 3.1), Vector3(-13, 0, 1.2)])
	_add_walker("amb_m", "res://assets/sprites/chars/dan_m.png",
		[Vector3(2.0, 0, -12.3), Vector3(-5, 0, -10.8), Vector3(-7.6, 0, -2.5), Vector3(-4.6, 0, 2.2), Vector3(2.0, 0, 7.2),
		 Vector3(-4.6, 0, 2.2), Vector3(-7.6, 0, -2.5), Vector3(-5, 0, -10.8)])


func _day() -> bool:
	return world.time_name in DAY_TIMES


# ------------------------------------------------------------------ hens
func _add_hen(variant: String) -> void:
	var s := Sprite3D.new()
	s.texture = Assets.tex("res://assets/sprites/props/chicken_%s.png" % variant)
	s.hframes = 4
	s.pixel_size = B.PX
	s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.shaded = true
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(s)
	B.lit_sprite(s)
	var p := Vector3(_rng.randf_range(YARD.position.x, YARD.end.x), 0, _rng.randf_range(YARD.position.y, YARD.end.y))
	_hens.append({"s": s, "p": p, "target": p, "state": "peck", "t": _rng.randf_range(0.5, 2.0), "anim": 0.0, "hop": 0.0})


func _update_hens(delta: float, player: Vector3, active: bool) -> void:
	for h in _hens:
		var s: Sprite3D = h["s"]
		s.visible = active
		if not active:
			continue
		var p: Vector3 = h["p"]
		var to_player := Vector2(p.x - player.x, p.z - player.z)
		var scared: bool = world.control_enabled and to_player.length() < 1.9
		if scared and h["state"] != "flee":
			h["state"] = "flee"
			var away := to_player.normalized() if to_player.length() > 0.01 else Vector2(1, 0)
			away = away.rotated(_rng.randf_range(-0.6, 0.6))
			h["target"] = _clamp_yard(p + Vector3(away.x, 0, away.y) * _rng.randf_range(2.6, 3.6))
			h["hop"] = 0.0
		h["t"] -= delta
		h["anim"] += delta
		var speed := 0.0
		match h["state"]:
			"walk":
				speed = 0.75
			"flee":
				speed = 2.8
				h["hop"] += delta
			"peck", "idle":
				speed = 0.0
		var tgt: Vector3 = h["target"]
		var d := Vector3(tgt.x - p.x, 0, tgt.z - p.z)
		if speed > 0.0:
			if d.length() < 0.08:
				h["state"] = "peck" if _rng.randf() < 0.6 else "idle"
				h["t"] = _rng.randf_range(0.8, 2.6)
			else:
				var step := minf(speed * delta, d.length())
				p += d.normalized() * step
				if absf(d.x) > 0.02:
					s.flip_h = d.x > 0.0
					(s.material_override as ShaderMaterial).set_shader_parameter("flip_x", s.flip_h)
		elif h["t"] <= 0.0:
			h["state"] = "walk"
			h["target"] = _clamp_yard(p + Vector3(_rng.randf_range(-2.5, 2.5), 0, _rng.randf_range(-1.8, 1.8)))
		h["p"] = p
		var frame := 0
		var hop := 0.0
		match h["state"]:
			"walk":
				frame = int(h["anim"] * 7.0) % 2
			"flee":
				frame = int(h["anim"] * 16.0) % 2
				hop = absf(sin(h["hop"] * 11.0)) * 0.12
			"peck":
				frame = 2 + int(h["anim"] * 3.5) % 2
			_:
				frame = 0
		s.frame = frame
		s.position = Vector3(p.x, 0.0, p.z) + Vector3(0, 14 * B.PX * 0.5 - B.PX + hop, 0)


func _clamp_yard(p: Vector3) -> Vector3:
	return Vector3(clampf(p.x, YARD.position.x, YARD.end.x), 0, clampf(p.z, YARD.position.y, YARD.end.y))


# ------------------------------------------------------------------ butterflies
func _add_butterfly(anchor: Vector3, i: int) -> void:
	var s := Sprite3D.new()
	s.texture = Assets.tex("res://assets/sprites/props/butterfly.png")
	s.hframes = 4
	s.pixel_size = 0.03
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.shaded = false
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(s)
	_flies.append({"s": s, "a": anchor, "k": float(i) * 1.7, "col": (i % 2) * 2})


func _update_flies(t: float, active: bool) -> void:
	for f in _flies:
		var s: Sprite3D = f["s"]
		s.visible = active
		if not active:
			continue
		var k: float = f["k"]
		var a: Vector3 = f["a"]
		s.position = a + Vector3(sin(t * 0.7 + k) * 1.6 + sin(t * 1.9 + k * 2.0) * 0.4, 0.7 + sin(t * 1.3 + k) * 0.35 + absf(sin(t * 6.0 + k)) * 0.12,
			cos(t * 0.53 + k) * 1.1)
		s.frame = int(f["col"]) + (int(t * 11.0 + k * 3.0) % 2)


# ------------------------------------------------------------------ the flock
func _update_flock(delta: float, t: float) -> void:
	if not _flock_on:
		_flock_t -= delta
		if _flock_t <= 0.0 and world.time_name in ["dawn", "day", "dusk", "dawn2"] and world.rig and world.rig.cam:
			# cross the area the camera is looking at, high enough to clear the trees
			var cam: Camera3D = world.rig.cam
			var focus := cam.global_position - cam.global_basis.z * 14.0
			var ang := _rng.randf_range(-0.5, 0.5)
			_flock_dir = Vector3(cos(ang), 0, sin(ang) * 0.6).normalized()
			if _rng.randf() < 0.5:
				_flock_dir = -_flock_dir
			_birds.global_position = Vector3(focus.x, 0, focus.z) - _flock_dir * 45.0 + Vector3(0, _rng.randf_range(9.0, 13.0), 0)
			_birds.look_at(_birds.global_position + _flock_dir, Vector3.UP)
			_birds.visible = true
			_flock_on = true
		return
	_birds.global_position += _flock_dir * 8.5 * delta
	for i in _bird_list.size():
		var glide := sin(t * 0.9 + i) > 0.55
		_bird_list[i].frame = 0 if glide else int(t * 7.0 + i * 0.7) % 2
		_bird_list[i].flip_h = _flock_dir.x < 0.0
	var cam: Camera3D = world.rig.cam
	var focus := cam.global_position - cam.global_basis.z * 14.0
	var along := (_birds.global_position - focus).dot(_flock_dir)
	if along > 50.0:
		_birds.visible = false
		_flock_on = false
		_flock_t = _rng.randf_range(16.0, 30.0)


# ------------------------------------------------------------------ villagers on errands
func _add_walker(id: String, sheet: String, route: Array) -> void:
	var a = world.spawn(id, sheet, route[0], "down")
	a.speed_walk = 1.6
	_walkers.append(a)
	_walk_loop(a, route)


func _walk_loop(a, route: Array) -> void:
	var i := 1
	while is_instance_valid(a):
		if not _day() or not world.visible:
			a.visible = false
			await get_tree().create_timer(1.0).timeout
			continue
		a.visible = true
		await a.move_to(route[i])
		if not is_instance_valid(a):
			return
		a.face(["down", "left", "right"][_rng.randi() % 3])
		await get_tree().create_timer(_rng.randf_range(1.5, 4.0)).timeout
		i = (i + 1) % route.size()


func _process(delta: float) -> void:
	if world == null or not world.visible:
		return
	var t := Time.get_ticks_msec() / 1000.0
	var player: Vector3 = world.hero.global_position if world.hero else Vector3(0, -100, 0)
	_update_hens(delta, player, world.time_name in ["dawn", "day", "dawn2"])
	_update_flies(t, _day())
	_update_flock(delta, t)
