extends Node
## Bạch Sơn, Part D (docs/N_bach_son.md 8.4, 8.7): the Chánh Ty takes the protagonist up to the Bạch Điện instead
## of putting them out. "Cho ta xem tay." What they found in the city, said to her face; her offer (narrow the test
## quietly, let the newest ones back, admit nothing, the Ty stays) for their silence; refuse (on to the Lễ Quét Vôi)
## or accept (variant b: no riot, nobody dies, nothing heals).
## Tâm does not know she is waiting for her teacher (Q45): she never speaks of him here. The wooden box is on its
## shelf behind her; nobody opens it. She keeps a span between herself and anyone, and never touches the hand.
##   var p = BachSonPalace.new(); p.story = story; add_child(p); var deal: String = await p.run()

const AshTest = preload("res://scripts/ui/ash_test.gd")
const PictureCard = preload("res://scripts/ui/picture_card.gd")
const Bld = preload("res://scripts/world/builder.gd")

const TAM := "Bà Tâm"
const KHIET := "Chánh Ty"
const LAM := "Người áo lam"
const NUM := ["", "Một", "Hai", "Ba", "Bốn", "Năm"]

var story
var world
var tam
var khiet
var hau


func run() -> String:
	world = story.world
	world.see_through_wall(true)
	if Game.auto and OS.get_cmdline_user_args().has("--khe"):
		Game.flags["bs_khe_stone"] = true   # tests: as if the stone at the old gate had been seen in the camp
	await _arrest()
	await _up()
	await _hall()
	var deal: String = await _offer()
	if deal == "accept":
		await _variant_b()
	else:
		await _leave()
	Game.flags["bs_deal"] = deal
	return deal


func _has(id: String) -> bool:
	return (Game.flags.get("bs_nhan_ra", []) as Array).has(id)


func _sins() -> Array:
	## What the Ty's report can tell her: someone put out at the gate in their place, or someone they named (8.4).
	var s: Array = []
	if Game.flags.get("bs_gate", "") == "blame":
		s.append("gate_blame")
	for x in Game.flags.get("bs_sins", []):
		if x == "bao_seo" or x == "bao_gam":
			s.append(x)
	return s


# ================================================================== the plaza, the morning after
func _arrest() -> void:
	var m: Dictionary = world.markers
	var h = world.hero
	world.set_time("highland", true)
	h.stop_move()
	h.global_position = m["plaza"]
	h.face("up")
	world.rig.follow(h, true)
	# they come down the street from the tiers, round the east side of the great basin
	var y: float = world.YARD_H
	var t1 = story.npc("ty_a", "maty", Vector3(4.4, y, -35.0), "down")
	var t2 = story.npc("ty_b", "maty", Vector3(2.0, y, -35.2), "down")
	khiet = story.npc("khiet", "khiet", Vector3(3.2, y, -34.5), "down")
	await Overlay.fade_in(0.8)
	await story.cut(true)
	t1.move_to(Vector3(4.3, y, -27.8), 2.2)
	t2.move_to(Vector3(3.3, y, -25.7), 2.2)
	await khiet.move_to(Vector3(2.9, y, -29.0), 2.0)
	khiet.face_point(h.global_position)
	h.face_point(khiet.global_position)
	AutoTest.shot("bs20_arrest")
	await story.say(LAM, "Thưa Chánh Ty, người này.")
	await story.say(KHIET, "Người gánh hòm của bà Sương.", "cold")
	var nights: int = Game.flags.get("bs_camp_nights", 0)
	if nights > 0:
		await story.say(LAM, "%s đêm chui qua Cửa Cống xuống trại. Có người thấy." % NUM[clampi(nights, 1, 5)], "stern")
	elif Game.flags.get("bs_gate", "") == "truth" or Game.flags.get("bs_retest", "") == "truth":
		await story.say(LAM, "Tự khai bị Nghiệt chạm. Thử lại vẫn xám.", "stern")
	else:
		await story.say(LAM, "Lật Sổ Tro ở Dinh Ty lúc thư lại đi vắng.", "stern")
	await story.say(KHIET, "Theo luật, hôm nay người này phải ra cổng.")
	await story.say(KHIET, "Nhưng Bà muốn gặp người từ Vô Danh Cốc.")
	await story.say(KHIET, "Đi sau tôi ba bước. Đừng để chạm vào ai.", "stern")
	story.end_talk()


# ================================================================== up through the tiers to the summit
func _up() -> void:
	var m: Dictionary = world.markers
	var h = world.hero
	await Overlay.fade_out(0.6)
	for id in ["ty_a", "ty_b"]:
		if world.actor(id):
			world.despawn(id)
	# the climb, seen once: from the street up the tiers to the roofs of the Điện
	world.rig.set_view(Vector3(2.0, world.YARD_H + 9.0, -33.0), Vector3(0, 18.0, -62.0))
	await Overlay.fade_in(0.6)
	await world.rig.view_to(Vector3(0.0, 31.0, -58.0), Vector3(0.0, 29.0, -79.0), 2.4)
	await story.say("", "Lên mỗi tầng, người đi đường dạt sang hai bên. Không ai nhìn người đi sau Chánh Ty.")
	story.end_talk()
	await Overlay.fade_out(0.5)
	h.global_position = m["dien_hero"]
	h.face("up")
	khiet.global_position = (m["dien_door"] as Vector3) + Vector3(0.9, 0, 0.6)
	khiet.face("up")
	world.rig.follow(h, true)
	# the servant: rice on the threshold, and back in
	hau = story.npc("hau", "hau_cam", (m["dien_door"] as Vector3) + Vector3(-0.4, 0, -1.4), "down")
	tam = story.npc("tam", "tam", m["dien_tam"], "up")
	# the threshold and the bowls on it, near enough to see, not the whole front of the Điện with them small below it
	world.rig.frame_pair(h.global_position, (m["dien_door"] as Vector3) + Vector3(0, 0, -0.4), 0.01)
	await Overlay.fade_in(0.6)
	await hau.move_to((m["dien_door"] as Vector3) + Vector3(0.6, 0, -0.5), 1.0)
	hau.face("down")
	await Game.wait(0.6)
	await story.say("", "Một bà già áo trắng đặt bát cơm lên bậc cửa rồi lùi vào trong. Bát cơm hôm qua vẫn còn nguyên.")
	story.end_talk()
	await hau.move_to((m["dien_door"] as Vector3) + Vector3(-3.4, 0, -2.6), 1.0)
	hau.face("down")
	AutoTest.shot("bs21_dien")
	khiet.face("up")
	await story.talk_shot([khiet, h])
	await story.say(KHIET, "Thưa Bà. Người từ Vô Danh Cốc.")
	await story.say("Trong điện", "Cho vào.")
	await story.say("Trong điện", "Ngọc Khiết, ở ngoài.")
	await story.say(KHIET, "Thưa Bà, người này đã...")
	await story.say("Trong điện", "Ở ngoài.")
	story.end_talk()
	await khiet.move_to(m["dien_khiet"], 1.6)
	khiet.face("left")


# ================================================================== in the hall
func _hall() -> void:
	var m: Dictionary = world.markers
	var h = world.hero
	await h.move_to(m["dien_in"], 1.6)
	h.face_point(tam.global_position)
	await Game.wait(0.3)
	AutoTest.shot("bs22_hall")
	Audio.sfx("water", -8.0, 0.1, 0.9)
	await story.say("", "Gian điện rộng, trống và lạnh. Tường trắng, chân tường ốp sứ. Một người đứng quay lưng bên chậu nước, đang rửa tay.")
	story.end_talk()
	await Game.wait(0.6)
	tam.face_point(h.global_position)
	await world.rig.frame([tam], 0.8, 3.0, 0.22, 0.3)   # her name over her, not over an empty hall
	await Overlay.name_card("BĂNG TÂM", "Vị Tự của Bạch Sơn", 1.6)
	await story.say(TAM, "Đứng đấy.", "cold")
	story.end_talk()
	story.back_to_follow()
	await h.move_to(m["dien_stand"], 1.2)
	h.face_point(tam.global_position)
	await story.talk_shot([tam, h])   # the two of them, a span apart, for all that is said in the hall
	await story.say("", "Giữa hai người là một sải tay. Bà không bước lại gần.")
	await story.say(TAM, "Cho ta xem tay.", "stern")
	story.end_talk()
	world.emo("hero", "give")   # the palm held out to her
	# she looks; she does not touch. The glaze from the pass is there, in the lines of the palm
	var at = AshTest.new()
	add_child(at)
	await at.open("Lòng bàn tay, chìa ra")
	await at.show_glaze(0.45)
	AutoTest.shot("bs23_tay")
	await story.say("", "Bà nhìn rất lâu. Không cầm tay, cũng không nói gì về điều mình thấy.")
	story.end_talk()
	await at.close()
	world.emo("hero", "none")   # the hand drawn back
	match _reason():
		"camp":
			await story.say(TAM, "Ngọc Khiết bảo con chui qua Cửa Cống.", "behind")
		"truth":
			await story.say(TAM, "Ngọc Khiết bảo con tự khai bị Nghiệt chạm.", "behind")
		_:
			await story.say(TAM, "Ngọc Khiết bảo con lật Sổ Tro.", "behind")
	await story.say(TAM, "Con lên Bạch Sơn làm gì?")
	await story.say(story.P(), "Đoàn của Lúa bị đuổi khỏi đây. Cái thứ ngoài cổng đuổi theo họ tới tận cửa đèo Vô Danh Cốc.", "resolve")
	await story.say(TAM, "Tới cột mốc thì nó dừng.")
	await story.say(story.P(), "...Vâng.", "think")
	await story.say("", "Bà im lặng một lúc.")
	await story.say(TAM, "Con thấy gì ở thành ta?", "listen")
	story.end_talk()
	await _findings()


func _reason() -> String:
	if Game.flags.get("bs_camp_nights", 0) > 0:
		return "camp"
	if Game.flags.get("bs_gate", "") == "truth" or Game.flags.get("bs_retest", "") == "truth":
		return "truth"
	return "so"


func _findings() -> void:
	## What they found, said to her face (the Nhận ra they have), and what she says back. She answers what she can;
	## where she cannot, she says nothing.
	var said := 0
	if _has("ky_khong_nhin"):
		said += 1
		await story.say(story.P(), "Sắc nào cũng do Chánh Ty soạn. Bà đóng ấn.", "stern")
		await story.say(TAM, "Ta đọc. Tuần nào cũng đọc.", "cold")
		await story.say(story.P(), "Bà đọc báo cáo. Còn Sổ Tro thì Bà không đọc. Cột đen ba trăm năm không có lấy một nét.")
		await story.say("", "Bà không đáp.")
	if _has("co_ly"):
		said += 1
		await story.say(story.P(), "Tro không nhận ra Nghiệt. Nó chỉ chui vào kẽ. Tay nứt vì vôi hay nước thuốc cũng ra xám.", "stern")
		await story.say(TAM, "Tro không biết nói dối.", "cold")
		tam.emo("clasp")   # (her hands go into her sleeves)
		await story.say("", "Bà khép hai tay vào trong tay áo.")
	if _has("khong_di"):
		said += 1
		await story.say(story.P(), "Người bị đuổi bị bán. Người của Ty đưa họ lên xe trắng, đếm đủ số rồi chở sang Vạn Thư.", "stern")
		await story.say(TAM, "Xe nào?", "stern")
		await story.say(story.P(), "Xe của bà Sương. Năm nào bà ấy cũng lên.")
		await story.say("", "Bà im rất lâu.")
		await story.say(TAM, "Người đã nhiễm thì đằng nào cũng hóa sứ.", "sigh")
		world.emo("hero", "sad")
	if _has("tung_chua"):
		said += 1
		var gone: Array = Game.flags.get("bs_gone", [])
		await story.say(story.P(), "Hồi trước, người ra xám được giữ lại chờ Bà rửa men. Ông Sẹo ở Nhà Rửa vẫn còn sẹo.", "chest")
		await story.say(TAM, "Ông ta còn sống à?", "surprise")
		if gone.has("seo"):
			await story.say(story.P(), "...Ông ấy bị đuổi rồi. Hôm kia.", "sad")
			tam.emo("sad")
			await story.say("", "Bà không hỏi ai đã báo tin.")
		else:
			await story.say(TAM, "Cổ tay trái. Hình cánh mai.", "sad")
	if _has("tho_no"):
		said += 1
		await story.say(story.P(), "Cái ngoài cổng không phải Sứ Giả. Nó là Nghiệt, sinh ra từ chính những ô cửa trong thành này.", "resolve")
		await story.say(TAM, "Ra quảng trường nói câu ấy, người ta sẽ không để con nói hết đâu.", "stern")
	if said == 0:
		await story.say(story.P(), "Người ta bị đuổi chỉ vì tay nứt.", "stern")
		await story.say(TAM, "Tro không biết nói dối.", "cold")
	story.end_talk()


# ================================================================== the offer (8.4)
func _offer() -> String:
	await story.say(TAM, "Con muốn gì?", "behind")
	await story.say(story.P(), "Bỏ các sắc. Mở cổng cho người ta về.", "resolve")
	await story.say(TAM, "Mở cổng thì thứ ngoài kia cũng vào theo.", "stern")
	await story.say(TAM, "Ta đã thấy một lần.", "sad")
	story.end_talk()
	# the stone at the old gate (7.6): theirs to tell or keep
	if Game.flags.get("bs_khe_stone", false):
		var c: int = await world.choose(["Kể về phiến đá ở nền cổng cũ.", "Không kể."])
		if c == 0:
			await story.say(story.P(), "Dưới lớp vôi ở nền cổng cũ có một phiến đá. Trên đó khắc một chữ Khê.", "listen")
			story.end_talk()
			tam.face("up")
			await Game.wait(2.2)
			await story.say(TAM, "Mấy vạch?")
			await story.say(story.P(), "Ba.")
			await story.say("", "Bà không hỏi thêm.")
			story.end_talk()
			tam.face_point(world.hero.global_position)
			Game.flags["bs_told_khe"] = true
	await story.say(TAM, "Ta sẽ làm thế này.", "behind")
	await story.say(TAM, "Từ mai, tro chỉ giữ người thật sự bị chạm. Ai mới bị đuổi theo sắc họ hàng thì cho về dần. Không đọc sắc, không dán thông báo. Không ai cần biết.")
	await story.say(TAM, "Ty vẫn là Ty. Ngọc Khiết vẫn là Chánh Ty.")
	await story.say(TAM, "Đổi lại, con không nói với ai.", "stern")
	world.emo("hero", "think")   # weighing it
	var sins := _sins()
	if not sins.is_empty():
		# she has read the week's report: they too have put someone out (9.6)
		await story.say(TAM, "Báo cáo tuần này có tên con.", "cold")
		match sins[0]:
			"gate_blame":
				await story.say(TAM, "Ở cổng, con đỡ hòm từ tay một người khiêng. Người ấy ra cổng, con vào.")
			_:
				await story.say(TAM, "Con chỉ cho người áo lam một người ở Nhà Rửa.")
		await story.say(TAM, "Xem kìa, con cũng đẩy được người ra ngoài rồi đấy.", "cold")
		world.emo("hero", "sad")
	story.end_talk()
	AutoTest.shot("bs24_offer")
	var pick: int = await world.choose(["Không. Mai ở Lễ Quét Vôi, cháu sẽ nói hết trước mọi người.", "...Cháu sẽ không nói."])
	if Game.auto and OS.get_cmdline_user_args().has("--deal=accept"):
		pick = 1
	AutoTest.note("deal_" + ["refuse", "accept"][pick])
	return ["refuse", "accept"][pick]


# ================================================================== (a) refuse: down, to the Lễ Quét Vôi
func _leave() -> void:
	var m: Dictionary = world.markers
	var h = world.hero
	world.emo("hero", "resolve")   # the refusal, held
	await story.say(TAM, "Phải rồi. Ba trăm năm nay, thành này chỉ thiếu một người chịu nói.", "cold")
	await story.say("", "Bà quay lại chậu nước.")
	story.end_talk()
	tam.face("up")
	Audio.sfx("water", -8.0, 0.1, 0.9)
	await Game.wait(0.8)
	await story.say(TAM, "Ngọc Khiết. Để người này đi. Hôm nay không ai ra cổng.")
	story.end_talk()
	story.back_to_follow()   # the camera goes out with them (the front comes back once they are past it)
	await h.move_to(m["dien_door"], 1.8)
	h.face("down")
	khiet.face_point(h.global_position)
	await story.say(KHIET, "...Thưa Bà.", "cold")
	story.end_talk()
	await Overlay.fade_out(0.6)
	await story.say(KHIET, "Mai ở quảng trường, đứng gần người này.")
	await story.say(LAM, "Dạ.")
	story.end_talk()
	await story.cut(false)
	_clear()


# ================================================================== (b) accept: variant 8.7
func _variant_b() -> void:
	var m: Dictionary = world.markers
	var h = world.hero
	await story.say(TAM, "Ừ.", "nod")
	await story.say(TAM, "Ngọc Khiết. Để người này đi. Từ mai làm như ta dặn.", "behind")
	story.end_talk()
	story.back_to_follow()
	await h.move_to(m["dien_door"], 1.8)
	world.emo("hero", "sad")   # out with the silence agreed (held through the quiet Lễ, the gate, the night)
	await story.say(KHIET, "Thưa Bà.", "bow")
	story.end_talk()
	await Overlay.fade_out(0.6)
	_clear()
	# the Lễ Quét Vôi, with no decree read
	await Overlay.card("Lễ Quét Vôi", "", 1.4)
	var plaza: Vector3 = m["plaza"]
	var basin: Vector3 = Vector3(0, world.YARD_H, -28.3)
	for i in 8:
		var a := i * TAU / 8.0 + 0.2
		var p := basin + Vector3(cos(a) * 2.6, 0, sin(a) * 2.6)
		var w = story.npc("le_%d" % i, "bs_w" if i % 2 == 0 else "bs_m", p, "up")
		w.face_point(basin)
		if i % 3 == 0:
			var br := Bld.billboard(world, "res://assets/sprites/props/broom.png", p + Vector3(0.3, 0, 0.1), 0.03)
			br.set_meta("le", true)
	h.global_position = plaza + Vector3(0.6, 0, 1.2)
	h.face_point(basin)
	world.rig.follow(h, true)
	await Overlay.fade_in(0.6)
	AutoTest.shot("bs25_le")
	await story.say("", "Năm ấy, Lễ Quét Vôi không đọc sắc nào. Người ta quét vôi lại bể rửa rồi về nhà.")
	story.end_talk()
	await Overlay.fade_out(0.6)
	for i in 8:
		world.despawn("le_%d" % i)
	for n in world.get_children():
		if n.has_meta("le"):
			n.queue_free()
	# dusk: the gate opens a hand's width, and the newest ones from the camp come back in
	world.set_time("highland_dusk", true)
	world.set_gate(true, 0.1)
	var back := ["refugee_w", "refugee_m", "refugee_w"]
	if (Game.flags.get("bs_gone", []) as Array).has("seo"):
		back.append("seo")
	var walkers: Array = []
	var y: float = world.YARD_H
	for i in back.size():
		walkers.append(story.npc("ve_%d" % i, back[i], Vector3(-0.6 + (i % 2) * 1.2, y, -21.0 - i * 0.9), "up"))
	# seen from the square, the protagonist in the foreground left of the great basin, the gate ahead
	h.global_position = Vector3(-2.7, y, -27.2)
	h.face("down")
	world.rig.set_view(Vector3(-4.8, y + 3.4, -33.5), Vector3(0.4, y + 1.0, -24.8))
	await Overlay.fade_in(0.6)
	for i in walkers.size():
		(walkers[i] as Node).move_to(Vector3(2.9 + i * 0.75, y, -26.3 - (i % 2) * 0.7), 1.0)
	await Game.wait(3.2)
	AutoTest.shot("bs26_ve")
	if back.has("seo"):
		await story.say("", "Chiều tối, cổng hé ra một khe. Mấy người trong trại đi vào, cúi đầu, không ai nói gì. Ông Sẹo đi sau cùng.")
	else:
		await story.say("", "Chiều tối, cổng hé ra một khe. Mấy người trong trại đi vào, cúi đầu, không ai nói gì.")
	story.end_talk()
	await Overlay.fade_out(0.6)
	world.set_gate(false, 0.1)
	for i in walkers.size():
		world.despawn("ve_%d" % i)
	# night: below the wall nothing has changed
	world.set_time("night", true)
	Audio.play_music("", 1.0)   # (only the tapping, as on every night below the wall)
	world.rig.follow(h, true)
	await Overlay.fade_in(0.6)
	story._tapping(3.0)
	await story.say("", "Đêm ấy, dưới trại vẫn có tiếng gõ trên sứ. Tiếng gõ chẳng thưa đi.")
	story.end_talk()
	await Game.wait(1.4)
	# the servant brings a sheet down: she teaches the stroke on paper, not on a hand
	var hc = story.npc("hau2", "hau_cam", h.global_position + Vector3(-3.0, 0, -1.0), "right")
	await hc.move_to(h.global_position + Vector3(-0.8, 0, -0.2), 1.0)
	hc.face_point(h.global_position)
	h.face_point(hc.global_position)
	world.emo("hau2", "give")   # the folded sheet held out
	var pc = PictureCard.new()
	add_child(pc)
	await pc.open("res://assets/ui/giay_tam.png", "Tờ giấy gấp đôi")
	AutoTest.shot("bs27_giay")
	await story.say("", "Bà hầu câm đưa tờ giấy rồi quay lên. Bà Tâm không xuống.")
	story.end_talk()
	await pc.close()
	world.despawn("hau2")
	await story.cut(false)


func _clear() -> void:
	for id in ["tam", "hau", "khiet"]:
		if world.actor(id):
			world.despawn(id)

