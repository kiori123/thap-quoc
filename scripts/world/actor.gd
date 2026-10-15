extends CharacterBody3D
## A pixel character standing in the 3D world (a Y-billboarded Sprite3D lit as if it had a body, shaders/sprite_lit.gdshader,
## casting its own shape as shadow).
## Walk sheets: rows 0 down, 1 left, 2 right, 3 up; cols 0-3 idle (breathing), 4 blink, 5-12 walk, 13-18 run.

const B = preload("res://scripts/world/builder.gd")
const SHEET_COLS := 19
const COL_BLINK := 4
const COL_WALK := 5
const COL_RUN := 13
const ACT_SHEET := "res://assets/sprites/chars/hero_act.png"
const ACT_FRAMES := 21
const ACT := {"ready": 0, "windup": 1, "strike": 2, "follow": 3, "sweep_wind": 4, "sweep_strike": 5, "guard": 6,
	"hurt": 7, "item": 8, "kneel": 9, "broom_a": 10, "broom_b": 11, "ready_b": 12, "windup_deep": 13, "smear": 14,
	"recover": 15, "sweep_smear": 16, "parry": 17, "hurt_b": 18, "thau": 19, "victory": 20}
## Emote sheets (<sheet>_emo.png, tools/art/chars.py EMOTES, in this order): rows 0 down, 1 left, 2 right; two columns
## per emote, the second a breath (or the shake of a laugh, of crying, the wave of a hand).
const EMOTES := ["smile", "beam", "laugh", "sad", "cry", "despair", "angry", "surprise", "shock", "worry", "scared",
	"think", "bow", "nod", "clasp", "cross", "behind", "chest", "point", "shrug", "wave", "resolve", "sigh", "sheepish",
	"cold", "stern", "give", "listen"]
## momentary ones: they end when the same person speaks again without asking for one (a laugh does not outlast its line)
const EMO_MOMENT := ["laugh", "surprise", "shock", "wave", "nod", "bow", "point", "shrug", "sheepish", "give", "beam"]
const EMO_FAST := {"laugh": 4.0, "cry": 2.6, "despair": 2.6, "wave": 3.2, "scared": 2.2}
const WALK_STRIDE := 1.9   # metres per full walk cycle (two steps)
const RUN_STRIDE := 2.4

var id := ""
var sheet_path := ""
var act_sheet := ACT_SHEET   # the hero's action frames: the axe in the valley; the old sword from Bạch Sơn on
var sprite: Sprite3D
var pose_sprite: Sprite3D     # used for special frames from other sheets
var blob: MeshInstance3D
var facing := "down":
	set(v):
		if v != facing and _opposite(v, facing):
			_turn_t = 0.09
			_turn_row = 0 if v in ["left", "right"] else (2 if facing == "left" else 1)
		facing = v
var moving := false
var running := false
var ground_fn := Callable()  # Vector3 -> float, floor height under a point
var speed_walk := 3.2
var speed_run := 5.4
var _anim_t := 0.0
var _step_t := 0.0
var _pose_active := false
var _emote: Label3D
var _emote_tw: Tween
var footsteps := false
var _turn_t := 0.0
var _turn_row := 0
var _phase := 0.0
var _last_pos := Vector3.ZERO
var _blink_t := 3.0
var _dust: GPUParticles3D
var emo_name := ""          # the emote shown ("" none)
var _emo_path := ""
var _emo_t := 0.0
var _emo_row := -1
var _bob_tw: Tween


func setup(actor_id: String, sheet: String) -> void:
	id = actor_id
	sheet_path = sheet
	_emo_path = sheet.get_basename() + "_emo.png"
	if not FileAccess.file_exists(_emo_path):
		_emo_path = ""
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	collision_layer = 2
	collision_mask = 1
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.28
	cap.height = 1.2
	cs.shape = cap
	cs.position.y = 0.6
	add_child(cs)
	sprite = _mk_sprite(Assets.tex(sheet), SHEET_COLS, 4, sheet)
	pose_sprite = _mk_sprite(null, 1, 1)
	pose_sprite.visible = false
	# soft shade on the ground where the figure stands, darkest under the feet
	blob = MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.8, 0.4)
	blob.mesh = qm
	blob.rotation_degrees.x = -90
	blob.position.y = 0.02
	var m := StandardMaterial3D.new()
	m.albedo_texture = _foot_shade()
	m.albedo_color = Color(0, 0, 0, 0.62)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	blob.material_override = m
	blob.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(blob)
	_dust = B.particles(self, "res://assets/sprites/props/smoke.png", 10, 0.55, Vector3(0.12, 0.02, 0.12), Vector3(0, 0.08, 0),
		{"spread": 70.0, "vmin": 0.3, "vmax": 0.7, "dir": Vector3(0, 0.6, 0), "size": 0.32, "smin": 0.5, "smax": 1.0,
		"gravity": Vector3(0, -0.4, 0), "color": Color(0.82, 0.74, 0.62, 0.55)})
	_dust.local_coords = false
	_dust.emitting = false
	_dust.preprocess = 0.0
	_blink_t = randf_range(1.0, 4.0)
	_update_frame()


static func _opposite(a: String, b: String) -> bool:
	return (a == "left" and b == "right") or (a == "right" and b == "left") or (a == "up" and b == "down") or (a == "down" and b == "up")


static var _shade_t: GradientTexture2D


static func _foot_shade() -> GradientTexture2D:
	if _shade_t == null:
		_shade_t = GradientTexture2D.new()
		_shade_t.fill = GradientTexture2D.FILL_RADIAL
		_shade_t.fill_from = Vector2(0.5, 0.5)
		_shade_t.fill_to = Vector2(1.0, 0.5)
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.35, Color(1, 1, 1, 0.7))
		_shade_t.gradient = g
	return _shade_t


func _lit(s: Sprite3D, path := "") -> void:
	## The sprite drawn through shaders/sprite_lit.gdshader: its sheet, its frame grid, and its normal map
	## (<sheet>_n.png beside it, tools/art/gen_chars.py) when there is one.
	var m := s.material_override as ShaderMaterial
	if m == null:
		m = ShaderMaterial.new()
		m.shader = Assets.shader("res://shaders/sprite_lit.gdshader")
		s.material_override = m
	if s.texture:
		m.set_shader_parameter("tex", s.texture)
	m.set_shader_parameter("frames", Vector2(s.hframes, s.vframes))
	var np_path := path.get_basename() + "_n.png" if path != "" else ""
	var has := np_path != "" and FileAccess.file_exists(np_path)
	m.set_shader_parameter("has_n", has)
	if has:
		m.set_shader_parameter("ntex", Assets.tex(np_path))
	m.set_shader_parameter("flip_x", s.flip_h)


func _mk_sprite(t: Texture2D, hf: int, vf: int, path := "") -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = t
	s.hframes = hf
	s.vframes = vf
	s.pixel_size = B.PX
	s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.shaded = true
	s.double_sided = true
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	s.position.y = (24 - 2) * B.PX
	add_child(s)
	_lit(s, path)
	return s


func _row() -> int:
	if _turn_t > 0.0:
		return _turn_row
	match facing:
		"left": return 1
		"right": return 2
		"up": return 3
	return 0


func _update_frame() -> void:
	if sprite == null:
		return
	var col := 0
	if moving:
		if running:
			col = COL_RUN + int(_phase * 6.0) % 6
		else:
			col = COL_WALK + int(_phase * 8.0) % 8
	elif _blink_t < 0.13:
		col = COL_BLINK
	else:
		col = int(_anim_t * 2.2) % 4
	sprite.frame = _row() * SHEET_COLS + col


func _process(delta: float) -> void:
	_anim_t += delta
	_turn_t -= delta
	_blink_t -= delta
	if _blink_t < -0.05:
		_blink_t = randf_range(2.2, 5.5)
	# the walk cycle follows the ground actually covered, so feet never slide
	var p := global_position
	var flat := Vector2(p.x - _last_pos.x, p.z - _last_pos.z).length()
	_last_pos = p
	if flat > 1.5:
		flat = 0.0  # teleported
	var before := _phase
	if moving:
		_phase += flat / (RUN_STRIDE if running else WALK_STRIDE)
	else:
		_phase = 0.0
	if emo_name != "":
		if moving:
			clear_emo()
		else:
			_emo_t += delta
			_emo_frame()
	if not _pose_active:
		_update_frame()
	if moving and footsteps and int(before * 2.0) != int(_phase * 2.0):
		Audio.sfx("step", -10.0, 0.15)   # (under the music, but there in the quiet)
	if _dust:
		_dust.emitting = moving and running and visible and not _pose_active


func face(dir: String) -> void:
	facing = dir
	_update_frame()


func face_point(p: Vector3) -> void:
	var d := p - global_position
	if abs(d.x) > abs(d.z):
		facing = "right" if d.x > 0 else "left"
	else:
		facing = "down" if d.z > 0 else "up"
	_update_frame()


func dir_from_vec(v: Vector3) -> String:
	if abs(v.x) > abs(v.z) * 0.9:
		return "right" if v.x > 0 else "left"
	return "down" if v.z > 0 else "up"


var _move_tw: Tween


func move_to(target: Vector3, speed := -1.0, run := false) -> void:
	## Cutscene movement (ignores collisions). await actor.move_to(p)
	var spd := speed if speed > 0 else (speed_run if run else speed_walk)
	if Game.fast:
		spd *= 4.0
	target.y = ground_fn.call(target) if ground_fn.is_valid() else global_position.y
	var dist := global_position.distance_to(target)
	if dist < 0.02:
		return
	facing = dir_from_vec(target - global_position)
	moving = true
	running = run
	clear_pose()
	var tw := create_tween()
	_move_tw = tw
	tw.tween_property(self, "global_position", target, dist / spd)
	await tw.finished
	moving = false
	running = false
	_update_frame()


func stop_move() -> void:
	## Drop a cutscene walk still in progress (one nobody awaits), e.g. before placing the actor for a new scene.
	if _move_tw and _move_tw.is_valid():
		_move_tw.kill()
	moving = false
	running = false
	_update_frame()


func set_pose(tex_path: String, hframes: int, frame: int, flip := false, vframes := 1) -> void:
	emo_name = ""
	pose_sprite.texture = Assets.tex(tex_path)
	pose_sprite.hframes = hframes
	pose_sprite.vframes = vframes
	pose_sprite.frame = frame
	pose_sprite.flip_h = flip
	_lit(pose_sprite, tex_path)
	pose_sprite.visible = true
	sprite.visible = false
	_pose_active = true


func act(pose_name: String) -> void:
	## Show one frame of the hero's action sheet.
	set_pose(act_sheet, ACT_FRAMES, ACT[pose_name])


func emo(name: String) -> void:
	## A face and body language from this person's emote sheet (EMOTES), held, breathing, until another emote, a walk,
	## clear_emo(), or (for a momentary one) their next line. "" or "none" clears. Not over a pose a scene set (sitting,
	## the axe); facing away from the camera the back shows nothing of it.
	if name == "" or name == "none":
		clear_emo()
		return
	if _emo_path == "" or (_pose_active and emo_name == "") or moving:
		return
	var i := EMOTES.find(name)
	if i < 0:
		push_warning("emote not in the sheet: " + name)
		return
	emo_name = name
	_emo_t = 0.0
	_emo_row = -2
	_emo_frame()


func _emo_frame() -> void:
	var row := {"down": 0, "left": 1, "right": 2}.get(facing, -1) as int
	if row < 0:   # (the back: the plain sheet)
		if _pose_active:
			pose_sprite.visible = false
			sprite.visible = true
			_pose_active = false
		_emo_row = row
		return
	var ph := int(_emo_t * EMO_FAST.get(emo_name, 1.1)) % 2
	var f := row * EMOTES.size() * 2 + EMOTES.find(emo_name) * 2 + ph
	if _emo_row != row or not _pose_active:
		var keep := emo_name
		set_pose(_emo_path, EMOTES.size() * 2, f, false, 3)
		emo_name = keep
		_emo_row = row
	else:
		pose_sprite.frame = f


func clear_emo() -> void:
	if emo_name == "":
		return
	emo_name = ""
	clear_pose()


func end_moment() -> void:
	## Their next line, with no emote asked for: a momentary one (a laugh, a nod) is over.
	if emo_name in EMO_MOMENT:
		clear_emo()


func speak_bob() -> void:
	## A small lift as a line begins, so who is speaking reads at a glance (not out of a pose a scene set: lying down,
	## sitting).
	if moving or (_pose_active and emo_name == ""):
		return
	if _bob_tw and _bob_tw.is_valid():
		_bob_tw.kill()
	var y0 := (24 - 2) * B.PX
	_bob_tw = create_tween()
	for s in [sprite, pose_sprite]:
		s.position.y = y0
	_bob_tw.tween_method(func(v: float):
		sprite.position.y = y0 + v
		pose_sprite.position.y = y0 + v, 0.0, B.PX * 1.5, 0.07).set_trans(Tween.TRANS_SINE)
	_bob_tw.tween_method(func(v: float):
		sprite.position.y = y0 + v
		pose_sprite.position.y = y0 + v, B.PX * 1.5, 0.0, 0.12).set_trans(Tween.TRANS_SINE)


func clear_pose() -> void:
	emo_name = ""
	if not _pose_active:
		return
	pose_sprite.visible = false
	sprite.visible = true
	_pose_active = false
	_update_frame()


func emote(text: String, hold := 1.2, color := Color(1, 0.95, 0.8)) -> void:
	# a new emote replaces the last one: stop its tween too, so nothing calls into the freed label
	if _emote_tw and _emote_tw.is_valid():
		_emote_tw.kill()
	if is_instance_valid(_emote):
		_emote.queue_free()
	_emote = B.label3d(self, text, Vector3(0, 2.15, 0), 64, color)
	var tw := create_tween()
	_emote_tw = tw
	_emote.position.y = 1.9
	tw.tween_property(_emote, "position:y", 2.2, 0.25).set_trans(Tween.TRANS_BACK)
	tw.tween_interval(hold)
	tw.tween_property(_emote, "modulate:a", 0.0, 0.3)
	tw.tween_callback(_emote.queue_free)


func flash(times := 2) -> void:
	var target: Sprite3D = pose_sprite if _pose_active else sprite
	for i in times:
		target.modulate = Color(3, 3, 3)
		await get_tree().create_timer(0.05).timeout
		target.modulate = Color.WHITE
		await get_tree().create_timer(0.05).timeout


func set_tint(c: Color) -> void:
	sprite.modulate = c
	pose_sprite.modulate = c
