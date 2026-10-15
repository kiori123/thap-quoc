extends Node3D
## A porcelain arm for cutscenes, built from the same links and hand as Trắng Tay's arms in battle.
## It grows out along a curve from `a` (where it comes from) through `m` to `b`, feels about while it is out
## (it cannot see: `grope` is how far the hand wanders), closes, and draws back.
##   var arm = ReachArm.new(); world.add_child(arm); arm.setup(a, m, b, 0.3)
##   await arm.reach(1.2); arm.grip(); await arm.retract(0.8)

const SEG := "res://assets/sprites/fx/reach_segment.png"
const HAND := "res://assets/sprites/fx/reach_hand.png"
const STEP := 0.4                  # metres between links

signal arrived

var a := Vector3.ZERO
var m := Vector3.ZERO
var b := Vector3.ZERO
var grope := 0.0
var tint := Color.WHITE
var u := 0.0                       # how far out it is along the curve (0..1)
var _mode := ""
var _k := 0.0
var _dur := 1.0
var _clock := 0.0
var _ph := randf() * TAU
var _segs: Array[Sprite3D] = []
var _hand: Sprite3D


func setup(from: Vector3, mid: Vector3, to: Vector3, wander := 0.0) -> void:
	a = from
	m = mid
	b = to
	grope = wander


func _ready() -> void:
	_hand = _sprite(HAND, 0.05, 7)
	_hand.visible = false


func _sprite(tex: String, px: float, prio: int) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = Assets.tex(tex)
	s.hframes = 2
	s.pixel_size = px
	s.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.no_depth_test = true
	s.shaded = false   # self-lit, like Trắng Tay
	s.render_priority = prio
	s.modulate = tint
	add_child(s)
	return s


func reach(t: float) -> void:
	_mode = "reach"
	_k = 0.0
	_dur = maxf(t * (0.3 if Game.fast else 1.0), 0.05)
	await arrived


func reaching() -> bool:
	return _mode == "reach"


func grip() -> void:
	## The hand closes on what it found, and stops feeling about.
	_hand.frame = 1
	b = _tip_target()
	grope = 0.0


func retract(t := 0.7) -> void:
	_mode = "retract"
	_dur = maxf(t * (0.3 if Game.fast else 1.0), 0.05)
	while u > 0.0:
		await get_tree().process_frame
	queue_free()


func hand_position() -> Vector3:
	return _point(u)


func _tip_target() -> Vector3:
	return b + Vector3(sin(_clock * 2.6 + _ph), 0.0, cos(_clock * 1.9 + _ph)) * grope


func _point(v: float) -> Vector3:
	var bb := _tip_target()
	return a.lerp(m, v).lerp(m.lerp(bb, v), v)


func _face(s: Sprite3D, pos: Vector3, dir: Vector3) -> void:
	## Flat to the camera, its +x running along `dir` on screen.
	var cb: Basis = get_viewport().get_camera_3d().global_transform.basis.orthonormalized()
	var ang := atan2(dir.dot(cb.y), dir.dot(cb.x))
	s.global_transform = Transform3D(Basis(cb.z, ang) * cb, pos)


func _process(delta: float) -> void:
	_clock += delta
	match _mode:
		"reach":
			_k = minf(1.0, _k + delta / _dur)
			u = 1.0 - pow(1.0 - _k, 2.2)   # shoots out, slows as it arrives
			if _k >= 1.0:
				_mode = "hold"
				arrived.emit()
		"retract":
			u = maxf(0.0, u - delta / _dur)
	var n := 28
	var pts: Array[Vector3] = []
	for i in n + 1:
		pts.append(_point(u * float(i) / n))
	var used := 0
	var acc := 0.0
	var next := 0.0
	for i in n:
		var p0 := pts[i]
		var p1 := pts[i + 1]
		var L := p0.distance_to(p1)
		while L > 0.0001 and next <= acc + L:
			if used >= _segs.size():
				_segs.append(_sprite(SEG, 0.052, 6))
			var sg := _segs[used]
			sg.visible = true
			sg.frame = 1 if used % 5 == 4 else 0
			_face(sg, p0.lerp(p1, (next - acc) / L), p1 - p0)
			used += 1
			next += STEP
		acc += L
	for i in range(used, _segs.size()):
		_segs[i].visible = false
	var dir := pts[n] - pts[n - 1]
	if dir.length() < 0.0001:
		dir = b - a
	_face(_hand, pts[n] + dir.normalized() * 0.32, dir)
	_hand.visible = u > 0.02
