extends Node3D
## Tilted perspective camera that follows a target, with tilt-shift depth of field and shake.

var cam: Camera3D
var target: Node3D
var offset := Vector3(0, 7.0, 10.6)
var look_offset := Vector3(0, 0.9, 0)
var smooth := 3.6
var bounds := Rect2(-60, -45, 120, 90)
var _focus_point := Vector3.ZERO
var _manual := false
var _shake := 0.0
var _shake_t := 0.0
var attrs: CameraAttributesPractical
var _lead := Vector3.ZERO
var _last_tp := Vector3.ZERO
var _vel := Vector3.ZERO


var _move: Tween          # the cutscene move in progress (a new move or a cut replaces it)
var see_through := true   # leaves between the camera and the player thin out (off only to compare, in tests)
var dof_focus = null      # a point to keep sharp instead of what the camera looks at (cutscenes); null = the usual
# HD-2D scale (Octopath): the world is the picture and the people small in it, so a sprite's pixel is about the size
# of the ground's. The follow camera stands zoom_out times its old distance (1.6: a person about an eighth of the
# screen's height, the city still full around them). The framing helpers (frame, frame_pair, focus) pull back more
# (a close two-shot was half the screen), never past CUT_MAX; a shot placed by hand (view_to, set_view) stays as
# it was composed.
var zoom_out := 1.6
const CUT_MAX := 24.0


func _ready() -> void:
	cam = Camera3D.new()
	cam.fov = 32.0
	for a in OS.get_cmdline_user_args():   # look development: --cam=2.2 --fov=26
		if a.begins_with("--cam="):   # 1 = the old, close camera
			zoom_out = float(a.split("=")[1])
		elif a.begins_with("--fov="):
			cam.fov = float(a.split("=")[1])
	cam.near = 0.2
	cam.far = 260.0
	attrs = CameraAttributesPractical.new()
	attrs.dof_blur_far_enabled = true
	attrs.dof_blur_far_distance = 20.0
	attrs.dof_blur_far_transition = 14.0
	attrs.dof_blur_near_enabled = true
	attrs.dof_blur_near_distance = 6.0
	attrs.dof_blur_near_transition = 3.0
	attrs.dof_blur_amount = 0.13
	cam.attributes = attrs
	add_child(cam)
	cam.current = true
	var w = get_parent()
	if zoom_out != 1.0 and w and w.get("sun"):   # shadows as far out as the camera now sees
		w.sun.directional_shadow_max_distance *= zoom_out


func follow(node: Node3D, snap := true) -> void:
	target = node
	_manual = false
	dof_focus = null
	attrs.dof_blur_amount = 0.13
	if snap and target:
		_lead = Vector3.ZERO
		_vel = Vector3.ZERO
		_last_tp = target.global_position
		_place(target.global_position, 1.0)


func cut_to(point: Vector3, zoom := 1.0) -> void:
	## A cut straight to the framing focus() would end on (no move, and no frame looking from the old place).
	if _move and _move.is_valid():
		_move.kill()
	_manual = true
	_focus_point = point
	cam.global_position = _out(point + offset * zoom, point)
	cam.look_at(point + look_offset * zoom, Vector3.UP)
	_sync_see()


func _sync_see() -> void:
	## Tell the see-through shaders where the camera is now, not at the next _process: after a cut made from a story
	## coroutine (which runs after this frame's _process), the walls between the new place and the player would
	## otherwise stand whole for one frame.
	RenderingServer.global_shader_parameter_set("cam_pos", cam.global_position if see_through else Vector3(0, -1000, 0))


func focus(point: Vector3, zoom := 1.0, t := 1.2, glide := false) -> void:
	## Smoothly frame a point (cutscenes). zoom < 1 moves closer. glide: the look turns over from where the camera
	## looks now as it moves, easing in and out (a long move from another shot), rather than snapping to the point.
	_manual = true
	var from_pos := cam.global_position
	var to_pos := _out(point + offset * zoom, point)
	var from_look := from_pos - cam.global_basis.z * from_pos.distance_to(point)
	var tw := _new_move()
	_focus_point = point
	tw.tween_method(func(v: float):
		cam.global_position = from_pos.lerp(to_pos, v)
		var look := point + look_offset * zoom
		cam.look_at(from_look.lerp(look, v) if glide else look, Vector3.UP)
	, 0.0, 1.0, t * (0.3 if Game.fast else 1.0))
	if glide:
		tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _wait(tw)


func view_to(pos: Vector3, look: Vector3, t := 1.0, pull := false) -> void:
	## Smoothly move to an explicit camera position / look target (side-on cutscene shots).
	_manual = true
	_focus_point = look
	if pull:
		pos = _out(pos, look)
	var from_pos := cam.global_position
	var from_look := cam.global_position - cam.global_basis.z * 10.0
	var tw := _new_move()
	tw.tween_method(func(v: float):
		cam.global_position = from_pos.lerp(pos, v)
		cam.look_at(from_look.lerp(look, v), Vector3.UP)
	, 0.0, 1.0, t * (0.3 if Game.fast else 1.0))
	await _wait(tw)


func frame(subjects: Array, t := 0.9, dist := 0.0, side := 0.2, high := 0.5) -> void:
	## Frame people or things in a cutscene: all of them in, their middle a little above the centre of the screen
	## (clear of the dialogue box along the bottom), seen from the south and a touch to one side; farther back the
	## more spread out they stand. Subjects are Node3D or Vector3 (a thing on the ground).
	if subjects.is_empty():
		return
	var pts: Array = []
	for s in subjects:
		pts.append((s as Node3D).global_position if s is Node3D else s)
	var c := Vector3.ZERO
	for p in pts:
		c += p
	c /= pts.size()
	var spread := 0.0
	for p in pts:
		spread = maxf(spread, Vector2(p.x - c.x, p.z - c.z).length())
	var d := dist if dist > 0.0 else 4.9 + spread * 1.5
	var pos := c + Vector3(d * side, d * high, d)
	# aim below their middle: with this lens they then sit in the upper half of the frame
	await view_to(pos, c + Vector3(0, 0.3, 0), t, true)


func frame_pair(a: Vector3, b: Vector3, t := 0.8, dist := 4.6, high := 0.46) -> void:
	## Two things side by side on screen (someone and what they are looking at): the camera looks across the line
	## between them, from whichever side faces the south (as the follow camera does), so neither hides the other.
	var d := Vector3(b.x - a.x, 0, b.z - a.z)
	if d.length() < 0.05:
		d = Vector3(1, 0, 0)
	d = d.normalized()
	var p := Vector3(d.z, 0, -d.x)
	if p.z < 0.0:
		p = -p
	p = (p + Vector3(0, 0, 0.35)).normalized()   # a little more from the south than square on
	var mid := (a + b) * 0.5
	await view_to(mid + p * dist + Vector3(0, dist * high, 0), mid + Vector3(0, 0.3, 0), t, true)


func side_view(subject_mid: Vector3, out_dir: Vector3, dist: float, height: float, look_h: float) -> Array:
	## Camera pose for a side-on shot along the pass: valley side on screen-right.
	var f := Vector3(-out_dir.z, 0, out_dir.x)
	if f.cross(Vector3.UP).dot(-out_dir) < 0:
		f = -f
	var look := subject_mid + Vector3(0, look_h, 0)
	return [look - f * dist + Vector3(0, height, 0), look]


func _out(pos: Vector3, look: Vector3) -> Vector3:
	## A framed shot's camera position pulled back along its line to what it looks at (see zoom_out).
	var v := pos - look
	var d := v.length()
	if zoom_out == 1.0 or d < 0.01:
		return pos
	var k := 1.0 + (zoom_out - 1.0) * 1.6
	return look + v / d * maxf(d, minf(d * k, CUT_MAX))


func _wait(tw: Tween) -> void:
	## Until the move ends, or is replaced by another move or a cut (a killed tween never says it finished).
	while tw.is_valid() and tw.is_running():
		await get_tree().process_frame


func _new_move() -> Tween:
	if _move and _move.is_valid():
		_move.kill()
	_move = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return _move


func set_view(pos: Vector3, look: Vector3) -> void:
	if _move and _move.is_valid():
		_move.kill()
	_manual = true
	_focus_point = look
	cam.global_position = pos
	cam.look_at(look, Vector3.UP)
	_sync_see()


func release(t := 0.8) -> void:
	## Hand the camera back to the follow: it glides (position and angle) from wherever it is.
	_manual = false
	if target:
		_last_tp = target.global_position
	await get_tree().create_timer(t * (0.3 if Game.fast else 1.0)).timeout


func shake(amount := 0.25, t := 0.3) -> void:
	_shake = amount
	_shake_t = t


func _place(p: Vector3, w: float) -> void:
	var off := offset * zoom_out
	var want := p + _lead + off
	want.x = clampf(want.x, bounds.position.x, bounds.end.x)
	var goal := Transform3D(Basis(), want).looking_at(want - off + look_offset, Vector3.UP)
	# blend the whole transform, so leaving a side-on or close-up shot eases back instead of snapping
	cam.global_transform = cam.global_transform.interpolate_with(goal, w)


func _process(delta: float) -> void:
	if not _manual and target and delta > 0.0:
		# look a little ahead of where the character is heading; ease in and out of it
		var tp := target.global_position
		var v := (tp - _last_tp) / delta
		_last_tp = tp
		if v.length() > 20.0:
			v = Vector3.ZERO  # teleport
		_vel = _vel.lerp(v, 1.0 - exp(-6.0 * delta))
		var lead_want := Vector3(_vel.x, 0, _vel.z) * 0.32
		if lead_want.length() > 1.4:
			lead_want = lead_want.normalized() * 1.4
		_lead = _lead.lerp(lead_want, 1.0 - exp(-2.2 * delta))
		_place(tp, 1.0 - exp(-smooth * delta))
	if _shake_t > 0.0:
		_shake_t -= delta
		cam.h_offset = randf_range(-_shake, _shake)
		cam.v_offset = randf_range(-_shake, _shake)
		if _shake_t <= 0.0:
			cam.h_offset = 0.0
			cam.v_offset = 0.0
	# foliage between this camera and the player thins out (shaders/foliage.gdshader): it needs to know which
	# camera is the gameplay one
	RenderingServer.global_shader_parameter_set("cam_pos", cam.global_position if see_through else Vector3(0, -1000, 0))
	# keep the in-focus band centred on what we are looking at
	var fp: Vector3 = target.global_position if (target and not _manual) else _focus_point
	if dof_focus is Vector3 and _manual:
		fp = dof_focus
	var focus_d := cam.global_position.distance_to(fp)
	if focus_d > 0.5:
		# the in-focus band widens with distance so wide shots stay readable
		attrs.dof_blur_far_distance = focus_d + maxf(6.0, focus_d * 0.6)
		attrs.dof_blur_far_transition = maxf(14.0, focus_d * 0.8)
		attrs.dof_blur_near_distance = maxf(focus_d - maxf(5.5, focus_d * 0.55), 1.5)
