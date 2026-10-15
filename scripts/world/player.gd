extends "res://scripts/world/actor.gd"
## The player character: camera-relative movement, running, interaction.

var world
var control := false
var _vel := Vector3.ZERO
const ACCEL := 26.0
const DECEL := 32.0


func _physics_process(delta: float) -> void:
	if not control or world == null:
		_vel = Vector3.ZERO
		return
	var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	running = Input.is_action_pressed("run")
	var want := Vector3.ZERO
	if v.length() > 0.1:
		var spd := speed_run if running else speed_walk
		want = Vector3(v.x, 0, v.y).normalized() * spd * minf(v.length() * 1.2, 1.0)
	# ease into and out of motion instead of snapping to full speed
	_vel = _vel.move_toward(want, (ACCEL if want.length() > _vel.length() else DECEL) * delta)
	if _vel.length() > 0.05:
		var dir := want.normalized() if want.length() > 0.1 else _vel.normalized()
		velocity = _vel
		var before := global_position
		move_and_slide()
		var after := global_position
		if not world.is_walkable(after):
			# slide along the boundary: try each axis separately
			var try_x := Vector3(after.x, 0, before.z)
			var try_z := Vector3(before.x, 0, after.z)
			if world.is_walkable(try_x):
				after = try_x
			elif world.is_walkable(try_z):
				after = try_z
			else:
				after = Vector3(before.x, 0, before.z)
		after.y = world.ground_at(after)
		global_position = after
		facing = dir_from_vec(dir)
		moving = true
	else:
		_vel = Vector3.ZERO
		velocity = Vector3.ZERO
		moving = false


func _unhandled_input(event: InputEvent) -> void:
	if control and world and event.is_action_pressed("act"):
		get_viewport().set_input_as_handled()
		world.try_interact()
