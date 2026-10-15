extends Node
## Turn-based battle staged inside the 3D world (at the pass), Octopath-style side view.
## Nghiệt have Hình (form, HP) and Chấp (absoluteness, shield pieces). Hitting a weakness breaks Chấp;
## broken Nghiệt lose a turn and take double damage. All attacks and defences are timing prompts.
##   var outcome: String = await battle.run(world, cfg)   # "win" | "lose" | "scripted"

const B = preload("res://scripts/world/builder.gd")
const Timing = preload("res://scripts/ui/timing.gd")
const UI = preload("res://scripts/battle/battle_ui.gd")

const ENEMIES := {
	"manh_tinh": {"name": "Mảnh Sành", "hp": 28, "chap": 2, "weak": ["quet"], "speed": 8, "atk": 6, "mark": 0.55,
		"sheet": "res://assets/sprites/monsters/manh_tinh.png", "frames": 6, "px": 0.042,
		"lore": "Một gương mặt trên vương miện của Trắng Tay, gãy lìa ở cổ, còn đội nón, mắt còn bịt. Nó bò trên những ngón tay sứ."},
	"nghiet_tinh": {"name": "Trắng Tay", "hp": 170, "chap": 4, "weak": ["bo"], "speed": 7, "atk": 10, "mark": 0.72,
		"sheet": "res://assets/sprites/monsters/nghiet_tinh.png", "frames": 7, "px": 0.04,
		"lore": "Mang hình đám người sau Cổng Trắng: những gương mặt bịt mắt dưới nón lá, dính lại thành một pho tượng sứ nghìn tay. Nó không nhìn ai, chỉ quờ tay. Chỗ bị chạm hóa sứ dần. Nó săn những người bị đuổi khỏi cổng."},
}
const HERO_MAX_HP := 70
const SKILL_NAMES := {"bo": "Bổ", "quet": "Quét", "thu": "Thủ", "thau": "Thấu", "thuoc": "Thuốc"}

var world
var ui
var timing
var cfg := {}
var hero
var hero_hp := HERO_MAX_HP
var potions := 3
var guarding := false
var men := 0                  # Xâm near Trắng Tay: layers of glaze on the hero, feet (1), hands (2: weaker), eyes (3)
var bit_mat := 0              # hero turns left with the eyes glazed over (Bịt Mắt): no stop mark, no defend ring
var _glaze: TextureRect       # the white closing in at the edges of sight while Bịt Mắt lasts
var units: Array = []          # enemy dicts
var outcome := ""
var center := Vector3.ZERO
var out_dir := Vector3.ZERO
var hero_home := Vector3.ZERO
var round_i := 0
var tut := {}                  # tutorial lines already shown
var thau_used := false
var boss_attacks := 0
var tinh := 0                  # Tịnh: calm earned by clean strokes and perfect parries; three opens Nhất Nét
var stats := {"dut": 0, "qua": 0, "do": 0, "the": 0}
var hero_idle := false
var _idle_t := 0.0
var _idle_f := -1
var _cam_base := Vector3.ZERO
var _clock := 0.0             # game time (follows hit-stop and frame stalls the same way the prompts do)
var _cam_tw: Tween
var chain_best := 0
var adds_made := 0            # Mảnh Sành shed from Trắng Tay's crown so far (for their letters)
var esc := {}                 # Chắn đường: {lua, helper, total, left, from, to, lat, men}; empty in other fights
var _fill: OmniLight3D        # a light on the hero's side when the fight is in the dark
var _touched := false         # the blade has met a Nghiệt this turn (the first time, Duyên shows where it came from)


func run(w, config: Dictionary) -> String:
	world = w
	cfg = config
	hero = world.hero
	hero_hp = cfg.get("hero_hp", HERO_MAX_HP)
	potions = cfg.get("potions", 3)
	ui = UI.new()
	ui.battle = self
	add_child(ui)
	timing = Timing.new()
	ui.add_child(timing)
	_stage()
	world.set_diorama(0.3, 0.5)
	if cfg.get("start_blind", false):
		men = 2
		_add_men(1)
		bit_mat = 99
	await _intro()
	while outcome == "":
		round_i += 1
		for u in _order():
			if outcome != "":
				break
			if u == null:
				await _hero_turn()
			elif u["alive"]:
				await _enemy_turn(u)
			_check_end()
		if outcome == "" and not esc.is_empty():
			await _escort_round()
	await _outro()
	return outcome


# ================================================================ staging
func _stage() -> void:
	# where the fight is staged: by default just outside the marker at the pass; cfg "stage_at" / "stage_dir"
	# put it anywhere (the hero at stage_at, the Nghiệt off along stage_dir)
	var anchor: Vector3 = cfg.get("stage_at", world.MARKER)
	var od: Vector3 = cfg.get("stage_dir", world.MARKER - Vector3(-24, 0, -12))
	od.y = 0
	out_dir = od.normalized()
	center = anchor + out_dir * 4.4
	hero_home = anchor + out_dir * (3.2 if cfg.has("escort") else 1.4)
	hero_home.y = world.height_at(hero_home.x, hero_home.z)
	hero.global_position = hero_home
	hero.face("left")
	hero.act("ready")
	var list: Array = cfg["enemies"]
	for i in list.size():
		var id: String = list[i]
		var d: Dictionary = ENEMIES[id]
		var lateral := Vector3(-out_dir.z, 0, out_dir.x)
		# staggered row across the screen (the camera looks along `lateral`), alternating near/far
		var n_en := list.size()
		var along := 2.6 if id == "nghiet_tinh" else 1.2 + i * 1.9
		var depth := 0.0 if n_en == 1 else (0.7 if i % 2 == 0 else -0.7)
		var p: Vector3 = center + out_dir * along + lateral * depth
		p.y = world.height_at(p.x, p.z)
		_add_unit(id, p, d["name"] + ("" if list.size() == 1 else " " + "ABC"[i]))
	if cfg.has("escort"):
		_escort_setup()
	_frame_camera()
	for u in units:
		if u["id"] == "nghiet_tinh":
			_backlight(u)
	if world.time_name == "dread" or world.time_name == "night":
		# the day has gone dark round Trắng Tay: a soft warm light on the hero's side keeps them readable
		var fill := OmniLight3D.new()
		fill.light_color = Color(1.0, 0.86, 0.7)
		fill.light_energy = 1.6 if world.time_name == "dread" else 3.2
		fill.omni_range = 7.0 if world.time_name == "dread" else 9.0
		fill.shadow_enabled = false
		world.add_child(fill)
		var toward: Vector3 = _cam_base - hero_home
		toward.y = 0.0
		fill.global_position = hero_home + toward.normalized() * 2.5 + Vector3(0, 2.2, 0)
		_fill = fill
	ui.set_hero(hero_hp, HERO_MAX_HP, potions)
	ui.set_tinh(0)


func _backlight(u: Dictionary) -> void:
	## Trắng Tay glows white against the mist: its porcelain is unshaded, and a cold light stands in the fog
	## behind it (away from the camera) so the mist round it lights up and the figure stands out dark-edged.
	(u["node"] as Sprite3D).shaded = false
	var away: Vector3 = (u["home"] as Vector3) - _cam_base
	away.y = 0.0
	var l := OmniLight3D.new()
	l.light_color = Color(0.72, 0.82, 1.0)
	l.light_energy = 3.5
	l.light_volumetric_fog_energy = 4.0
	l.omni_range = 9.0
	l.shadow_enabled = false
	world.add_child(l)
	l.global_position = (u["home"] as Vector3) + away.normalized() * 2.2 + Vector3(0, 1.2, 0)
	u["light"] = l


func _frame_camera() -> void:
	## Side-on framing: party on the right, Nghiệt on the left, everything in shot, camera above the slopes.
	var f := Vector3(-out_dir.z, 0, out_dir.x)
	if f.cross(Vector3.UP).dot(-out_dir) < 0:
		f = -f
	var ec := Vector3.ZERO
	var boss := false
	for u in units:
		ec += u["home"]
		if u["id"] == "nghiet_tinh":
			boss = true
	ec /= max(units.size(), 1)
	var mid := (hero_home + ec) * 0.5
	var span := hero_home.distance_to(ec) + (3.0 if boss else 1.5)
	var dist := clampf(span * 1.05 + (8.0 if boss else 4.8), 8.5, 18.0 if boss else 15.5)
	var look := mid + Vector3(0, 1.2 if boss else 0.15, 0) + (hero_home - ec).normalized() * (0.0 if boss else -0.7)
	var cam := look - f * dist + Vector3(0, 3.4 if boss else 3.0, 0)
	var ground: float = world.height_at(cam.x, cam.z)
	cam.y = maxf(cam.y, ground + 3.0)
	# also keep the sight line clear of the slope half-way to the subject
	var half := (cam + look) * 0.5
	var g2: float = world.height_at(half.x, half.z)
	if g2 > half.y - 1.2:
		cam.y += (g2 - (half.y - 1.2)) * 2.0
	world.rig.set_view(cam, look)
	world.rig._focus_point = look
	_cam_base = cam


func _enemy_frame(u: Dictionary, idle: bool) -> void:
	var spr: Sprite3D = u["node"]
	if not is_instance_valid(spr):
		return
	if idle:
		if u["id"] == "nghiet_tinh" and u["windup"]:
			spr.frame = 4
			spr.modulate = Color.WHITE.lerp(Color(1.3, 1.4, 1.65), 0.5 + 0.5 * sin(_clock * 6.0))
		elif u["id"] == "nghiet_tinh":
			spr.frame = int(_clock * 1000.0 / 260.0) % 3
		else:
			spr.frame = int(_clock * 1000.0 / 340.0) % 2


func _process(delta: float) -> void:
	_clock += delta
	var now := _clock
	for u in units:
		if not u["alive"] or u.get("busy", false):
			continue
		_enemy_frame(u, true)
		var spr: Sprite3D = u["node"]
		if not is_instance_valid(spr):
			continue
		# idle: Trắng Tay floats, the small ones crouch and breathe; feet stay on the ground when they swell
		var boss: bool = u["id"] == "nghiet_tinh"
		var amp := 0.08 if boss else 0.025
		var bob := sin(now * (1.5 if boss else 3.2) + float(u["phase_off"])) * amp
		spr.position = u["home"] + Vector3(0, (spr.scale.y - 1.0) * float(u["half_h"]) + bob, 0)
	if hero_idle and is_instance_valid(hero):
		_idle_t += delta
		var f := int(_idle_t / 0.55) % 2
		if f != _idle_f:
			_idle_f = f
			hero.act("guard" if guarding else ("ready" if f == 0 else "ready_b"))


func _add_unit(id: String, p: Vector3, nm: String) -> Dictionary:
	var d: Dictionary = ENEMIES[id]
	var spr := B.billboard(world, d["sheet"], p, d["px"], true, d["frames"], 0)
	spr.flip_h = false
	if id != "nghiet_tinh":   # lit like the characters (Trắng Tay is its own light: _backlight)
		B.lit_sprite(spr)
	var u := {"id": id, "name": nm, "hp": d["hp"], "max_hp": d["hp"],
		"chap": d["chap"], "max_chap": d["chap"], "weak": d["weak"].duplicate(), "revealed": false,
		"broken": 0, "speed": d["speed"], "atk": d["atk"], "node": spr, "home": spr.position,
		"frames": d["frames"], "alive": true, "lore": d["lore"], "phase": 1,
		"mark": d["mark"], "xam": 0, "base_scale": 1.0, "half_h": spr.texture.get_height() * d["px"] * 0.5,
		"phase_off": randf() * TAU, "busy": true, "dazed": 0, "windup": false, "windup_broken": false,
		"ho": false, "ran": false, "chao": false, "slow": 1.0}
	units.append(u)
	ui.add_enemy(u)
	return u


func _order() -> Array:
	var arr := []
	arr.append({"u": null, "s": 10.0 + randf() * 2.0})
	for u in units:
		if u["alive"]:
			arr.append({"u": u, "s": float(u["speed"]) + randf() * 2.0})
	arr.sort_custom(func(a, b): return a["s"] > b["s"])
	var out := []
	for e in arr:
		out.append(e["u"])
	ui.set_order(out)
	return out


func _alive() -> Array:
	return units.filter(func(u): return u["alive"])


func _check_end() -> void:
	if outcome != "":
		return
	if hero_hp <= 0:
		outcome = "lose"
	elif _alive().is_empty():
		outcome = "win"
	elif cfg.has("scripted_end"):
		for u in units:
			if u["id"] == "nghiet_tinh" and u["hp"] <= u["max_hp"] * float(cfg["scripted_end"]):
				outcome = "scripted"


func _body(u: Dictionary) -> Vector3:
	## Enemy sprites are centred on the body (see builder.billboard): this is where a blade lands.
	return (u["node"] as Sprite3D).global_position


func _cut_size(u: Dictionary) -> float:
	## Brush cuts scale with the body (a Mảnh Sành is the 1.0 reference).
	return clampf(float(u["half_h"]) * (u["node"] as Sprite3D).scale.y / 0.67, 1.0, 2.4)


func _screen(p: Vector3) -> Vector2:
	return world.rig.cam.unproject_position(p)


# ================================================================ intro / outro
func _intro() -> void:
	Audio.play_music(cfg.get("music", "battle"), 0.6)
	ui.message(cfg.get("intro", "Nghiệt lao tới!"))
	for u in units:
		var spr: Sprite3D = u["node"]
		var home: Vector3 = u["home"]
		spr.position = home + out_dir * 3.0
		spr.modulate = Color(1, 1, 1, 0)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(spr, "position", home, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(spr, "modulate:a", 1.0, 0.4)
	Audio.sfx("roar", -6.0)
	world.rig.shake(0.12, 0.4)
	await get_tree().create_timer(0.65, false).timeout
	for u in units:
		u["busy"] = false
	await Game.wait(0.6)


func _outro() -> void:
	ui.hide_menu()
	world.set_diorama(1.0)
	if men > 0 or bit_mat > 0:   # the glaze does not follow the hero out of the fight
		bit_mat = 0
		_set_men(0)
	match outcome:
		"win":
			hero_idle = false
			hero.act("victory")
			ui.message("Nghiệt tan.")
			stats["noi"] = chain_best
			ui.show_summary(stats)
			if AutoTest.active:
				await get_tree().create_timer(0.5).timeout
				AutoTest.shot("b_summary_" + str(cfg["enemies"][0]))
			await Game.wait(1.8)
		"lose":
			hero.act("kneel")
			ui.message("Không đứng dậy nổi nữa...")
			await Game.wait(1.4)
		"scripted":
			await Game.wait(0.3)
		"lose_lua":
			ui.message("Lúa hóa sứ.")
			hero.act("kneel")
			await Game.wait(1.6)
	for u in units:
		if is_instance_valid(u["node"]) and not cfg.get("keep_enemy_nodes", false):
			u["node"].queue_free()
		if u.has("light") and is_instance_valid(u["light"]):
			u["light"].queue_free()
	if _fill and is_instance_valid(_fill):
		_fill.queue_free()
	ui.queue_free()


# ================================================================ hero turn
func _tutorial(key: String, text: String, shot := "") -> void:
	## cfg "teach": which lessons this fight gives (the first fight only what the chores already taught).
	## Each lesson is given once a playthrough: a fight retried after a loss does not repeat them.
	if not cfg.get("tutorial", false) or tut.has(key) or Game.flags.has("taught_" + key):
		return
	if cfg.has("teach") and not (cfg["teach"] as Array).has(key):
		return
	tut[key] = true
	Game.flags["taught_" + key] = true
	await ui.tutorial(text, false, shot)


func _hero_turn() -> void:
	guarding = false
	hero.act("ready")
	if round_i == 1:
		await _tutorial("escort", "Trắng Tay không thấy, không nghe. Nó không đánh mình: tay nó quờ về phía [b]Lúa[/b]. Đứng chắn mà đỡ. Đỡ chuẩn thì tay bật ra; đang [b]Thủ[/b] thì đỡ tạm cũng chặn được. Tay nào lọt qua, men leo lên người Lúa; ba lớp là Lúa hóa sứ. Vỡ Chấp, đánh rạn hình hài thì nó rụt tay lại. Giữ cho tới khi Lúa qua được cột mốc.")
		await _tutorial("bars", "Nghiệt có hai thứ cần để ý. Thanh đỏ là [b]Hình[/b], sức chịu đựng hình hài của nó; về 0 thì hình hài tan. Những miếng khiên sứ là [b]Chấp[/b], mức độ nó bám chặt vào dục vọng nuôi mình.")
		await _tutorial("break", "Đánh trúng [b]điểm yếu[/b] thì vỡ một miếng Chấp. Vỡ hết, Nghiệt lảo đảo: mất lượt và chịu đòn gấp đôi.")
		await _tutorial("thau", "Chạm vào Nghiệt thì thoáng thấy nơi nó sinh ra. Làm việc đó có chủ ý là [b]Thấu[/b]: lộ điểm yếu và vạch dừng của nhát chém.")
	ui.set_hero(hero_hp, HERO_MAX_HP, potions, _status())
	var opened := _alive().filter(func(v): return v["ho"])
	if not opened.is_empty():
		await _mark_lesson("ho")
	for w in _alive():
		if w["windup"]:
			ui.message("%s đang dang tay. Chém dứt một nét để bẻ thế, hoặc Thủ mà chờ." % w["name"])
	if round_i <= 2:
		AutoTest.shot("b_%s_r%d" % [cfg["enemies"][0], round_i])
	while true:
		hero_idle = true
		var cmd: String = await ui.menu(potions)
		hero_idle = false
		match cmd:
			"bo":
				var t = await ui.pick_target(_alive(), opened[0] if not opened.is_empty() else null)
				if t == null:
					continue
				await _do_bo(t)
			"quet":
				await _do_quet()
			"nhatnet":
				if tinh < 3:
					ui.message("Tâm chưa tịnh: cần đủ 3 Tịnh.")
					continue
				var t3 = await ui.pick_target(_alive())
				if t3 == null:
					continue
				await _do_nhatnet(t3)
			"thu":
				await _do_thu()
			"thau":
				var t2 = await ui.pick_target(_alive())
				if t2 == null:
					continue
				await _do_thau(t2)
			"thuoc":
				if potions <= 0:
					ui.message("Hết thuốc rồi.")
					continue
				await _do_thuoc()
		break
	if _touched and cfg.get("glimpse_on_touch", false):
		await _glimpse()
	_touched = false
	for v in opened:   # not used this turn: it has gathered itself again
		_mark(v, "ho", false)
	if bit_mat > 0:
		bit_mat -= 1
		if bit_mat == 0:
			_set_men(0)
			ui.message("Lớp men trên mắt nứt ra, rơi xuống. Lại thấy rồi.")
	ui.set_hero(hero_hp, HERO_MAX_HP, potions, _status())


func _dmg_mult(grade: String) -> float:
	var m := 1.0
	match grade:
		"perfect": m = 1.6
		"good": m = 1.0
		_: m = 0.35
	if men >= 2:
		m *= 0.6
	return m


func _stroke_mult(grade: String, power: float, mark: float) -> float:
	## Một nét: the further the stroke went before stopping, the harder it lands, up to the mark.
	var m := 1.0
	match grade:
		"perfect": m = 1.8
		"good": m = 1.25
		_: m = lerpf(0.25, 0.9, clampf(power / maxf(mark, 0.01), 0.0, 1.0))
	if men >= 2:
		m *= 0.6
	return m


func _do_bo(u: Dictionary) -> void:
	await _tutorial("bo", "Như lúc chẻ củi: [b]Bổ[/b] là một nét. Giữ Space cho nét đi tới, thả đúng ở [b]vạch dừng[/b] là chém dứt. Thả sớm thì non tay. Quá vạch là [b]quá đà[/b]: Nghiệt nuốt lấy nhát chém và lớn thêm.")
	var spr: Sprite3D = u["node"]
	var opened: bool = u["ho"]   # a parry left it open: the stroke goes in there
	if opened:
		_mark(u, "ho", false)
	var target_pos := _approach(u, 1.4)
	if OS.get_cmdline_user_args().has("--seq") and not tut.has("seq_bo"):
		tut["seq_bo"] = true
		for q in 14:
			_shot_seq("seq_bo_%02d" % q, q * 0.09)
	await _hero_run(target_pos)
	var cut_arm := _cut_arm(u)
	# Nối nét: after a clean stroke the hand may go on (harder, faster, a new place to stop) or stop.
	# Stopping is what calms the mind (Tịnh). Going past the mark mid-chain feeds the whole chain to the Nghiệt.
	var chain := 0
	var mark: float = u["mark"]
	var draw_time := 1.1
	var held := false
	while true:
		hero.act("windup_deep")
		var at := _cut_point(u)
		_cam_push(at, 0.16 + 0.05 * chain, 0.8 if chain == 0 else 0.35)
		if not tut.has("shot_stroke_" + u["id"]):
			tut["shot_stroke_" + u["id"]] = true
			_shot_later("b_stroke_" + u["id"], 0.5)
		if chain == 1 and not tut.has("shot_chain"):
			tut["shot_chain"] = true
			_shot_later("b_chain", 0.3)
		var hint := "Giữ Space, thả ở vạch" if chain == 0 else "Nét %d: thả ở vạch mới" % (chain + 1)
		var into := opened and chain == 0
		if into:
			hint = "Chỗ hở: thả ở vạch"
		if timing.blind:   # the fourth beat lands on the mark: at least 0.88 s to it, a 0.22 s beat
			draw_time = maxf(draw_time, 0.88 / pow(mark, 1.0 / 1.45))
		var grade: String = await timing.stroke(_screen(at), mark, draw_time, u["revealed"] or into, hint, held)
		var power: float = timing.stroke_v
		await _strike_anim(at, grade, false, chain, 0.0, _cut_size(u))
		if grade == "over":
			Audio.sfx("chop_bad", -2.0, 0.1)
			stats["qua"] += 1
			_lose_tinh()
			if chain > 0:
				ui.message("Nét thứ %d quá đà. %s nuốt cả chuỗi." % [chain + 1, u["name"]])
			else:
				ui.message("Nhát chém quá đà. %s nuốt lấy nó." % u["name"])
			await _feed(u, 0.12 * (1 + chain))
			if u["id"] == "nghiet_tinh" and u["alive"]:
				_add_men(1)
			break
		Audio.sfx("chop" if grade != "miss" else "chop_bad", -2.0, 0.1 + 0.08 * chain)
		var dmg := int(round(14 * _stroke_mult(grade, power, mark) * (1.0 + 0.35 * chain)))
		var as_weak := false
		if grade == "miss":
			ui.message("Non tay: nét dừng sớm, đòn nhẹ." + (" Chỗ hở khép lại." if into else ""))
		elif into:
			dmg = int(round(dmg * 1.5))
			as_weak = true
			stats["the"] += 1
			AutoTest.note("the_bo_into_ho")
			ui.message("Bổ vào chỗ hở.")
			_float_text(_body(u) + Vector3(0, float(u["half_h"]) * 0.95, 0), "VÀO CHỖ HỞ", MARKS["ho"][1], 46)
		if grade == "perfect":
			stats["dut"] += 1
			if u["xam"] > 0:
				u["xam"] -= 1  # a clean stroke cuts the want back
		if chain > 0 and grade != "miss":
			_float_text(_body(u) + Vector3(0, float(u["half_h"]) * 0.75, 0), "NÉT %d" % (chain + 1), Color(0.95, 0.78, 0.38), 40)
		chain_best = maxi(chain_best, chain + 1)
		await _hit(u, dmg, "bo", grade, as_weak)
		if grade != "miss" and u["alive"]:   # a stroke that stopped has an edge: it leaves a crack
			_mark(u, "ran", true, chain == 0 and not into)
		if grade != "perfect":
			break
		if not u["alive"] or chain >= 2:
			# it ended on a clean stop by itself
			_chip_men()
			await _gain_tinh(hero.global_position + Vector3(0, 2.3, 0))
			break
		if not cfg.get("chain", true) or timing.blind:   # the first fight (one stroke, as at the chopping block), or eyes glazed
			_chip_men()
			await _gain_tinh(hero.global_position + Vector3(0, 2.3, 0))
			break
		await _tutorial("chain", "Chém dứt rồi thì có thể [b]nối nét[/b]. Vạch dừng của nét sau hiện sẵn trên dải giấy; nhấn và giữ Space trước khi vạch thời gian cháy hết thì chém tiếp, mạnh hơn và nhanh hơn một chút. Tối đa ba nét.\nĐể yên thì [b]dừng tay[/b]: biết dừng thì tâm thêm một giọt Tịnh. Quá đà giữa chừng thì Nghiệt nuốt [b]cả chuỗi[/b].")
		# the next stroke: a little faster, a new place to stop, shown on the strip before the hand commits
		var next_mark := randf_range(0.5, 0.82)
		var next_draw := 1.1 * pow(0.9, chain + 1)
		if not tut.has("shot_offer"):
			tut["shot_offer"] = true
			_shot_later("b_offer", 0.12)
		var go: bool = await timing.offer(1.2, _auto_chain(chain), "Nhấn giữ Space: nối nét", next_mark, next_draw)
		if not go:
			ui.message("Dừng tay.")
			_chip_men()
			await _gain_tinh(hero.global_position + Vector3(0, 2.3, 0))
			break
		chain += 1
		held = true
		mark = next_mark
		draw_time = next_draw
	if not cut_arm.is_empty():
		_arm_recoil(cut_arm, true)
	await Game.wait(0.15)
	hero.act("recover")
	_cam_reset(0.45)
	await Game.wait(0.15)
	await _hero_run(hero_home)
	hero.act("ready")
	if u["alive"] and u["ran"]:
		await _mark_lesson("ran")


func _auto_chain(chain: int) -> bool:
	## What the autotest does at the Nối nét window.
	match Game.auto_timing:
		"perfect": return chain == 0
		"over": return true
		"good", "miss": return false
	return randf() < 0.45


func _do_quet() -> void:
	await _tutorial("quet", "[b]Quét[/b]: giữ Space để vệt quét đi dần, thả ra khi nó vào vùng vàng. Y như quét sân. Trúng mọi Nghiệt. Giữ quá tay là [b]quá đà[/b]: cả bầy cùng lớn.")
	var alive := _alive()
	var near: Dictionary = alive[0]
	for u in alive:
		if (u["home"] as Vector3).distance_to(hero_home) < (near["home"] as Vector3).distance_to(hero_home):
			near = u
	var step: Vector3 = (near["home"] as Vector3) - out_dir * 1.8
	if not esc.is_empty():   # at the pass the sweep is made where the hero stands, in front of Lúa
		step = hero_home + out_dir * 0.4
	step.y = world.height_at(step.x, step.z)
	await _hero_run(step)
	hero.act("sweep_wind")
	var ec := Vector3.ZERO
	var lo := INF
	var hi := -INF
	for u in alive:
		var b := _body(u)
		ec += b
		var along := (b - hero_home).dot(out_dir)
		lo = minf(lo, along)
		hi = maxf(hi, along)
	ec /= float(alive.size())
	_cam_push(ec, 0.14, 0.8)
	var grade: String = await timing.hold(_screen(hero.global_position + Vector3(0, 1.2, 0)))
	Audio.sfx("sweep", 0.0)
	# the sweep runs across the screen through the whole pack, low on the bodies
	var span := clampf(hi - lo + 2.6, 2.8, 6.5)
	await _strike_anim(ec - Vector3(0, 0.12, 0), grade, true, 0, span)
	if grade == "over":
		stats["qua"] += 1
		_lose_tinh()
		ui.message("Quét quá tay. Cả bầy Nghiệt cùng lớn.")
		for u in alive:
			_feed(u, 0.06)
		await Game.wait(0.5)
	else:
		var dmg := int(round(8 * _dmg_mult(grade)))
		# the stroke reaches the nearest first and the farthest last
		alive.sort_custom(func(a, b): return _body(a).distance_to(hero.global_position) < _body(b).distance_to(hero.global_position))
		var burst := 0
		for i in alive.size():
			if i > 0:
				await get_tree().create_timer(0.07).timeout
			var v: Dictionary = alive[i]
			var cracked: bool = v["ran"] and grade != "miss"   # the sweep catches the edge of the crack and it bursts
			if cracked:
				_mark(v, "ran", false)
				burst += 1
				stats["the"] += 1
				AutoTest.note("the_quet_bursts_ran")
				_float_text(_body(v) + Vector3(0, float(v["half_h"]) * 0.95, 0), "BUNG!", MARKS["ran"][1], 50)
			_hit(v, dmg * (2 if cracked else 1), "quet", grade, cracked)
		if grade == "miss":
			ui.message("Thả sớm: vệt quét chưa tới, đòn nhẹ.")
		else:
			for v in alive:   # swept off their footing
				_mark(v, "chao", true, false)
			ui.message(("Vết rạn bung ra. " if burst > 0 else "") + ("Nó chao chân." if alive.size() == 1 else "Cả bầy chao chân."))
		if grade == "perfect":
			stats["dut"] += 1
			await Game.wait(0.3)
			await _gain_tinh(hero.global_position + Vector3(0, 2.3, 0))
	await Game.wait(0.45)
	_cam_reset(0.45)
	await _hero_run(hero_home)
	hero.act("ready")
	if _alive().any(func(v): return v["chao"]):
		await _mark_lesson("chao")


func _do_thu() -> void:
	guarding = true
	hero.act("guard")
	ui.message("Vào thế thủ. Đỡ đúng lúc sẽ phản đòn.")
	Audio.sfx("ui_ok", -6.0)
	await Game.wait(0.6)


func _do_thuoc() -> void:
	potions -= 1
	hero.act("item")
	Audio.sfx("heal", -2.0)
	var amt := 30
	hero_hp = mini(HERO_MAX_HP, hero_hp + amt)
	if bit_mat > 0:
		bit_mat = 0
		_set_men(0)
		ui.message("Lá thuốc rửa sạch lớp men trên mắt.")
	elif men > 0:
		_set_men(men - 1)
	_float_text(hero.global_position + Vector3(0, 2.0, 0), "+%d" % amt, Color(0.6, 1.0, 0.6))
	ui.set_hero(hero_hp, HERO_MAX_HP, potions, _status())
	await Game.wait(0.7)
	hero.act("ready")


func _do_thau(u: Dictionary) -> void:
	thau_used = true
	hero.act("thau")
	var spr: Sprite3D = u["node"]
	var tw := create_tween()
	tw.tween_property(spr, "modulate", Color(1.8, 1.8, 2.2), 0.25)
	tw.tween_property(spr, "modulate", Color.WHITE, 0.4)
	await Game.wait(0.3)
	await _glimpse()
	var weak_names := []
	for w in u["weak"]:
		weak_names.append(SKILL_NAMES[w])
	for v in units:
		if v["id"] == u["id"]:
			v["revealed"] = true
			ui.refresh_enemy(v)
	await ui.tutorial("[b]%s[/b]. %s\nĐiểm yếu: [b]%s[/b]. Vạch dừng của nó giờ đã rõ." % [u["name"], u["lore"], ", ".join(weak_names)], true)
	hero.act("ready")


func _glimpse() -> void:
	## Duyên: whoever touches a Nghiệt glimpses one end of it, where it was born. Once per vision; no words but
	## the captions of what is seen.
	if not cfg.has("vision") or Game.flags.has("vision_" + str(cfg["vision"]["id"])):
		return
	Game.flags["vision_" + str(cfg["vision"]["id"])] = true
	ui.visible_all(false)
	if cfg["vision"].has("stage"):
		await Overlay.vision_stage(load(cfg["vision"]["stage"]), cfg["vision"]["lines"])
	else:
		await Overlay.vision(cfg["vision"]["image"], cfg["vision"]["lines"])
	ui.visible_all(true)


func _hero_dash(p: Vector3) -> void:
	var tw := create_tween()
	tw.tween_property(hero, "global_position", p, 0.18 if not Game.fast else 0.05).set_trans(Tween.TRANS_QUAD)
	await tw.finished


func _hero_run(p: Vector3) -> void:
	## Run there on the real run cycle (with dust), instead of sliding in a pose.
	hero.clear_pose()
	await hero.move_to(p, 10.0, true)


func _strike_anim(at: Vector3, grade: String, sweep := false, variant := 0, span := 0.0, size := 1.0) -> void:
	## Smear frame and a short lunge into the blow, the ink cut, the camera snapping closer,
	## a hitch on a clean hit, then the follow-through.
	hero.act("sweep_smear" if sweep else "smear")
	var base: Vector3 = hero.global_position
	var lunge: Vector3 = base + out_dir * (0.55 if sweep else 0.38)
	lunge.y = world.height_at(lunge.x, lunge.z)
	var tw: Tween = hero.create_tween()
	tw.tween_property(hero, "global_position", lunge, 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.12)
	tw.tween_property(hero, "global_position", base, 0.3).set_trans(Tween.TRANS_SINE)
	_ink_slash(at, grade, sweep, size, variant, span)
	_cam_punch(at, grade)
	if grade == "perfect":
		_hitstop(0.09)
	await get_tree().create_timer(0.08, true, false, true).timeout
	hero.act("sweep_strike" if sweep else "follow")


func _ink_slash(at: Vector3, grade: String, sweep := false, size := 1.0, variant := 0, span := 0.0) -> void:
	## One brush cut through the body: the blade's light runs first, then the ink lands and breaks into flecks.
	## variant: 0 the down cut, 1 the rising return (flipped), 2 the flat cut (the third stroke of a chain).
	var s := Sprite3D.new()
	var flat := sweep or variant == 2
	s.texture = Assets.tex("res://assets/sprites/fx/ink_sweep.png" if flat else "res://assets/sprites/fx/ink_slash.png")
	s.hframes = 6
	var width := span if span > 0.0 else (3.0 if flat else 2.6) * size
	match grade:
		"over": width *= 1.3   # it does not stop where it should: the cut runs on past the body
		"miss": width *= 0.7
	s.pixel_size = width / (256.0 if flat else 160.0)
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	s.no_depth_test = true
	s.shaded = false
	s.render_priority = 6
	s.flip_v = variant == 1
	match grade:
		"over": s.modulate = Color(1.35, 0.42, 0.36)
		"miss": s.modulate = Color(1, 1, 1, 0.5)
		_: s.modulate = Color.WHITE
	world.add_child(s)
	s.global_position = at
	var times := [0.03, 0.04, 0.08, 0.06, 0.06, 0.07]
	for f in 6:
		if not is_instance_valid(s):
			return
		s.frame = f
		await get_tree().create_timer(times[f], true, false, true).timeout
	s.queue_free()


func _cam_to(p: Vector3, t: float, snap := false) -> void:
	## One camera move at a time (a new one replaces the last). Snaps ignore hit-stop.
	var cam: Camera3D = world.rig.cam
	if _cam_tw and _cam_tw.is_valid():
		_cam_tw.kill()
	_cam_tw = cam.create_tween()
	_cam_tw.set_ignore_time_scale(snap)
	_cam_tw.tween_property(cam, "global_position", p, t).set_trans(Tween.TRANS_QUAD if snap else Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _cam_push(focus: Vector3, amt := 0.1, t := 0.35) -> void:
	# lean toward the space between the hero and the target, so a tall Nghiệt never pushes the hero out of shot
	_cam_to(_cam_base.lerp(focus.lerp(_hero_chest(), 0.4), amt), t)


func _cam_punch(focus: Vector3, grade: String) -> void:
	## On contact the camera snaps a step closer and stays there until _cam_reset.
	var amt := 0.3 if grade == "perfect" else (0.24 if grade != "miss" else 0.18)
	_cam_to(_cam_base.lerp(focus.lerp(_hero_chest(), 0.4), amt), 0.07, true)


func _cam_reset(t := 0.4) -> void:
	_cam_to(_cam_base, t)


func _feed(u: Dictionary, heal_frac := 0.12) -> void:
	## Xâm: an overshot stroke is swallowed. The Nghiệt heals, grows and hits harder.
	if not u["alive"]:
		return
	var spr: Sprite3D = u["node"]
	if u["ran"] or u["ho"]:
		u["ran"] = false
		u["ho"] = false
		_float_text(_body(u) + Vector3(0, float(u["half_h"]) * 0.95, 0), "liền lại", Color(0.85, 0.6, 0.55), 36)
	u["xam"] = mini(3, u["xam"] + 1)
	var heal := int(round(u["max_hp"] * heal_frac))
	if not tut.has("shot_feed"):
		tut["shot_feed"] = true
		_shot_later("b_feed", 0.25)
	u["hp"] = mini(u["max_hp"], u["hp"] + heal)
	u["atk"] += 2
	Audio.sfx("roar", -10.0, 0.1)
	_float_text(_body(u) + Vector3(0, float(u["half_h"]) * 0.5, 0), "+%d" % heal, Color(0.95, 0.4, 0.32), 48)
	var sc: float = u["base_scale"] * (1.0 + 0.12 * u["xam"])
	u["busy"] = true
	var tw := spr.create_tween()
	tw.tween_property(spr, "modulate", Color(1.7, 0.6, 0.5), 0.1)
	tw.parallel().tween_property(spr, "scale", Vector3.ONE * sc * 1.1, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(spr, "scale", Vector3.ONE * sc, 0.22)
	tw.parallel().tween_property(spr, "modulate", Color.WHITE, 0.3)
	ui.refresh_enemy(u)
	await get_tree().create_timer(0.45).timeout
	u["busy"] = false


# ================================================================ Nối thế: what one move leaves, the next one uses
## Đỡ chuẩn -> HỞ: Bổ into it counts as the weak point, half again as hard, the stop mark plain to see.
## Bổ (a stroke that stopped) -> RẠN: Quét across it bursts the crack, twice as hard, as the weak point.
## Quét -> CHAO: its next turn comes late and slow, easier to parry clean, and a clean parry opens it again.
## An overshot stroke is swallowed and closes the crack and the opening.
const MARKS := {"ho": ["HỞ", Color(1.0, 0.82, 0.4)], "ran": ["RẠN", Color(0.78, 0.9, 1.0)], "chao": ["CHAO", Color(0.95, 0.78, 0.6)]}
const MARK_LESSONS := {
	"ho": "Đỡ chuẩn thì đòn nó hụt đà, thân nó [b]hở[/b] ra. Lượt này [b]Bổ[/b] vào con đang HỞ: vạch dừng hiện rõ, đòn nặng gấp rưỡi và tính như trúng điểm yếu. Hết lượt này thì chỗ hở khép lại.",
	"ran": "Nét chém biết dừng thì có mép, để lại [b]vết rạn[/b] trên hình hài nó. [b]Quét[/b] qua con đang RẠN thì vết rạn bung ra: đòn quét lên nó nặng gấp đôi và tính như trúng điểm yếu. Quá đà thì nó nuốt nét, vết rạn liền lại.",
	"chao": "Quét trúng thì nó [b]chao[/b] chân. Lượt tới của con đang CHAO, đòn nó tới chậm hơn, dễ đỡ chuẩn hơn. Đỡ chuẩn thì nó lại hở.",
}
const CYCLE_LESSON := "\n[b]Đỡ[/b] cho nó hở. [b]Bổ[/b] vào chỗ hở thì nó rạn. [b]Quét[/b] vết rạn thì nó chao. Nó chao thì dễ đỡ. Việc trước gây ra việc sau."


func _mark(u: Dictionary, key: String, on: bool, pop := true) -> void:
	if not u["alive"] or bool(u[key]) == on:
		return
	u[key] = on
	if on:
		AutoTest.note("mark_%s %s" % [key, u["name"]])
	if on and pop:   # over where it stands, not where it is mid-lunge
		_float_text((u["home"] as Vector3) + Vector3(0, float(u["half_h"]) * 1.7, 0), MARKS[key][0], MARKS[key][1], 44)
	ui.refresh_enemy(u)


func _mark_lesson(key: String) -> void:
	## The third of the three to be taught also names the whole round of them.
	var seen := 0
	for k in MARK_LESSONS:
		if k != key and Game.flags.has("taught_" + k):
			seen += 1
	await _tutorial(key, MARK_LESSONS[key] + (CYCLE_LESSON if seen == 2 else ""), "b_lesson_" + key)


func _gain_tinh(at: Vector3) -> void:
	if tinh >= 3:
		return
	tinh += 1
	ui.set_tinh(tinh)
	_float_text(at, "Tịnh", Color(0.65, 0.9, 1.0), 40)
	Audio.sfx("parry", -14.0)
	if tinh == 3:
		ui.message("Tâm đã tịnh. Có thể dùng Nhất Nét.")
		await _tutorial("nhatnet", "Mỗi lần chém dứt rồi dừng tay, hoặc đỡ chuẩn, tâm thêm một giọt [b]Tịnh[/b]. Đủ ba giọt thì mở [b]Nhất Nét[/b]: một nét chém dứt, phá hết Chấp và cắt sạch Xâm. Chỉ một lần quá đà là tâm loạn, mất hết Tịnh.")


func _lose_tinh() -> void:
	if tinh > 0:
		tinh = 0
		ui.set_tinh(0)
		_float_text(hero.global_position + Vector3(0, 2.4, 0), "tâm loạn", Color(0.8, 0.5, 0.5), 36)


func _status() -> String:
	if bit_mat > 0:
		return "BỊT MẮT: còn %d lượt" % bit_mat
	return ["", "Men sứ tới chân", "Men sứ tới tay: đòn yếu đi", ""][men]


func _add_men(n: int) -> void:
	## Xâm: near Trắng Tay the want to shut out what one fears is swollen in the hero as well, and its touch
	## glazes them. Feet, hands, then the eyes: Bịt Mắt for two turns, as the people behind the gate.
	if bit_mat > 0 or n <= 0:
		return
	_set_men(mini(3, men + n))
	var words := ["", "Men tới chân", "Men tới tay", "BỊT MẮT"]
	_float_text(hero.global_position + Vector3(0, 2.25, 0), words[men], Color(0.72, 0.85, 1.0), 58 if men >= 3 else 40)
	Audio.sfx("crack", -2.0 if men >= 3 else -9.0, 0.1)
	if men >= 3:
		bit_mat = 2
		ui.message("Men sứ phủ kín mắt. Không thấy gì nữa. Nghe hai tiếng gõ, giữ nhịp: nhịp thứ tư thì đỡ, thì thả tay.")
		world.rig.shake(0.08, 0.3)
		_shot_later("b_blind", 0.45)
	elif men == 2:
		ui.message("Men sứ leo tới tay. Đòn chém yếu đi. Dừng tay đúng lúc thì men nứt ra.")
	ui.set_hero(hero_hp, HERO_MAX_HP, potions, _status())


func _chip_men() -> void:
	## Stopping by choice is the one thing the want cannot swell: a layer cracks off.
	if men <= 0 or bit_mat > 0:
		return
	_set_men(men - 1)
	_float_text(hero.global_position + Vector3(0, 2.6, 0), "men nứt", Color(0.85, 0.92, 1.0), 34)
	_shards(hero.global_position + Vector3(0, 0.6, 0), 4)
	ui.set_hero(hero_hp, HERO_MAX_HP, potions, _status())


func _set_men(v: int) -> void:
	men = v
	hero.set_tint(Color.WHITE.lerp(Color(0.78, 0.86, 1.2), clampf(men / 3.0, 0.0, 1.0)))
	var blind := men >= 3
	timing.blind = blind
	ui.set_blind(blind)
	if blind and _glaze == null:
		# nothing of the field shows through: glazed white, a little brighter in the middle, the menu and the
		# hero's own panel still on top of it
		var g := Gradient.new()
		g.set_color(0, Color(0.93, 0.95, 0.98, 1.0))
		g.set_color(1, Color(0.74, 0.79, 0.88, 1.0))
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(1.05, 0.5)
		gt.width = 256
		gt.height = 144
		_glaze = TextureRect.new()
		_glaze.texture = gt
		_glaze.set_anchors_preset(Control.PRESET_FULL_RECT)
		_glaze.stretch_mode = TextureRect.STRETCH_SCALE
		_glaze.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_glaze.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_glaze.modulate.a = 0.0
		ui.add_child(_glaze)
		ui.move_child(_glaze, 0)
	if _glaze:
		_glaze.create_tween().tween_property(_glaze, "modulate:a", 1.0 if blind else 0.0, 0.5)


func _do_nhatnet(u: Dictionary) -> void:
	tinh = 0
	ui.set_tinh(0)
	var spr: Sprite3D = u["node"]
	var target_pos := _approach(u, 1.6)
	await _hero_run(target_pos)
	hero.act("windup_deep")
	var at := _cut_point(u)
	_cam_push(at, 0.24, 0.7)
	ui.message("Nhất Nét.")
	_shot_later("b_nhatnet_wind", 0.2)
	await Game.wait(0.6)
	# one flat stroke, 一: the light, a beat of white, then the ink
	hero.act("smear")
	_ink_slash(at, "perfect", true, 1.0, 2, 4.6 * maxf(1.0, _cut_size(u) * 0.8))
	Overlay.flash(Color(1, 0.98, 0.92, 0.55), 0.35)
	_cam_punch(at, "perfect")
	_shot_later("b_nhatnet_hit", 0.05)
	_hitstop(0.22)
	world.rig.shake(0.2, 0.3)
	Audio.sfx("chop", 0.0)
	stats["dut"] += 1
	if men > 0 or bit_mat > 0:
		bit_mat = 0
		_set_men(0)
	u["xam"] = 0
	if u["broken"] == 0:
		u["chap"] = 0
		u["broken"] = 2
		Audio.sfx("shatter", 0.0)
		_shards(spr.global_position, 26)
		_float_text(_body(u) + Vector3(0, float(u["half_h"]) * 0.6, 0), "VỠ CHẤP!", Color(0.75, 0.9, 1.0), 64)
	await get_tree().create_timer(0.08, true, false, true).timeout
	hero.act("follow")
	await _hit(u, 30, "nhatnet", "perfect")
	await Game.wait(0.3)
	hero.act("recover")
	_cam_reset(0.5)
	await Game.wait(0.2)
	await _hero_run(hero_home)
	hero.act("ready")


func _hit(u: Dictionary, dmg: int, kind: String, grade: String, as_weak := false) -> void:
	if not u["alive"]:
		return
	if kind != "counter":
		_touched = true
	var spr: Sprite3D = u["node"]
	var mult := 2.0 if u["broken"] > 0 or u["dazed"] > 0 else 1.0
	dmg = int(dmg * mult)
	u["hp"] = max(0, u["hp"] - dmg)
	var pushed := false
	if not esc.is_empty() and u["id"] == "nghiet_tinh":
		u["hp"] = maxi(1, u["hp"])   # it is not beaten here, only held back
		var marks := int((1.0 - float(u["hp"]) / float(u["max_hp"])) / 0.25)
		if marks > int(u.get("push_marks", 0)):
			u["push_marks"] = marks
			pushed = true
	world.rig.shake(0.06 if grade != "perfect" else 0.14, 0.18)
	_float_text(_body(u) + Vector3(0, float(u["half_h"]) * 0.3, 0), str(dmg), Color(1, 0.95, 0.85) if mult == 1.0 else Color(1, 0.7, 0.3), 60 if grade == "perfect" else 50)
	u["busy"] = true
	spr.frame = 4 if u["id"] == "manh_tinh" else 5
	spr.modulate = Color(2.5, 2.5, 2.5)
	var tw := create_tween()
	tw.tween_property(spr, "modulate", Color.WHITE, 0.25)
	# knocked back along the line of the blow, squashed, then springs back
	var base_pos := spr.position
	var kb := spr.create_tween()
	kb.tween_property(spr, "position", base_pos + out_dir * (0.45 if grade == "perfect" else 0.25), 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	kb.tween_property(spr, "position", base_pos, 0.26).set_trans(Tween.TRANS_SINE)
	var sc: float = u["base_scale"] * (1.0 + 0.12 * u["xam"])
	var sq := spr.create_tween()
	sq.tween_property(spr, "scale", Vector3(sc * 1.12, sc * 0.86, sc), 0.06)
	sq.tween_property(spr, "scale", Vector3.ONE * sc, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if grade == "good":
		_hitstop(0.04)
	if u["windup"] and not u["windup_broken"] and grade == "perfect" and (kind == "bo" or kind == "nhatnet"):
		u["windup_broken"] = true
		ui.message("Bẻ được thế! Mấy cánh tay rụng khỏi vòng hào quang.")
		_float_text(_body(u) + Vector3(0, float(u["half_h"]) * 0.85, 0), "BẺ THẾ", Color(0.95, 0.78, 0.38), 56)
		_shards(spr.global_position + Vector3(0, float(u["half_h"]) * 0.4, 0), 16)
		Audio.sfx("shatter", -4.0, 0.1)
	var shed := false
	if grade != "miss" and u["broken"] == 0 and (u["weak"].has(kind) or as_weak):
		u["chap"] -= 1
		Audio.sfx("shatter", -8.0, 0.1)
		_shards(spr.global_position, 8)
		if u["chap"] <= 0:
			u["chap"] = 0
			u["broken"] = 2
			Audio.sfx("shatter", 0.0)
			_shards(spr.global_position, 26)
			_float_text(_body(u) + Vector3(0, float(u["half_h"]) * 0.6, 0), "VỠ CHẤP!", Color(0.75, 0.9, 1.0), 64)
			world.rig.shake(0.22, 0.35)
			if u["windup"]:
				u["windup"] = false
				spr.modulate = Color.WHITE
			shed = u["id"] == "nghiet_tinh"
	ui.refresh_enemy(u)
	await Game.wait(0.3)
	u["busy"] = false
	if u["hp"] <= 0:
		await _kill(u)
	else:
		if pushed:
			u["dazed"] = maxi(int(u["dazed"]), 1)
			ui.message("Hình hài nó mẻ một mảng. Trắng Tay rụt tay lại một lượt.")
			_float_text(_body(u) + Vector3(0, float(u["half_h"]) * 0.7, 0), "RỤT TAY", Color(0.95, 0.78, 0.38), 48)
		if shed:
			await _shed_faces(u)


func _kill(u: Dictionary) -> void:
	u["alive"] = false
	var spr: Sprite3D = u["node"]
	ui.remove_enemy(u)
	Audio.sfx("shatter", -2.0, 0.1)
	if u["id"] == "manh_tinh":
		spr.frame = 5
	_shards(spr.global_position, 20)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(spr, "modulate:a", 0.0, 0.5)
	tw.tween_property(spr, "position:y", spr.position.y - 0.3, 0.5)
	await tw.finished
	spr.visible = false


# ================================================================ enemy turn
func _enemy_turn(u: Dictionary) -> void:
	var spr: Sprite3D = u["node"]
	u["slow"] = 1.0
	if u["chao"]:   # still reeling from the sweep: this turn its blows come late and slow
		_mark(u, "chao", false)
		u["slow"] = 1.35
		AutoTest.note("chao_slow %s" % u["name"])
	if u["broken"] > 0:
		u["broken"] -= 1
		if u["broken"] == 0:
			u["chap"] = u["max_chap"]
			if u["id"] == "nghiet_tinh" and u["phase"] == 1:
				u["phase"] = 2
				u["weak"] = ["quet"]
				u["revealed"] = false
				ui.message("Trắng Tay đổi hình. Điểm yếu của nó đã khác.")
				await Game.wait(1.0)
			ui.refresh_enemy(u)
		else:
			ui.message("%s đang lảo đảo." % u["name"])
			_float_text(_body(u) + Vector3(0, float(u["half_h"]) * 0.5, 0), "...", Color(0.8, 0.85, 0.95))
			await Game.wait(0.7)
			return
	if u["dazed"] > 0:
		u["dazed"] -= 1
		ui.message("%s còn lảo đảo, chưa gom được tay." % u["name"])
		_float_text(_body(u) + Vector3(0, float(u["half_h"]) * 0.5, 0), "...", Color(0.8, 0.85, 0.95))
		await Game.wait(0.7)
		return
	var boss: bool = u["id"] == "nghiet_tinh"
	if boss and u["windup"]:
		await _flurry(u)
		return
	if boss:
		boss_attacks += 1
		if boss_attacks % 3 == 0:
			await _windup(u)
			return
	var at_lua := boss and not esc.is_empty()
	ui.message(("Tay Trắng Tay quờ về phía Lúa." if at_lua else "%s tấn công!" % u["name"])
		+ (" Nó còn chao, đòn tới chậm." if u["slow"] > 1.0 else ""))
	u["busy"] = true
	var home: Vector3 = u["home"]
	# wind-up: creep in, rear back, a red glint
	var lunge := home - out_dir * (1.1 if not boss else 0.5)
	spr.frame = 2 if not boss else 3
	var tw := create_tween()
	tw.tween_property(spr, "position", lunge, 0.3).set_trans(Tween.TRANS_QUAD)
	await tw.finished
	if not tut.has("defend") and cfg.get("tutorial", false):
		await _tutorial("defend", "Như lúc gánh nước: nó tới nơi rồi hẵng đỡ. Nhấn [b]Space[/b] đúng lúc vòng đỏ khép vào vòng trắng.")
	await _telegraph(spr, boss, false)
	var travel := 0.72 if boss else 0.62
	_attack_shots(u, "", travel)
	await _strike(u, "reach" if boss else "pounce", travel, u["atk"])
	if at_lua and u["alive"] and hero_hp > 0 and outcome == "":   # a thousand arms: a second follows close behind
		await Game.wait(0.05)
		await _strike(u, "reach", 0.5, int(round(float(u["atk"]) * 0.6)), 1, 2)
	await _return_home(u)


func _attack_shots(u: Dictionary, suffix: String, travel: float) -> void:
	var shot_key: String = "shot_def_" + u["id"] + suffix
	if tut.has(shot_key):
		return
	tut[shot_key] = true
	_shot_later("b_attack_" + u["id"] + suffix, travel * 0.55)
	_shot_later("b_impact_" + u["id"] + suffix, travel + 0.02)
	if OS.get_cmdline_user_args().has("--seq"):
		for q in 8:
			_shot_seq("seq_%s%s_%d" % [u["id"], suffix, q], q * 0.12)


func _strike(u: Dictionary, kind: String, travel: float, base: int, arms := 3, arm0 := 0, counter := 10) -> String:
	## One blow at the hero: it flies while the defend prompt runs and lands exactly when the ring closes.
	## kind: "reach" (Trắng Tay's arms), "grab" (one arm that clamps), "ground" (hands out of the earth),
	## "pounce" (a Mảnh Sành). A grab or the ground hands not parried leave Hóa Sứ. Returns the defend grade.
	var spr: Sprite3D = u["node"]
	var boss: bool = u["id"] == "nghiet_tinh"
	travel *= float(u["slow"])
	if timing.blind:   # it gropes for what it cannot see either: slower, so the count-in has room before it lands
		travel = maxf(travel * 1.6, 0.88)
	var start_t := _clock
	var proj := {"nodes": []}
	match kind:
		"ground":
			_ground_hands(spr, travel, proj)
		"reach", "grab":
			_reach_arms(spr, travel, proj, arms, arm0)
		_:
			_pounce(spr, travel)
	# the prompt runs on its own; the hit resolves the instant the blow arrives (or the late window closes)
	timing.defend(_screen(hero.global_position + Vector3(0, 1.0, 0)), _screen(spr.global_position), travel)
	var late: float = 0.17 * timing._scale()
	while true:
		var e: float = _clock - start_t
		if timing.result != "" and e >= travel:
			break
		if e >= travel + late:
			break
		await get_tree().process_frame
	var grade: String = timing.result if timing.result != "" else "miss"
	timing.close_defend()
	var m := 1.0
	if guarding:
		m = {"perfect": 0.0, "good": 0.3, "miss": 0.6}[grade]
	else:
		m = {"perfect": 0.4, "good": 0.7, "miss": 1.0}[grade]
	# at the pass the arm is not after the hero: a clean parry turns it, in Thủ a half one does too; otherwise it
	# goes past to Lúa (missed outright, it does not even touch the hero on the way)
	var slipped: bool = boss and not esc.is_empty() and (grade == "miss" or (grade == "good" and not guarding))
	if slipped and grade == "miss":
		m = 0.0
	var dmg := int(round(base * m))
	_impact(grade, boss, spr, proj)
	if slipped:
		_glaze_lua(u)
	if grade == "perfect":
		stats["do"] += 1
		hero.act("parry")
		_mark(u, "ho", true)   # met at the very moment, its reach is spent and it stands open
	if dmg > 0:
		hero_hp = max(0, hero_hp - dmg)
		hero.act("hurt_b" if grade == "miss" else "hurt")
		hero.flash(1)
		_float_text(hero.global_position + Vector3(0, 2.0, 0), str(dmg), Color(1, 0.5, 0.4), 72 if grade == "miss" else 56)
	# its touch glazes: a grab or the ground hands that get through, or an arm taken full on
	if boss and not slipped and (grade == "miss" or (grade == "good" and (kind == "ground" or kind == "grab"))):
		_add_men(1)
	ui.set_hero(hero_hp, HERO_MAX_HP, potions, _status())
	if grade == "perfect":
		await _gain_tinh(hero.global_position + Vector3(0, 2.3, 0))
	if guarding and grade == "perfect" and counter > 0 and u["alive"]:
		await Game.wait(0.12)
		hero.act("smear")
		_ink_slash(spr.global_position, "perfect", false, _cut_size(u), 1)
		_cam_punch(spr.global_position, "perfect")
		Audio.sfx("chop", -2.0)
		ui.message("Phản đòn!")
		await _hit(u, counter, "counter", "good")
		u["busy"] = u["alive"]   # still mid-move: the caller sends it home
	return grade


func _return_home(u: Dictionary) -> void:
	var spr: Sprite3D = u["node"]
	await Game.wait(0.35)
	if is_instance_valid(spr) and u["alive"]:
		spr.frame = 0
		var tw2 := create_tween()
		tw2.tween_property(spr, "position", u["home"], 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await tw2.finished
	u["busy"] = false
	if hero_hp > 0:
		hero.act("guard" if guarding else "ready")


# ================================================================ Chắn đường: standing between Trắng Tay and Lúa
func _escort_setup() -> void:
	## cfg "escort": Lúa, held up by the young man, makes for the marker one step a round. Trắng Tay does not
	## see or hear the hero. It does not need to come closer: its arms reach Lúa from where it stands, and all the
	## hero can do is stand in their way. So the hero keeps to Lúa's side (cutting at the arms there, never going
	## off to its body) and falls back with Lúa. An arm that gets past puts a layer of glaze on Lúa; three and
	## Lúa is porcelain.
	var e: Dictionary = cfg["escort"]
	var lateral := Vector3(-out_dir.z, 0, out_dir.x)
	var start: Vector3 = world.MARKER + out_dir * 2.3 + lateral * 0.7
	var goal: Vector3 = world.MARKER - out_dir * 0.8 + lateral * 0.7
	start.y = world.height_at(start.x, start.z)
	goal.y = world.height_at(goal.x, goal.z)
	var lua = world.actor(e["who"])
	if lua == null:
		lua = world.spawn(e["who"], e["sheet"], start, "down")
	var helper = world.actor(e["helper"])
	if helper == null:
		helper = world.spawn(e["helper"], e["helper_sheet"], start, "down")
	for a in [lua, helper]:
		a.visible = true
		a.clear_pose()
	lua.set_tint(Color.WHITE)
	lua.global_position = start
	helper.global_position = start + lateral * 0.55
	lua.face_point(goal)
	helper.face_point(goal)
	esc = {"lua": lua, "helper": helper, "total": int(e.get("rounds", 6)), "left": int(e.get("rounds", 6)),
		"from": start, "to": goal, "lat": lateral * 0.55, "men": 0}
	hero_home = _guard_spot()
	hero.global_position = hero_home
	for u in units:
		if u["id"] == "nghiet_tinh":
			u["push_marks"] = 0
	_update_track()


func _guard_spot() -> Vector3:
	## Where the hero stands: a pace in front of Lúa, toward Trắng Tay.
	var p: Vector3 = (esc["lua"] as Node3D).global_position + out_dir * 1.0
	p.y = world.height_at(p.x, p.z)
	return p


func _update_track() -> void:
	if esc.is_empty():
		return
	ui.set_track("Lúa: còn %d bước tới cột mốc\nMen trên người Lúa: %d/3" % [esc["left"], esc["men"]])


func _approach(u: Dictionary, back: float) -> Vector3:
	## Where the hero goes to strike u. At the pass, against Trắng Tay, only half a pace out from Lúa's side.
	if not esc.is_empty() and u["id"] == "nghiet_tinh":
		return hero_home + out_dir * 0.5
	var p: Vector3 = (u["node"] as Sprite3D).global_position - out_dir * back
	p.y = world.height_at(p.x, p.z)
	return p


func _cut_point(u: Dictionary) -> Vector3:
	## Where the blade lands on u: its body, or at the pass, the arm reaching in front of the hero.
	if not esc.is_empty() and u["id"] == "nghiet_tinh":
		return hero_home + out_dir * 1.8 + Vector3(0, 1.15, 0)
	return _body(u)


func _cut_arm(u: Dictionary) -> Dictionary:
	## At the pass: the arm the hero is cutting at, reaching in from Trắng Tay toward Lúa.
	if esc.is_empty() or u["id"] != "nghiet_tinh":
		return {}
	var from: Vector3 = (u["node"] as Sprite3D).global_position + Vector3(0, 1.2, 0)
	var to := _cut_point(u)
	var arm := {"a": from, "m": (from + to) * 0.5 + Vector3(0, 1.4, 0), "b": to, "u": 0.0, "mode": "reach", "segs": [], "hand": null}
	_run_arm(arm, 0.3, 0.0)
	return arm


func _arm_to_lua(u: Dictionary) -> void:
	## An arm that got past the hero: it goes on to Lúa and closes on Lúa's shoulder, then lets go.
	var lua_p: Vector3 = (esc["lua"] as Node3D).global_position + Vector3(0, 1.1, 0)
	var from: Vector3 = (u["node"] as Sprite3D).global_position + Vector3(0, 1.0, 0)
	var arm := {"a": from, "m": (from + lua_p) * 0.5 + Vector3(0, 0.6, 0), "b": lua_p, "u": 0.0, "mode": "reach", "segs": [], "hand": null}
	_run_arm(arm, 0.22, 0.0)
	await get_tree().create_timer(0.3).timeout
	if arm["hand"] != null and is_instance_valid(arm["hand"]):
		(arm["hand"] as Sprite3D).frame = 1
	await get_tree().create_timer(0.35).timeout
	arm["mode"] = "retract"


func _glaze_lua(u: Dictionary) -> void:
	## It touched Lúa: the glaze climbs a layer. Three and Lúa is porcelain.
	if esc.is_empty() or outcome != "":
		return
	_arm_to_lua(u)
	esc["men"] += 1
	AutoTest.note("lua_touched %d (round %d, guarding %s)" % [esc["men"], round_i, str(guarding)])
	var lua = esc["lua"]
	await get_tree().create_timer(0.3).timeout
	lua.flash(2)
	lua.set_tint(Color.WHITE.lerp(Color(1.45, 1.5, 1.7), float(esc["men"]) / 3.0))
	_float_text(lua.global_position + Vector3(0, 2.1, 0), "men lên người Lúa", Color(0.75, 0.85, 1.0), 40)
	ui.message("Một bàn tay lọt qua, chạm vào Lúa." if esc["men"] < 3 else "Men phủ kín người Lúa.")
	Audio.sfx("crack", -3.0, 0.1)
	_update_track()
	if esc["men"] >= 3:
		outcome = "lose_lua"


func _escort_round() -> void:
	## A round has gone by: the young man has got Lúa one step nearer the marker, and the hero falls back with them.
	esc["left"] -= 1
	var k := 1.0 - float(esc["left"]) / float(esc["total"])
	var p: Vector3 = (esc["from"] as Vector3).lerp(esc["to"], k)
	p.y = world.height_at(p.x, p.z)
	esc["lua"].move_to(p, 1.1)
	esc["helper"].move_to(p + esc["lat"], 1.1)
	var g := p + out_dir * 1.0
	g.y = world.height_at(g.x, g.z)
	hero_home = g
	hero.clear_pose()
	await hero.move_to(g, 1.2)
	hero.face("left")
	hero.act("guard" if guarding else "ready")
	esc["lua"].face_point(esc["to"])
	_update_track()
	if esc["left"] <= 0:
		ui.message("Lúa qua được cột mốc.")
		await Game.wait(0.6)
		outcome = "scripted"


# ================================================================ Trắng Tay's own moves
func _windup(u: Dictionary) -> void:
	## Nghìn Tay, first half. It spreads every arm, its halo brightens, and it listens; nothing lands this turn.
	## Before its next turn a clean stroke breaks the stance (only one arm will come), and Thủ answers each arm parried.
	var spr: Sprite3D = u["node"]
	u["windup"] = true
	u["windup_broken"] = false
	u["busy"] = true
	ui.message("Trắng Tay dang hết những cánh tay ra.")
	spr.frame = 4
	Audio.sfx("glint", -2.0, 0.05)
	Audio.sfx("roar", -12.0, 0.1)
	world.rig.shake(0.05, 0.6)
	Overlay.flash(Color(0.85, 0.93, 1.0, 0.16), 0.5)
	_float_text(_body(u) + Vector3(0, float(u["half_h"]) * 0.85, 0), "NGHÌN TAY", Color(0.72, 0.88, 1.0), 52)
	_shot_later("b_windup", 0.5)
	await Game.wait(1.0)
	u["busy"] = false


func _flurry(u: Dictionary) -> void:
	## Nghìn Tay, second half. Blind, the arms come one after another on an uneven beat, then hands burst out of
	## the ground. Parry every one and it overreaches: it reels and loses its next turn.
	var spr: Sprite3D = u["node"]
	var broke: bool = u["windup_broken"]
	u["windup"] = false
	u["busy"] = true
	spr.modulate = Color.WHITE
	ui.message(("Thế đã gãy. Chỉ vài cánh tay quờ tới." if broke else "Trắng Tay quờ hết những cánh tay tới!")
		+ (" Nó còn chao, tay tới chậm." if u["slow"] > 1.0 else ""))
	spr.frame = 3
	var tw := create_tween()
	tw.tween_property(spr, "position", (u["home"] as Vector3) - out_dir * 0.5, 0.3).set_trans(Tween.TRANS_QUAD)
	await tw.finished
	await _telegraph(spr, true, true)
	var beats: Array = [0.62] if broke else [0.62, 0.44, 0.74, 0.48]
	var parried := 0
	var through := 0
	for i in beats.size():
		spr.frame = 3 if i % 2 == 0 else 4
		if i == 0:
			_attack_shots(u, "_flurry", beats[0])
		var g := await _strike(u, "reach", beats[i], int(round(float(u["atk"]) * 0.55)), 1 if i % 2 == 0 else 2, i, 4)
		if g == "perfect":
			parried += 1
		elif g == "miss":
			through += 1
		if hero_hp <= 0 or not u["alive"]:
			break
		await Game.wait(0.06)
	if hero_hp > 0 and u["alive"] and not broke:
		spr.frame = 4
		ui.message("Những bàn tay trắng trồi lên từ đất!")
		_attack_shots(u, "_special", 0.85)
		var g2 := await _strike(u, "ground", 0.85, u["atk"] + 4)
		if g2 == "perfect":
			parried += 1
		elif g2 == "miss":
			through += 1
		if parried == beats.size() + 1 and u["alive"]:
			u["dazed"] = 1
			ui.message("Đỡ hết. Trắng Tay vươn hụt, lảo đảo.")
			_float_text(_body(u) + Vector3(0, float(u["half_h"]) * 0.6, 0), "HỤT TAY", Color(0.95, 0.78, 0.38), 60)
			_shards(spr.global_position, 16)
			world.rig.shake(0.15, 0.3)
			_shot_later("b_dazed", 0.3)
	await _return_home(u)


func _shed_faces(u: Dictionary) -> void:
	## Its Chấp broken, faces crack off its crown and drop to the ground as Mảnh Sành (never more than three about).
	var room := 3 - _alive().filter(func(v): return v["id"] == "manh_tinh").size()
	var n := mini(2, room)
	if n <= 0 or not u["alive"]:
		return
	ui.message("Gương mặt nứt khỏi vương miện của Trắng Tay, rơi xuống, bò dậy.")
	Audio.sfx("crack", -2.0)
	var boss_spr: Sprite3D = u["node"]
	var lateral := Vector3(-out_dir.z, 0, out_dir.x)
	for k in n:
		var side := -1.0 if (adds_made + k) % 2 == 0 else 1.0
		var p: Vector3 = (u["home"] as Vector3) - out_dir * (1.9 + 1.5 * k) + lateral * side * 0.5
		if not esc.is_empty():
			p = hero_home + out_dir * (1.9 + 1.1 * k) + lateral * side * 0.5
		p.y = world.height_at(p.x, p.z)
		var a := _add_unit("manh_tinh", p, "Mảnh Sành " + "ABCDEFGH"[adds_made % 8])
		adds_made += 1
		var spr: Sprite3D = a["node"]
		var land: Vector3 = spr.global_position
		var from: Vector3 = boss_spr.global_position + Vector3(0, float(u["half_h"]) * 0.75, 0)
		spr.global_position = from
		spr.frame = 4
		_shards(from, 6)
		_arc(spr, from, land, 1.0, 0.5)
		get_tree().create_timer(0.5).timeout.connect(func():
			if is_instance_valid(spr):
				spr.frame = 0
				_dust_puff(land - Vector3(0, float(a["half_h"]), 0))
			a["busy"] = false)
		await Game.wait(0.25)
	_shot_later("b_shed", 0.35)
	await Game.wait(0.5)


# ================================================================ enemy attacks
func _hero_chest() -> Vector3:
	return hero.global_position + Vector3(0, 1.0, 0) + out_dir * 0.25


func _telegraph(spr: Sprite3D, boss: bool, special: bool) -> void:
	## A red glint where the attack will come from, the Nghiệt flushing bright.
	Audio.sfx("glint", -3.0 if special else -6.0, 0.05)
	var g := Sprite3D.new()
	g.texture = Assets.tex("res://assets/sprites/fx/spark.png")
	g.pixel_size = 0.05
	g.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	g.no_depth_test = true
	g.shaded = false
	g.render_priority = 6
	g.modulate = Color(3.0, 1.0, 0.8)
	world.add_child(g)
	g.global_position = spr.global_position + Vector3(0, 3.1 if boss else 0.9, 0) - out_dir * 0.2
	g.scale = Vector3.ONE * 0.2
	var tw := g.create_tween()
	tw.tween_property(g, "scale", Vector3.ONE * (3.2 if special else 2.2), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(g, "scale", Vector3.ONE * 0.1, 0.22)
	tw.tween_callback(g.queue_free)
	var fl := spr.create_tween()
	fl.tween_property(spr, "modulate", Color(1.7, 1.25, 1.2), 0.1)
	fl.tween_property(spr, "modulate", Color.WHITE, 0.25)
	if special:
		world.rig.shake(0.06, 0.4)
		Overlay.flash(Color(1.0, 0.95, 0.9, 0.18), 0.35)
	await Game.wait(0.4 if special else 0.3)


func _ghost(src: Sprite3D, tint: Color, life := 0.22) -> void:
	## One fading after-image of a moving sprite.
	if not is_instance_valid(src):
		return
	var g := Sprite3D.new()
	g.texture = src.texture
	g.hframes = src.hframes
	g.vframes = src.vframes
	g.frame = src.frame
	g.flip_h = src.flip_h
	g.pixel_size = src.pixel_size
	g.billboard = src.billboard
	g.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	g.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	g.shaded = false
	g.modulate = tint
	g.scale = src.scale
	world.add_child(g)
	g.global_position = src.global_position
	var tw := g.create_tween()
	tw.tween_property(g, "modulate:a", 0.0, life)
	tw.tween_callback(g.queue_free)


func _trail(src: Sprite3D, t: float, tint: Color) -> void:
	var e := 0.0
	while e < t and is_instance_valid(src):
		_ghost(src, tint)
		await get_tree().create_timer(0.035).timeout
		e += 0.035


func _arc(node: Node3D, a: Vector3, b: Vector3, height: float, t: float) -> void:
	## Flight driven by the battle clock (game time), the same clock the defend prompt runs on, so they always agree.
	var c := (a + b) * 0.5 + Vector3(0, height, 0)
	var t0 := _clock
	while is_instance_valid(node):
		var k := clampf((_clock - t0) / maxf(t, 0.01), 0.0, 1.0)
		var e := 1.0 - cos(k * PI * 0.5)
		node.global_position = a.lerp(c, e).lerp(c.lerp(b, e), e)
		if k >= 1.0:
			return
		await get_tree().process_frame


func _pounce(spr: Sprite3D, t: float) -> void:
	## Mảnh Sành springs at the hero along an arc, leaving after-images.
	spr.frame = 3
	Audio.sfx("whoosh", -4.0, 0.1)
	var land: Vector3 = hero.global_position + out_dir * 0.75 + Vector3(0, spr.global_position.y - hero.global_position.y, 0)
	_arc(spr, spr.global_position, land, 1.1, t)
	_trail(spr, t, Color(1.0, 0.75, 0.75, 0.55))


func _reach_arms(spr: Sprite3D, t: float, proj: Dictionary, count := 3, first := 0) -> void:
	## Trắng Tay's arms stretch out of the fan behind it: three porcelain arms uncoil across the field,
	## slowly at first, then whip in and snap shut on the hero's chest just as the defend ring closes.
	var target := _hero_chest()
	var lateral := Vector3(-out_dir.z, 0, out_dir.x)
	proj["arms"] = []
	for j in count:
		var k: int = (first + j) % 3
		# the camera looks along `lateral`, so the three arms are told apart by height: a high arc, a flat one, a low one
		var from: Vector3 = spr.global_position + Vector3(0, 1.9 - k * 0.8, 0) + lateral * (k - 1) * 0.3
		var to: Vector3 = target + Vector3(0, (1 - k) * 0.3, 0)
		var bow: Vector3 = Vector3(0, [3.0, 1.1, -0.9][k], 0)
		var arm := {"a": from, "m": (from + to) * 0.5 + bow, "b": to, "u": 0.0, "mode": "reach", "segs": [], "hand": null}
		proj["arms"].append(arm)
		_run_arm(arm, t, j * 0.07)
	Audio.sfx("whoosh", -2.0, 0.15)


func _arm_point(arm: Dictionary, u: float) -> Vector3:
	var a: Vector3 = arm["a"]
	var m: Vector3 = arm["m"]
	var b: Vector3 = arm["b"]
	return a.lerp(m, u).lerp(m.lerp(b, u), u)


func _face_cam(s: Sprite3D, pos: Vector3, dir: Vector3) -> void:
	## Lay a sprite flat to the camera, turned so its +x runs along `dir` on screen.
	var cb: Basis = world.rig.cam.global_transform.basis.orthonormalized()
	var ang := atan2(dir.dot(cb.y), dir.dot(cb.x))
	s.global_transform = Transform3D(Basis(cb.z, ang) * cb, pos)


func _arm_sprite(tex: String, frames: int, px: float, prio: int) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = Assets.tex(tex)
	s.hframes = frames
	s.pixel_size = px
	s.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.no_depth_test = true
	s.shaded = false         # self-lit like Trắng Tay itself, so the arm reads as part of it in any light
	s.render_priority = prio
	world.add_child(s)
	return s


func _run_arm(arm: Dictionary, t: float, delay: float) -> void:
	## Lays porcelain links along the arm's path every frame, up to how far it has reached (u), the hand at the tip.
	var hand := _arm_sprite("res://assets/sprites/fx/reach_hand.png", 2, 0.05, 7)
	hand.visible = false
	arm["hand"] = hand
	var segs: Array = arm["segs"]
	var step := 0.4
	var t0 := _clock + delay
	var last := _clock
	var cracked := false
	while is_instance_valid(hand):
		var dt := _clock - last
		last = _clock
		if arm["mode"] == "reach":
			var k := clampf((_clock - t0) / maxf(t - delay, 0.01), 0.0, 1.0)
			arm["u"] = pow(k, 1.9)
			if k > 0.72 and not cracked and not timing.blind:
				cracked = true
				Audio.sfx("crack", -9.0, 0.15)
			if k >= 1.0:
				arm["mode"] = "hold"
		elif arm["mode"] == "retract":
			arm["u"] = maxf(0.0, float(arm["u"]) - dt * 3.2)
		var u: float = arm["u"]
		var n := 32
		var pts: Array = []
		for i in n + 1:
			pts.append(_arm_point(arm, u * float(i) / n))
		var used := 0
		var acc := 0.0
		var next := 0.0
		for i in n:
			var p0: Vector3 = pts[i]
			var p1: Vector3 = pts[i + 1]
			var L := p0.distance_to(p1)
			while L > 0.0001 and next <= acc + L:
				if used >= segs.size():
					segs.append(_arm_sprite("res://assets/sprites/fx/reach_segment.png", 2, 0.052, 6))
				var sg: Sprite3D = segs[used]
				sg.visible = true
				sg.frame = 1 if used % 5 == 4 else 0
				_face_cam(sg, p0.lerp(p1, (next - acc) / L), p1 - p0)
				used += 1
				next += step
			acc += L
		for i in range(used, segs.size()):
			(segs[i] as Sprite3D).visible = false
		var tip: Vector3 = pts[n]
		var dir: Vector3 = pts[n] - pts[n - 1]
		if dir.length() < 0.0001:
			dir = (arm["b"] as Vector3) - (arm["a"] as Vector3)
		_face_cam(hand, tip + dir.normalized() * 0.32, dir)
		hand.visible = u > 0.02
		if arm["mode"] == "retract" and u <= 0.0:
			break
		await get_tree().process_frame
	for sg in segs:
		if is_instance_valid(sg):
			sg.queue_free()
	if is_instance_valid(hand):
		hand.queue_free()


func _arm_recoil(arm: Dictionary, parried: bool) -> void:
	## Parried: the hand is knocked aside and the arm snaps back. Hit: the hand clamps shut, holds, then lets go.
	var hand: Sprite3D = arm["hand"]
	if is_instance_valid(hand):
		if parried:
			_shards(hand.global_position, 3)
			hand.modulate = Color(2.4, 2.0, 1.2)
		else:
			hand.frame = 1
	if not parried:
		await get_tree().create_timer(0.2).timeout
	arm["mode"] = "retract"


func _ground_hands(spr: Sprite3D, t: float, proj: Dictionary) -> void:
	## Hóa Sứ: porcelain hands break up through the earth in a line racing at the hero.
	var from := spr.global_position
	from.y = 0
	var to: Vector3 = hero.global_position + out_dir * 0.35
	to.y = 0
	var n := 7
	for k in n:
		var s := float(k + 1) / n
		await get_tree().create_timer(t / n).timeout
		var p := from.lerp(to, s) + Vector3(-out_dir.z, 0, out_dir.x) * (0.35 if k % 2 == 0 else -0.35)
		p.y = world.height_at(p.x, p.z)
		var h := Sprite3D.new()
		h.texture = Assets.tex("res://assets/sprites/fx/ground_hand.png")
		h.hframes = 3
		h.pixel_size = 0.05 + 0.006 * k
		h.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		h.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		h.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		h.shaded = false
		h.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		world.add_child(h)
		h.global_position = p + Vector3(0, 34 * h.pixel_size * 0.5 - h.pixel_size * 2.0, 0)
		h.scale = Vector3(1.0, 0.2, 1.0)
		var tw := h.create_tween()
		tw.tween_property(h, "scale", Vector3.ONE, 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func(): h.frame = 1)
		tw.tween_interval(0.45)
		tw.tween_callback(func(): h.frame = 2)
		tw.tween_interval(0.35)
		tw.tween_property(h, "scale", Vector3(1.0, 0.0, 1.0), 0.18)
		tw.tween_callback(h.queue_free)
		_dust_puff(p)
		if k % 2 == 0:
			Audio.sfx("crack", -6.0 + k * 0.6, 0.1)
		world.rig.shake(0.03 + 0.01 * k, 0.12)
		if k == n - 1:
			proj["nodes"].append(h)


func _dust_puff(p: Vector3) -> void:
	var d := B.particles(world, "res://assets/sprites/props/smoke.png", 8, 0.6, Vector3(0.3, 0.05, 0.3), p + Vector3(0, 0.15, 0),
		{"spread": 80.0, "vmin": 0.6, "vmax": 1.4, "dir": Vector3(0, 1, 0), "size": 0.5, "gravity": Vector3(0, -1.5, 0),
		"color": Color(0.62, 0.55, 0.48, 0.6)})
	d.one_shot = true
	d.preprocess = 0.0
	d.explosiveness = 0.9
	d.emitting = true
	get_tree().create_timer(1.2).timeout.connect(d.queue_free)


func _impact(grade: String, boss: bool, spr: Sprite3D, proj: Dictionary) -> void:
	var at := _hero_chest()
	if AutoTest.active and is_instance_valid(spr):
		AutoTest.note("impact_%s_%s_dist_%.2f" % [grade, "boss" if boss else "manh", Vector2(spr.global_position.x - at.x, spr.global_position.z - at.z).length()])
	var toward := -out_dir
	if grade == "perfect":
		# deflected: the blow glances off in a gold ring
		Audio.sfx("parry", -2.0, 0.05)
		_burst(at, Color(3.0, 2.4, 1.2), 0.7)
		_shock(at, Color(3.0, 2.5, 1.3))
		_spark(at)
		_hitstop(0.06)
		world.rig.shake(0.08, 0.15)
		for arm in proj.get("arms", []):
			_arm_recoil(arm, true)
		for a in proj["nodes"]:
			if is_instance_valid(a):
				var tw: Tween = a.create_tween().set_parallel(true)
				tw.tween_property(a, "global_position", a.global_position - toward * 1.6 + Vector3(0, 2.2, 0), 0.35)
				tw.tween_property(a, "modulate:a", 0.0, 0.35)
				tw.chain().tween_callback(a.queue_free)
		if not boss and is_instance_valid(spr):
			var tw2 := spr.create_tween()
			tw2.tween_property(spr, "position", spr.position - toward * 1.0 + Vector3(0, 0.35, 0), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw2.tween_property(spr, "position", spr.position - toward * 1.4, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		return
	var heavy := grade == "miss"
	Audio.sfx("impact", -1.0 if heavy else -5.0, 0.08)
	if not heavy:
		Audio.sfx("parry", -9.0, 0.1)
	_burst(at, Color(3.0, 1.3, 1.1) if heavy else Color(2.4, 2.4, 2.6), 0.85 if heavy else 0.65)
	if heavy:
		_shards(at, 12 if boss else 7)
		Overlay.flash(Color(0.85, 0.12, 0.08, 0.3), 0.3)
	else:
		_shock(at, Color(2.2, 2.2, 2.4))
	_hitstop(0.09 if heavy else 0.05)
	world.rig.shake((0.24 if boss else 0.16) if heavy else 0.08, 0.25 if heavy else 0.15)
	for arm in proj.get("arms", []):
		_arm_recoil(arm, false)
	# knocked back a step, then recover
	var hp0: Vector3 = hero.global_position
	var kb: Tween = hero.create_tween()
	kb.tween_property(hero, "global_position", hp0 + toward * (0.45 if heavy else 0.2), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	kb.tween_property(hero, "global_position", hp0, 0.3).set_trans(Tween.TRANS_SINE)
	for a in proj["nodes"]:
		if is_instance_valid(a):
			var tw3: Tween = a.create_tween()
			tw3.tween_property(a, "modulate:a", 0.0, 0.15)
			tw3.tween_callback(a.queue_free)
			_shards(a.global_position, 4)


func _burst(p: Vector3, tint: Color, size: float) -> void:
	var s := Sprite3D.new()
	s.texture = Assets.tex("res://assets/sprites/fx/burst.png")
	s.hframes = 4
	s.pixel_size = 0.05 * size
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.no_depth_test = true
	s.shaded = false
	s.render_priority = 6
	s.modulate = tint
	world.add_child(s)
	s.global_position = p
	for f in 4:
		if not is_instance_valid(s):
			return
		s.frame = f
		await get_tree().create_timer(0.035, true, false, true).timeout
	s.queue_free()


func _shock(p: Vector3, tint: Color) -> void:
	var s := Sprite3D.new()
	s.texture = Assets.tex("res://assets/sprites/fx/shock.png")
	s.hframes = 4
	s.pixel_size = 0.06
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.no_depth_test = true
	s.shaded = false
	s.render_priority = 6
	s.modulate = tint
	world.add_child(s)
	s.global_position = p
	for f in 4:
		if not is_instance_valid(s):
			return
		s.frame = f
		await get_tree().create_timer(0.05, true, false, true).timeout
	s.queue_free()


func _hitstop(t: float) -> void:
	## A few frames of near-freeze so a hit lands with weight.
	Engine.time_scale = 0.05
	await get_tree().create_timer(t, true, false, true).timeout
	Engine.time_scale = 1.0


func _shot_seq(n: String, t: float) -> void:
	await get_tree().create_timer(t, true, false, true).timeout
	AutoTest.shot(n)


func _shot_later(n: String, t := 0.35) -> void:
	await get_tree().create_timer(t).timeout
	AutoTest.shot(n)


# ================================================================ fx
var _floats: Array = []   # [position, time] of the float texts still up


func _float_text(p: Vector3, text: String, col: Color, size := 56) -> void:
	## Pops in big, hops up a little and settles, then fades: it stays next to what it belongs to. Texts that come
	## up at the same place while one is still there stack above it instead of printing over it.
	var now := Time.get_ticks_msec() / 1000.0
	_floats = _floats.filter(func(f): return now - f[1] < 0.9)
	var n := 0
	for f in _floats:
		if (f[0] as Vector3).distance_to(p) < 1.6:
			n += 1
	_floats.append([p, now])
	p += Vector3(0, 0.42 * n, 0)
	var l := B.label3d(world, text, p, size, col)
	l.scale = Vector3.ONE * 1.7
	var tw := l.create_tween().set_parallel(true)
	tw.tween_property(l, "scale", Vector3.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "position:y", p.y + 0.36, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(l, "position:y", p.y + 0.24, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_property(l, "position:y", p.y + 0.42, 0.75)
	tw.tween_property(l, "modulate:a", 0.0, 0.4).set_delay(0.35)
	tw.chain().tween_callback(l.queue_free)


func _slash_fx(p: Vector3, big: bool) -> void:
	var s := Sprite3D.new()
	s.texture = Assets.tex("res://assets/sprites/fx/slash.png")
	s.hframes = 4
	s.pixel_size = 0.045 if big else 0.035
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.no_depth_test = true
	s.shaded = false
	s.modulate = Color(1.6, 1.7, 2.0)
	s.render_priority = 5
	world.add_child(s)
	s.global_position = p
	for f in 4:
		s.frame = f
		await get_tree().create_timer(0.04).timeout
	s.queue_free()


func _spark(p: Vector3) -> void:
	var s := Sprite3D.new()
	s.texture = Assets.tex("res://assets/sprites/fx/spark.png")
	s.pixel_size = 0.06
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.no_depth_test = true
	s.shaded = false
	s.modulate = Color(2.2, 2.0, 1.4)
	world.add_child(s)
	s.global_position = p
	var tw := s.create_tween().set_parallel(true)
	tw.tween_property(s, "scale", Vector3.ONE * 2.2, 0.25)
	tw.tween_property(s, "modulate:a", 0.0, 0.3)
	tw.chain().tween_callback(s.queue_free)


func _shards(p: Vector3, n: int) -> void:
	var pp := B.particles(world, "res://assets/sprites/fx/shard.png", n, 0.9, Vector3(0.3, 0.3, 0.3), p,
		{"spread": 180.0, "vmin": 2.0, "vmax": 4.5, "gravity": Vector3(0, -9, 0), "size": 0.16, "color": Color(1, 1, 1)})
	pp.one_shot = true
	pp.preprocess = 0.0
	pp.explosiveness = 0.95
	pp.emitting = true
	get_tree().create_timer(1.5).timeout.connect(pp.queue_free)
