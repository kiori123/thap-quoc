extends Node
## Automated play-through for testing. Run with:
##   Godot --path . -- --autotest=full --shots=qa/shots --timing=perfect [--fast]
## Scenarios: full | incident | night | departure | title
## Writes screenshots and qa report (beats reached, fps stats, errors seen).

var active := false
var scenario := "full"
var title_play := ""   # --title-play=new|bachson: the title scenario goes on into the game after the cut
var title_wait := 1.5
var chain := false     # --chain: a prologue scenario goes on into Bạch Sơn at its end, as the game does
var shots_dir := ""
var report := {"beats": [], "shots": [], "fps": [], "notes": []}
var _fps_t := 0.0
var _film := 0.0      # --film=0.5: a still every that many seconds, to review camera work frame by frame
var _film_t := 0.0
var _film_n := 0
var _start_ms := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--autotest"):
			active = true
			if a.contains("="):
				scenario = a.split("=")[1]
		elif a.begins_with("--title-play="):
			title_play = a.split("=")[1]
		elif a.begins_with("--title-wait="):   # how long the title sits before the cut (a filmed run wants it seen)
			title_wait = float(a.split("=")[1])
		elif a.begins_with("--shots="):
			shots_dir = a.split("=")[1]
		elif a.begins_with("--timing="):
			Game.auto_timing = a.split("=")[1]
		elif a == "--fast":
			Game.fast = true
		elif a == "--chain":
			chain = true
		elif a == "--watch":
			Game.watch = true
		elif a.begins_with("--film="):
			_film = float(a.split("=")[1])
		elif a.begins_with("--choice="):
			Game.auto_choice = int(a.split("=")[1])
		elif a == "--assist":
			Game.timing_assist = true
		elif a == "--lowq":
			Game.quality_high = false
	if not active:
		set_process(false)
		return
	Game.auto = true
	if not Game.watch:   # a run to be watched keeps its sound and its window where it can be seen
		Game.music_vol = 0.0
		Game.sfx_vol = 0.0
	if OS.get_cmdline_user_args().has("--sound"):   # (a filmed run: the default levels, whatever the player set; not saved)
		Game.music_vol = 0.8
		Game.sfx_vol = 0.9
	_start_ms = Time.get_ticks_msec()
	if active and not OS.get_cmdline_user_args().has("--show") and (not Game.watch or OS.get_cmdline_user_args().has("--offscreen")):
		# out of the way of whoever is using the machine: just off the right edge of the screen, never taking
		# focus (it still renders there; a minimized window would not, and the run would wait forever)
		var win := get_window()
		win.unfocusable = true
		var scr := DisplayServer.screen_get_position() + DisplayServer.screen_get_size()
		win.position = Vector2i(scr.x + 40, 0)
		# off screen, a window that waits on vsync gets throttled by the compositor: draw on our own clock
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = 60
	if shots_dir != "":
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://") + shots_dir)


var _last_tag := ""
var _last_us := 0


func _process(delta: float) -> void:
	# (a frame that took long: the game stood still that long, a stall a player would see; Movie Maker hides them)
	var now := Time.get_ticks_usec()
	if active and Engine.get_process_frames() > 30 and _last_us > 0 and now - _last_us > 250000:
		print("[stall] %.2f s at @%.2f after %s" % [(now - _last_us) / 1e6, (Time.get_ticks_msec() - _start_ms) / 1000.0, _last_tag])
	_last_us = now
	if active and DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MINIMIZED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)   # minimized, nothing is drawn
	if _film > 0.0 and shots_dir != "":
		_film_t += delta
		if _film_t >= _film:
			_film_t = 0.0
			_film_n += 1
			shot("f_%04d" % _film_n)
	_fps_t += delta
	if _fps_t >= 0.5:
		_fps_t = 0.0
		report["fps"].append(Engine.get_frames_per_second())


func note(tag: String) -> void:
	if not active:
		return
	report["beats"].append({"tag": tag, "t": (Time.get_ticks_msec() - _start_ms) / 1000.0})
	_last_tag = tag
	print("[autotest] ", tag, "  @%.3f" % ((Time.get_ticks_msec() - _start_ms) / 1000.0))


func _probe_hide(name: String) -> void:
	## (--probe-hide=<shot>:<part>) hide one part of the hero just before that shot: all, sprite, blob, dust.
	for a in OS.get_cmdline_user_args():
		if not a.begins_with("--probe-hide=" + name + ":"):
			continue
		var w = get_tree().current_scene.get("world")
		var h = w.hero
		match a.split(":")[1]:
			"all": h.visible = false
			"sprite": h.sprite.visible = false
			"blob": h.blob.visible = false
			"dust": h._dust.visible = false
			var what:   # class=<Class> or shader=<file name part>: every such thing in the scene
				var kv: PackedStringArray = what.split("=")
				var stack: Array = [get_tree().current_scene]
				var n_hid := 0
				while not stack.is_empty():
					var n: Node = stack.pop_back()
					stack.append_array(n.get_children())
					if not (n is GeometryInstance3D):
						continue
					var hit := false
					if kv[0] == "class":
						hit = n.get_class() == kv[1]
					elif kv[0] == "shader":
						var m = (n as GeometryInstance3D).material_override
						if m == null and n is MeshInstance3D and (n as MeshInstance3D).mesh and (n as MeshInstance3D).mesh.get_surface_count() > 0:
							m = (n as MeshInstance3D).mesh.surface_get_material(0)
						if m == null and n is MultiMeshInstance3D and (n as MultiMeshInstance3D).multimesh and (n as MultiMeshInstance3D).multimesh.mesh:
							m = (n as MultiMeshInstance3D).multimesh.mesh.surface_get_material(0)
						hit = m is ShaderMaterial and (m as ShaderMaterial).shader and (m as ShaderMaterial).shader.resource_path.contains(kv[1])
					elif kv[0] == "noshadow":
						(n as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
						n_hid += 1
					if hit:
						(n as Node3D).visible = false
						n_hid += 1
				print("[probe] hid ", n_hid, " of ", what)
		print("[probe] hid ", a.split(":")[1])


func _probe_ray(name: String) -> void:
	## (--probe-ray=<shot>:x,y) What is seen at screen pixel x,y in that shot: every drawn thing whose box the camera's
	## ray through it passes, nearest first, with its material.
	for a in OS.get_cmdline_user_args():
		if not a.begins_with("--probe-ray=" + name + ":"):
			continue
		var xy := a.split(":")[1].split(",")
		var cam := get_viewport().get_camera_3d()
		var px := Vector2(float(xy[0]), float(xy[1]))
		var o := cam.project_ray_origin(px)
		var dr := cam.project_ray_normal(px)
		var hits: Array = []
		var stack: Array = [get_tree().current_scene]
		while not stack.is_empty():
			var n: Node = stack.pop_back()
			stack.append_array(n.get_children())
			if n is GeometryInstance3D and (n as Node3D).is_visible_in_tree():
				var box := (n as VisualInstance3D).global_transform * (n as VisualInstance3D).get_aabb()
				var hit = box.intersects_ray(o, dr)
				if hit != null and box.size.length() < 400.0:
					var mat = (n as GeometryInstance3D).material_override
					if mat == null and n is MeshInstance3D and (n as MeshInstance3D).mesh and (n as MeshInstance3D).mesh.get_surface_count() > 0:
						mat = (n as MeshInstance3D).mesh.surface_get_material(0)
					var desc := ""
					if mat is StandardMaterial3D and (mat as StandardMaterial3D).albedo_texture:
						desc = (mat as StandardMaterial3D).albedo_texture.resource_path + " tint " + str((mat as StandardMaterial3D).albedo_color)
					elif mat is ShaderMaterial:
						desc = (mat as ShaderMaterial).shader.resource_path
					hits.append([o.distance_to(hit), n.get_path(), n.get_class(), desc, box])
		hits.sort_custom(func(p, q): return p[0] < q[0])
		for h in hits.slice(0, 8):
			print("[ray] %.1f m %s %s %s %s" % h)


func _probe_shadow(name: String) -> void:
	## (--probe=<shot>:x,y) What casts the shadow at screen pixel x,y in that shot: a ray from the camera to the floor
	## there (the plane at the player's feet), then toward the sun; every drawn thing whose box it passes through.
	for a in OS.get_cmdline_user_args():
		if not a.begins_with("--probe=" + name + ":"):
			continue
		var xy := a.split(":")[1].split(",")
		var cam := get_viewport().get_camera_3d()
		var px := Vector2(float(xy[0]), float(xy[1]))
		var o := cam.project_ray_origin(px)
		var dr := cam.project_ray_normal(px)
		var w = get_tree().current_scene.get("world")
		var fy: float = (w.hero as Node3D).global_position.y if w and w.get("hero") else 0.0
		var t := (fy + 0.05 - o.y) / dr.y
		var pt := o + dr * t
		var sun_dir: Vector3 = w.sun.global_transform.basis.z
		print("[probe] floor point ", pt, " toward sun ", sun_dir)
		var stack: Array = [get_tree().current_scene]
		while not stack.is_empty():
			var n: Node = stack.pop_back()
			stack.append_array(n.get_children())
			if n is VisualInstance3D and (n as VisualInstance3D).is_visible_in_tree():
				var vi := n as VisualInstance3D
				var box := vi.global_transform * vi.get_aabb()
				if box.intersects_segment(pt + sun_dir * 0.2, pt + sun_dir * 80.0):
					var cs = vi.get("cast_shadow")
					print("[probe] ", vi.get_path(), " ", vi.get_class(), " cast_shadow=", cs, " box=", box)
				if box.size.x < 60.0 and box.size.z < 60.0 and box.grow(0.6).has_point(pt):
					var tex = vi.get("texture")
					var mat = vi.get("material_override")
					print("[near] ", vi.get_path(), " ", vi.get_class(), " box=", box, " tex=", tex.resource_path if tex else "", " mat=", mat)
					var par := vi.get_parent()
					if par is CharacterBody3D and par.get("id") != null:
						print("[near]   at ", par.global_position, " sprite at ", par.sprite.global_position, " scale ", par.sprite.scale, " tex ", par.sprite.texture.get_size() if par.sprite.texture else Vector2.ZERO, " hf ", par.sprite.hframes, " vf ", par.sprite.vframes, " blob ", par.blob.visible, " blob_scale ", par.blob.scale)
						print("[near]   actor id=", par.id, " sprite.visible=", par.sprite.visible, " frame=", par.sprite.frame,
							" modulate=", par.sprite.modulate, " pose=", par.pose_sprite.visible, " moving=", par.moving, " dust=", par._dust.emitting)


func shot(name: String) -> void:
	if not active or shots_dir == "":
		return
	_probe_shadow(name)
	_probe_ray(name)
	_probe_hide(name)
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("res://") + shots_dir + "/" + name + ".png"
	img.save_png(path)
	report["shots"].append(name)
	print("[autotest] shot ", name)


func run(main) -> void:
	note("start_" + scenario)
	Overlay.set_black(false)
	if scenario == "controls":
		await _controls(main)
		finish()
		return

	if scenario == "duel":
		await _duel(main)
		finish()
		return
	if scenario == "gallery":
		await _gallery(main)
		finish()
		return
	if scenario == "vision":
		# the Duyên glimpse on its own, at real speed, with a shot in the middle and near the end of each beat
		Game.fast = false
		var starts := [0.3, 3.8, 9.1]
		get_tree().create_timer(starts[0] + 1.4).timeout.connect(func(): shot("vis_0_a"))
		get_tree().create_timer(starts[0] + 2.9).timeout.connect(func(): shot("vis_0_b"))
		for j in 3:   # the crowd: looking out, porcelain creeping up them, all of them blindfolded
			get_tree().create_timer(starts[1] + [1.2, 2.7, 4.8][j]).timeout.connect(func(): shot("vis_1_%s" % "abc"[j]))
		for j in 4:   # the chase: arms out, the first caught, the second, the last and the ones who got away
			get_tree().create_timer(starts[2] + [1.0, 2.0, 2.9, 4.2][j]).timeout.connect(func(): shot("vis_2_%s" % "abcd"[j]))
		if OS.get_cmdline_user_args().has("--source"):   # the second glimpse, at the camp (Bạch Sơn, Part C)
			await Overlay.vision_stage(load("res://scripts/fx/vision_source.gd"), ["", "", ""])
		else:
			await Overlay.vision_stage(load("res://scripts/fx/vision_gate.gd"), ["Cổng Trắng khép lại.",
				"Sau cổng, những gương mặt nhìn ra. Một bàn tay khép then cửa.", "Rồi từ sau song cổng, những bàn tay trắng bò ra."])
		note("vision_done")
		finish()
		return
	if scenario == "manual":
		await _manual(main)
		finish()
		return
	if scenario == "perf":
		await _perf(main)
		finish()
		return
	if scenario == "canopy":
		await _canopy(main)
		finish()
		return
	if scenario == "bstour":   # Bạch Sơn's places, one still each (layout checks; no story)
		if main.world:
			main.world.queue_free()
		await get_tree().process_frame
		var w = load("res://scripts/world/bach_son.gd").new()
		main.add_child(w)
		main.world = w
		await get_tree().process_frame
		var m: Dictionary = w.markers
		var views := [["t_wide", Vector3(6.0, 16.0, 62.0), Vector3(0, 18.0, -60.0)],
			["t_flank", Vector3(-8.0, 9.0, 30.0), Vector3(-40.0, 22.0, -20.0)],
			["t_plaza", Vector3(0, 13.6, -19.5), Vector3(0, 4, -28.3)],
			["t_cuacong", Vector3(3.0, 8.5, -31.0), Vector3(7.0, 4.8, -25.5)],
			["t_nharua", (m["nha_rua"] as Vector3) + Vector3(4.0, 7.0, 5.0), m["nha_rua"]],
			["t_stair", Vector3(2.0, 13.0, -32.0), Vector3(3.0, 7.0, -42.0)],
			["t_tier1", Vector3(-2.0, 19.6, -38.0), Vector3(-6.0, 10.0, -47.0)],
			["t_dinhty", Vector3(-10.0, 16.0, -40.0), Vector3(-13.0, 11.0, -48.0)],
			["t_alley", Vector3(5.0, 18.0, -44.0), Vector3(2.0, 11.0, -54.0)],
			["t_den", Vector3(-11.0, 25.0, -51.0), Vector3(-14.0, 18.0, -61.0)],
			["t_dien", Vector3(0.0, 33.0, -65.0), Vector3(0.0, 28.0, -76.0)]]
		for v in views:
			w.rig.set_view(v[1], v[2])
			await Game.wait(0.4)
			await shot(v[0])
		note("tour_done")
		finish()
		return
	if scenario == "bachson":   # the Bạch Sơn chapter, bản thử, end to end
		var from := "arrive"
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--beat="):   # start part way in: camp, night, caravan, gate, inside
				from = a.split("=")[1]
		await main.start_bach_son(from)
		note("story_done")
		finish()
		return
	var beat := "morning"
	match scenario:
		"incident": beat = "incident"
		"night": beat = "night"
		"departure": beat = "departure"
	await main.start(beat)
	note("story_done")
	finish()


func _hold(action: String, t: float) -> void:
	Input.action_press(action)
	await get_tree().create_timer(t).timeout
	Input.action_release(action)
	await get_tree().physics_frame


func _tap(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().process_frame
	var ev2 := InputEventAction.new()
	ev2.action = action
	ev2.pressed = false
	Input.parse_input_event(ev2)
	await get_tree().process_frame


func _check(name: String, ok: bool, detail := "") -> void:
	report.get_or_add("checks", []).append({"name": name, "ok": ok, "detail": detail})
	print("[autotest] check %s: %s %s" % [name, "PASS" if ok else "FAIL", detail])


func _controls(main) -> void:
	## Drive the real player controller with simulated input.
	var w = main.world
	Game.auto = false
	main.pause.enabled = true
	w.set_time("day", true)
	w.hero.visible = true
	w.hero.global_position = w.markers["yard_center"]
	w.rig.follow(w.hero, true)
	w.set_control(true)
	await get_tree().create_timer(0.3).timeout
	var p0: Vector3 = w.hero.global_position
	await _hold("move_right", 1.0)
	var p1: Vector3 = w.hero.global_position
	_check("walk_right", p1.x - p0.x > 2.0 and p1.x - p0.x < 4.5, "dx=%.2f" % (p1.x - p0.x))
	await shot("c01_walk")
	await _hold("move_up", 2.5)
	var p2: Vector3 = w.hero.global_position
	_check("porch_step_up", absf(p2.y - 0.3) < 0.01, "y=%.2f" % p2.y)
	_check("house_wall_blocks", p2.z > w.HOUSE.z + 0.9, "z=%.2f wall=%.2f" % [p2.z, w.HOUSE.z + 0.85])
	# straight at the open doorway: the invisible panel keeps the player out
	w.hero.global_position = Vector3(w.HOUSE.x, 0.3, w.HOUSE.z + 2.2)
	await _hold("move_up", 1.5)
	_check("doorway_blocks", w.hero.global_position.z > w.HOUSE.z + 0.9, "z=%.2f" % w.hero.global_position.z)
	# and back down off the porch
	await _hold("move_down", 1.5)
	_check("porch_step_down", absf(w.hero.global_position.y) < 0.01 and w.hero.global_position.z > w.HOUSE.z + 3.0, "y=%.2f z=%.2f" % [w.hero.global_position.y, w.hero.global_position.z])
	w.hero.global_position = w.markers["yard_center"] + Vector3(-2, 0, 0)
	await get_tree().physics_frame
	var a: Vector3 = w.hero.global_position
	Input.action_press("run")
	await _hold("move_down", 0.6)
	Input.action_release("run")
	var b: Vector3 = w.hero.global_position
	_check("fence_blocks_south", b.z < 7.7, "z=%.2f" % b.z)
	w.hero.global_position = Vector3(-6, 0, 2)
	await get_tree().physics_frame
	var c0: Vector3 = w.hero.global_position
	Input.action_press("run")
	await _hold("move_left", 1.0)
	Input.action_release("run")
	var c1: Vector3 = w.hero.global_position
	_check("run_faster", c0.x - c1.x > 4.4, "dx=%.2f" % (c0.x - c1.x))
	# valley boundary: push east beyond the edge
	w.hero.global_position = Vector3(33, 0, -2)
	await get_tree().physics_frame
	await _hold("move_right", 2.5)
	var e: Vector3 = w.hero.global_position
	_check("valley_boundary", w.is_walkable(e) and e.x < 37.5, "x=%.2f" % e.x)
	# the marker: cannot walk past it
	w.hero.global_position = w.MARKER + Vector3(2.5, 0, 2.5)
	await get_tree().physics_frame
	Input.action_press("move_left")
	Input.action_press("move_up")
	await get_tree().create_timer(2.0).timeout
	Input.action_release("move_left")
	Input.action_release("move_up")
	var m: Vector3 = w.hero.global_position
	var past: float = (Vector2(m.x, m.z) - Vector2(w.MARKER.x, w.MARKER.z)).dot(w.PASS_OUT)
	_check("marker_boundary", past < 0.6, "past=%.2f" % past)
	await shot("c02_marker")
	# interaction
	var got := [""]
	w.interacted.connect(func(id): got[0] = id)
	w.hero.global_position = w.markers["chop_spot"] + Vector3(0.5, 0, 0.5)
	w.rig.follow(w.hero)   # (a teleport: the camera snaps rather than glides)
	w.add_interact("probe", w.markers["chop_spot"], "Thử", 1.7)
	await get_tree().create_timer(0.2).timeout
	await shot("c03_prompt")
	await _tap("act")
	await get_tree().create_timer(0.1).timeout
	_check("interact", got[0] == "probe", "got=%s" % got[0])
	# pause menu
	await _tap("pause")
	await get_tree().create_timer(0.2).timeout
	_check("pause_opens", get_tree().paused)
	await shot("c04_pause")
	await _tap("pause")
	await get_tree().create_timer(0.2).timeout
	_check("pause_closes", not get_tree().paused)
	# the settings board and the Sổ ghi, as they look
	var lay := CanvasLayer.new()
	lay.layer = 60
	add_child(lay)
	var holder := Control.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.theme = Assets.theme
	lay.add_child(holder)
	var sp: PanelContainer = preload("res://scripts/ui/settings_panel.gd").new()
	sp.anchor_left = 0.5
	sp.anchor_right = 0.5
	sp.anchor_top = 0.5
	sp.anchor_bottom = 0.5
	sp.offset_left = -270
	sp.offset_right = 270
	sp.offset_top = -190
	sp.offset_bottom = 190
	holder.add_child(sp)
	sp.open()
	await get_tree().create_timer(0.2).timeout
	await shot("c05_settings")
	lay.queue_free()
	var jn = preload("res://scripts/ui/journal.gd").new()
	add_child(jn)
	jn.set_entries(["Đứa bé chưa tên năm PK 395 không phải mình."], ["Sổ Tro: cột đen không có lấy một nét.", "Chén men rạn trong nhà bà Lành."])
	jn.toggle()
	await get_tree().create_timer(0.2).timeout
	await shot("c06_journal")
	jn.queue_free()
	Game.auto = true


func _keyu(code: int, unicode := 0) -> void:
	## A key pressed and let go, as from the keyboard, with the character it types.
	for down in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = code
		ev.physical_keycode = code
		ev.unicode = unicode if down else 0
		ev.pressed = down
		Input.parse_input_event(ev)
		await get_tree().process_frame


func _focus_text() -> String:
	var f = get_viewport().gui_get_focus_owner()
	if f == null:
		return "(none)"
	return f.text if "text" in f else f.get_class()


func title_input(main, title) -> void:
	## The title driven with the keyboard: move in the menu, open and close the settings, open the naming box, leave
	## it with Esc, open it again, type a name, rub a letter out, Enter; and through the cut hammer Space, Esc and Tab.
	## Then in the game: Esc pauses and unpauses. Checks what a player would notice.
	Game.auto = false
	await get_tree().create_timer(2.0).timeout
	_check("title_focus_start", _focus_text() == "Bắt đầu", _focus_text())
	await _keyu(KEY_DOWN)
	await _keyu(KEY_DOWN)
	_check("title_down_down", _focus_text() == "Bạch Sơn (bản thử)" or _focus_text() == "Thiết lập", _focus_text())
	await _keyu(KEY_UP)
	await _keyu(KEY_UP)
	await _keyu(KEY_UP)
	_check("title_up_wraps_or_stops", _focus_text() != "(none)", _focus_text())
	# the settings
	var setb: Button = null
	for b in title._buttons:
		if b.text == "Thiết lập":
			setb = b
	setb.grab_focus()
	await _keyu(KEY_ENTER)
	await get_tree().create_timer(0.3).timeout
	_check("settings_open", title.settings.visible)
	await shot("i01_settings")
	await _keyu(KEY_ESCAPE)
	await get_tree().create_timer(0.3).timeout
	_check("settings_close_esc", not title.settings.visible)
	_check("focus_back_after_settings", _focus_text() != "(none)", _focus_text())
	# the naming box: open, Esc, open again
	title._buttons[0].grab_focus()
	await _keyu(KEY_ENTER)
	await get_tree().create_timer(0.3).timeout
	_check("name_box_open", title.name_box.visible)
	await shot("i02_name")
	await _keyu(KEY_ESCAPE)
	await get_tree().create_timer(0.3).timeout
	_check("name_box_esc", not title.name_box.visible)
	_check("focus_back_after_name", _focus_text() == "Bắt đầu", _focus_text())
	await _keyu(KEY_SPACE)
	await get_tree().create_timer(0.3).timeout
	_check("name_box_reopen_space", title.name_box.visible)
	# type over the name, rub a letter out with Backspace (bound to "back" too)
	await _keyu(KEY_A, 0x41)
	await _keyu(KEY_N, 0x6E)
	await _keyu(KEY_H, 0x68)
	await _keyu(KEY_BACKSPACE)
	_check("name_box_still_open_after_backspace", title.name_box.visible)
	_check("name_typed", title.name_edit.text == "An", title.name_edit.text)
	await _keyu(KEY_ENTER)
	_check("name_set", Game.player_name == "An", Game.player_name)
	# hammer keys through the cut
	for i in 24:
		await _keyu([KEY_SPACE, KEY_ESCAPE, KEY_TAB, KEY_ENTER][i % 4])
		await get_tree().create_timer(0.12).timeout
	await get_tree().create_timer(4.0).timeout
	var enters := (report["beats"] as Array).filter(func(b): return str(b["tag"]).begins_with("enter_")).size()
	_check("entered_once", enters == 1, str(enters))
	_check("in_valley", main.world != null and main.world.get_script() == load("res://scripts/world/world.gd"), str(main.world))
	_check("not_paused_after_cut", not get_tree().paused)
	await shot("i03_in_game")
	await get_tree().create_timer(3.0).timeout
	await _keyu(KEY_ESCAPE)
	await get_tree().create_timer(0.4).timeout
	_check("esc_pauses_in_game", get_tree().paused)
	await shot("i04_pause")
	await _keyu(KEY_ESCAPE)
	await get_tree().create_timer(0.4).timeout
	_check("esc_unpauses", not get_tree().paused)
	finish()


func _duel(main) -> void:
	## A short scripted fight straight away, for recording the battle animation with --write-movie.
	var w = main.world
	w.set_time("gloom", true)
	w.hero.visible = true
	w.set_control(false)
	w.hud.visible = false
	var Battle = load("res://scripts/battle/battle.gd")
	var b = Battle.new()
	main.add_child(b)
	var cmds: Array = ["bo", "quet", "bo", "thu", "nhatnet", "bo", "bo"]
	var foes: Array = ["manh_tinh", "manh_tinh"]
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--cmds="):
			cmds = Array(a.split("=")[1].split(","))
		if a.begins_with("--foes="):
			foes = Array(a.split("=")[1].split(","))
	var conf := {"enemies": foes, "intro": "Nghiệt chặn đường.", "auto_cmds": cmds, "potions": 3,
		"start_blind": OS.get_cmdline_user_args().has("--blind")}
	if OS.get_cmdline_user_args().has("--teach"):   # with the lesson cards (Nối thế)
		conf["tutorial"] = true
		conf["teach"] = ["ho", "ran", "chao"]
	if OS.get_cmdline_user_args().has("--escort"):   # the pass fight: hold Trắng Tay back from Lúa
		conf["escort"] = {"who": "lua", "sheet": "res://assets/sprites/chars/lua.png", "helper": "ref_m",
			"helper_sheet": "res://assets/sprites/chars/refugee_m.png", "rounds": 6, "boss_steps": 4}
	var res: String = await b.run(w, conf)
	note("duel_" + res)


func _frames(label: String, t: float) -> void:
	## Frame times over t seconds, no screenshots: average, worst, and how many frames took over 50 ms.
	var n := 0
	var total := 0.0
	var worst := 0.0
	var slow := 0
	var t0 := Time.get_ticks_usec()
	var last := t0
	while float(Time.get_ticks_usec() - t0) / 1e6 < t:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		var dt := float(now - last) / 1000.0
		last = now
		n += 1
		total += dt
		worst = maxf(worst, dt)
		if dt > 50.0:
			slow += 1
	note("perf %s: avg %.1f ms (%.0f fps), worst %.0f ms, %d frames over 50 ms" % [label, total / maxi(n, 1), 1000.0 * n / maxf(total, 1.0), worst, slow])


func _canopy(main) -> void:
	## A tree crown between the follow camera and the player: the leaves in the way must thin out
	## (shaders/foliage.gdshader). Behind the banyan (the camera looks north), right under it, and in the
	## bamboo hedge. Each spot is shot twice: with the see-through on, and off for comparison.
	var w = main.world
	w.set_time("day", true)
	w.set_control(false)
	var b: Vector3 = w.props["banyan"].global_position
	var spots := [b + Vector3(0, 0, -2.4), b + Vector3(0.6, 0, -0.6), Vector3(26.2, 0, -4.0)]
	for k in spots.size():
		var p: Vector3 = spots[k]
		p.y = w.height_at(p.x, p.z)
		w.hero.global_position = p
		w.rig.follow(w.hero, true)
		await _settle(1.0)
		await shot("c%d_on" % k)
		w.rig.see_through = false
		await _settle(0.3)
		await shot("c%d_off" % k)
		w.rig.see_through = true
	note("canopy_done")


func _perf(main) -> void:
	## Where the frame rate goes: the yard by day, the moment night falls (lights on for the first time), the
	## porch lanterns at night up close, with the high and the low graphics setting.
	var w = main.world
	w.set_control(false)
	w.hud.visible = false
	var H: Vector3 = w.HOUSE
	for q in [true, false]:
		Game.quality_high = q
		var tag := "high" if q else "low"
		w.set_time("day", true)
		w.rig.set_view(H + Vector3(2.0, 5.5, 16.0), H + Vector3(0, 1.2, 3.0))
		await _settle(1.5)
		await _frames("%s day yard" % tag, 3.0)
		w.set_time("night", true)
		await _frames("%s night first 1.5 s" % tag, 1.5)
		w.rig.set_view(H + Vector3(-1.5, 4.2, 9.5), H + Vector3(-1.2, 1.2, 2.2))
		await _settle(1.0)
		await _frames("%s night porch lanterns" % tag, 3.0)
		for ls in w._lantern_sprites:
			note("lantern at %s vis %s frame %d/%d tex %s off %s scale %s" % [str(ls.global_position), str(ls.is_visible_in_tree()), ls.frame, ls.hframes, str(ls.texture.get_size()), str(ls.offset), str(ls.global_transform.basis.get_scale())])
		var lp: Vector3 = w._lantern_sprites[0].global_position
		w.rig.set_view(lp + Vector3(0.6, -0.2, 3.2), lp + Vector3(0, -0.4, 0))
		await _settle(0.3)
		await shot("p_lantern_close_%s" % tag)
		w.rig.set_view(H + Vector3(-1.5, 4.2, 9.5), H + Vector3(-1.2, 1.2, 2.2))
		await _settle(0.3)
		await shot("p_lanterns_%s_a" % tag)
		await _settle(0.45)
		await shot("p_lanterns_%s_b" % tag)
	Game.quality_high = true
	note("perf_done")


func _settle(t := 0.6) -> void:
	await get_tree().create_timer(t).timeout


func _gallery(main) -> void:
	## Fixed views for judging the look quickly (no story).
	var w = main.world
	var C := "res://assets/sprites/chars/"
	var Hs: Vector3 = w.HOUSE
	w.set_time("day", true)
	var ong = w.spawn("ong", C + "ong.png", Hs + Vector3(-1.2, 0, 5.0), "down")
	var lua = w.spawn("lua", C + "lua.png", Hs + Vector3(-2.4, 0, 5.2), "down")
	var ti = w.spawn("ti", C + "ti.png", Hs + Vector3(1.4, 0, 5.3), "down")
	var baca = w.spawn("baca", C + "baca.png", Hs + Vector3(2.6, 0, 5.0), "down")
	w.hero.global_position = Hs + Vector3(0.1, 0, 5.1)
	w.hero.face("down")
	await get_tree().process_frame
	# 1. close line-up (sprites, light on them)
	w.rig.set_view(Hs + Vector3(0.1, 2.6, 11.0), Hs + Vector3(0.1, 0.9, 5.0))
	await _settle(1.0)
	await shot("g01_lineup")
	# 1b. close walk strip (animation check)
	w.rig.set_view(Hs + Vector3(-1.0, 2.2, 10.5), Hs + Vector3(-1.0, 0.8, 5.0))
	w.hero.move_to(Hs + Vector3(-5.0, 0, 5.1))
	for k in 4:
		await _settle(0.09)
		await shot("g01_walk_%d" % k)
	await _settle(1.4)
	# 2. the yard at gameplay distance with walkers
	w.rig.follow(w.hero, true)
	w.hero.move_to(Hs + Vector3(6.0, 0, 5.4))
	ti.move_to(Hs + Vector3(-4.0, 0, 6.4), -1.0, true)
	await _settle(0.45)
	await shot("g02_yard_walk")
	await _settle(2.2)
	note("perf_yard_fps_%d" % Engine.get_frames_per_second())
	# 2b. hens and washing in the yard at day
	w.rig.set_view(Hs + Vector3(4.5, 4.2, 15.5), Hs + Vector3(4.5, 0.6, 9.0))
	await _settle(0.9)
	await shot("g02b_hens")
	# 3. the village square
	w.rig.set_view(w.VILLAGE + Vector3(2.0, 7.5, 13.0), w.VILLAGE + Vector3(0, 1.2, -2.0))
	await _settle(0.8)
	await shot("g03_village")
	await _settle(1.5)
	note("perf_village_fps_%d" % Engine.get_frames_per_second())
	# 4. establishing shot at dawn
	w.set_time("dawn", true)
	w.rig.set_view(Vector3(-3, 21, 44), Vector3(-8, 7, -20))
	await _settle(0.8)
	await shot("g04_valley")
	# 5. dusk over the paddies
	w.set_time("dusk", true)
	w.rig.set_view(Vector3(-18, 9.0, 24.0), Vector3(-26, 0.3, 8.0))
	await _settle(0.8)
	await shot("g05_paddies")
	# 6. the porch at night
	w.set_time("night", true)
	for l in w.lights_night:
		l.visible = true
	ong.global_position = Hs + Vector3(-1.0, 0.3, 2.0)
	w.hero.global_position = Hs + Vector3(-3.0, 0.3, 2.1)
	w.rig.set_view(Hs + Vector3(-1.5, 3.6, 9.5), Hs + Vector3(-1.5, 1.0, 1.8))
	await _settle(0.8)
	await shot("g06_porch_night")
	# 7. the pass in the gloom
	w.set_time("gloom", true)
	var mk: Vector3 = w.MARKER
	w.hero.global_position = mk + Vector3(2.0, 0, 2.0)
	var out := (mk - Vector3(-24, 0, -12)).normalized()
	var sv: Array = w.rig.side_view(mk + out * 1.5, out, 13.0, 2.6, 1.6)
	w.rig.set_view(sv[0], sv[1])
	await _settle(0.8)
	await shot("g07_pass")
	for a in [ong, lua, ti, baca]:
		a.queue_free()


func _key(code: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = true
	Input.parse_input_event(e)
	await get_tree().process_frame
	var e2 := InputEventKey.new()
	e2.keycode = code
	e2.physical_keycode = code
	e2.pressed = false
	Input.parse_input_event(e2)
	await get_tree().process_frame


func _manual(main) -> void:
	## A player mashing Space from the title screen, at real speed, with no auto-play.
	Game.auto = false
	Game.fast = false
	main.show_title()
	await get_tree().create_timer(3.5).timeout
	await shot("u01_title")
	await _key(KEY_ENTER)
	await get_tree().create_timer(0.8).timeout
	await shot("u02_name")
	_check("name_prompt", main.get_children().any(func(c): return c.get("name_box") != null and c.name_box.visible))
	await _key(KEY_ENTER)
	_check("name_set", Game.player_name == "Bến", Game.player_name)
	var w = main.world
	await _mash_until(func(): return w.control_enabled, 40.0)
	_check("manual_reached_play", w.control_enabled and report["beats"].any(func(b): return b["tag"] == "beat_morning"))
	await shot("u03_control")
	# walk to the chopping block with the real controller, then play the chop prompts by mashing
	var arrived: bool = await _walk_to(w, w.markers["chop_block"], 12.0)
	_check("manual_walk_to_chop", arrived, "%.2f m left" % _flat_dist(w.hero.global_position, w.markers["chop_block"]))
	await get_tree().create_timer(0.2).timeout
	_check("manual_chop_prompt", w.nearest_interact() == "chop", w.nearest_interact())
	await shot("u04_at_block")
	await _mash_until(func(): return w.hud._obj_label.text.contains("chổi"), 70.0, "u05_chop")
	_check("manual_chop_done", w.hud._obj_label.text.contains("chổi"), w.hud._obj_label.text)
	await shot("u06_after_chop")
	await _mash_until(func(): return w.control_enabled, 20.0)
	await _settle(0.3)
	_check("camera_follows_after_chop", not w.rig._manual and w.rig.target == w.hero)
	# fetch the broom and sweep the three piles, walking between them ourselves
	var at_broom: bool = await _walk_to(w, w.markers["broom_prop"], 12.0)
	await _settle(0.2)
	_check("manual_walk_to_broom", at_broom and w.nearest_interact() == "broom", "%.2f m left, nearest '%s', control %s" % [_flat_dist(w.hero.global_position, w.markers["broom_prop"]), w.nearest_interact(), str(w.control_enabled)])
	await shot("u06b_at_broom")
	await _tap("act")
	await _mash_until(func(): return w.hud._obj_label.text.contains("Quét lá") and w.control_enabled, 30.0)
	_check("sweep_started", w.hud._obj_label.text.contains("Quét lá"), w.hud._obj_label.text)
	# mashing never sweeps clean: a pile left behind keeps its arrow and is gone back to (three goes at most)
	for n in 9:
		var k := n % 3
		if n == 3:
			_check("unswept_pile_kept", [0, 1, 2].any(func(j): return w.props["leaves_%d" % j].visible), w.hud._obj_label.text)
		if not w.props["leaves_%d" % k].visible or w.hud._obj_label.text.contains("giếng"):
			continue
		var pile: Vector3 = w.props["leaves_%d" % k].global_position
		_check("camera_follows_sweep_%d" % k, not w.rig._manual and w.rig.target == w.hero)
		var cam0: Vector3 = w.rig.cam.global_position
		await _walk_to(w, pile, 10.0)
		var moved: float = w.rig.cam.global_position.distance_to(cam0)
		_check("camera_moved_with_player_%d" % k, moved > 0.4 or _flat_dist(cam0, pile) < 12.0, "cam moved %.2f" % moved)
		if k == 1:
			await shot("u07_walk_to_pile")
		await _settle(0.15)
		await _tap("act")
		await _mash_until(func(): return w.control_enabled or w.hud._obj_label.text.contains("giếng"), 20.0)
	await _mash_until(func(): return w.hud._obj_label.text.contains("giếng"), 30.0)
	_check("sweep_done", w.hud._obj_label.text.contains("giếng"), w.hud._obj_label.text)
	_check("camera_follows_after_sweep", not w.rig._manual)
	await shot("u08_after_sweep")
	Game.auto = true


func _flat_dist(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))


func _mash_until(cond: Callable, limit: float, shot_name := "") -> void:
	var t := 0.0
	var shot_taken := false
	while t < limit and not cond.call():
		await _tap("act")
		await get_tree().create_timer(0.3).timeout
		t += 0.33
		if shot_name != "" and not shot_taken and t > 4.0:
			shot_taken = true
			await shot(shot_name)


func _walk_to(w, target: Vector3, limit: float) -> bool:
	## Steer with the move actions (the camera looks north, so up = -z, right = +x).
	var t := 0.0
	var held: Array[String] = []
	var last: Vector3 = w.hero.global_position
	var stuck_t := 0.0
	var detour := 0.0  # while > 0, move along one axis only to get round an obstacle
	var detour_axis := 0
	while t < limit:
		var d: Vector3 = target - w.hero.global_position
		if Vector2(d.x, d.z).length() < 1.1:
			break
		var want: Array[String] = []
		if detour <= 0.0 or detour_axis == 0:
			if d.x > 0.3: want.append("move_right")
			elif d.x < -0.3: want.append("move_left")
		if detour <= 0.0 or detour_axis == 1:
			if d.z > 0.3: want.append("move_down")
			elif d.z < -0.3: want.append("move_up")
		detour -= get_physics_process_delta_time()
		stuck_t += get_physics_process_delta_time()
		if stuck_t > 0.3:
			if _flat_dist(last, w.hero.global_position) < 0.05:
				detour = 0.8
				detour_axis = 1 - detour_axis
			last = w.hero.global_position
			stuck_t = 0.0
		for a in held:
			if not want.has(a):
				Input.action_release(a)
		for a in want:
			Input.action_press(a)
		held = want
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	for a in held:
		Input.action_release(a)
	await get_tree().physics_frame
	return _flat_dist(w.hero.global_position, target) < 1.1


func finish() -> void:
	if Game.watch:   # let the last card sit before the window closes
		await get_tree().create_timer(4.0).timeout
	var fps: Array = report["fps"]
	if fps.size() > 0:
		var s := 0.0
		var mn := 9999.0
		for f in fps:
			s += f
			mn = min(mn, f)
		report["fps_avg"] = s / fps.size()
		report["fps_min"] = mn
	report["seconds"] = (Time.get_ticks_msec() - _start_ms) / 1000.0
	if shots_dir != "":
		var f2 := FileAccess.open(ProjectSettings.globalize_path("res://") + shots_dir + "/report.json", FileAccess.WRITE)
		f2.store_string(JSON.stringify(report, "  "))
		f2.close()
	print("[autotest] done ", JSON.stringify({"fps_avg": report.get("fps_avg", 0), "fps_min": report.get("fps_min", 0), "seconds": report["seconds"]}))
	get_tree().quit()
