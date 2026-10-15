extends Node
## Bạch Sơn, bản thử: the opening of the chapter (docs/N_bach_son.md 8.1, 8.2).
## Beats: arrive (up from the Bãi Tro with Mạnh) -> camp (bà Lành, the news, the camp to walk round)
##        -> night (by the fire; Mảnh Sành out of the Rãnh Sứ) -> caravan (bà Sương's physicians; the cart)
##        -> gate (Thử Tro; lão Cẩn: "tro ướt") -> inside (the first street of the Tầng Rửa)
##        -> city (Part C: four days inside, scripts/story/bach_son_city.gd)
##        -> palace (Part D: the Bạch Điện, scripts/story/bach_son_palace.gd).
## Lines are short and spoken; nobody names the protagonist's gender (they say "cháu", or nothing).

const Battle = preload("res://scripts/battle/battle.gd")
const Timing = preload("res://scripts/ui/timing.gd")
const B = preload("res://scripts/world/builder.gd")
const AshTest = preload("res://scripts/ui/ash_test.gd")
const BachSonCity = preload("res://scripts/story/bach_son_city.gd")
const BachSonPalace = preload("res://scripts/story/bach_son_palace.gd")

const BEATS := ["arrive", "camp", "night", "caravan", "gate", "inside", "city", "palace"]
const CH := "res://assets/sprites/chars/"
const LANH := "Bà Lành"
const MANH := "Mạnh"
const SUONG := "Bà Sương"
const CAN := "Lão Cẩn"
const KHAM := "Khám sư"
const KHIET := "Chánh Ty"
const VUNG := "Anh Vững"

signal finished

var world
var main
var timing
var _timing_layer: CanvasLayer
var hero_hp := 70
var _chest: Node3D


func _ready() -> void:
	_timing_layer = CanvasLayer.new()
	_timing_layer.layer = 45
	add_child(_timing_layer)
	timing = Timing.new()
	_timing_layer.add_child(timing)


func run(from_beat := "arrive") -> void:
	# who speaks under which name (world.say: their face and gestures, a lift as they start a line)
	world.talkers = {LANH: "lanh", MANH: "manh", SUONG: "suong", CAN: "can", KHAM: ["kham", "kham2", "ty_watch"],
		KHIET: "khiet", VUNG: "porter1", "Cỏ": "co", "Diệu": "dieu", "Mẹ Mạnh": "me_manh", "Bà Mẫn": "bamau",
		"Ông Sẹo": "seo", "Chị Gấm": "gam", "Thư lại": "thu_lai", "Người coi đền": "coi_den", "Người đàn bà": "vung_wife",
		"Bà Tâm": "tam", "Người áo lam": ["ty_a", "ty_b", "maty", "ty1", "ty2"]}
	var start := BEATS.find(from_beat)
	if start < 0:
		start = 0
	_setup_people(BEATS[start])
	for i in range(start, BEATS.size()):
		Game.set_checkpoint("bs_" + BEATS[i])
		AutoTest.note("beat_bs_" + BEATS[i])
		match BEATS[i]:
			"arrive": await _arrive()
			"camp": await _camp()
			"night": await _night()
			"caravan": await _caravan()
			"gate": await _gate()
			"inside": await _inside()
			"city": await _city()
			"palace": await _palace()
	await _end_card()
	finished.emit()


# ------------------------------------------------------------------ helpers (as in the prologue)
func P() -> String:
	return Game.player_name


func say(spk: String, text: String, emote := "") -> void:
	## emote: the speaker's face and body language for the line (tools/art/chars.py EMOTES), see world.say
	await world.say(spk, text, emote)


func end_talk() -> void:
	world.dialogue.hide_box()


func cut(on: bool) -> void:
	world.set_control(not on)
	world.hud.show_hints(not on)
	if on:
		world.hud.objective("")
	await Overlay.letterbox(on, 0.4)


func screen_of(p: Vector3) -> Vector2:
	return world.rig.cam.unproject_position(p)


func npc(id: String, sheet: String, pos: Vector3, facing := "down"):
	if world.actor(id):
		world.despawn(id)
	return world.spawn(id, CH + sheet + ".png", pos, facing)


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


func go_interact(iid: String, pos: Vector3, prompt: String, objective: String, radius := 1.7) -> void:
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
		await world.hero.move_to(pos + (from.normalized() if from.length() > 0.01 else Vector3(0, 0, 1)) * radius * 0.7)
	else:
		while true:
			var got: String = await world.interacted
			if got == iid:
				break
	world.set_control(false)
	world.remove_interact(iid)
	world.set_markers([])


func _setup_people(from_beat: String) -> void:
	var m: Dictionary = world.markers
	npc("lanh", "balanh", m["lanh"], "down")
	npc("co", "co", m["co"], "down")
	npc("dieu", "dieu", m["dieu"], "down")
	npc("me_manh", "me_manh", m["me_manh"], "down")
	var manh_at: Vector3 = m["arrive"] + Vector3(-1.2, 0, 0.6) if from_beat == "arrive" else m["me_manh"] + Vector3(1.0, 0, 0.3)
	npc("manh", "refugee_m", manh_at, "up")
	if from_beat == "gate" or from_beat == "inside":
		world.hero.global_position = m["yard_entry"]
	elif from_beat != "arrive":
		world.hero.global_position = m["camp_road"]
	world.set_time("highland", true)


func carry_chest(on: bool) -> void:
	## Bà Sương's medicine chest on the protagonist's shoulder (the porter's job that got them in).
	if _chest and is_instance_valid(_chest):
		_chest.queue_free()
		_chest = null
	if on:
		_chest = B.box(world.hero, Vector3(0.42, 0.32, 0.28), Vector3(0, 0.95, 0.22),
			B.mat("res://assets/tex/planks.png", 1.2, Vector3.ONE, {"triplanar": true, "tint": Color(0.7, 0.55, 0.4)}), 0, false, 0.03)


func _process(_delta: float) -> void:
	# the chest rides on the protagonist's back: toward the camera when they walk away, behind them when they come
	if _chest and is_instance_valid(_chest) and world and world.hero:
		var back := {"up": Vector3(0, 0.95, 0.24), "down": Vector3(0, 0.95, -0.26), "left": Vector3(0.24, 0.95, 0.05),
			"right": Vector3(-0.24, 0.95, 0.05)}
		_chest.position = back.get(world.hero.facing, Vector3(0, 0.95, 0.24))


func put_chest(at: Vector3) -> Node3D:
	## Set the chest down where it is wanted (the clerk's floor, the cart): it stays there as a thing in the world.
	carry_chest(false)
	var c: MeshInstance3D = B.box(world, Vector3(0.5, 0.36, 0.34), at + Vector3(0, 0.18, 0),
		B.mat("res://assets/tex/planks.png", 1.2, Vector3.ONE, {"triplanar": true, "tint": Color(0.7, 0.55, 0.4)}), 0, false, 0.03)
	return c


func talk_shot(people: Array, t := 0.9) -> void:
	## A conversation: everyone in it framed in the upper half of the screen, clear of the dialogue box.
	await world.rig.frame(people, t)


func look_shot(at: Vector3, t := 0.8) -> void:
	## Something looked at closely: the camera comes in on it, the protagonist beside it.
	world.hero.face_point(at)
	await world.rig.frame_pair(world.hero.global_position, at, t)


func back_to_follow() -> void:
	world.rig.follow(world.hero, false)


func white_cart(at: Vector3) -> Node3D:
	## Bà Sương's cart under its white cloth (the "xe trắng"): the same cart at the camp and behind the Dinh Ty.
	var cart := Node3D.new()
	world.add_child(cart)
	cart.global_position = at
	var planks := B.mat("res://assets/tex/planks.png", 1.4, Vector3.ONE, {"triplanar": true})
	var dark := B.mat("res://assets/tex/planks.png", 1.4, Vector3.ONE, {"triplanar": true, "tint": Color(0.5, 0.4, 0.32)})
	# the bed, its sides, the two shafts reaching forward
	B.box(cart, Vector3(1.4, 0.1, 2.5), Vector3(0, 0.78, 0), planks, 0, false)
	for sx in [-0.68, 0.68]:
		B.box(cart, Vector3(0.06, 0.32, 2.5), Vector3(sx, 0.98, 0), planks, 0, false)
		var shaft := B.box(cart, Vector3(0.08, 0.08, 2.0), Vector3(sx * 0.8, 0.62, 2.1), dark, 0, false)
		shaft.rotation.x = -0.12
	# the wheels: rim, hub, eight spokes
	for sx in [-0.8, 0.8]:
		var wheel := Node3D.new()
		wheel.position = Vector3(sx, 0.52, 0.2)
		cart.add_child(wheel)
		var rim := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.44
		tm.outer_radius = 0.52
		tm.rings = 18
		tm.ring_segments = 4
		rim.mesh = tm
		rim.material_override = dark
		rim.rotation.z = PI * 0.5
		wheel.add_child(rim)
		var hub: MeshInstance3D = B.cylinder(wheel, 0.09, 0.16, Vector3.ZERO, dark, false, 8)
		hub.rotation.z = PI * 0.5
		for k in 8:
			var sp := B.box(wheel, Vector3(0.04, 0.88, 0.04), Vector3.ZERO, dark, 0, false)
			sp.rotation.x = k * PI / 8.0
	# the cloth over three hoops, sagging between them, tied down at the sides
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var L := 2.4
	var R := 0.72
	var nz := 8
	var na := 8
	for i in nz:
		for j in na:
			var quad := []
			for c in [[i, j], [i + 1, j], [i + 1, j + 1], [i, j], [i + 1, j + 1], [i, j + 1]]:
				var u: float = float(c[0]) / nz
				var a: float = PI * float(c[1]) / na
				var sag := 0.07 * sin(PI * fposmod(u * 2.0, 1.0)) * sin(a)
				var r := R - sag
				quad.append(Vector3(cos(a) * r, 1.05 + sin(a) * r * 0.85, -L * 0.5 + L * u))
			for v in quad:
				st.add_vertex(v)
	st.generate_normals()
	var cover := MeshInstance3D.new()
	cover.mesh = st.commit()
	var cloth := B.color_mat(Color(0.88, 0.87, 0.82))
	cloth.cull_mode = BaseMaterial3D.CULL_DISABLED
	cover.material_override = cloth
	cart.add_child(cover)
	var rope := B.color_mat(Color(0.5, 0.44, 0.34))
	for z in [-0.9, 0.0, 0.9]:
		B.box(cart, Vector3(1.56, 0.03, 0.03), Vector3(0, 1.08, z), rope, 0, false)
	return cart


func _tapping(t: float) -> void:
	## Porcelain taps out of the dark: few, then more and closer (as at the pass).
	var e := 0.0
	var gap := 0.45
	while e < t:
		Audio.sfx("tick", -16.0 + 10.0 * e / t, 0.35, randf_range(0.7, 1.15))
		var w := gap * randf_range(0.6, 1.4)
		await Game.wait(w)
		e += w
		gap = maxf(0.08, gap * 0.85)


# ================================================================== ARRIVE
func _arrive() -> void:
	var h = world.hero
	var m: Dictionary = world.markers
	Audio.play_music("tension", 2.0)
	Overlay.set_black(true)
	world.rig.follow(h, true)
	# the opening: low on the road among the porcelain people, every one of them facing up to the white city
	world.rig.set_view(Vector3(12.5, world.height_at(12.5, 49.0) + 1.3, 49.0), Vector3(1.0, 9.0, -20.0))
	# the porcelain people and the city both readable: focus on the near row, a light depth of field, no tilt-shift
	world.rig.dof_focus = world.actor("porc_1").global_position
	world.rig.attrs.dof_blur_amount = 0.045
	world.set_diorama(0.25)
	await Overlay.fade_in(1.2)
	world.rig.view_to(Vector3(11.0, world.height_at(11.0, 46.5) + 1.7, 46.5), Vector3(0.5, 10.0, -22.0), 4.0)   # a slow push in, under the card
	await Overlay.card("Bạch Sơn", "Ba ngày sau khi rời Vô Danh Cốc", 1.6)
	await Game.wait(0.6)
	AutoTest.shot("bs01_road")
	await cut(true)
	world.actor("manh").face_point(m["road_view"])
	world.set_diorama(1.0)
	world.rig.dof_focus = null
	world.rig.attrs.dof_blur_amount = 0.13
	await talk_shot([h, world.actor("manh")], 1.4)
	await say(MANH, "Qua bãi này là tới trại.")
	await say(MANH, "Đừng nhìn mấy pho tượng lâu quá.")
	await say(P(), "Họ là ai?")
	await say(MANH, "Người bị đuổi ra đấy. Trắng Tay chạm vào đầu thì thành thế.", "sad")
	end_talk()
	back_to_follow()
	await cut(false)
	world.actor("manh").move_to(m["camp_edge"] + Vector3(1.0, 0, 0.6), 2.8)
	# a statue by the road can be looked at on the way
	world.add_interact("porc", world.actor("porc_4").global_position, "Xem", 1.8)
	var looked := false
	world.add_trigger("camp_edge", m["camp_edge"], 3.0)
	world.set_markers([m["camp_edge"]], 2.6)
	world.hud.objective("Theo Mạnh lên Trại Ngoài Cổng")
	world.hud.show_hints(true)
	world.set_control(true)
	if Game.auto:
		await Game.wait(0.3)
		await h.move_to(world.actor("porc_4").global_position + Vector3(1.2, 0, 0.8))
		await _look("porc", world.actor("porc_4").global_position)
		await h.move_to(m["camp_edge"], -1, true)
	else:
		while true:
			var r = await _either()
			if r == "porc" and not looked:
				looked = true
				world.set_control(false)
				await _look("porc", world.actor("porc_4").global_position)
				world.set_control(true)
			elif r == "camp_edge":
				break
	world.set_control(false)
	world.remove_trigger("camp_edge")
	world.remove_interact("porc")
	world.set_markers([])
	# the city above, seen from the camp for the first time
	await cut(true)
	h.face("up")
	# first the wall, from below, as the camp sees it every day; then up, over it, to the whole white city
	world.rig.set_view(m["camp_edge"] + Vector3(2.0, 2.0, 7.0), Vector3(0, 12.0, -30.0))
	await world.rig.view_to(m["camp_edge"] + Vector3(1.5, 2.6, 6.0), Vector3(0, 13.0, -30.0), 1.4)
	await world.rig.view_to(Vector3(2.0, 19.0, 26.0), Vector3(0, 15.0, -56.0), 2.6)
	AutoTest.shot("bs02_city")
	await say(MANH, "Đấy. Bạch Sơn.")
	await say(P(), "Trắng thật.")
	await say(MANH, "Ở dưới này, ngày nào cũng phải ngước lên nhìn nó.")
	end_talk()


func _either():
	## The next interact or trigger, whichever comes first.
	var res := [null]
	var f1 := func(id):
		if res[0] == null:
			res[0] = id
	world.interacted.connect(f1, CONNECT_ONE_SHOT)
	world.trigger_entered.connect(f1, CONNECT_ONE_SHOT)
	while res[0] == null:
		await get_tree().process_frame
	if world.interacted.is_connected(f1):
		world.interacted.disconnect(f1)
	if world.trigger_entered.is_connected(f1):
		world.trigger_entered.disconnect(f1)
	return res[0]


const LOOKS := {
	"porc": "Một pho người bằng sứ, quay mặt về phía cổng. Dải men lam bịt ngang mắt.",
	"nong": "Cái nong đựng những mảnh sứ bằng ngón tay. Mảnh nào cũng khắc một năm. Bà Lành bảo mỗi mảnh là một người.",
	"khe": "Mấy khối đá xám nằm dưới lớp vôi bong. Trên một phiến đá có khắc chữ \"Khê\" và ba vạch.",
	"well": "Giếng do người trong trại tự đào. Nước lợ, có vị vôi.",
	"glaze": "Vệt đất trắng bóng như men, chạy từ chân núi về phía trại. Giẫm lên nghe giòn như vỏ trứng.",
	"stream": "Nước đục chảy từ cống dưới chân tường thành xuống. Người trong trại vẫn múc để giặt.",
}


func _look(k: String, at = null) -> void:
	if k == "khe":
		Game.flags["bs_khe_stone"] = true
	if at is Vector3:
		await look_shot(at)
	await say("", LOOKS.get(k, ""))
	end_talk()
	if at is Vector3:
		back_to_follow()


# ================================================================== CAMP
const TALKS := {
	"co": [["Cỏ", "Trên bậc cổng có cái chậu trắng to lắm. Người trong ấy rửa tay ở đấy.", "point"],
		["Cỏ", "Em chưa rửa ở đấy bao giờ. Bà Lành bảo người dưới này không được lại gần.", "sad"]],
	"dieu": [["Diệu", "Đứng xích ra, chắn hết ánh sáng rồi. Tôi đang giã thuốc.", "cross"],
		["Diệu", "Ông lính trên tường ấy à? Tối nào ông ấy cũng đứng đó. Kệ ông ấy.", "shrug"]],
	"me_manh": [["Mẹ Mạnh", "Cảm ơn cháu đã đưa nó về.", "chest"],
		["Mẹ Mạnh", "Nhà bác bị đuổi theo sắc mới. Chú nó bị đuổi mấy năm trước rồi, giờ đến lượt hai mẹ con bác.", "sad"]],
}


func _camp() -> void:
	var h = world.hero
	var m: Dictionary = world.markers
	var lanh = world.actor("lanh")
	var manh = world.actor("manh")
	await cut(true)
	world.rig.follow(h, false)
	await lanh.move_to(m["camp_edge"] + Vector3(-1.6, 0, -1.2))
	lanh.face_point(manh.global_position)
	await talk_shot([h, lanh, manh], 1.0)
	AutoTest.shot("bs03_lanh")
	await say(LANH, "Thằng Mạnh! Mày còn sống à?", "surprise")
	await say(MANH, "Con đưa Lúa tới Vô Danh Cốc rồi, bà ạ.")
	await say(LANH, "Mẹ mày ngồi ngoài bếp chờ mày từ hôm đi đến giờ đấy. Ra đi.", "point")
	end_talk()
	manh.move_to(m["me_manh"] + Vector3(0.9, 0, 0.2), 3.4)
	lanh.face_point(h.global_position)
	h.face_point(lanh.global_position)
	talk_shot([h, lanh], 1.2)
	await say(LANH, "Còn đây là ai? Mặt mũi sạch sẽ thế kia, đâu phải người ở trại.", "cross")
	await say(P(), "Cháu ở Vô Danh Cốc. Cháu với Mạnh đưa Lúa về đấy.", "bow")
	await say(LANH, "Con bé học thuốc ấy à? Nó còn sống thật à?", "worry")
	await say(P(), "Còn ạ. Chỗ trắng trên chân thôi lan rồi.", "nod")
	await say(LANH, "...Thế thì tốt. Ở đây, bà chưa thấy ai thôi lan bao giờ.", "sad")
	await say(LANH, "Lên đây làm gì?", "cross")
	await say(P(), "Cháu muốn gặp người dựng cái cổng kia.", "resolve")
	lanh.emote("ha", 0.8)
	await say(LANH, "Lên đấy thì phải thử tro. Thử xong mà bị đuổi thì xuống đây ở với bà.", "shrug")
	world.emo("hero", "worry")
	await say(LANH, "Mà cháu lên đúng lúc xui rồi. Trên ấy vừa ra sắc mới, nhà nào có người bị đuổi thì họ hàng cũng phải ra nốt.", "sigh")
	await say(LANH, "Năm ngày nữa là Lễ Quét Vôi. Đợt người tiếp theo bị đuổi đúng hôm ấy.")
	end_talk()
	back_to_follow()
	await lanh.move_to(m["lanh"])
	lanh.face("down")
	await cut(false)
	await _free_roam()


func _free_roam() -> void:
	## Walk round the camp; when ready, sit by the fire with bà Lành (evening).
	var m: Dictionary = world.markers
	var spots := {
		"co": world.actor("co").global_position, "dieu": world.actor("dieu").global_position,
		"me_manh": world.actor("me_manh").global_position, "nong": world.props["nong"].global_position,
		"khe": world.props["khe_stone"], "well": world.props["camp_well"], "glaze": m["glaze"],
		"stream": Vector3(-3.0, world.height_at(-3.0, 10.3), 10.3),
	}
	for k in spots:
		world.add_interact(k, spots[k], "Nói chuyện" if TALKS.has(k) else "Xem", 1.7)
	world.add_interact("fire", m["fire_seat"], "Ngồi xuống bếp", 1.8)
	world.set_markers([m["fire_seat"]])
	world.hud.objective("Đi quanh trại. Xong rồi thì ra bếp ngồi với bà Lành.")
	world.hud.show_hints(true)
	world.set_control(true)
	if Game.auto:
		for k in ["co", "nong", "khe"]:
			await world.hero.move_to((spots[k] as Vector3) + Vector3(1.0, 0, 0.9))
			world.set_control(false)
			await _talk(k, spots[k])
			world.set_control(true)
		AutoTest.shot("bs04_camp")
		await world.hero.move_to(m["fire_seat"] + Vector3(0.8, 0, 0.8))
	else:
		while true:
			var got: String = await world.interacted
			if got == "fire":
				break
			world.set_control(false)
			await _talk(got, spots[got])
			world.set_control(true)
	world.set_control(false)
	for k in spots:
		world.remove_interact(k)
	world.remove_interact("fire")
	world.set_markers([])


func _talk(k: String, at = null) -> void:
	if TALKS.has(k):
		var a = world.actor(k)
		if a:
			a.face_point(world.hero.global_position)
			world.hero.face_point(a.global_position)
			await talk_shot([world.hero, a], 0.7)
		for line in TALKS[k]:   # [speaker, line] or [speaker, line, emote]
			await say(line[0], line[1], line[2] if line.size() > 2 else "")
		end_talk()
		back_to_follow()
	else:
		await _look(k, at)


# ================================================================== NIGHT
func _night() -> void:
	var h = world.hero
	var m: Dictionary = world.markers
	var lanh = world.actor("lanh")
	await cut(true)
	await Overlay.fade_out(0.8)
	world.set_time("highland_dusk", true)
	h.global_position = m["fire_seat"]
	h.face_point(world.CAMP)
	lanh.global_position = world.CAMP + Vector3(-1.6, 0, -1.0)
	lanh.global_position.y = world.height_at(lanh.global_position.x, lanh.global_position.z)
	lanh.face_point(h.global_position)
	for pair in [["me_manh", Vector3(-3.4, 0, 1.2)], ["manh", Vector3(-2.5, 0, 2.3)]]:
		var a = world.actor(pair[0])
		if a:
			var at: Vector3 = world.CAMP + pair[1]
			at.y = world.height_at(at.x, at.z)
			a.global_position = at
			a.face_point(world.CAMP)
	world.rig.set_view(world.CAMP + Vector3(1.0, 3.2, 8.0), world.CAMP + Vector3(0, 0.8, 0))
	await Overlay.fade_in(1.0)
	AutoTest.shot("bs05_fire")
	await say(LANH, "Ăn đi. Mắm cá suối đấy.", "give")
	await say(P(), "...Ngon ạ.")
	await say(LANH, "Trên kia cái gì lên men cũng bị chê là thối. Thối mà ngon thế này thì bà cứ ăn.", "smile")
	await say(LANH, "Ăn xong thì vào lều ngủ. Đêm đừng có ra ngoài.", "stern")
	end_talk()
	await Overlay.fade_out(0.8)
	world.set_time("night", true)
	await Overlay.fade_in(0.8)
	# taps on porcelain out of the dark, from the Rãnh Sứ; then a child's voice
	Audio.play_music("", 1.0)
	_tapping(3.0)
	await Game.wait(2.2)
	await say("Cỏ", "Bà ơi!", "scared")
	end_talk()
	lanh.emote("!", 0.8)
	h.face_point(m["fight"])
	await h.move_to(m["fight"] + Vector3(0.8, 0, -0.6), -1, true)
	await cut(false)
	world.set_control(false)
	var dir: Vector3 = m["glaze"] - m["fight"]
	while true:
		var b = Battle.new()
		add_child(b)
		world.hud.visible = false
		var res: String = await b.run(world, {"enemies": ["manh_tinh", "manh_tinh", "manh_tinh"],
			"intro": "Mảnh Sành bò ra từ Rãnh Sứ, đang bò về phía lều của Cỏ!", "stage_at": m["fight"], "stage_dir": dir,
			"hero_hp": hero_hp})
		hero_hp = maxi(b.hero_hp, 40)
		b.queue_free()
		world.hud.visible = true
		world.hero.clear_pose()
		world.rig.follow(world.hero, true)
		if res != "lose":
			break
		await say("", "Ngã xuống rồi. Đứng dậy lần nữa?")
		await world.choose(["Thử lại"])
		end_talk()
		if Game.auto:
			Game.auto_timing = "perfect"
	Audio.play_music("night", 2.5)   # (the fight's drums give way to the night: they were left running to the end)
	await cut(true)
	var co = world.actor("co")
	co.global_position = m["co_tent"] + Vector3(1.2, 0, 1.8)
	co.global_position.y = world.height_at(co.global_position.x, co.global_position.z)
	co.face_point(h.global_position)
	lanh.global_position = m["fight"] + Vector3(-1.2, 0, 1.0)
	lanh.global_position.y = world.height_at(lanh.global_position.x, lanh.global_position.z)
	lanh.face_point(h.global_position)
	await world.rig.focus(m["fight"], 0.7, 0.8)
	await say(LANH, "Đêm nào cũng thế. Có đêm nó chỉ cào cửa lều thôi.", "sigh")
	world.emo("hero", "worry")
	await say(LANH, "Có đêm... à mà thôi.", "sigh")
	co.emote("...", 1.2)
	await Game.wait(0.8)
	await say("Cỏ", "Mai lên cổng à? Rửa tay ở cái chậu ấy rồi về kể em nghe nhé.", "smile")
	end_talk()
	await Overlay.fade_out(1.0)
	world.emo("hero", "none")
	world.emo("lanh", "none")
	world.emo("co", "none")
	world.set_time("highland", true)


# ================================================================== CARAVAN
func _caravan() -> void:
	Audio.play_music("tension", 3.0)   # morning, the road up to the gate and its test
	var h = world.hero
	var m: Dictionary = world.markers
	var lanh = world.actor("lanh")
	h.global_position = m["camp_road"] + Vector3(-1.5, 0, 1.0)
	h.global_position.y = world.height_at(h.global_position.x, h.global_position.z)
	lanh.global_position = m["camp_road"] + Vector3(-2.6, 0, 0.0)
	lanh.global_position.y = world.height_at(lanh.global_position.x, lanh.global_position.z)
	world.rig.follow(h, true)
	# bà Sương's physicians, up from the Vạn Thư road, resting at the camp; their cart under white cloth
	var road_in: Vector3 = m["camp_road"] + Vector3(6.0, 0, 14.0)
	road_in.y = world.height_at(road_in.x, road_in.z)
	var suong = npc("suong", "suong", road_in, "up")
	var p1 = npc("porter1", "dan_m", road_in + Vector3(1.2, 0, 1.0), "up")
	var cart := white_cart(road_in + Vector3(2.4, 0, -1.0))
	await Overlay.fade_in(1.0)
	await cut(true)
	suong.move_to(m["camp_road"] + Vector3(0.8, 0, 1.4), 2.6)
	p1.move_to(m["camp_road"] + Vector3(2.0, 0, 2.4), 2.6)
	var ct := create_tween()
	var cart_to: Vector3 = m["camp_road"] + Vector3(5.0, 0, -2.0)
	cart_to.y = world.height_at(cart_to.x, cart_to.z)
	ct.tween_property(cart, "global_position", cart_to, 2.6)
	# the cart rolling up the road with them, then the three who talk, in the top half of the frame
	await world.rig.frame([h, suong, cart], 1.6)
	await ct.finished
	suong.face_point(h.global_position)
	h.face_point(suong.global_position)
	await talk_shot([h, suong, lanh], 0.8)
	AutoTest.shot("bs06_caravan")
	await say(SUONG, "Ai biết gánh thì lại đây. Người của tôi bỏ về giữa đường rồi.")
	await say(P(), "Cháu gánh được.", "chest")
	await say(SUONG, "Đưa tay đây xem.", "stern")
	world.emo("hero", "give")
	await Game.wait(0.4)
	await say(SUONG, "Tay chai thế này thì gánh được. Lên cổng cứ đứng sau tôi, đừng nói gì.")
	end_talk()
	world.emo("hero", "none")
	lanh.face_point(cart.global_position)
	await say(LANH, "Bà Sương năm nào cũng lên một lần. Lúc đi xe rỗng, lúc về xe đầy.")
	await say(P(), "Đầy gì ạ?", "think")
	await say(LANH, "Người chứ gì. Nghe bảo ai lên xe thì được đưa đi chữa bệnh.", "shrug")
	end_talk()
	# the medicine chest on the protagonist's shoulder
	carry_chest(true)
	back_to_follow()
	await cut(false)
	suong.move_to(m["yard_entry"] + Vector3(-1.2, 0, 1.0), 2.4)
	p1.move_to(m["yard_entry"] + Vector3(1.4, 0, 1.6), 2.4)
	await go_trigger("yard_entry", m["yard_entry"], 2.4, "Gánh hòm thuốc, theo bà Sương lên Sân Tro")


# ================================================================== GATE
func _gate() -> void:
	var h = world.hero
	var m: Dictionary = world.markers
	world.set_gate(true, 0.1)
	var suong = world.actor("suong")
	if suong == null:
		suong = npc("suong", "suong", m["yard_entry"] + Vector3(-1.2, 0, 1.0), "up")
	var kham = npc("kham", "khamsu", m["khamsu"], "down")
	var can = npc("can", "can", m["can"], "down")
	var q1 = npc("q1", "bs_w", m["test_spot"] + Vector3(-2.0, 0, 0.6), "up")
	var q2 = npc("q2", "bs_m", m["queue"] + Vector3(0.3, 0, -0.6), "up")
	var vung = world.actor("porter1")
	if vung == null:
		vung = npc("porter1", "dan_m", m["yard_entry"] + Vector3(1.4, 0, 1.6), "up")
	vung.move_to(m["queue"] + Vector3(0.9, 0, 2.6), 2.4)
	await cut(true)
	world.rig.follow(h, false)
	h.move_to(m["queue"] + Vector3(0.2, 0, 1.8), 2.4)
	suong.move_to(m["queue"] + Vector3(-0.6, 0, 0.9), 2.4)
	await world.rig.focus(m["test_spot"] + Vector3(-0.5, 0, 0.5), 0.85, 1.4, true)   # (turning as it moves, no jump)
	AutoTest.shot("bs07_yard")
	# the one in front of them: tested, passed
	q1.move_to(m["test_spot"], 2.0)
	await Game.wait(0.8)
	await say(KHAM, "Người tiếp theo. Đưa tay đây.", "cold")
	end_talk()
	Audio.sfx("water", -10.0, 0.1)
	await Game.wait(0.8)
	await say(KHAM, "Trắng.")
	end_talk()
	q1.move_to(m["gate_in"] + Vector3(-2.6, 0, 1.2), 2.4)   # in through the gate and aside, not into the great basin
	q2.move_to(m["test_spot"] + Vector3(-1.9, 0, 1.1), 2.0)
	suong.move_to(m["test_spot"], 2.2)
	await Game.wait(0.6)
	await say(KHAM, "Bà Sương. Năm nay cũng lên à?")
	await say(SUONG, "Năm nào tôi chẳng lên.")
	end_talk()
	Audio.sfx("water", -10.0, 0.1)
	await Game.wait(0.6)
	await say(KHAM, "Trắng.")
	end_talk()
	suong.move_to(m["suong_wait"] + Vector3(-1.0, 0, -2.5), 2.2)
	# their turn
	vung.move_to(m["test_spot"] + Vector3(0.5, 0, 1.7), 2.0)
	await h.move_to(m["test_spot"])
	h.face("up")
	kham.face_point(h.global_position)
	await say(KHAM, "Đưa tay đây. Ngửa bàn tay ra.")
	end_talk()
	var at = AshTest.new()
	add_child(at)
	await at.open()
	await at.rub()
	await say(KHAM, "Giữ yên.")
	end_talk()
	# The hand held still: the yoke's rhythm. It cannot change what the ash finds (the porcelain Trắng Tay's hand
	# left at the pass is real); it changes how dark the streak is, and so who can still speak up for them.
	var steady: int = await timing.pendulum(Vector2(world.get_viewport().get_visible_rect().size.x * 0.66, 360), 5, 1.15,
		"Space khi tay lắc ra mép", "Tay yên")
	if steady < 4:
		at.tremble(1.0)
	Game.flags["bs_ash_steady"] = steady
	var faint := steady >= 3
	await at.wash(0.6 if faint else 0.95)
	AutoTest.shot("bs08_ash")
	await at.stamp("XÁM")
	await say(KHAM, "...Xám.", "stern")
	await say(SUONG, "Người gánh hòm thuốc cho tôi đấy. Gánh nặng thì tay nứt thôi.", "shrug")
	await say(KHAM, "Sổ ghi xám thì phải giữ lại.")
	end_talk()
	can.move_to(m["test_spot"] + Vector3(1.0, 0, 0.2), 2.0)   # beside the one tested, before the table
	await Game.wait(0.9)
	can.face_point(h.global_position)
	if not faint:
		# too dark for anyone to believe "wet ash": the old guard looks, and looks away
		can.emote("...", 1.0)
		await Game.wait(0.9)
		can.face("down")
	# Who pays for this crossing (docs/N_bach_son.md 8.2, 9.6): the old guard, the protagonist, or the porter
	var opts: Array = []
	var ways: Array = []
	if faint:
		opts.append("(Im lặng)")
		ways.append("can")
	opts.append("Cháu bị Nghiệt chạm ở cửa đèo.")
	ways.append("truth")
	opts.append("Cháu đỡ hòm từ tay anh ấy suốt đường.")
	ways.append("blame")
	var way: String = ways[await world.choose(opts)]
	if Game.auto:
		way = _auto_gate(ways)
	Game.flags["bs_gate"] = way
	AutoTest.note("gate_" + way)
	match way:
		"can":
			await _gate_can(at, can)
		"truth":
			await _gate_truth(at, kham, can, suong)
		"blame":
			await _gate_blame(at, kham, can, suong, vung)
	# through the gateway
	world.set_control(false)
	h.move_to(m["gate_in"], 2.2)
	suong.move_to(m["gate_in"] + Vector3(-1.0, 0, -1.0), 2.2)
	await world.rig.focus(m["gate_in"], 0.9, 2.0, true)
	await cut(false)


func _auto_gate(ways: Array) -> String:
	## Tests pick the way with --gate=can|truth|blame (can, when it is open, otherwise the first).
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--gate=") and ways.has(a.split("=")[1]):
			return a.split("=")[1]
	return ways[0]


func _gate_can(at, can) -> void:
	## They keep quiet; lão Cẩn speaks for them. He pays for it later (the Ty makes an example of him).
	await say(CAN, "Tro ướt.", "behind")
	await say(KHAM, "Dạ?", "surprise")
	await say(CAN, "Tay đổ mồ hôi thì tro không ăn. Thử lại đi.")
	end_talk()
	at.clear_stamp()
	# the old guard does it himself: little ash, a lot of water
	await at.rub(0.6)
	Audio.sfx("water", -2.0, 0.1)
	await at.wash(0.0, 1.8)
	await at.stamp("TRẮNG")
	AutoTest.shot("bs09_white")
	await say(KHAM, "...Trắng.", "think")
	end_talk()
	await Game.wait(0.4)
	await at.close()
	can.face_point(world.hero.global_position)
	await say(CAN, "Đi đi.", "nod")
	end_talk()
	# a man in cobalt by the kiln has seen it
	var ty = npc("ty_watch", "khamsu", world.markers["khamsu"] + Vector3(-4.2, 0, 0.6), "right")
	ty.face_point(can.global_position)
	ty.emote("...", 1.2)
	world.emo("ty_watch", "cold")
	can.move_to(world.markers["can"], 2.0)
	await Game.wait(0.8)


func _gate_truth(at, kham, can, suong) -> void:
	## They say it. A night held on the Sân Tro, as Ngọc Khiết was held at nine; in the morning he comes down.
	var h = world.hero
	var m: Dictionary = world.markers
	await say(P(), "Cháu bị Nghiệt chạm ở cửa đèo.")
	end_talk()
	can.emote("...", 1.0)
	world.emo("can", "sad")
	suong.face_point(kham.global_position)
	await say(SUONG, "Tôi thuê người ở trại hôm qua. Chuyện của người ấy, tôi không biết.", "cold")
	await say(KHAM, "Giữ lại.")
	end_talk()
	await at.close()
	can.move_to(m["can"], 2.0)
	suong.move_to(m["gate_in"] + Vector3(-1.0, 0, -1.0), 2.4)
	await Overlay.fade_out(0.8)
	world.set_time("night", true)
	world.set_gate(false, 0.1)
	h.global_position = m["queue"] + Vector3(-2.6, 0, 0.6)
	h.face("down")
	world.rig.set_view(m["queue"] + Vector3(1.5, 2.6, 5.5), m["queue"] + Vector3(-2.0, 0.8, 0))
	await Overlay.fade_in(0.8)
	await Overlay.card("", "Đêm ở Sân Tro", 1.2)
	AutoTest.shot("bs08c_night")
	_tapping(3.0)
	await Game.wait(2.4)
	await say("", "Dưới chân dốc có tiếng gõ trên sứ, lúc thưa lúc dày. Cổng sau lưng vẫn đóng chặt.")
	end_talk()
	await Overlay.fade_out(1.0)
	world.set_time("highland", true)
	world.set_gate(true, 0.1)
	h.global_position = m["test_spot"]
	h.face("up")
	var khiet = npc("khiet", "khiet", m["gate_in"] + Vector3(0.4, 0, 0.8), "down")
	world.rig.follow(h, false)
	await world.rig.focus(m["test_spot"] + Vector3(-0.5, 0, 0.5), 0.85, 0.1)
	await Overlay.fade_in(1.0)
	await khiet.move_to(m["test_spot"] + Vector3(0.6, 0, -1.2), 2.2)
	khiet.face_point(h.global_position)
	await say(KHAM, "Thưa Chánh Ty.", "bow")
	world.emo("kham", "clasp")
	await say(KHIET, "Khai thật với khám sư à?", "cold")
	await say(KHIET, "Ba trăm năm nay, chưa ai đứng ở cổng này tự nhận mình bị Nghiệt chạm.", "think")
	await say(KHIET, "Cho vào. Sáng nào cũng lên Dinh Ty cho tôi xem tay.", "stern")
	end_talk()
	khiet.move_to(m["gate_in"] + Vector3(0.6, 0, -2.0), 2.4)
	await Game.wait(0.6)


func _gate_blame(at, kham, can, suong, vung) -> void:
	## They point at the porter. His hands are cracked from the yoke, so the ash holds; he is kept, and later put
	## out. Bạch Sơn's own sin, done with Bạch Sơn's own test (docs/N_bach_son.md 9.6).
	var h = world.hero
	var m: Dictionary = world.markers
	await say(P(), "Cháu đỡ hòm từ tay anh ấy suốt đường.")
	end_talk()
	vung.emote("!", 0.8)
	await at.close()
	kham.face_point(vung.global_position)
	await say(KHAM, "Anh kia. Đưa tay đây.", "point")
	await say(VUNG, "Tay tôi... Gánh hòm thì tay nứt chứ.", "scared")
	end_talk()
	h.move_to(m["test_spot"] + Vector3(-0.9, 0, 0.5), 1.2)
	await vung.move_to(m["test_spot"])
	vung.face("up")
	var at2 = AshTest.new()
	add_child(at2)
	await at2.open("Tay anh Vững")
	await at2.rub()
	await at2.wash(0.85)
	await at2.stamp("XÁM")
	AutoTest.shot("bs08b_vung")
	world.emo("hero", "sad")
	await say(KHAM, "Xám. Giữ lại.", "cold")
	await say(KHAM, "Tay người này dính lây từ tay anh ta. Rửa lại.")
	end_talk()
	await at2.close()
	vung.move_to(m["test_spot"] + Vector3(1.4, 0, 1.2), 1.4)
	await h.move_to(m["test_spot"])
	h.face("up")
	var at3 = AshTest.new()
	add_child(at3)
	await at3.open()
	await at3.rub(0.6)
	Audio.sfx("water", -2.0, 0.1)
	await at3.wash(0.0, 1.8)
	await at3.stamp("TRẮNG")
	AutoTest.shot("bs09_white")
	await say(KHAM, "...Trắng.")
	end_talk()
	await at3.close()
	can.face_point(h.global_position)
	can.emote("...", 1.4)
	world.emo("can", "cross")
	vung.face_point(suong.global_position)
	await say(VUNG, "Bà Sương, tôi gánh hòm cho bà sáu năm rồi.", "worry")
	end_talk()
	world.emo("porter1", "sad")
	await Game.wait(0.8)
	suong.face_point(h.global_position)
	await say(SUONG, "Đi thôi.", "cold")
	end_talk()
	# a guard walks him back down the yard, toward the camp road
	vung.move_to(m["yard_entry"] + Vector3(3.0, 0, 3.5), 3.0)
	can.move_to(m["can"], 2.0)
	await Game.wait(0.6)


# ================================================================== INSIDE
func _inside() -> void:
	var h = world.hero
	var m: Dictionary = world.markers
	h.stop_move()
	h.global_position = m["street"] + Vector3(0.4, 0, -3.6)
	world.set_gate(true, 0.1)
	var suong = world.actor("suong")
	if suong == null:
		suong = npc("suong", "suong", m["gate_in"] + Vector3(-1.0, 0, -1.0), "up")
	suong.stop_move()
	suong.global_position = m["street"] + Vector3(-0.8, 0, -4.4)
	# people of the Tầng Rửa at their thresholds, washing
	for i in 4:
		var side := -1.0 if i % 2 == 0 else 1.0
		var p := Vector3(side * 3.6, world.YARD_H, -29.0 - i * 3.0 + 0.8)
		npc("tang_%d" % i, "bs_w" if i % 2 == 0 else "bs_m", p, "left" if side > 0 else "right")
	await cut(true)
	world.see_through_wall(true)
	# up the street to the tiers, all of it white
	world.rig.set_view(Vector3(3.0, world.YARD_H + 5.0, -27.5), m["street"] + Vector3(0, 2.0, -6))
	await world.rig.view_to(Vector3(2.4, world.YARD_H + 17.0, -27.0), Vector3(0, 21.0, -70.0), 2.6)
	AutoTest.shot("bs10_tiers")
	await Game.wait(0.6)
	# back down to the people at the gateway
	# a cut back down to them, not a move: a move from up there runs the camera through the gatehouse roof (and no
	# follow first: for a frame it would show the gate from behind; the follow comes back with the control)
	world.rig.cut_to(m["street"] + Vector3(0.0, 0, -3.8), 0.8)
	suong.face_point(h.global_position)
	match Game.flags.get("bs_gate", "can"):
		"can":
			await say(SUONG, "Lão gác ấy làm thế nhiều lần rồi. Sớm muộn gì cũng có ngày bị bắt.", "sigh")
		"truth":
			await say(SUONG, "Từ giờ đứng cách tôi ra một quãng.", "cold")
		"blame":
			# the porter's wife, at her threshold in the Tầng Rửa
			var wife = npc("vung_wife", "bs_w", m["street"] + Vector3(-2.8, 0, -7.4), "right")
			await wife.move_to(m["street"] + Vector3(-1.6, 0, -5.0), 1.6)
			wife.face_point(suong.global_position)
			AutoTest.shot("bs10b_wife")
			await say("Người đàn bà", "Bà Sương, anh Vững nhà em đâu rồi?", "worry")
			await say(SUONG, "Bị giữ lại ở cổng.", "stern")
			end_talk()
			wife.face_point(h.global_position)
			world.emo("vung_wife", "scared")
			wife.emote("...", 1.4)
			await Game.wait(1.2)
	await say(SUONG, "Rửa tay đi. Ở đây không rửa là người ta nhìn đấy.", "point")
	end_talk()
	await cut(false)
	await go_interact("basin", m["basin_in"], "Rửa tay", "Rửa tay ở chậu nước trước cửa nhà", 1.6)
	Audio.sfx("water", -4.0, 0.1)
	await say("", "Nước lạnh. Chảy từ tầng trên xuống.")
	end_talk()
	AutoTest.shot("bs11_basin")


func _city() -> void:
	## Part C (docs/N_bach_son.md 8.3): four days inside the walls. The gate shuts behind them; from now on the
	## only way out to the camp is the Cửa Cống.
	world.set_gate(false, 1.2)   # (the gate swings shut behind them: heard, and seen when it is in the shot)
	await Game.wait(0.9)
	await Overlay.fade_out(0.8)
	carry_chest(false)   # the chest goes to bà Sương's store; it comes out again when there is carrying to do
	world.see_through_wall(true)
	for i in 4:   # the people washing at their thresholds go in; the city keeps its own hours from here
		if world.actor("tang_%d" % i):
			world.despawn("tang_%d" % i)
	if world.actor("vung_wife"):
		world.despawn("vung_wife")
	var city = BachSonCity.new()
	city.story = self
	add_child(city)
	await city.run()
	city.queue_free()


func _palace() -> void:
	## Part D (docs/N_bach_son.md 8.4, 8.7): the morning after the city's last part, the Chánh Ty comes.
	carry_chest(false)
	await Overlay.fade_out(0.6)
	await Overlay.card("", "Sáng hôm sau", 1.2)
	var p = BachSonPalace.new()
	p.story = self
	add_child(p)
	await p.run()
	p.queue_free()


func _end_card() -> void:
	await Overlay.fade_out(1.6)
	if _chest and is_instance_valid(_chest):
		_chest.queue_free()
	if Game.flags.get("bs_deal", "") == "refuse":
		await Overlay.card("LỄ QUÉT VÔI", "Sáng mai, cả thành sẽ ra Quảng Trường Rửa.", 2.4)
		await Overlay.card("", "Hết bản thử nghiệm. Cảm ơn đã chơi.", 2.4)
	elif Game.flags.get("bs_deal", "") == "accept":
		await Overlay.card("", "Không có bạo loạn, không ai chết. Ty vẫn nguyên vẹn. Bà Tâm không rời Bạch Điện. Cái ngoài cổng không yếu đi.", 3.0)
		await Overlay.card("", "Hết bản thử nghiệm. Cảm ơn đã chơi.", 2.4)
	elif Game.flags.has("bs_nhan_ra"):
		# the end of Part C: the Chánh Ty sends for them (Part D, the Bạch Điện, is not built yet)
		var n := 0
		for id in Game.flags["bs_nhan_ra"]:
			if BachSonCity.COUNTED.has(id):
				n += 1
		await Overlay.card("BẠCH ĐIỆN", "Sáng hôm sau, người của Ty gõ cửa nhà kho. Chánh Ty mời lên Bạch Điện.", 2.4)
		await Overlay.card("", "Đã nhận ra %d trong 5 điều. Hết bản thử nghiệm. Cảm ơn đã chơi." % n, 2.6)
	else:
		await Overlay.card("BẠCH SƠN", "Bốn ngày nữa là tới Lễ Quét Vôi", 2.0)
		await Overlay.card("", "Hết bản thử nghiệm. Cảm ơn đã chơi.", 2.2)
	Game.set_checkpoint("")
