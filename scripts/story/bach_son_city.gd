extends Node
## Bạch Sơn, Part C (docs/N_bach_son.md 8.3, 9.1, 9.6): four days inside the walls before the Lễ Quét Vôi.
## Each day has a morning, an afternoon and an evening; one thing of weight fills each. The protagonist writes
## down what they see (Sổ ghi); two things seen together make a realisation (Nhận ra). The Ty watches (Nghi), and
## the way to keep its eye off you is Bạch Sơn's own sin: put someone else out (báo Ty), or do not look (never go
## down to the camp at night). Four realisations, or the fourth evening, and the Chánh Ty sends for them.
##   var city = BachSonCity.new(); city.story = story; add_child(city); await city.run()

const Battle = preload("res://scripts/battle/battle.gd")
const AshTest = preload("res://scripts/ui/ash_test.gd")
const PictureCard = preload("res://scripts/ui/picture_card.gd")
const Status = preload("res://scripts/ui/bs_status.gd")
const Journal = preload("res://scripts/ui/journal.gd")

const PARTS := ["Sáng", "Chiều", "Tối"]
const NOTES := {
	"tro_men": "Bà Mẫn xoa tro lên cái chén men rạn rồi dội nước. Kẽ rạn vẫn đen. Da bị Nghiệt chạm cũng có lớp men rạn như thế.",
	"tay_nut": "Bà Mẫn xoa tro lên tay mình. Ba mươi năm ngâm thuốc, tay bà nứt hết. Thử tro cũng ra xám.",
	"cot_den": "Sổ Tro, cột \"đen\" của người trong thành. Lật mấy chục tập vẫn không có dòng nào.",
	"sac_chanh_ty": "Sắc suốt ba mươi lăm năm nay đều cùng một nét chữ. Cuối mỗi tờ ghi \"Chánh Ty Ngọc Khiết soạn\", bên dưới đóng ấn của Điện.",
	"so_ban": "Một quyển sổ mỏng kẹp trong Sổ Tro. Bên cạnh tên mỗi người là một con số. Trang cuối đóng dấu của một nhà buôn Vạn Thư.",
	"giu_lai": "Sổ Tro tập đầu, năm PK 21: \"Xám thì giữ lại ở Nhà Rửa, đợi Bà.\"",
	"pk395": "Sổ Tro tập PK 395. Một nhà ở Tầng Rửa, năm người. Dòng cuối ghi \"trẻ nhỏ, chưa tên\". Cũng năm ấy, mình bị bỏ ở cửa đèo.",
	"khong_phai": "Bà Lành kể, đứa bé nhà ấy không qua được mùa đông đầu. Năm đó có đoàn người phương bắc mang theo một đứa bé quấn khăn kẻ ô bàn cờ, đi về phía đèo.",
	"xe_trang": "Tối hôm ấy, sau Dinh Ty, người của Ty dẫn ba người bị đuổi lên xe trắng. Bà Sương trả tiền.",
	"tranh_tho": "Đền Thầy có bức tranh vẽ một nhát chém chia người sạch và người bẩn. Người coi đền bảo Sứ Giả ngoài cổng sinh ra từ lòng thành của dân.",
	"dau_nguon": "Lúc tay nó chạm vào mình ở trại, mình thấy những ô cửa sáng đèn trong thành. Người đứng sau lớp giấy nhìn xuống. Trên bậc cửa nhà nào cũng có chén sứ.",
	"seo": "Ông Sẹo kể, năm bảy tuổi ông bị Nghiệt chạm. Bà tự tay rửa men cho ông ở Nhà Rửa. Rồi có một năm Bà không xuống nữa.",
	"vung_xe": "Anh Vững ngồi ở đầu xe trắng. Anh không ngẩng lên.",
	"khong_nhin": "Đêm cuối, mình không xuống trại. Tay nó thò tận vào lều. Ông Bảy bán than hóa sứ ngay trước cửa lều.",
}
# [id, text, [notes]]: the four that send the Chánh Ty for them are any four of the first five
const PAIRS := [
	["co_ly", "Cái cổng có lý do để tồn tại. Tro phát hiện được dấu Nghiệt chạm, nhưng tay nứt vì vôi, thuốc hay gánh cũng ra xám.", ["tro_men", "tay_nut"]],
	["ky_khong_nhin", "Bà đóng ấn mà không nhìn. Sắc nào cũng do Chánh Ty soạn. Cột đen trống suốt ba trăm năm mà sắc vẫn được ban xuống.", ["cot_den", "sac_chanh_ty"]],
	["khong_di", "Người bị đuổi không biến mất. Tên họ bị bán, rồi họ bị đưa lên xe trắng sang Vạn Thư.", ["so_ban", "xe_trang"]],
	["tho_no", "Cả thành thờ thứ đang săn người ngoài cổng. Nó sinh ra từ chính những ô cửa ấy.", ["tranh_tho", "dau_nguon"]],
	["tung_chua", "\"Xám thì giữ lại\" từng là giữ lại để chữa, Bà giữ lại để cứu họ chứ đâu đuổi họ đi.", ["giu_lai", "seo"]],
	["khong_phai_minh", "Đứa trẻ chưa tên trong sổ năm PK 395 không phải mình.", ["pk395", "khong_phai"]],
]
const COUNTED := ["co_ly", "ky_khong_nhin", "khong_di", "tho_no", "tung_chua"]

var story
var world
var day := 1
var part := 0
var nghi := 0.0
var notes: Array = []
var nhan_ra: Array = []
var level := "street"
var done := {}
var gone := {}
var met := {}
var sins: Array = []
var washed_part := -1
var cart_day := -1
var camp_nights := 0
var status
var journal
var _auto_plan: Array = []


# ================================================================== the loop
func run() -> String:
	world = story.world
	status = Status.new()
	add_child(status)
	journal = Journal.new()
	add_child(journal)
	nghi = {"can": 20.0, "truth": 60.0, "blame": 0.0}.get(Game.flags.get("bs_gate", "can"), 20.0)
	# tests: one scene a part. The default round gets four realisations by the second afternoon; --city-plan=
	# a,b,c picks another (porter, yvien, camp, den, nharua, cart, report, wait)
	_auto_plan = ["porter", "yvien", "camp", "nharua", "den", "cart", "wait", "wait", "wait", "wait", "wait", "wait"]
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--city-plan="):
			_auto_plan = Array(a.split("=")[1].split(","))
			for i in 12:
				_auto_plan.append("wait")
	if _auto_flag("--city-retest"):
		nghi = 100.0   # tests: the Ty sends for a retest at once
	_refresh()
	while true:
		if _palace_due():
			break
		await _begin_part()
		if nghi >= 100.0:
			await _retest()
		var action: String = await _part_loop()
		AutoTest.note("city_d%d_%s_%s" % [day, PARTS[part], action])
		if _palace_due():
			break
		await _next_part()
	Game.flags["bs_nhan_ra"] = nhan_ra.duplicate()
	Game.flags["bs_sins"] = sins.duplicate()
	Game.flags["bs_gone"] = gone.keys()
	Game.flags["bs_city_notes"] = notes.duplicate()
	Game.flags["bs_camp_nights"] = camp_nights
	status.queue_free()
	journal.queue_free()
	return "palace"


func _palace_due() -> bool:
	var n := 0
	for id in nhan_ra:
		if COUNTED.has(id):
			n += 1
	return n >= 4 or day > 4 or (day == 4 and part == 2 and done.has("d4_toi"))


func _auto_flag(f: String) -> bool:
	return Game.auto and OS.get_cmdline_user_args().has(f)


func _refresh() -> void:
	status.set_when(day, PARTS[part])
	status.set_nghi(nghi)
	var nr_texts: Array = []
	for p in PAIRS:
		if nhan_ra.has(p[0]):
			nr_texts.append(p[1])
	var note_texts: Array = []
	for id in notes:
		note_texts.append(NOTES[id])
	journal.set_entries(nr_texts, note_texts)


func add_note(id: String) -> void:
	if notes.has(id):
		return
	notes.append(id)
	world.hud.toast("Sổ ghi: thêm một điều thấy (Tab)")
	for p in PAIRS:
		if nhan_ra.has(p[0]):
			continue
		var all := true
		for n in p[2]:
			if not notes.has(n):
				all = false
		if all:
			nhan_ra.append(p[0])
			await Game.wait(0.6)
			world.hud.toast("Nhận ra: " + p[1], 3.2)
			AutoTest.note("nhan_ra_" + p[0])
			await Game.wait(1.0 if Game.fast else 2.6)
	_refresh()


func add_nghi(v: float) -> void:
	nghi = clampf(nghi + v, 0.0, 100.0)
	_refresh()
	if v > 0.0:
		world.hud.toast("Nghi tăng")
	elif v < 0.0:
		world.hud.toast("Nghi giảm")


# ================================================================== parts of the day
func _begin_part() -> void:
	var lit := "highland_dusk" if part == 2 else "highland"
	world.set_time(lit, true)
	Audio.play_music("night" if part == 2 else "tension", 2.0)   # the white streets by day, the evening
	_refresh()
	if part == 0:
		await Overlay.card("Ngày %d" % day, ["Bốn ngày nữa là tới Lễ Quét Vôi", "Ba ngày tới Lễ Quét Vôi", "Hai ngày tới Lễ Quét Vôi", "Mai là Lễ Quét Vôi"][day - 1], 1.4)
	else:   # the hour turns: said, so the black between is not empty
		await Overlay.card("", "Ngày %d · %s" % [day, PARTS[part]], 0.7)
	_go_level("street", "plaza")
	_place_people()
	await Overlay.fade_in(0.6)
	await AutoTest.shot("c_d%d_%d" % [day, part])
	# what the city says about yesterday
	if day == 1 and part == 1 and Game.flags.get("bs_gate", "") == "can":
		await story.say("", "Ngoài Sân Tro có tiếng roi quất. Người qua đường bảo lão gác già bị phạt vì làm ướt tro cho người lạ.")
		story.end_talk()
	if day == 4 and part == 0 and camp_nights == 0:
		var g = world.actor("gam")
		await story.say("Chị Gấm" if g else "", "Đêm qua tay nó thò vào tận lều. Ông Bảy bán than hóa sứ ngay trước cửa lều.", "sad")
		story.end_talk()
		sins.append("khong_nhin")
		await add_note("khong_nhin")


func _next_part() -> void:
	if part == 1:   # the afternoon ends with the gate bell ("Ngồi đợi tiếng chuông cổng."): heard as the light goes
		Audio.sfx("bell", -7.0)
	await Overlay.fade_out(0.6)
	part += 1
	if part > 2:
		part = 0
		day += 1
	washed_part = -1


func _go_level(lv: String, at: String) -> void:
	level = lv
	var h = world.hero
	h.stop_move()
	h.global_position = world.markers[at]
	h.face("up")
	world.rig.follow(h, true)


func _place_people() -> void:
	## Who is where at this hour (only on the level the protagonist is on; the rest are spawned when they get there).
	var m: Dictionary = world.markers
	for id in ["suong", "maty", "seo", "gam", "bamau", "thu_lai", "coi_den", "kham2", "ty1", "ty2"]:
		if world.actor(id):
			world.despawn(id)
	match level:
		"street":
			if part == 0:
				story.npc("suong", "suong", m["plaza"] + Vector3(2.4, 0, -1.6), "left")
			if part < 2:
				story.npc("maty", "maty", m["maty"], "right")
			var nr: Vector3 = m["nha_rua"]
			if not gone.has("seo"):
				story.npc("seo", "seo", nr + Vector3(0.6, 0, -2.9), "right")
			if not gone.has("gam"):
				story.npc("gam", "gam", nr + Vector3(0.5, 0, 1.6), "right")
		"tier1":
			if part < 2:
				story.npc("bamau", "bamau", (m["y_vien"] as Vector3) + Vector3(1.3, 0, 0.2), "down")
				story.npc("thu_lai", "khamsu", (m["dinh_ty"] as Vector3) + Vector3(1.6, 0, 0.2), "down")
		"tier2":
			if part < 2:
				story.npc("coi_den", "bs_m", (m["den_thay"] as Vector3) + Vector3(1.3, 0, 0.2), "down")


func _interacts() -> Dictionary:
	## {id: [pos, prompt, kind]} for this level and hour. kind: major (fills the hour), minor, move.
	var m: Dictionary = world.markers
	var d := {}
	match level:
		"street":
			if washed_part != part:
				d["basin"] = [m["big_basin"], "Rửa tay", "minor"]
			if part == 0 and world.actor("suong"):
				d["suong"] = [world.actor("suong").global_position, "Gánh hòm cho bà Sương", "major"]
			if part < 2 and world.actor("maty"):
				d["maty"] = [world.actor("maty").global_position, "Nói chuyện", "minor"]
			d["nharua"] = [m["nha_rua"], "Vào Nhà Rửa", "major" if not done.has("nharua") else "minor"]
			if part == 2:
				d["cuacong"] = [m["cua_cong"], "Chui qua Cửa Cống", "major"]
			if part < 2 or (part == 2 and cart_day == day and not done.has("cart")):
				d["up1"] = [m["stair1_foot"], "Lên Tầng Giữa", "move"]
			else:
				d["up1_shut"] = [m["stair1_foot"], "Cổng tầng đã đóng", "minor"]
			d["wait"] = [(m["big_basin"] as Vector3) + Vector3(3.6, 0, 0), "Ngồi đợi tới " + ["chiều", "tối", "sáng mai"][part], "major"]
		"tier1":
			d["down1"] = [m["tier1_top"], "Xuống Tầng Rửa", "move"]
			if part < 2:
				d["yvien"] = [m["y_vien"], "Vào Y Viện", "major" if not done.has("yvien") else "minor"]
				d["dinhty"] = [m["dinh_ty"], "Dinh Ty", "minor"]
				d["up2"] = [m["alley_top"], "Lên Tầng Đền", "move"]
			elif cart_day == day and not done.has("cart"):
				d["cart"] = [m["cart_spot"], "Ra sau Dinh Ty", "major"]
		"tier2":
			d["down2"] = [m["tier2_top"], "Xuống Tầng Giữa", "move"]
			if part < 2:
				d["den"] = [m["den_thay"], "Vào Đền Thầy", "major" if not done.has("den") else "minor"]
	return d


func _part_loop() -> String:
	## Walk about; small things (wash, talk, go up or down a tier) do not use the hour; one thing of weight does.
	while true:
		var d := _interacts()
		world.hud.objective("%s. Đi đâu tùy mình (Tab: Sổ ghi)" % ["Bốn ngày nữa là tới Lễ Quét Vôi", "Ba ngày tới Lễ Quét Vôi", "Hai ngày tới Lễ Quét Vôi", "Mai là Lễ Quét Vôi"][day - 1])
		var got := ""
		if Game.auto:
			got = _auto_pick(d)
			d = _interacts()
			if d.has(got) and d[got][2] != "move":   # (walk up to it, as a player would, not talk from afar)
				var to: Vector3 = d[got][0]
				var from: Vector3 = world.hero.global_position - to
				from.y = 0.0
				await world.hero.move_to(to + (from.normalized() if from.length() > 0.01 else Vector3(0, 0, 1)) * 1.3)
				world.hero.face_point(to)
		else:
			var marks: Array = []
			for k in d:
				world.add_interact(k, d[k][0], d[k][1], 1.7)
				# arrows over the places of weight not yet seen, and the ways up and down
				if (d[k][2] == "major" and k != "wait") or d[k][2] == "move":
					marks.append(d[k][0])
			world.set_markers(marks)
			world.hud.show_hints(true)
			world.set_control(true)
			while true:
				got = await world.interacted
				if d.has(got):
					break
			world.set_control(false)
			world.set_markers([])
			for k in d:
				world.remove_interact(k)
		world.hud.objective("")
		world.hud.show_hints(false)
		var kind: String = d[got][2] if d.has(got) else "major"
		await _do(got)
		if kind == "major":
			if part == 2 and day == 4:
				done["d4_toi"] = true
			return got
	return "wait"


func _auto_pick(d: Dictionary) -> String:
	## Tests: a fixed round of the city (a scene per part), moving level to reach it.
	if _auto_plan.is_empty():
		return "wait"
	var want: String = _auto_plan[0]
	var where := {"porter": "street", "yvien": "tier1", "camp": "street", "den": "tier2", "nharua": "street",
		"cart": "tier1", "report": "street", "wait": "street"}
	var lv: String = where.get(want, "street")
	if lv != level:
		_go_level(lv, {"street": "plaza", "tier1": "tier1_top", "tier2": "tier2_top"}[lv])
		_place_people()
		d = _interacts()
	var act: String = {"porter": "suong", "camp": "cuacong", "report": "maty"}.get(want, want)
	if not d.has(act):
		# not at this hour (the cart is an evening thing, the Cửa Cống too): let the hour pass on the street,
		# and keep the plan for later
		if level != "street":
			_go_level("street", "plaza")
			_place_people()
		return "wait"
	_auto_plan.pop_front()
	return act


func _talk_to(npc, others := []) -> void:
	## Turn to each other and frame everyone in the talk above the dialogue box, as every talk outside the city is.
	if npc == null:
		return
	var h = world.hero
	# side by side on screen, a step apart: one standing behind the other (the camera looks along z) or across the
	# yard is no conversation; the place to press is often a door the person stands beside
	var d: Vector3 = h.global_position - npc.global_position
	d.y = 0.0
	if absf(d.x) < 0.9 or d.length() > 3.0:
		var side := 1.0 if d.x >= 0.0 else -1.0
		await h.move_to(npc.global_position + Vector3(1.25 * side, 0, 0.15), 2.2)
	npc.face_point(h.global_position)
	h.face_point(npc.global_position)
	var people: Array = [h, npc]
	for o in others:
		if o:
			o.face_point(h.global_position)
			people.append(o)
	await story.talk_shot(people)


func _do(id: String) -> void:
	await _do_one(id)
	story.back_to_follow()


func _do_one(id: String) -> void:
	match id:
		"basin":
			await _wash()
		"suong":
			await _porter()
		"maty":
			await _maty()
		"nharua":
			await _nha_rua()
		"cuacong":
			await _camp_night()
		"up1":
			await _move_level("tier1", "tier1_top")
		"up1_shut":
			world.hud.toast("Tối rồi. Cổng các tầng đóng hết rồi.")
		"down1":
			await _move_level("street", "stair1_foot")
		"up2":
			await _move_level("tier2", "tier2_top")
		"down2":
			await _move_level("tier1", "alley_top")
		"yvien":
			await _y_vien()
		"dinhty":
			await story.say("Thư lại", "Không có việc thì đi chỗ khác.", "cross")
			story.end_talk()
		"cart":
			await _cart()
		"den":
			await _den_thay()
		"wait":
			await story.say("", ["Ngồi bên bể rửa, nhìn người ta rửa tay.", "Ngồi đợi tiếng chuông cổng.", "Về chỗ ngủ trong nhà kho của bà Sương."][part])
			story.end_talk()


func _move_level(lv: String, at: String) -> void:
	await Overlay.fade_out(0.35)
	_go_level(lv, at)
	_place_people()
	await Overlay.fade_in(0.35)


# ================================================================== small things
func _wash() -> void:
	Audio.sfx("water", -4.0, 0.1)
	washed_part = part
	await story.say("", "Nước lạnh.")
	story.end_talk()
	add_nghi(-5.0)


func _maty() -> void:
	## The Mắt Ty: report someone and the Ty forgets about you for a while (docs 9.6). Each name, once.
	var a = world.actor("maty")
	await _talk_to(a)
	world.emo("maty", "cold")   # (the speaker "Người áo lam" is the maty actor here, not ty_a: his face is set directly)
	if not met.has("maty"):
		met["maty"] = true
		await story.say("Người áo lam", "Người gánh hòm cho bà Sương đấy à?")
		await story.say("Người áo lam", "Ở đây thấy gì thì báo cho Ty. Báo đúng, Ty sẽ nhớ.")
	else:
		await story.say("Người áo lam", "Thấy gì thì cứ báo.")
	var opts: Array = []
	var who: Array = []
	if met.has("seo") and not gone.has("seo"):
		opts.append("Ông già ở Nhà Rửa.")
		who.append("seo")
	if met.has("gam") and not gone.has("gam"):
		opts.append("Chị Gấm ở Nhà Rửa.")
		who.append("gam")
	opts.append("Không thấy ai.")
	who.append("")
	var c: int = await world.choose(opts)
	if Game.auto and _auto_flag("--city-report") and who.size() > 1:
		c = 0
	var pick: String = who[c]
	if pick == "":
		story.end_talk()
		return
	world.emo("maty", "nod")
	await story.say("Người áo lam", "Ừ. Cứ để Ty lo.")
	story.end_talk()
	gone[pick] = true
	sins.append("bao_" + pick)
	AutoTest.note("reported_" + pick)
	add_nghi(-40.0)


# ================================================================== the five threads (8.3)
func _porter() -> void:
	## Carrying for bà Sương: the Ty likes a porter who carries. The first time, the chest goes to the Dinh Ty,
	## and the Sổ Tro lies open while the clerk is called away.
	var s = world.actor("suong")
	await _talk_to(s)
	if done.has("so_tro"):
		await story.say("Bà Sương", ["Lên Y Viện lấy mấy gói thuốc cho tôi.", "Mang hòm ra Sân Tro. Người của Hội Y đang đợi.", "Hòm hôm nay nhẹ đấy. Đi nhanh rồi về."][day % 3])
		story.end_talk()
		story.carry_chest(true)
		await Overlay.fade_out(0.4)
		await Overlay.fade_in(0.4)
		await story.say("", "Hòm nặng trĩu. Người qua đường nhìn cái hòm, chẳng ai nhìn người đang gánh.")
		story.end_talk()
		story.carry_chest(false)
		add_nghi(-20.0)
		return
	done["so_tro"] = true
	await story.say("Bà Sương", "Hôm nay mang hòm lên Dinh Ty. Hội Y phải trình sổ thuốc cho Ty.", "behind")
	story.end_talk()
	story.carry_chest(true)
	await Overlay.fade_out(0.4)
	_go_level("tier1", "dinh_ty")
	_place_people()
	await Overlay.fade_in(0.4)
	var tl = world.actor("thu_lai")
	if tl:
		tl.face_point(world.hero.global_position)
	await story.say("Thư lại", "Đặt hòm ở kia. Đứng chờ.", "point")
	var chest: Node3D = story.put_chest(world.hero.global_position + Vector3(0.7, 0, -0.5))
	await story.say("Thư lại", "Chánh Ty gọi. Đừng động vào thứ gì.")
	story.end_talk()
	if tl:
		await tl.move_to((world.markers["dinh_ty"] as Vector3) + Vector3(-3.5, 0, 0.6), 2.4)
		tl.visible = false
	var pc = PictureCard.new()
	add_child(pc)
	await pc.open("res://assets/ui/so_cot.png", "Sổ Tro, Tầng Rửa")
	AutoTest.shot("bs12_sotro")
	await story.say("", "Mỗi dòng ghi một người, có ba cột: trắng, xám, đen. Lật mấy chục trang, cột đen vẫn trống trơn.")
	await add_note("cot_den")
	await pc.swap("res://assets/ui/so_sac.png", "Các sắc, cuối tập")
	await story.say("", "Cuối tập là các tờ sắc. Nét chữ tờ nào cũng giống nhau. Dòng cuối ghi \"Chánh Ty Ngọc Khiết soạn\", bên dưới là ấn của Điện.")
	await add_note("sac_chanh_ty")
	await pc.swap("res://assets/ui/so_ban.png", "Quyển mỏng kẹp giữa")
	await story.say("", "Kẹp giữa Sổ Tro là một quyển mỏng. Bên cạnh mỗi tên là một con số. Trang cuối đóng dấu của một nhà buôn Vạn Thư.")
	await add_note("so_ban")
	await pc.swap("res://assets/ui/so_pk21.png", "Sổ Tro, tập đầu")
	await story.say("", "Tập đầu tiên, năm PK 21. Mực đã nhạt: \"Xám thì giữ lại ở Nhà Rửa, đợi Bà.\"")
	await add_note("giu_lai")
	await pc.swap("res://assets/ui/so_pk395.png", "Sổ Tro, tập PK 395")
	AutoTest.shot("bs12b_pk395")
	await story.say("", "Tập năm PK 395. \"Nhà (tro che mất tên), Tầng Rửa, Luật Cả Nhà. Năm người. Trẻ nhỏ, chưa tên.\"")
	story.end_talk()
	await Game.wait(0.8)
	await add_note("pk395")
	await pc.close()
	if tl:
		tl.visible = true
		await tl.move_to((world.markers["dinh_ty"] as Vector3) + Vector3(1.6, 0, 0.2), 2.4)
		tl.face_point(world.hero.global_position)
	await story.say("Thư lại", "Xong rồi thì đi.")
	story.end_talk()
	chest.queue_free()   # the clerk keeps it for the Hội Y
	await Overlay.fade_out(0.4)
	_go_level("street", "plaza")
	_place_people()
	await Overlay.fade_in(0.4)
	var s2 = world.actor("suong")
	if s2:
		s2.face_point(world.hero.global_position)
	await story.say("Bà Sương", "Tối mai ra sau Dinh Ty. Có mấy cái hòm cần khiêng.")
	story.end_talk()
	cart_day = day + 1
	add_nghi(-20.0)


func _y_vien() -> void:
	if done.has("yvien"):
		await _talk_to(world.actor("bamau"))
		await story.say("Bà Mẫn", "Đi đi. Ở đây lâu quá, người ta để ý đấy.", "worry")
		story.end_talk()
		return
	done["yvien"] = true
	var b = world.actor("bamau")
	await _talk_to(b)
	AutoTest.shot("bs12y_yvien")
	await story.say("Bà Mẫn", "Ai đấy? Người lạ à? Từ Vô Danh Cốc lên sao?", "surprise")
	await story.say("Bà Mẫn", "Lúa còn sống không?", "worry")
	await story.say(story.P(), "Còn ạ. Chỗ trắng trên chân thôi lan rồi.", "smile")
	await story.say("Bà Mẫn", "...Ừ.", "sigh")
	await story.say("Bà Mẫn", "Nó theo bà xuống Cửa Cống chữa cho người trong trại. Người ta bắt nó chứ không bắt bà. Bà còn chữa cho nhà Chánh Ty cơ mà.", "sad")
	await story.say(story.P(), "Thử tro ở cổng thì biết được gì ạ?", "think")
	await story.say("Bà Mẫn", "Ngồi xuống đây.", "point")
	story.end_talk()
	var pc = PictureCard.new()
	add_child(pc)
	await pc.open("res://assets/tex/chen_ran.png", "Cái chén men rạn")
	pc.note("Bà xoa tro lên chén, dội nước. Men trôi sạch, kẽ rạn còn đen.")
	AutoTest.shot("bs13_chen")
	await story.say("Bà Mẫn", "Tro có biết Nghiệt là gì đâu. Nó chỉ chui vào kẽ thôi. Da bị Nghiệt chạm cũng có lớp men rạn như cái chén này, nên tro mới bám vào.")
	await add_note("tro_men")
	story.end_talk()
	await pc.close()
	var at = AshTest.new()
	add_child(at)
	await at.open("Tay bà Mẫn")
	await at.rub()
	await at.wash(0.7)
	await at.stamp("XÁM")
	await story.say("Bà Mẫn", "Tay bà ngâm thuốc suốt ba mươi năm, nứt hết cả rồi. Ra cổng thử tro, bà cũng bị tính là xám thôi.", "shrug")
	await story.say("Bà Mẫn", "Ba trăm năm nay, trong thành có ai bị Nghiệt chạm đâu. Thế mà năm nào cũng có người bị thử ra xám.")
	story.end_talk()
	await at.close()
	await add_note("tay_nut")
	await story.say("Bà Mẫn", "Tối muốn xuống trại thì tìm Cửa Cống ở góc quảng trường. Cẩn thận, đừng để người áo lam trông thấy.", "worry")
	story.end_talk()


func _den_thay() -> void:
	if done.has("den"):
		await _talk_to(world.actor("coi_den"))
		await story.say("Người coi đền", "Tối nhớ đặt chén lên bậc cửa.")
		story.end_talk()
		return
	done["den"] = true
	var k = world.actor("coi_den")
	await _talk_to(k)
	await story.say("Người coi đền", "Rửa tay chưa? Rồi thì vào đi.", "stern")
	story.end_talk()
	var pc = PictureCard.new()
	add_child(pc)
	await pc.open("res://assets/tex/tranh_tho.png", "Tranh thờ")
	AutoTest.shot("bs14_tranh")
	await story.say("Người coi đền", "Thầy của Bà đấy. Một nhát chém, người sạch một bên, người bẩn một bên.")
	await story.say(story.P(), "Ông cháu bổ củi đâu có chém kiểu ấy.")
	await story.say("Người coi đền", "Ông cháu thì biết cái gì.", "cross")
	pc.note("Bên trái người áo trắng đứng thẳng. Bên phải người tối màu cúi rạp. Ở giữa là nét trắng.")
	await story.say("", "Nét chém trong tranh không dừng lại ở đâu. Nó kéo thẳng xuống tận mép tranh.")
	story.end_talk()
	await pc.close()
	await story.say("Người coi đền", "Sứ Giả ngoài cổng cũng từ lòng thành của dân mình mà ra. Nó có đụng đến ai trong thành đâu.", "chest")
	await story.say("Người coi đền", "Tối về nhớ đặt một chén lên bậc. Nhà nào cũng đặt cả.")
	story.end_talk()
	await add_note("tranh_tho")


func _nha_rua() -> void:
	var g = world.actor("gam")
	var o = world.actor("seo")
	if done.has("nharua"):
		if gone.has("seo"):
			if g:
				await _talk_to(g)
				await story.say("Chị Gấm", "Sáng nay người của Ty xuống đưa ông ấy ra cổng. Ông ấy chẳng mang theo thứ gì.", "sad")
				if sins.has("bao_seo"):
					world.emo("gam", "cold")
					g.emote("...", 1.4)
				story.end_talk()
		else:
			await story.say("Chị Gấm", "Ông ấy ngủ rồi. Cứ để ông ấy ngủ.")
			story.end_talk()
		return
	done["nharua"] = true
	met["gam"] = true
	await _talk_to(g, [o] if (o and not gone.has("seo")) else [])
	await story.say("Chị Gấm", "Tìm ai? Đây là chỗ giặt đồ liệm. Người trên kia chẳng xuống đây đâu.", "cross")
	if gone.has("seo") or o == null:
		story.end_talk()
		add_nghi(15.0)
		return
	met["seo"] = true
	o.face_point(world.hero.global_position)
	await story.say("Ông Sẹo", "Cứ để người ta vào, Gấm.", "smile")
	await story.say("Ông Sẹo", "Người gánh hòm cho mụ Sương phải không? Ngồi đi. Khoan, đừng ngồi chỗ ấy. Chỗ lõm kia là chỗ Bà từng ngồi.", "point")
	await story.say(story.P(), "Bà nào ạ?")
	await story.say("Ông Sẹo", "Bà trên Điện ấy.")
	await story.say("Ông Sẹo", "Năm tôi bảy tuổi, tay bị Nghiệt chạm. Thử tro ra xám, người ta đưa tôi xuống đây.", "chest")
	await story.say("Ông Sẹo", "Bà ngồi đúng chỗ ấy, nắm cổ tay tôi rồi cạo lớp men đi. Chỉ còn cái sẹo này.", "give")
	await story.say(story.P(), "Tay ra xám mà không bị đuổi ạ?", "surprise")
	await story.say("Ông Sẹo", "Hồi ấy xám thì giữ lại, chờ Bà rửa men. Sau này Bà không xuống nữa. Từ đó, cứ xám là bị đuổi.", "sad")
	world.emo("hero", "sad")
	await story.say("Chị Gấm", "Ông lại kể chuyện ngày xưa rồi.", "sigh")
	await story.say("Ông Sẹo", "Cái chén ngoài bậc là tôi đặt cho Bà. Không phải cho thứ ngoài cổng ấy.")
	story.end_talk()
	await add_note("seo")
	add_nghi(15.0)


func _cart() -> void:
	## Evening, behind the Dinh Ty: what the white cart carries (8.3, 6.6). The same cart as at the camp.
	done["cart"] = true
	var m: Dictionary = world.markers
	var spot: Vector3 = m["cart_spot"]
	var cart: Node3D = story.white_cart(spot + Vector3(1.6, 0, -1.2))
	var s = story.npc("suong", "suong", spot + Vector3(-0.6, 0, 0.4), "right")
	var t1 = story.npc("ty1", "khamsu", spot + Vector3(-6.0, 0, -0.4), "right")
	var who: Array = []
	for i in 3:
		who.append(story.npc("xe_%d" % i, ["refugee_m", "refugee_w", "dan_m"][i] if not (i == 0 and Game.flags.get("bs_gate", "") == "blame") else "dan_m",
			spot + Vector3(-7.2 - i * 0.8, 0, 0.2), "right"))
	world.hero.global_position = spot + Vector3(0.2, 0, 1.2)
	world.rig.follow(world.hero, true)
	await Game.wait(0.3)
	story.carry_chest(true)
	await story.say("Bà Sương", "Đặt hòm lên xe. Cẩn thận đấy.")
	story.end_talk()
	var chest: Node3D = story.put_chest(spot + Vector3(1.6, 1.9, -0.4))   # roped on top of the cloth
	t1.move_to(spot + Vector3(-1.4, 0, -0.6), 2.0)
	for i in who.size():
		(who[i] as Node).move_to(spot + Vector3(0.9 + i * 0.25, 0, -1.9), 1.6)
	await Game.wait(1.6)
	AutoTest.shot("bs15_xetrang")
	await story.say("", "Người áo lam dẫn ba người ra từ cửa sau Dinh Ty. Tay họ bị trói lỏng. Họ trèo lên xe rồi chui xuống dưới tấm vải trắng.")
	for w in who:
		(w as Node3D).visible = false
	world.emo("ty1", "cold")   # (the man who speaks as "Người áo lam" here is ty1)
	await story.say("Người áo lam", "Ba người. Đúng như trong sổ.")
	await story.say("Bà Sương", "Ba người.", "nod")
	story.end_talk()
	if Game.flags.get("bs_gate", "") == "blame":
		await story.say("", "Anh Vững ngồi ở đầu xe. Anh cúi mặt, không ngẩng lên.")
		story.end_talk()
		await add_note("vung_xe")
	await story.say(story.P(), "Họ đi đâu vậy?", "worry")
	await story.say("Bà Sương", "Đi chữa bệnh. Ở Vạn Thư, người ta hiểu về men hơn ở đây. Tôi đã cứu được hai người rồi.", "chest")
	await story.say(story.P(), "Thế còn những người khác?")
	await story.say("Bà Sương", "Về ngủ đi.", "cold")
	story.end_talk()
	await add_note("xe_trang")
	await Overlay.fade_out(0.5)
	cart.queue_free()
	chest.queue_free()
	for id in ["ty1", "xe_0", "xe_1", "xe_2"]:
		if world.actor(id):
			world.despawn(id)
	_go_level("street", "plaza")


func _camp_night() -> void:
	## Through the Cửa Cống to the camp at night (Nghi): bà Lành, the nong, and the hand at the tents (8.3).
	camp_nights += 1
	add_nghi(25.0)
	await Overlay.fade_out(0.6)
	await story.say("", "Cửa Cống thấp, phải cúi gập người mới chui qua được. Nước thải ngập đến đầu gối.")
	story.end_talk()
	world.see_through_wall(false)
	world.set_time("night", true)
	Audio.play_music("", 1.0)   # below the wall at night: only the tapping on porcelain, as on the first night
	var h = world.hero
	h.global_position = world.CAMP + Vector3(1.4, 0, 1.8)
	h.global_position.y = world.height_at(h.global_position.x, h.global_position.z)
	h.face_point(world.CAMP)
	var lanh = world.actor("lanh")
	lanh.global_position = world.CAMP + Vector3(-1.6, 0, -1.0)
	lanh.global_position.y = world.height_at(lanh.global_position.x, lanh.global_position.z)
	lanh.face_point(h.global_position)
	world.rig.set_view(world.CAMP + Vector3(1.0, 3.2, 8.0), world.CAMP + Vector3(0, 0.8, 0))
	await Overlay.fade_in(0.6)
	await story.say("Bà Lành", "Lại xuống đây à? Ngồi đi. Trên ấy có ai lo cho cháu ăn đâu.", "smile")
	story.end_talk()
	if notes.has("pk395") and not notes.has("khong_phai"):
		await story.say(story.P(), "Bà ơi, năm PK 395 có nhà nào ở Tầng Rửa bị đuổi, mang theo một đứa bé chưa đặt tên không?")
		story.end_talk()
		var pc = PictureCard.new()
		add_child(pc)
		await pc.open("res://assets/ui/nong_close.png", "Cái nong của bà Lành")
		pc.note("Mỗi mảnh thẻ tro là một người. Năm mảnh xâu chung một sợi dây.")
		AutoTest.shot("bs16_nong")
		await story.say("Bà Lành", "Nhà ông Thục. Năm người, đủ cả năm mảnh đây.", "give")
		await story.say("Bà Lành", "Đứa bé không qua nổi mùa đông đầu tiên.", "sad")
		await story.say("Bà Lành", "Sao tự dưng hỏi chuyện ấy?", "think")
		await story.say(story.P(), "...Không có gì ạ.")
		await story.say("Bà Lành", "Năm ấy có đoàn người phương bắc ở nhờ trại mấy tuần. Họ mang theo một đứa bé, chẳng cho ai bế. Khăn quấn nó có ô vuông như bàn cờ. Rồi cả đoàn đi về phía đèo.")
		story.end_talk()
		await pc.close()
		await add_note("khong_phai")
	if Game.flags.get("bs_gate", "") == "can" and not done.has("dieu_roi"):
		done["dieu_roi"] = true
		var dieu = world.actor("dieu")
		if dieu:
			dieu.global_position = world.CAMP + Vector3(2.6, 0, -0.6)
			dieu.global_position.y = world.height_at(dieu.global_position.x, dieu.global_position.z)
			dieu.face_point(h.global_position)
		await story.say("Diệu", "Bố tôi bị đánh roi ở Sân Tro. Chỉ vì cho một người lạ qua cổng.", "angry")
		story.end_talk()
	if not done.has("camp_hand"):
		done["camp_hand"] = true
		story._tapping(2.6)
		await Game.wait(2.0)
		world.emo("lanh", "worry")
		await story.say("Cỏ", "Bà ơi! Nó lại xuống rồi!", "scared")
		story.end_talk()
		await h.move_to(world.markers["fight"] + Vector3(0.8, 0, -0.6), -1, true)
		world.set_control(false)
		var dir: Vector3 = world.markers["glaze"] - world.markers["fight"]
		while true:
			var b = Battle.new()
			add_child(b)
			world.hud.visible = false
			var res: String = await b.run(world, {"enemies": ["manh_tinh", "manh_tinh"],
				"intro": "Tay trắng thò vào lều. Mảnh Sành bò theo sau.", "stage_at": world.markers["fight"], "stage_dir": dir,
				"hero_hp": story.hero_hp, "glimpse_on_touch": true,
				"vision": {"id": "source", "image": "res://assets/vision/gate.png", "stage": "res://scripts/fx/vision_source.gd", "lines": ["", "", ""]}})
			story.hero_hp = maxi(b.hero_hp, 40)
			b.queue_free()
			world.hud.visible = true
			world.hero.clear_pose()
			if res != "lose":
				break
			await story.say("", "Ngã xuống rồi. Đứng dậy lần nữa?")
			await world.choose(["Thử lại"])
			story.end_talk()
		await add_note("dau_nguon")
		world.rig.follow(world.hero, true)
		await story.say("Bà Lành", "Mấy đêm nay nó xuống sớm hơn rồi.", "worry")
		story.end_talk()
	await story.say("", "Phải về qua Cửa Cống trước khi chuông cổng vang lên.")
	story.end_talk()
	await Overlay.fade_out(0.6)
	world.see_through_wall(true)
	_go_level("street", "plaza")


# ================================================================== the Ty tests again (9.2)
func _retest() -> void:
	## Nghi full: a khám sư and a man of the Ty stop them in the square. The glaze on the hand is real; who pays?
	var m: Dictionary = world.markers
	var k = story.npc("kham2", "khamsu", (m["plaza"] as Vector3) + Vector3(-1.2, 0, -1.4), "down")
	story.npc("ty2", "maty", (m["plaza"] as Vector3) + Vector3(1.2, 0, -1.6), "down")
	world.hero.global_position = (m["plaza"] as Vector3) + Vector3(0, 0, 0.4)
	world.hero.face("up")
	world.rig.follow(world.hero, true)
	# (the talker "Khám sư" finds the gate's khám sư first, still standing at the gate: this one's face is set directly)
	world.emo("kham2", "stern")
	world.emo("ty2", "cold")
	await story.say("Khám sư", "Người gánh hòm cho bà Sương phải không? Có người báo lên rồi. Đưa tay đây.")
	story.end_talk()
	var at = AshTest.new()
	add_child(at)
	await at.open()
	await at.rub()
	var steady: int = await story.timing.pendulum(Vector2(world.get_viewport().get_visible_rect().size.x * 0.66, 360), 5, 1.15,
		"Space khi tay lắc ra mép", "Tay yên")
	await at.wash(0.6 if steady >= 3 else 0.95)
	await at.stamp("XÁM")
	await story.say("Khám sư", "...Xám.")
	story.end_talk()
	var opts: Array = ["Cháu bị Nghiệt chạm ở cửa đèo.", "Tay cháu nứt vì gánh hòm."]
	var ways: Array = ["truth", "plea"]
	if met.has("gam") and not gone.has("gam"):
		opts.append("Chị Gấm ở Nhà Rửa cũng bị xám, sao chị ấy vẫn ở trong thành?")
		ways.append("blame")
	var way: String = ways[await world.choose(opts)]
	match way:
		"truth":
			world.emo("kham2", "think")
			await story.say("Khám sư", "...Giữ lại.")
			story.end_talk()
			await at.close()
			await Overlay.fade_out(0.5)
			await story.say("", "Bị giữ ở Dinh Ty đến chiều. Không ai hỏi thêm câu nào.")
			story.end_talk()
			nghi = 70.0
		"plea":
			world.emo("kham2", "sigh")
			await story.say("Khám sư", "...Xám nhạt. Đi đi.")
			story.end_talk()
			await at.close()
			nghi = 60.0
		"blame":
			world.emo("kham2", "cold")
			await story.say("Khám sư", "Gấm nào? ...Thôi, đi đi. Ty sẽ xuống Nhà Rửa.")
			story.end_talk()
			await at.close()
			gone["gam"] = true
			sins.append("bao_gam")
			nghi = 20.0
	AutoTest.note("retest_" + way)
	Game.flags["bs_retest"] = way
	if world.actor("kham2"):
		world.despawn("kham2")
	if world.actor("ty2"):
		world.despawn("ty2")
	_refresh()
	if way == "truth":
		await Overlay.fade_in(0.5)
