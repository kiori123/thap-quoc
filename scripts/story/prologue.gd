extends Node
## Chương Mở Đầu: one day in Vô Danh Cốc. Beats: morning -> incident -> night -> departure.

const Battle = preload("res://scripts/battle/battle.gd")
const Timing = preload("res://scripts/ui/timing.gd")
const B = preload("res://scripts/world/builder.gd")
const ReachArm = preload("res://scripts/fx/reach_arm.gd")

const BEATS := ["morning", "incident", "night", "departure"]
const ONG := "Ông"
const ACT := "res://assets/sprites/chars/hero_act.png"
const ONGX := "res://assets/sprites/chars/ong_x.png"
const SIT := "res://assets/sprites/chars/sitters.png"

signal finished

var world
var main
var timing
var _timing_layer: CanvasLayer
var hero_hp := 70
var visited := {}


func _ready() -> void:
	_timing_layer = CanvasLayer.new()
	_timing_layer.layer = 45
	add_child(_timing_layer)
	timing = Timing.new()
	_timing_layer.add_child(timing)


func run(from_beat := "morning") -> void:
	# who speaks under which name (world.say: their face and gestures, a lift as they start a line)
	world.talkers = {ONG: "ong", "Lúa": "lua", "Tí": "ti", "Người bán muối": "peddler", "Người tị nạn": ["ref_m", "ref_o"],
		"Chú Năm": "chunam", "Na": "na"}
	var start := BEATS.find(from_beat)
	if start < 0:
		start = 0
	for i in range(start, BEATS.size()):
		Game.set_checkpoint(BEATS[i])
		AutoTest.note("beat_" + BEATS[i])
		match BEATS[i]:
			"morning": await _beat_morning()
			"incident": await _beat_incident()
			"night": await _beat_night()
			"departure": await _beat_departure()
	await _ending()
	finished.emit()


# ================================================================== helpers
func P() -> String:
	return Game.player_name


func say(spk: String, text: String, emote := "") -> void:
	## emote: the speaker's face and body language for the line (tools/art/chars.py EMOTES), see world.say
	await world.say(spk, text, emote)


func end_talk() -> void:
	world.dialogue.hide_box()


func ong():
	return world.actor("ong")


func cut(on: bool) -> void:
	world.set_control(not on)
	world.hud.show_hints(not on)
	if on:
		world.hud.objective("")
	await Overlay.letterbox(on, 0.4)


func screen_of(p: Vector3) -> Vector2:
	return world.rig.cam.unproject_position(p)


func go_interact(iid: String, pos: Vector3, prompt: String, objective: String, radius := 1.7) -> void:
	## Let the player walk freely until they interact with `iid`.
	world.add_interact(iid, pos, prompt, radius)
	world.set_markers([pos])
	world.hud.objective(objective)
	world.hud.show_hints(true)
	world.set_control(true)
	if Game.auto:
		await get_tree().create_timer(0.3).timeout
		await AutoTest.shot("go_" + iid)
		var from: Vector3 = world.hero.global_position - pos
		from.y = 0.0
		var stand: Vector3 = pos + (from.normalized() if from.length() > 0.01 else Vector3(0, 0, 1)) * radius * 0.7
		await world.hero.move_to(stand)
		await Game.wait(0.1)
	else:
		while true:
			var got: String = await world.interacted
			if got == iid:
				break
	world.set_control(false)
	world.remove_interact(iid)
	world.set_markers([])


func go_trigger(tid: String, pos: Vector3, radius: float, objective: String) -> void:
	world.add_trigger(tid, pos, radius)
	world.set_markers([pos], 2.6)
	world.hud.objective(objective)
	world.hud.show_hints(true)
	world.set_control(true)
	if Game.auto:
		await get_tree().create_timer(0.4).timeout
		await AutoTest.shot("go_" + tid)
		await world.hero.move_to(pos, -1, true)
	else:
		while true:
			var got: String = await world.trigger_entered
			if got == tid:
				break
	world.set_control(false)
	world.remove_trigger(tid)
	world.set_markers([])


func npc(id: String, sheet: String, pos: Vector3, facing := "down"):
	if world.actor(id):
		world.despawn(id)
	return world.spawn(id, sheet, pos, facing)


# ================================================================== MORNING
func _beat_morning() -> void:
	Overlay.set_black(true)
	world.set_time("dawn", true)
	var o = npc("ong", "res://assets/sprites/chars/ong.png", world.markers["porch_ong"], "down")
	world.hero.global_position = world.markers["door"] + Vector3(0.8, 0, 0.3)
	world.hero.face("down")
	world.set_control(false)
	Audio.play_music("village", 2.5)
	# establishing shot: the valley at dawn, then down to the house
	world.rig.set_view(Vector3(-3, 21, 44), Vector3(-8, 7, -20))
	AutoTest.note("reveal_start")
	await Overlay.fade_in(1.4)
	await Overlay.card("Vô Danh Cốc", "Thung lũng không thuộc nước nào", 1.6)
	AutoTest.shot("m01_valley")
	await world.rig.focus(world.HOUSE + Vector3(0, 0, 3.0), 0.8, 3.0, true)
	await cut(true)
	AutoTest.shot("m02_house")
	await say(ONG, "Dậy rồi thì ra chẻ ít củi. Ông còn nấu cháo.")
	await say(P(), "Dạ...", "sigh")
	end_talk()
	await world.rig.focus(world.markers["chop_block"], 0.7, 0.9)
	await say(ONG, "Rìu cắm ở gốc chặt, cạnh đống củi.")
	end_talk()
	world.rig.follow(world.hero, false)
	await world.rig.release(1.0)
	await cut(false)
	await go_interact("chop", world.markers["chop_block"], "Chẻ củi", "Ra gốc chặt cạnh đống củi", 1.6)
	await _chore_chop()
	await _chore_sweep()
	await _chore_carry()
	await _free_roam_morning()


func _chore_chop() -> void:
	await cut(true)
	var h = world.hero
	await h.move_to(world.markers["chop_spot"])
	h.face("left")
	await ong().move_to(world.markers["chop_ong"])
	ong().face_point(h.global_position)
	await world.rig.focus(world.markers["chop_spot"] + Vector3(-1.0, 0, 0), 0.62, 1.0)
	await say(ONG, "Cầm rìu cho chắc. Đừng bổ bằng tay, bổ bằng cả người.")
	await say(ONG, "Một nét. Bắt đầu từ chỗ mình đứng, đi tới chỗ mình chọn, rồi dừng.", "behind")
	await say(P(), "Chẻ củi thôi mà ông, có phải đánh nhau đâu.", "shrug")
	await say(ONG, "Ừ. Chẻ đi.")
	end_talk()
	world.props["axe_block"].visible = false   # in the hands now
	await world.hud.guide("Chẻ củi: một nét", [
		"Nhấn và GIỮ Space: rìu giơ lên, vệt mực chạy dài trên dải giấy ở dưới màn hình.",
		"THẢ Space đúng lúc vệt mực chạm vạch vàng.",
		"Thả sớm thì non tay. Giữ quá vạch thì dập củi."])
	await timing.demo_stroke(screen_of(world.props["log"].global_position), 0.6, 1.3)
	var perfect := 0
	var cleaned := 0
	var logs := 0      # logs done with: split, or (after three goes) set aside
	var fails := 0     # goes at this log that did not split it
	while logs < 3:
		world.props["log"].visible = true
		world.props["log_split"].visible = false
		h.act("ready")
		await Game.wait(0.35)
		h.act("windup_deep")
		var log_pos: Vector3 = world.props["log"].global_position
		var grade: String = await timing.stroke(screen_of(log_pos), 0.6, 1.05 - logs * 0.08, true, "Giữ Space, thả ở vạch")
		h.act("smear")
		await get_tree().create_timer(0.07).timeout
		h.act("follow")
		world.rig.shake(0.05 if grade == "miss" else (0.16 if grade == "over" else 0.1), 0.15)
		if grade == "miss" or grade == "over":
			Audio.sfx("chop_bad", -2.0, 0.1)
			h.emote("dập" if grade == "over" else "non", 0.7, Color(0.85, 0.75, 0.7))
			fails += 1
			await Game.wait(0.5)
			if fails >= 3:
				# chewed up past splitting: it goes on the pile as it is, and a fresh log comes up
				await say(ONG, "Khúc này xơ rồi. Để đấy, lấy khúc khác.", "sigh")
				end_talk()
				logs += 1
				fails = 0
				continue
			# he says it the way he would; the strip's terms go in the line under it
			if grade == "over":
				world.hud.toast("Giữ quá vạch vàng nên dập củi. Thả sớm hơn một chút.", 2.8)
				await say(ONG, "Mạnh tay quá, dập rồi. Lại.", "stern")
			else:
				world.hud.toast("Thả sớm quá, vệt mực chưa tới vạch vàng.", 2.8)
				await say(ONG, "Non tay. Lại.", "cross")
			if fails == 2:
				await say(ONG, "Nhìn ông này.")
				end_talk()
				await timing.demo_stroke(screen_of(log_pos), 0.6, 1.3)
			end_talk()
			continue
		Audio.sfx("chop", -1.0, 0.1)
		world.props["log"].visible = false
		world.props["log_split"].visible = true
		cleaned += 1
		logs += 1
		fails = 0
		if grade == "perfect":
			perfect += 1
		await Game.wait(0.5)
	AutoTest.shot("m03_chop")
	h.clear_pose()
	h.face("left")
	Game.flags["chop_perfect"] = perfect
	if perfect > 0:
		# the near-smile: the corner of his mouth moves, then his hand goes to the old wound
		await world.rig.focus(ong().global_position, 0.5, 0.8)
		ong().face("down")
		ong().set_pose(ONGX, 6, 0)
		AutoTest.shot("m04_nearsmile")
		await Game.wait(0.9)
		ong().set_pose(ONGX, 6, 1)
		await Game.wait(0.8)
		ong().clear_pose()
		ong().face("up")
		await say(P(), "Ông đau à?", "worry")
		await say(ONG, "Vết cũ. Trời sắp trở gió.")
		ong().face_point(h.global_position)
	elif cleaned > 0:
		await say(ONG, "Tách thì tách được. Chưa nhát nào ngọt.", "cross")
	else:
		await say(ONG, "Dập hết rồi. Mai chẻ lại.", "sigh")
	await say(ONG, "Được rồi. Bê vào chái bếp cho ông.", "none")
	end_talk()
	world.props["log_split"].visible = false
	world.props["axe_block"].visible = true
	await cut(false)


func _chore_sweep() -> void:
	await cut(true)
	await say(ONG, "Quét cái sân đi. Lá đa bay sang cả đây rồi.")
	end_talk()
	await world.rig.focus(world.markers["broom_prop"], 0.7, 0.9)
	await say(ONG, "Chổi dựng ở góc hiên.")
	end_talk()
	await world.rig.release(0.6)
	await cut(false)
	await go_interact("broom", world.markers["broom_prop"], "Lấy chổi", "Lấy chổi ở góc hiên", 1.8)
	await cut(true)
	world.props["broom"].visible = false
	await say(ONG, "Quét một lượt thôi. Quét đi quét lại bụi nó bay vào mặt.")
	end_talk()
	await world.hud.guide("Quét lá", [
		"Đi tới từng đống lá (có mũi tên vàng), nhấn Space.",
		"GIỮ Space: vòng quét đầy dần.",
		"THẢ khi vòng chạy vào khúc vàng. Giữ quá tay thì bụi bay vào mặt."])
	await cut(false)
	var good := 0          # piles swept clean at the first go
	var shown := false
	var goes := [0, 0, 0]
	var h = world.hero
	var left := [0, 1, 2]
	for k in 3:
		world.add_interact("leaves_%d" % k, world.props["leaves_%d" % k].global_position, "Quét", 1.4)
	world.hud.objective("Quét lá (0/3)")
	world.set_markers([world.props["leaves_0"].global_position, world.props["leaves_1"].global_position, world.props["leaves_2"].global_position], 1.5)
	while left.size() > 0:
		# the player walks to whichever pile they like; the camera follows them the whole time
		var i: int = left[0]
		if not Game.auto:
			var got: String = await world.interacted
			if not got.begins_with("leaves_"):
				continue
			i = int(got.substr(7))
		left.erase(i)
		world.remove_interact("leaves_%d" % i)
		world.set_control(false)
		world.hud.show_hints(false)
		var pile = world.props["leaves_%d" % i]
		await h.move_to(pile.global_position + Vector3(1.0, 0, 0.1))
		h.face("left")
		h.act("broom_a")
		await world.rig.focus(pile.global_position, 0.78, 0.35)
		if not shown:   # the first pile: one sweep shown before the player's own
			shown = true
			await timing.demo_hold(screen_of(h.global_position + Vector3(0, 1.3, 0)))
		var grade: String = await timing.hold(screen_of(h.global_position + Vector3(0, 1.3, 0)))
		h.act("broom_b")
		Audio.sfx("sweep", -2.0, 0.1)
		var leaves = B.particles(world, "res://assets/sprites/props/leaf.png", 14 if grade != "miss" else 5, 0.9, Vector3(0.4, 0.1, 0.3), pile.global_position + Vector3(-0.2, 0.2, 0),
			{"dir": Vector3(-1, 0.6, 0), "spread": 40.0, "vmin": 1.5, "vmax": 3.0, "gravity": Vector3(0, -3, 0), "size": 0.14})
		leaves.one_shot = true
		leaves.preprocess = 0.0
		leaves.explosiveness = 0.9
		leaves.emitting = true
		get_tree().create_timer(1.5).timeout.connect(leaves.queue_free)
		if grade == "over":
			h.emote("khụ!", 0.7, Color(0.85, 0.8, 0.7))  # swept too hard: the dust flies up in their face
		goes[i] += 1
		if grade == "perfect" or grade == "good":
			if goes[i] == 1:
				good += 1
			pile.visible = false
		else:
			# a clumsy stroke: some of it flies, a smaller heap stays behind, to be swept again
			pile.scale *= 0.65
			if goes[i] >= 3:
				pile.visible = false
				world.hud.toast("Đống lá vơi hẳn. Gió cuốn nốt chỗ còn lại.", 2.4)
			else:
				left.append(i)
				world.add_interact("leaves_%d" % i, pile.global_position, "Quét lại", 1.4)
				if grade == "over":
					world.hud.toast("Giữ quá tay, lá bay tung mà vẫn còn sót. Quét lại đống này.", 2.8)
				else:
					world.hud.toast("Thả sớm quá, vòng quét chưa tới khúc vàng. Quét lại đống này.", 2.8)
		await Game.wait(0.45)
		h.clear_pose()
		var rest := []
		for j in left:
			rest.append(world.props["leaves_%d" % j].global_position)
		world.set_markers(rest, 1.5)
		if left.size() > 0:
			world.hud.objective("Quét lá (%d/3)" % (3 - left.size()) + (": còn sót, quét lại" if goes[i] > 0 and left.has(i) else ""))
			world.hud.show_hints(true)
			world.set_control(true)
	AutoTest.shot("m05_sweep")
	await cut(true)
	world.props["broom"].visible = true
	await world.rig.release(0.6)
	if good >= 2:
		await say(ONG, "Ừ.", "nod")
	else:
		await say(ONG, "Sạch rồi. Lần sau quét một lượt thôi.")
	for i in 3:
		world.props["leaves_%d" % i].visible = false
	end_talk()
	await cut(false)


func _chore_carry() -> void:
	await cut(true)
	await say(ONG, "Gánh nước đổ đầy chum.")
	end_talk()
	await world.rig.focus(world.markers["well_center"], 0.75, 0.9)
	await say(ONG, "Đòn gánh để cạnh giếng.")
	end_talk()
	await world.rig.release(0.6)
	await cut(false)
	await go_interact("well", world.markers["well_center"], "Gánh nước", "Ra giếng lấy đòn gánh", 2.0)
	await cut(true)
	await say(ONG, "Đòn gánh nó nhún thì kệ nó, đừng ghì. Thùng văng ra tới nơi rồi hẵng đỡ.", "behind")
	end_talk()
	var h = world.hero
	var yoke: Sprite3D = world.props["yoke"]
	var yoke_parent := yoke.get_parent()
	var well_at: Vector3 = h.global_position
	var steady := 0
	var trip := 0
	while true:
		trip += 1
		if trip > 1:   # back at the well for another load
			await Overlay.fade_out(0.4)
			h.global_position = well_at
			h.face_point(world.markers["jar"])
			world.rig.follow(h, true)
			await Overlay.fade_in(0.4)
		yoke_parent.remove_child(yoke)
		h.add_child(yoke)
		yoke.position = Vector3(0, 0.95, 0.05)
		if trip == 1:
			await world.hud.guide("Gánh nước", [
				"Đòn gánh lắc qua lắc lại: chấm trắng chạy trên thanh phía trên đầu.",
				"Nhấn Space đúng lúc chấm trắng chạy tới khúc vàng ở một trong hai đầu.",
				"Bấm sớm, hay để lỡ một nhịp, thì nước sóng sánh đổ ra."])
			await timing.demo_pendulum(screen_of(h.global_position + Vector3(0, 2.4, 0)))
		world.rig.follow(h, false)
		h.move_to(world.markers["jar"], 2.7)
		steady = await timing.pendulum(screen_of(h.global_position + Vector3(0, 2.0, 0)), 6, 1.3)
		while h.moving:
			await get_tree().process_frame
		if trip == 1:
			AutoTest.shot("m06_carry")
		Audio.sfx("water", -2.0)
		h.remove_child(yoke)
		yoke_parent.add_child(yoke)
		yoke.global_position = world.markers["jar"] + Vector3(0.9, 0.53, -0.3)
		if steady >= 5:
			await say(ONG, "Đầy chum.", "nod")
			break
		if trip >= 3:
			await say(ONG, "Thôi, thế là đủ nấu cơm rồi.", "sigh")
			break
		if steady >= 3:
			await say(ONG, "Được nửa chum. Đủ nấu cơm.", "nod")
			if await world.choose(["Gánh thêm chuyến nữa", "Thôi, đủ rồi"]) == 1:
				break
		else:
			await say(ONG, "Đổ gần hết dọc đường rồi. Gánh lại chuyến nữa.", "stern")
		end_talk()
	Game.flags["water"] = steady
	end_talk()
	# the salt seller comes in at the gate with what the road is saying; the old man and he talk, the child listens.
	# (He has passed this house for ten years and greets the old man as a stranger every time: people meet the
	# old man and talk with him, but the memory goes once he is out of sight. Only those of his house remember.)
	var ped = npc("peddler", "res://assets/sprites/chars/peddler.png", world.markers["gate"] + Vector3(0, 0, 1.6), "up")
	var by_ong: Vector3 = ong().global_position + Vector3(1.6, 0, 1.0)
	await world.rig.focus((by_ong + ong().global_position) * 0.5, 0.65, 0.8)
	await ped.move_to(by_ong)
	ped.face_point(ong().global_position)
	ong().face_point(ped.global_position)
	AutoTest.shot("m07_peddler")
	await say("Người bán muối", "Nhà có ai không? Bác có lấy muối không? Muối Bạch Sơn, trắng lắm.", "smile")
	await say(ONG, "Ừ. Để ngoài hiên.", "listen")
	await say("Người bán muối", "Trên đèo vắng hoe. Tôi đi một mình mà cứ phải ngoái lại.", "worry")
	await say("Người bán muối", "Trên Bạch Sơn lại đuổi một đoàn ra ngoài cổng đấy bác. Nghe bảo có cả mấy người học thuốc.")
	world.emo("hero", "worry")
	await say("Người bán muối", "Họ đang dạt về phía đèo này. Ai cũng bảo lũng nhà bác Nghiệt không vào được mà.")
	end_talk()
	ong().face("up")
	ong().emote("...", 1.0)
	await Game.wait(1.0)
	await say(ONG, "Ừ.")
	world.hero.face_point(ped.global_position)
	await say(P(), "Lúa cũng đang học thuốc trên đó...")
	await say("Người bán muối", "Thế à. Mong là không phải đoàn ấy.")
	ong().face_point(ped.global_position)
	await say(ONG, "Vào ăn bát cháo đã rồi hẵng đi.")
	end_talk()
	ped.move_to(world.markers["gate"] + Vector3(0, 0, 2.4))
	ong().face_point(world.hero.global_position)
	await say(ONG, "Được rồi. Đi chơi đi. Trưa về ăn cơm. Đừng ra quá cột mốc.", "behind")
	await say(P(), "Dạ, con biết rồi.", "nod")
	end_talk()
	world.despawn("peddler")
	await world.rig.release(0.6)
	await cut(false)


# ------------------------------------------------------------------ free roam
const TALKS := {
	"baca": [["Bà Cả", "Cháu ở cái nhà cuối xóm phải không? Lớn nhanh thật."],
		["Bà Cả", "Hồi bé ai nuôi cháu nhỉ... Bà già rồi, nhớ chẳng ra. Chắc cả làng nuôi."]],
	"chunam": [["Chú Năm", "Năm nay được mùa đấy. Đất này lành, chưa thấy Nghiệt bén mảng bao giờ.", "smile"],
		["Chú Năm", "Ra khỏi lũng thì chú không dám chắc. Nghe đâu trên Bạch Sơn lại đuổi người ra khỏi cổng.", "worry"]],
	"kids": [["Na", "Mày hứa rồi đấy nhé! Lời thần trói thiên hạ, lời Tự trói mình!", "point"],
		["Tí", "Mày học đâu cái câu dài ngoằng thế?", "smile"],
		["Na", "Bà tao nói suốt. Bà bảo hứa rồi thì phải giữ, chẳng ai bắt cũng phải giữ.", "chest"]],
	"peddler": [["Người bán muối", "Chú đi buôn mười năm, chưa thấy chỗ nào yên như lũng này.", "smile"],
		["Người bán muối", "Đi khắp mười nước, chỗ nào chú cũng gặp Nghiệt. Bên Thiên Mệnh cứ bảo nước họ sạch. Chú chẳng tin.", "shrug"],
		["Người bán muối", "Chú ở lại vài hôm, đợi đường đèo yên đã."]],
	"pegs": [["", "Mười cái móc gỗ cũ, mòn bóng. Cái thứ mười một mới hơn, ông đóng cho con hồi nhỏ."]],
	"coinjar": [["", "Hũ tiền đồng cũ. Ông bảo đó không phải tiền của ông, nên không bao giờ tiêu."]],
	"beam": [["", "Cây xà chính. Gỗ đen bóng, chắc còn cũ hơn cả ngôi nhà."]],
	"sword": [["", "Thanh kiếm cùn treo trên vách. Ông bảo của một người khách bỏ quên."]],
	"stele": [["", "Bia đá ở cửa đèo. Mười con dấu, mỗi con một kiểu. Dòng chữ đã mờ: \"Đất này không thuộc nước nào.\""]],
	"marker": [["", "Cột mốc. Ông dặn không bao giờ được ra quá chỗ này."]],
	"shrine": [["", "Miếu thổ địa. Nhang vẫn còn ấm."]],
	"banyan": [["", "Cây đa đầu làng. Người già bảo nó có trước cả làng."]],
	"well": [["", "Giếng nước. Sâu và mát."]],
}


func _spawn_villagers() -> void:
	var baca = npc("baca", "res://assets/sprites/chars/baca.png", world.markers["baca"], "down")
	baca.set_pose(SIT, 3, 0)
	npc("chunam", "res://assets/sprites/chars/chunam.png", world.markers["chunam"], "up")
	npc("ti", "res://assets/sprites/chars/ti.png", world.markers["kids"], "right")
	npc("na", "res://assets/sprites/chars/na.png", world.markers["kids"] + Vector3(1.3, 0, 0.3), "left")
	npc("peddler", "res://assets/sprites/chars/peddler.png", world.markers["peddler"], "down")


func _free_roam_morning() -> void:
	_spawn_villagers()
	await ong().move_to(world.markers["porch_ong"])
	ong().face("down")
	var spots := {
		"baca": world.markers["baca"], "chunam": world.markers["chunam"], "kids": world.markers["kids"] + Vector3(0.6, 0, 0),
		"peddler": world.markers["peddler"], "pegs": world.HOUSE + Vector3(-1.45, 0, 2.6),
		"coinjar": world.HOUSE + Vector3(3.9, 0, 2.6), "beam": world.HOUSE + Vector3(2.0, 0, 3.0),
		"sword": world.HOUSE + Vector3(0, 0, 2.6), "stele": world.STELE + Vector3(1.2, 0, 1.2),
		"marker": world.MARKER + Vector3(1.0, 0, 1.0), "shrine": world.VILLAGE + Vector3(3.6, 0, -0.2),
		"banyan": world.VILLAGE + Vector3(0.0, 0, -3.2), "well": world.markers["well_center"],
	}
	var prompts := {"baca": "Nói chuyện", "chunam": "Nói chuyện", "kids": "Nói chuyện", "peddler": "Nói chuyện"}
	for k in spots:
		world.add_interact(k, spots[k], prompts.get(k, "Xem"), {"banyan": 2.6, "well": 2.0}.get(k, 1.8))
	world.add_interact("ong_home", world.markers["porch_ong"] + Vector3(0, 0, 0.6), "Về nhà ăn cơm", 1.8)
	world.hud.objective("Đi dạo quanh làng. Về nhà gặp ông khi xong")
	world.hud.show_hints(true)
	world.set_control(true)
	AutoTest.shot("m07_freeroam")
	if Game.auto:
		for k in ["pegs", "coinjar", "beam", "sword", "baca", "kids", "chunam", "peddler", "stele", "marker"]:
			await world.hero.move_to(spots[k] + Vector3(0.7, 0, 0.7), -1, true)
			await _talk(k)
			if k == "baca":
				AutoTest.shot("m08_baca")
			if k == "stele":
				AutoTest.shot("m09_stele")
		await world.hero.move_to(world.markers["porch_ong"] + Vector3(0.6, 0, 1.2), -1, true)
	else:
		while true:
			var got: String = await world.interacted
			if got == "ong_home":
				world.set_control(false)
				world.hero.face_point(ong().global_position)
				await say(ONG, "Đi chơi đủ rồi à?")
				var c: int = await world.choose(["Về ăn cơm", "Đi thêm chút nữa"])
				end_talk()
				if c == 0:
					break
				world.set_control(true)
				continue
			world.set_control(false)
			await _talk(got)
			world.set_control(true)
	world.set_control(false)
	for k in spots:
		world.remove_interact(k)
	world.remove_interact("ong_home")


func _talk(k: String) -> void:
	visited[k] = true
	var who = null
	match k:
		"baca": who = world.actor("baca")
		"chunam": who = world.actor("chunam")
		"kids": who = world.actor("na")
		"peddler": who = world.actor("peddler")
	if who and k != "baca":
		who.face_point(world.hero.global_position)
	if who:
		world.hero.face_point(who.global_position)
	for line in TALKS[k]:   # [speaker, line] or [speaker, line, emote]
		await say(line[0], line[1], line[2] if line.size() > 2 else "")
	end_talk()


# ================================================================== INCIDENT
func _beat_incident() -> void:
	await Overlay.fade_out(0.8)
	for id in ["baca", "chunam", "ti", "na", "peddler"]:
		world.despawn(id)
	if world.actor("ong") == null:
		npc("ong", "res://assets/sprites/chars/ong.png", world.markers["porch_ong"], "down")
	world.set_time("gloom", true)
	Audio.play_music("", 1.0)
	world.hero.global_position = world.markers["porch_ong"] + Vector3(1.4, -0.3, 1.6)
	world.hero.face("left")
	ong().global_position = world.markers["porch_ong"]
	ong().face("right")
	world.rig.follow(world.hero, true)
	var ti = npc("ti", "res://assets/sprites/chars/ti.png", world.markers["gate"] + Vector3(0, 0, 2.0), "up")
	await Overlay.fade_in(1.0)
	await Overlay.card("", "Trưa", 0.8)
	await cut(true)
	await ti.move_to(world.markers["yard_center"] + Vector3(0, 0, 1.0), -1, true)
	ti.emote("!", 0.8)
	await say("Tí", "%s ơi! Có người ở cửa đèo! Đông lắm..." % P(), "surprise")
	world.emo("hero", "worry")
	await say("Tí", "Có cả... cái gì trắng trắng đuổi theo sau!", "scared")
	end_talk()
	Audio.play_music("tension", 1.5)
	ong().face("up")
	await world.rig.focus(ong().global_position, 0.55, 1.0)
	ong().emote("...", 1.2)
	await Game.wait(1.2)
	ong().face_point(world.hero.global_position)
	await say(ONG, "Đừng ra quá cột mốc.", "stern")
	end_talk()
	world.hud.toast("Cầm lấy cái rìu.", 1.6)
	world.despawn("ti")
	await world.rig.release(0.6)
	await cut(false)
	# the pass is a long way: out of the yard gate, along the road through the village, then up toward the
	# hills; arrows on the road show the way
	var hp: Vector3 = world.hero.global_position
	world.set_trail([Vector2(hp.x, hp.z), Vector2(15, 7.2), Vector2(11, 9), Vector2(2, 7), Vector2(-5, 2), Vector2(-8, -2),
		Vector2(-15, -9), Vector2(-23, -13.5), Vector2(-30, -17.5)])
	await go_trigger("pass", world.markers["pass_trigger"], 3.2, "Ra cửa đèo: theo đường đất qua đầu làng, lên phía đồi")
	world.set_trail([])
	await _pass_scene()


func _pass_scene() -> void:
	await cut(true)
	var mk: Vector3 = world.MARKER
	var out: Vector3 = (mk - Vector3(-24, 0, -12)).normalized()
	var h = world.hero
	await h.move_to(world.markers["marker_in"] + Vector3(1.2, 0, 1.2), -1, true)
	h.face_point(mk)
	await world.rig.focus(mk + out * 2.0, 0.9, 1.2)
	# refugees stumble out of the white fog
	var refugees := []
	var specs := [["lua", "res://assets/sprites/chars/lua.png", 2.6], ["ref_o", "res://assets/sprites/chars/refugee_o.png", 5.0],
		["ref_w", "res://assets/sprites/chars/refugee_w.png", 6.4], ["ref_m", "res://assets/sprites/chars/refugee_m.png", 4.2]]
	for i in specs.size():
		var s: Array = specs[i]
		var lateral := Vector3(-out.z, 0, out.x) * (i - 1.5) * 0.9
		var start: Vector3 = mk + out * (s[2] + 6.0) + lateral
		start.y = world.height_at(start.x, start.z)
		var a = npc(s[0], s[1], start, "down")
		refugees.append(a)
	for i in refugees.size():
		var s2: Array = specs[i]
		var lateral2 := Vector3(-out.z, 0, out.x) * (i - 1.5) * 0.9
		var dest: Vector3 = mk + out * float(s2[2]) + lateral2
		dest.y = world.height_at(dest.x, dest.z)
		refugees[i].move_to(dest, 1.4)
	await Game.wait(2.4)
	AutoTest.shot("i01_refugees")
	await say("Người tị nạn", "Cứu... cứu với...")
	await say(P(), "Lúa?!", "surprise")
	await say("Lúa", "...Đừng lại gần. Tao bị... Chạy đi. Nó tới.", "scared")
	end_talk()
	Audio.sfx("roar", -4.0)
	world.rig.shake(0.1, 0.5)
	await Game.wait(0.6)
	# the hero steps past the marker, against the old man's word
	await h.move_to(mk + out * 1.4, -1, true)
	await cut(false)
	world.set_control(false)
	world.hud.show_hints(false)
	# ---------------- battle 1: three Mảnh Sành (provisional folk name)
	for r in refugees:
		r.visible = false
	while true:
		var res := await _battle({"enemies": ["manh_tinh", "manh_tinh", "manh_tinh"], "tutorial": true,
			"teach": ["bo", "defend", "quet", "ho", "ran", "chao"], "chain": false, "glimpse_on_touch": true,
			"intro": "Ba Mảnh Sành bò ra khỏi màn sương trắng!",
			"vision": {"id": "gate", "image": "res://assets/vision/gate.png", "stage": "res://scripts/fx/vision_gate.gd",
				"lines": ["Cổng Trắng khép lại.", "Sau cổng, những gương mặt nhìn ra. Một bàn tay khép then cửa.",
					"Rồi từ sau song cổng, những bàn tay trắng bò ra."]}})
		if res != "lose":
			break
		await _retry_prompt()
	for r in refugees:
		r.visible = true
	# Lúa can hardly stand: the young man holds Lúa up, still well short of the marker; the others lag behind
	var lat_o := Vector3(-out.z, 0, out.x)
	var lua_at: Vector3 = mk + out * 2.3 + lat_o * 0.7
	lua_at.y = world.height_at(lua_at.x, lua_at.z)
	world.actor("lua").global_position = lua_at
	world.actor("ref_m").global_position = lua_at + lat_o * 0.55
	world.actor("lua").face_point(mk)
	world.actor("ref_m").face_point(mk)
	# ---------------- the big one. First a sound out of the mist, many small taps on the road; then its hands,
	# feeling along the ground for whoever lagged behind (it cannot see); then, following the arms back into the
	# white, what they belong to.
	await cut(true)
	h.clear_pose()
	h.global_position = mk + out * 3.2
	h.face_point(mk + out * 6.0)
	Audio.play_music("", 0.8)
	world.set_time("dread")   # the light goes out of the day as it comes near (and comes back when it leaves)
	var lat := Vector3(-out.z, 0, out.x)
	var shot: Array = world.rig.side_view(mk + out * 5.5, out, 14.5, 2.6, 2.4)
	await world.rig.view_to(shot[0], shot[1], 0.9)
	var far: Vector3 = mk + out * 15.0
	far.y = world.height_at(far.x, far.z)
	var big := B.billboard(world, "res://assets/sprites/monsters/nghiet_tinh.png", far, 0.04, true, 7, 0)
	big.shaded = false   # porcelain stays white whatever the light does
	big.modulate = Color(0.34, 0.38, 0.46, 0.0)   # at first only a shape in the mist
	create_tween().tween_property(big, "modulate:a", 0.55, 2.0)
	_shards_home(big, mk + out * 4.5, out, 16, 1.7)
	get_tree().create_timer(1.0).timeout.connect(func(): AutoTest.shot("i02a_shards"))
	_tapping(3.6)
	await Game.wait(1.4)
	var victims := [world.actor("ref_w"), world.actor("ref_o")]
	for v in victims:
		v.face_point(far)
		v.emote("...", 1.0)
	await Game.wait(0.6)
	# four hands come along the ground; two find the ones who lagged behind, two feel about at nothing
	var arms := []
	for i in 4:
		var arm = ReachArm.new()
		world.add_child(arm)
		var to: Vector3
		var wander := 0.5
		if i < 2:
			to = (victims[i] as Node3D).global_position + Vector3(0, 0.3, 0)
			wander = 0.18
		else:
			to = mk + out * (7.8 - 0.8 * (i - 2)) + lat * (1.8 if i == 2 else -1.6)
			to.y = world.height_at(to.x, to.z) + 0.25
		var from: Vector3 = big.global_position + Vector3(0, -0.4 + 0.45 * i, 0) + lat * (0.5 - 0.35 * i)
		arm.setup(from, from.lerp(to, 0.55) + Vector3(0, 0.5, 0), to, wander)
		arms.append(arm)
		arm.reach(1.5 + 0.3 * i)
		await Game.wait(0.2)
	Audio.sfx("crack", -9.0, 0.1)
	if arms[1].reaching():
		await arms[1].arrived
	AutoTest.shot("i02b_hands")
	await Game.wait(0.5)
	# the two that found someone close on them, and the porcelain climbs from the ankle up
	for i in 2:
		arms[i].grip()
		victims[i].flash(3)
		Audio.sfx("crack", -3.0, 0.1)
	await Game.wait(0.45)
	for v in victims:
		var spr_path := "res://assets/sprites/chars/statue_w.png" if v.id == "ref_w" else "res://assets/sprites/chars/statue_o.png"
		npc(v.id + "_statue", spr_path, v.global_position, "down")
		world.despawn(v.id)
		Audio.sfx("shatter", -6.0)
	world.emo("lua", "scared")
	await say(P(), "Không!", "shock")
	end_talk()
	# the arms draw back into the mist, and the eye goes with them, low, to what they belong to
	for arm in arms:
		arm.retract(1.0)
	var at: Vector3 = mk + out * 9.0
	at.y = world.height_at(at.x, at.z)
	var low: Array = world.rig.side_view(mk + out * 7.0, out, 13.5, 0.5, 1.4)
	var low_pos: Vector3 = low[0]
	low_pos.y = maxf(low_pos.y, world.height_at(low_pos.x, low_pos.z) + 1.2)
	world.set_diorama(0.25, 0.45)   # keep the tall figure sharp (the fight that follows does the same)
	world.rig.view_to(low_pos, at + Vector3(0, 1.0, 0), 1.4)
	Audio.sfx("reveal", 0.0)   # a breath drawn in, then the porcelain: the struck part lands as it comes clear
	# a cold light in the mist behind it, so it stands out against a glowing fog instead of melting into it
	var halo := OmniLight3D.new()
	halo.light_color = Color(0.72, 0.82, 1.0)
	halo.light_energy = 0.0
	halo.light_volumetric_fog_energy = 4.0
	halo.omni_range = 9.0
	world.add_child(halo)
	var away: Vector3 = at - low_pos
	away.y = 0.0
	halo.global_position = at + away.normalized() * 2.2 + Vector3(0, 2.4, 0)
	create_tween().tween_property(halo, "light_energy", 3.5, 1.4)
	var big_end: Vector3 = big.position + (at - far)
	var glide := create_tween().set_parallel(true)
	glide.tween_property(big, "position", big_end, 1.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	glide.tween_property(big, "modulate", Color(0.62, 0.66, 0.74, 0.92), 1.1)
	await get_tree().create_timer(1.1 * (0.3 if Game.fast else 1.0), false).timeout
	# clear of the mist: the halo of arms flung wide, the glaze catching the light all at once; and the cut to the
	# foot of it, looking up (the author's reference: a monument filling the sky)
	glide.kill()
	big.position = big_end   # (hidden by the cut) it has come all the way out
	big.frame = 4
	big.modulate = Color(1.5, 1.55, 1.7, 1.0)
	create_tween().tween_property(big, "modulate", Color(0.9, 0.92, 0.97), 0.9)
	Overlay.flash(Color(0.92, 0.96, 1.0, 0.6), 0.5)
	halo.light_volumetric_fog_energy = 1.2   # from close up, lit mist between the lens and it would wash it out
	var props: Array = await _monument(big, at, low_pos)
	AutoTest.shot("i02_big")
	await Overlay.name_card("TRẮNG TAY", "Nghiệt Bạch Sơn")
	await _monument_clear(props)
	big.frame = 0
	halo.queue_free()   # the fight puts its own behind it
	await cut(false)
	# ---------------- battle 2: Trắng Tay (provisional folk name; cannot be beaten here)
	big.visible = false
	var res2 := "lose"
	while true:
		res2 = await _battle({"enemies": ["nghiet_tinh"], "keep_enemy_nodes": false,
			"escort": {"who": "lua", "sheet": "res://assets/sprites/chars/lua.png", "helper": "ref_m",
				"helper_sheet": "res://assets/sprites/chars/refugee_m.png", "rounds": 6, "boss_steps": 4},
			"tutorial": true, "teach": ["escort", "bars", "break", "thau", "chain", "nhatnet", "ho", "ran", "chao"],
			"intro": "Những mảnh sứ vỡ cuộn quanh nó. Trắng Tay vươn những cánh tay trắng.", "hero_hp": maxi(hero_hp, 50)})
		if res2 != "lose" and res2 != "lose_lua":
			break
		await _retry_prompt(res2)
	big.visible = true
	big.frame = 5
	# ---------------- retreat to the marker: the wall nobody can see
	await cut(true)
	var lua = world.actor("lua")
	h.clear_pose()
	await say(P(), "Lúa, đi!", "resolve")
	end_talk()
	lua.move_to(world.markers["marker_in"] + Vector3(0.9, 0, 0.4), 4.0)
	await h.move_to(world.markers["marker_in"] + Vector3(0.6, 0, 0.6), 5.0)
	h.face_point(mk)
	var shot2: Array = world.rig.side_view(mk + out * 1.5, out, 15.5, 3.0, 2.7)
	await world.rig.view_to(shot2[0], shot2[1], 0.5)
	big.frame = 3
	var charge := create_tween()
	charge.tween_property(big, "position", mk + out * 1.0 + Vector3(0, big.position.y - mk.y, 0), 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await charge.finished
	Audio.sfx("wall", 0.0)
	world.rig.shake(0.35, 0.6)
	_wall_ripple(mk + Vector3(0, 1.4, 0))
	world.set_time("gloom")   # it falls back into the mist and the day comes back
	big.frame = 6
	var back := create_tween().set_parallel(true)
	back.tween_property(big, "position", mk + out * 9.0 + Vector3(0, big.position.y - mk.y, 0), 2.2).set_trans(Tween.TRANS_SINE)
	back.tween_property(big, "modulate:a", 0.0, 2.4)
	AutoTest.shot("i03_wall")
	await back.finished
	big.queue_free()
	Audio.play_music("", 2.0)
	await Game.wait(0.8)
	await say(P(), "...Nó không vào được.", "sigh")
	_lay_down(lua)
	await say("", "Trắng Tay lùi vào trong sương, tan dần. Trên đường chỉ còn mấy mảnh sứ.")
	world.emo("hero", "worry")
	await say("Lúa", "Chưa hết đâu... Nó còn quay lại.")
	await say("Lúa", "Chân tao... lạnh quá. Không thấy gì nữa.")
	end_talk()
	await Game.wait(0.6)
	await Overlay.fade_out(1.2)
	for id in ["ref_m", "ref_w_statue", "ref_o_statue"]:
		world.despawn(id)
	await cut(false)


func _monument(big: Sprite3D, at: Vector3, from_side: Vector3) -> Array:
	## The shot Trắng Tay is named in. The camera drops to the ground a few paces off its base and looks up,
	## wide, so it fills the sky; a great ring of cold light opens behind its crown; stones and shards of
	## porcelain lift off the road round it and hang there; black ink is flung out across the ground under it;
	## broken stones stand dark in the foreground. Returns what it put in the world, for _monument_clear.
	var f := 0.3 if Game.fast else 1.0
	var made := []
	var toward: Vector3 = from_side - at
	toward.y = 0.0
	toward = toward.normalized()
	var right: Vector3 = (-toward).cross(Vector3.UP).normalized()
	var cam_pos: Vector3 = at + toward * 6.2 - right * 0.4
	cam_pos.y = world.height_at(cam_pos.x, cam_pos.z) + 0.95
	var look: Vector3 = at + Vector3(0, 3.2, 0) - right * 1.9
	var cam: Camera3D = world.rig.cam
	made.append(["fov", cam.fov])
	cam.fov = 60.0
	world.rig.set_view(cam_pos, look)
	Overlay.set_vignette(0.95)
	world.rig.shake(0.3, 0.8)
	Audio.sfx("roar", -6.0)
	Audio.sfx("wall", -8.0)
	# black ink flung out across the ground under it
	var ink := Decal.new()
	ink.texture_albedo = Assets.tex("res://assets/sprites/fx/ink_burst.png")
	ink.size = Vector3(2.0, 6.0, 2.0)
	ink.normal_fade = 0.6   # only on the ground, not up the sides of things
	world.add_child(ink)
	ink.global_position = at + Vector3(0, 0.5, 0)
	create_tween().tween_property(ink, "size", Vector3(14.0, 6.0, 14.0), 0.35 * f).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	made.append(ink)
	# the ring of light behind the crown
	var ring := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(4.6, 4.6)
	ring.mesh = qm
	var rm := StandardMaterial3D.new()
	rm.albedo_texture = Assets.tex("res://assets/sprites/fx/halo_ring.png")
	rm.albedo_color = Color(1.2, 1.3, 1.6, 0.0)
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	rm.disable_fog = true
	ring.material_override = rm
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(ring)
	ring.global_position = at + Vector3(0, 4.85, 0) - toward * 0.7
	ring.scale = Vector3.ONE * 0.6
	var rt := create_tween().set_parallel(true)
	rt.tween_property(rm, "albedo_color:a", 0.7, 0.5 * f)
	rt.tween_property(ring, "scale", Vector3.ONE, 0.7 * f).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	made.append(ring)
	# stones and shards of porcelain lift off the road and hang there, turning
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	for i in 30:
		var shard := i % 3 != 0
		var s := Sprite3D.new()
		if shard:
			s.texture = Assets.tex("res://assets/sprites/fx/shard.png")
			s.shaded = false
			s.modulate = Color(0.85, 0.9, 1.05) if i % 4 else Color(0.55, 0.68, 1.0)
			s.pixel_size = rng.randf_range(0.03, 0.05)
		else:
			s.texture = Assets.tex("res://assets/sprites/fx/debris.png")
			s.hframes = 3
			s.frame = i % 3
			s.pixel_size = rng.randf_range(0.04, 0.07)
		s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		world.add_child(s)
		var a := rng.randf() * TAU
		var r := rng.randf_range(2.2, 6.5)
		var p: Vector3 = at + Vector3(cos(a) * r, 0, sin(a) * r)
		if i < 2:   # a couple close to the lens, out at the edges of the frame
			p = cam_pos.lerp(at, rng.randf_range(0.3, 0.45)) + right * (2.6 if i == 0 else -2.4)
			s.pixel_size *= 0.6
		elif (p - at).dot(toward) > 1.0 and absf((p - at).dot(right)) < 1.6:
			p += right * 2.4   # never hanging in front of it
		p.y = world.height_at(p.x, p.z) + 0.15
		s.global_position = p
		var up := p + Vector3(0, rng.randf_range(0.6, 6.0) if i >= 2 else rng.randf_range(0.3, 0.9), 0)
		var tw := s.create_tween()
		tw.tween_interval(rng.randf_range(0.0, 0.4) * f)
		tw.tween_property(s, "global_position", up, rng.randf_range(1.2, 2.0) * f).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		tw.tween_property(s, "global_position", up + Vector3(0, 0.25, 0), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(s, "global_position", up, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		made.append(s)
	# broken stones standing dark in the foreground, framing it
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.05, 0.05, 0.07)
	dark.roughness = 1.0
	for side in [-1.0, 1.0]:
		var b := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.7, 2.6 if side < 0 else 1.6, 0.6)
		b.mesh = bm
		b.material_override = dark
		world.add_child(b)
		var bp: Vector3 = cam_pos + (at - cam_pos).normalized() * 2.2 + right * side * 2.4
		bp.y = world.height_at(bp.x, bp.z) + bm.size.y * 0.35
		b.global_position = bp
		b.rotation = Vector3(rng.randf_range(-0.15, 0.15), rng.randf_range(0, TAU), side * 0.12)
		made.append(b)
	# mist curling round its base
	for i in 7:
		var m := Sprite3D.new()
		m.texture = Assets.tex("res://assets/sprites/props/smoke.png")
		m.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		m.shaded = false
		m.pixel_size = rng.randf_range(0.09, 0.14)
		m.modulate = Color(0.6, 0.66, 0.8, 0.0)
		world.add_child(m)
		var a2 := rng.randf() * TAU
		var mp: Vector3 = at + Vector3(cos(a2), 0, sin(a2)) * rng.randf_range(1.0, 3.2)
		mp.y = world.height_at(mp.x, mp.z) + rng.randf_range(0.3, 1.2)
		m.global_position = mp
		var mt := m.create_tween().set_parallel(true)
		mt.tween_property(m, "modulate:a", rng.randf_range(0.35, 0.6), 0.8 * f)
		mt.tween_property(m, "global_position", mp + right * rng.randf_range(-1.2, 1.2) + Vector3(0, 0.4, 0), 4.0)
		made.append(m)
	await get_tree().create_timer(0.9 * f, false).timeout
	return made


func _monument_clear(made: Array) -> void:
	## Back to the fight's framing: the props of the named shot go.
	for m in made:
		if m is Array and m[0] == "fov":
			world.rig.cam.fov = m[1]
		elif m is Node and is_instance_valid(m):
			m.queue_free()
	Overlay.set_vignette(world.TIMES[world.time_name]["vig"])
	await get_tree().process_frame


func _tapping(t: float) -> void:
	## Out of the mist, before anything is seen: taps on porcelain, a few and far apart, then more and closer
	## together, from all along the road (fingers feeling their way). The same tap is the count-in of Bịt Mắt.
	var e := 0.0
	var gap := 0.42
	while e < t:
		Audio.sfx("tick", -16.0 + 10.0 * e / t, 0.35, randf_range(0.7, 1.15))
		var w := gap * randf_range(0.6, 1.4)
		await Game.wait(w)
		e += w
		gap = maxf(0.07, gap * 0.86)


func _shards_home(body: Sprite3D, field: Vector3, out: Vector3, n: int, t: float) -> void:
	## Mảnh Sành are pieces of Trắng Tay: what is left of them on the field tumbles back and into its body.
	var lateral := Vector3(-out.z, 0, out.x)
	for i in n:
		var s := Sprite3D.new()
		s.texture = Assets.tex("res://assets/sprites/fx/shard.png")
		s.pixel_size = 0.035 + 0.01 * (i % 3)
		s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		s.modulate = Color(0.85, 0.9, 1.05) if i % 3 else Color(0.55, 0.68, 1.0)
		world.add_child(s)
		var a: Vector3 = field + out * randf_range(-2.0, 2.0) + lateral * randf_range(-1.2, 1.2)
		a.y = world.height_at(a.x, a.z) + 0.1
		s.global_position = a
		var delay := t * 0.6 * float(i) / n
		var tw := s.create_tween()
		tw.tween_interval(delay)
		# a short skitter along the ground toward it, then a hop up into the body
		var mid: Vector3 = a.lerp(body.global_position, 0.35)
		mid.y = world.height_at(mid.x, mid.z) + 0.1
		tw.tween_property(s, "global_position", mid, t * 0.25).set_trans(Tween.TRANS_SINE)
		var into: Vector3 = body.global_position + Vector3(randf_range(-0.4, 0.4), randf_range(-1.6, 0.6), 0)
		tw.tween_property(s, "global_position", into, t * 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(s, "modulate:a", 0.0, 0.08)
		tw.tween_callback(s.queue_free)
		if i % 4 == 0:
			get_tree().create_timer(delay + t * 0.55).timeout.connect(func(): Audio.sfx("shatter", -16.0, 0.2))


func _battle(config: Dictionary) -> String:
	var b = Battle.new()
	add_child(b)
	world.hud.visible = false
	config["hero_hp"] = config.get("hero_hp", hero_hp)
	var res: String = await b.run(world, config)
	hero_hp = b.hero_hp
	if res == "lose":
		hero_hp = 70
	b.queue_free()
	world.hud.visible = true
	world.hero.clear_pose()
	world.rig.follow(world.hero, true)
	Audio.play_music("tension", 1.0)
	return res


func _retry_prompt(why := "lose") -> void:
	AutoTest.note("battle_lost_retry")
	if Game.auto:
		Game.auto_timing = "perfect"
	await say("", "Không kịp. Làm lại lần nữa?" if why == "lose_lua" else "Ngã xuống rồi. Đứng dậy lần nữa?")
	await world.choose(["Thử lại"])
	end_talk()


func _wall_ripple(p: Vector3) -> void:
	var s := Sprite3D.new()
	s.texture = Assets.tex("res://assets/sprites/props/smoke.png")
	s.pixel_size = 0.12
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.shaded = false
	s.modulate = Color(2.0, 2.0, 2.3, 0.9)
	world.add_child(s)
	s.global_position = p
	var tw := create_tween().set_parallel(true)
	tw.tween_property(s, "scale", Vector3.ONE * 6.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(s, "modulate:a", 0.0, 0.7)
	tw.chain().tween_callback(s.queue_free)


# ================================================================== NIGHT
func _beat_night() -> void:
	Overlay.set_black(true)
	for id in ["ref_m", "ref_w_statue", "ref_o_statue", "ref_o", "ref_w"]:
		world.despawn(id)
	world.set_time("night", true)
	Audio.play_music("night", 2.0)
	if world.actor("ong") == null:
		npc("ong", "res://assets/sprites/chars/ong.png", world.markers["porch_ong"], "down")
	var lua = world.actor("lua")
	if lua == null:
		lua = npc("lua", "res://assets/sprites/chars/lua.png", world.markers["mat_lua"], "down")
	lua.global_position = world.markers["mat_lua"]
	_lay_down(lua)
	world.props["tray"].visible = true
	world.props["bowl_up"].visible = true
	var h = world.hero
	h.global_position = world.markers["mat_hero"]
	h.set_pose(SIT, 3, 2)
	ong().global_position = world.markers["mat_ong"]
	ong().face("left")
	world.rig.follow(h, true)
	await world.rig.focus(world.markers["mat_hero"] + Vector3(0.6, 0, 0), 0.6, 0.1)
	await Overlay.fade_in(1.4)
	await Overlay.card("", "Tối", 0.8)
	await cut(true)
	AutoTest.shot("n01_porch")
	ong().set_pose(ONGX, 6, 3, false)
	await say(ONG, "Rửa vừa thôi. Rửa mạnh quá thì không lành.")
	ong().clear_pose()
	ong().face("left")
	await say(P(), "Ông đắp lá gì thế? Chỗ trắng trên chân Lúa không lan lên nữa.")
	await say(ONG, "Lá ngoài vườn.")
	await say(P(), "Bọn trên Bạch Sơn đóng cổng lại, mặc người ta chết ngoài ấy.")
	await say(ONG, "Ừ. Ông thấy.")
	await say(P(), "Loại người như thế, hiểu làm gì cho mệt.")
	await say(ONG, "Người gác cổng ấy chắc cũng từng mất người nhà.", "sad")
	var c: int = await world.choose(["Mất người nhà thì được đẩy người khác ra chết à?", "Sao lúc nào ông cũng bênh họ thế?"])
	Game.flags["night_choice"] = c
	if c == 0:
		await say(ONG, "Ông có bảo thế đâu.")
		await say(ONG, "Mai con có gặp họ thì nhìn cho kỹ đã. Rồi muốn làm gì thì làm.", "behind")
	else:
		await say(ONG, "Ông có bênh ai.")
		await say(P(), "Thế ông nghĩ gì?")
		await say(ONG, "Ăn đi, cơm nguội rồi.", "none")
	await say(P(), "Mai con lên Bạch Sơn. Phải có thuốc cho Lúa. Gặp đứa nào đóng cổng thì con hỏi cho ra nhẽ.")
	end_talk()
	world.emo("ong", "sigh")
	ong().emote("...", 1.4)
	await Game.wait(1.4)
	ong().face("up")
	await say(ONG, "Ngủ đi. Mai đi sớm.")
	await say("Lúa", "Bác ơi... bác tên gì ấy nhỉ? Cháu quên mất.")
	ong().face_point(lua.global_position)
	await say(ONG, "Cứ gọi là ông.", "none")
	await say("Lúa", "...Dạ.")
	end_talk()
	await cut(false)
	# a quiet moment the player can spend looking around the porch
	h.clear_pose()
	h.global_position = world.markers["mat_hero"] + Vector3(0.6, -0.3, 1.6)
	world.add_interact("bowl", world.props["bowl_up"].global_position + Vector3(0, 0, 0.9), "Xem", 1.7)
	world.add_interact("pegs", world.HOUSE + Vector3(-1.2, 0, 2.6), "Xem", 1.6)
	world.add_interact("beam", world.HOUSE + Vector3(2.4, 0, 3.0), "Xem", 1.6)
	world.add_interact("sleep", world.markers["door"] + Vector3(0.5, 0, 1.2), "Đi ngủ", 1.8)
	world.hud.objective("Đi ngủ")
	world.hud.show_hints(true)
	world.set_control(true)
	if Game.auto:
		await h.move_to(world.props["bowl_up"].global_position + Vector3(0.5, 0, 0.6))
		await _night_look("bowl")
		await h.move_to(world.markers["door"] + Vector3(0.0, 0, 0.6))
	else:
		while true:
			var got: String = await world.interacted
			if got == "sleep":
				break
			world.set_control(false)
			await _night_look(got)
			world.set_control(true)
	world.set_control(false)
	for k in ["bowl", "pegs", "beam", "sleep"]:
		world.remove_interact(k)
	# before sleeping, the old man rests his hand on the main beam
	await cut(true)
	await ong().move_to(world.markers["beam_spot"])
	ong().face("down")
	ong().set_pose(ONGX, 6, 4)
	await world.rig.focus(world.markers["beam_spot"] + Vector3(0, 0.6, 0), 0.5, 1.2)
	AutoTest.shot("n02_beam")
	await Game.wait(2.0)
	ong().clear_pose()
	await Overlay.fade_out(1.8)
	world.props["tray"].visible = false
	world.props["bowl_up"].visible = false
	world.despawn("lua")
	await cut(false)


func _lay_down(a) -> void:
	a.set_pose(a.sheet_path, a.SHEET_COLS, 0, false, 4)
	a.pose_sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	a.pose_sprite.rotation_degrees = Vector3(-90, 0, 90)
	a.pose_sprite.position = Vector3(0, 0.06, 0)
	a.blob.visible = false


func _night_look(k: String) -> void:
	var lines := {
		"bowl": "Mười cái bát úp sau mâm, cái nào cũng sạch. Bữa tối nào ông cũng bày đủ mười cái, chẳng bao giờ nói để cho ai.",
		"pegs": "Mười cái móc gỗ cũ trong ánh đèn. Không cái nào treo gì.",
		"beam": "Cây xà chính. Ông lại vừa lau nó.",
	}
	await say("", lines.get(k, ""))
	end_talk()


# ================================================================== DEPARTURE
func _beat_departure() -> void:
	Overlay.set_black(true)
	world.set_time("dawn2", true)
	Audio.play_music("village", 3.0)
	if world.actor("ong") == null:
		npc("ong", "res://assets/sprites/chars/ong.png", world.markers["porch_ong"], "down")
	var h = world.hero
	h.clear_pose()
	h.global_position = world.markers["yard_center"] + Vector3(0.8, 0, 0)
	h.face("left")
	ong().global_position = world.markers["yard_center"] + Vector3(-0.9, 0, -0.2)
	ong().face("right")
	world.rig.follow(h, true)
	await world.rig.focus(h.global_position + Vector3(0, 0, -0.8), 0.6, 0.1)
	await Overlay.fade_in(1.6)
	await Overlay.card("", "Rạng sáng hôm sau", 0.8)
	await cut(true)
	await say(ONG, "Cơm nắm đây. Đi đường xa phải ăn.", "give")
	world.props["sword_wall"].visible = false
	ong().set_pose(ONGX, 6, 5, true)
	AutoTest.shot("d00_sword")
	await say(ONG, "Của người khách bỏ quên. Cùn rồi, nhưng còn hơn cái rìu.")
	ong().clear_pose()
	ong().face("right")
	await say(P(), "Ông giữ nhà nhé. Con đi ít lâu thôi.", "smile")
	world.emo("ong", "nod")
	end_talk()
	AutoTest.shot("d01_give")
	await Overlay.fade_out(1.0)
	# walk the last stretch to the marker together: the camera already on the marker, as the talk there will be framed
	# (wider), the two walking into it along the road (following them from the stele put the shrine's roof across half
	# the frame, then a tree's crown)
	var mk: Vector3 = world.MARKER
	var mk_in: Vector3 = world.markers["marker_in"]
	var along: Vector3 = (mk_in - (world.STELE + Vector3(3.0, 0, 2.4))).normalized()
	h.global_position = mk_in - along * 4.6
	ong().global_position = mk_in - along * 5.4 + Vector3(0.5, 0, 0.4)
	for a in [h, ong()]:
		a.global_position.y = world.height_at(a.global_position.x, a.global_position.z)
	# side on, from the north-east of the road: from the south a tree's crown by the marker fills the bottom of the frame
	var side := Vector3(-along.z, 0, along.x)
	if side.z > 0.0:
		side = -side
	var mid: Vector3 = mk_in - along * 2.0
	var eye: Vector3 = mid + side * 7.5 + Vector3(0, 3.6, 0)
	eye.y = maxf(eye.y, world.height_at(eye.x, eye.z) + 2.6)
	await world.rig.view_to(eye, mid + Vector3(0, 0.6, 0), 0.01)
	await Overlay.fade_in(1.0)
	world.rig.view_to(eye - side * 1.5 + along * 1.0, mk_in + Vector3(0, 0.6, 0), 4.0)
	ong().move_to(mk_in + Vector3(0.6, 0, 0.8), 1.6)
	await h.move_to(mk_in + Vector3(-0.4, 0, -0.2), 1.6)
	await Game.wait(0.6)
	h.face_point(ong().global_position)
	ong().face_point(h.global_position)
	var two: Vector3 = (h.global_position + ong().global_position) * 0.5
	var eye2: Vector3 = two + side * 4.6 + Vector3(0, 2.2, 0)
	eye2.y = maxf(eye2.y, world.height_at(eye2.x, eye2.z) + 1.8)
	await world.rig.view_to(eye2, two + Vector3(0, 0.7, 0), 1.2)
	AutoTest.shot("d02_marker")
	await say(P(), "Ông không đi tiếp à?", "worry")
	await say(ONG, "Ông không đi xa được. Chân yếu.", "behind")
	end_talk()
	world.emo("hero", "sad")
	await Game.wait(1.2)
	await say(ONG, "Đi đi. Ông chờ.", "nod")
	end_talk()
	# the hero walks out into the morning mist; the old man stays at the marker
	var out: Vector3 = (mk - Vector3(-24, 0, -12)).normalized()
	var road: Vector3 = mk + out * 16.0
	road.y = world.height_at(road.x, road.z)
	h.move_to(road, 1.5)
	h.face("up")   # (walking away from us, down the road)
	ong().face("up")
	# from behind the old man, down the road after them: he stays in the near ground, they go small into the mist
	# (the shot from the south had a tree's crown filling the bottom of the frame)
	var op: Vector3 = ong().global_position
	var perp := Vector3(-out.z, 0, out.x)
	var cam_at: Vector3 = op - out * 5.2 - perp * 1.0 + Vector3(0, 3.4, 0)
	cam_at.y = maxf(cam_at.y, world.height_at(cam_at.x, cam_at.z) + 1.6)
	# (looking down the road, not out at the bright mist over it: level, a third of the frame burned white)
	await world.rig.view_to(cam_at, mk + out * 6.5 + Vector3(0, -0.3, 0), 4.0)
	AutoTest.shot("d03_walkaway")
	await Game.wait(3.5)


func _ending() -> void:
	## The protagonist has walked out of the valley: the name of the game, and the road goes on to Bạch Sơn
	## (scripts/main.gd start(): its first beat, "three days after leaving Vô Danh Cốc"; Tiếp tục picks it up there).
	await Overlay.fade_out(2.5)
	await cut(false)
	Audio.stop_music(3.0)
	Game.set_checkpoint("bs_arrive")
	# the name of the game; Bạch Sơn is built behind it while it holds (main.start_bach_son waits for it to go), so
	# the second or two that building takes is a held title, not a frozen black screen
	Overlay.card("THẬP TỰ", "Đoạn Nghiệt", 2.6)
	await Game.wait(1.1)
