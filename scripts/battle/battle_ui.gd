extends CanvasLayer
## Battle HUD: command menu, target picker, hero panel, floating enemy bars (Hình + Chấp), turn order,
## message line and tutorial boxes. In automated runs it chooses commands with a small AI.

signal _picked(value)
signal _tut_closed

const CMDS := [
	{"id": "bo", "name": "Bổ", "icon": 0, "desc": "Một nhát mạnh vào một Nghiệt."},
	{"id": "quet", "name": "Quét", "icon": 1, "desc": "Quét ngang, trúng mọi Nghiệt."},
	{"id": "nhatnet", "name": "Nhất Nét", "icon": 8, "desc": "Cần 3 Tịnh. Một nét chém dứt: phá hết Chấp, cắt sạch Xâm."},
	{"id": "thu", "name": "Thủ", "icon": 2, "desc": "Vào thế thủ. Đỡ đúng lúc sẽ phản đòn."},
	{"id": "thau", "name": "Thấu", "icon": 3, "desc": "Chạm vào Nghiệt, thấy nó từ đâu ra và điểm yếu."},
	{"id": "thuoc", "name": "Thuốc", "icon": 4, "desc": "Đắp lá thuốc, hồi 30 Hình."},
]

var battle
var blind := false            # Bịt Mắt: enemy bars hidden with the field
var track: Label              # Chắn đường: the two step counts
var root: Control
var menu_box: PanelContainer
var menu_rows: Array = []
var menu_desc: Label
var hero_panel: PanelContainer
var hero_hp_bar: ProgressBar
var hero_hp_label: Label
var hero_status: Label
var tinh_box: HBoxContainer
var summary: PanelContainer
var msg: Label
var order_box: HBoxContainer
var msg_box: PanelContainer
var _hero_shown := false
var tut_panel: PanelContainer
var tut_text: RichTextLabel
var cursor: TextureRect
var enemy_ui := {}       # name -> {root, hp, chap_box, weak_box}
var icons: Texture2D
var _mode := ""
var _sel := 0
var _menu_sel := 0
var _targets: Array = []
var _potions := 0
var _lead_shot := false
var _sel_box := Assets.lacquer_bar(true)   # a lacquer bar under the chosen command
var _none_box := StyleBoxEmpty.new()


func _ready() -> void:
	layer = 35
	_sel_box.content_margin_left = 26
	_sel_box.content_margin_right = 30
	icons = Assets.tex("res://assets/ui/icons.png")
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = Assets.theme
	add_child(root)
	# the battle line: on a lacquer chip in a band of its own (under the turn order and the Lúa tracker, over the
	# field), so it never prints across them or a nameplate
	msg_box = PanelContainer.new()
	msg_box.add_theme_stylebox_override("panel", Assets.lacquer_bar(false))
	msg_box.anchor_left = 0.5
	msg_box.anchor_right = 0.5
	msg_box.offset_top = 104
	msg_box.offset_bottom = 104
	msg_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	msg_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	msg_box.modulate.a = 0.0
	Assets.paper(msg_box)
	root.add_child(msg_box)
	msg = Label.new()
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_font_override("font", Assets.serif(true))
	msg.add_theme_font_size_override("font_size", 20)
	msg.add_theme_color_override("font_color", Assets.TEXT)
	msg_box.add_child(msg)
	# turn order
	order_box = HBoxContainer.new()
	order_box.position = Vector2(24, 20)
	order_box.add_theme_constant_override("separation", 6)
	root.add_child(order_box)
	# command menu
	menu_box = PanelContainer.new()
	menu_box.anchor_top = 1.0
	menu_box.anchor_bottom = 1.0
	menu_box.offset_left = 24
	menu_box.offset_right = 300
	menu_box.offset_top = -372
	menu_box.offset_bottom = -24
	menu_box.visible = false
	Assets.paper(menu_box)
	root.add_child(menu_box)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	menu_box.add_child(vb)
	for c in CMDS:
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		var ic := TextureRect.new()
		var at := AtlasTexture.new()
		at.atlas = icons
		at.region = Rect2(c["icon"] * 16, 0, 16, 16)
		ic.texture = at
		ic.custom_minimum_size = Vector2(32, 32)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		hb.add_child(ic)
		var l := Label.new()
		l.text = c["name"]
		l.add_theme_font_override("font", Assets.serif(true))
		l.add_theme_font_size_override("font_size", 24)
		hb.add_child(l)
		vb.add_child(hb)
		menu_rows.append({"row": hb, "label": l, "id": c["id"], "icon": ic})
	menu_desc = Label.new()
	menu_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_desc.custom_minimum_size = Vector2(240, 48)
	menu_desc.add_theme_font_size_override("font_size", 15)
	menu_desc.add_theme_color_override("font_color", Assets.TEXT_SOFT)
	vb.add_child(menu_desc)
	# hero panel
	hero_panel = PanelContainer.new()
	hero_panel.anchor_left = 1.0
	hero_panel.anchor_right = 1.0
	hero_panel.anchor_top = 1.0
	hero_panel.anchor_bottom = 1.0
	hero_panel.offset_left = -360
	hero_panel.offset_right = -24
	hero_panel.offset_top = -176
	hero_panel.offset_bottom = -24
	Assets.paper(hero_panel)
	root.add_child(hero_panel)
	var hv := VBoxContainer.new()
	hero_panel.add_child(hv)
	var nm := Label.new()
	nm.text = Game.player_name
	nm.add_theme_font_override("font", Assets.serif(true))
	nm.add_theme_font_size_override("font_size", 22)
	hv.add_child(nm)
	hero_hp_bar = _bar(Color(0.78, 0.26, 0.22))
	hero_hp_bar.custom_minimum_size = Vector2(300, 16)
	hv.add_child(hero_hp_bar)
	hero_hp_label = Label.new()
	hero_hp_label.add_theme_font_size_override("font_size", 17)
	hv.add_child(hero_hp_label)
	tinh_box = HBoxContainer.new()
	tinh_box.add_theme_constant_override("separation", 4)
	var tl := Label.new()
	tl.text = "Tịnh"
	tl.add_theme_font_size_override("font_size", 16)
	tl.add_theme_color_override("font_color", Assets.BLUE)
	tinh_box.add_child(tl)
	for k in 3:
		tinh_box.add_child(_icon(10, 20))
	hv.add_child(tinh_box)
	hero_status = Label.new()
	hero_status.add_theme_font_size_override("font_size", 15)
	hero_status.add_theme_color_override("font_color", Assets.BLUE)
	hv.add_child(hero_status)
	# tutorial
	tut_panel = PanelContainer.new()
	tut_panel.add_theme_stylebox_override("panel", Assets.panel_solid())
	tut_panel.anchor_left = 0.5
	tut_panel.anchor_right = 0.5
	tut_panel.anchor_top = 1.0
	tut_panel.anchor_bottom = 1.0
	tut_panel.offset_left = -278
	tut_panel.offset_right = 278
	tut_panel.offset_top = -222
	tut_panel.offset_bottom = -24
	tut_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	tut_panel.visible = false
	Assets.paper(tut_panel)
	root.add_child(tut_panel)
	var tv := VBoxContainer.new()
	tut_panel.add_child(tv)
	tut_text = RichTextLabel.new()
	tut_text.bbcode_enabled = true
	tut_text.fit_content = true
	tut_text.scroll_active = false
	tut_text.custom_minimum_size = Vector2(496, 60)
	tut_text.add_theme_font_override("normal_font", Assets.serif(false))
	tut_text.add_theme_font_override("bold_font", Assets.serif(true))
	tut_text.add_theme_font_size_override("normal_font_size", 20)
	tut_text.add_theme_font_size_override("bold_font_size", 20)
	tv.add_child(tut_text)
	var cont := Label.new()
	cont.text = "[Space] tiếp"
	cont.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cont.add_theme_font_size_override("font_size", 14)
	cont.add_theme_color_override("font_color", Assets.GOLD)
	tv.add_child(cont)
	# target cursor
	cursor = TextureRect.new()
	cursor.texture = Assets.tex("res://assets/ui/cursor.png")
	cursor.custom_minimum_size = Vector2(26, 26)
	cursor.size = Vector2(26, 26)
	cursor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cursor.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	cursor.visible = false
	root.add_child(cursor)


func _bar(col: Color) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	# a dark trough edged in old gold, the colour inside it (tools/art/lacquer_ui.py bar_trough / bar_fill_flat)
	var bars := Assets.bar_styles(col)
	b.add_theme_stylebox_override("background", bars[0])
	b.add_theme_stylebox_override("fill", bars[1])
	return b


func visible_all(v: bool) -> void:
	root.visible = v


var _msg_tw: Tween


func message(text: String) -> void:
	msg.text = text
	var w := msg_box.get_combined_minimum_size().x
	msg_box.offset_left = -w * 0.5   # centred: as wide as its words, the same on both sides
	msg_box.offset_right = w * 0.5
	msg_box.modulate.a = 1.0
	msg_box.move_to_front()   # over the nameplates (a Nghiệt lunging toward the camera lifts its plate into the band)
	if _msg_tw and _msg_tw.is_valid():
		_msg_tw.kill()
	_msg_tw = create_tween()
	_msg_tw.tween_interval(2.2)
	_msg_tw.tween_property(msg_box, "modulate:a", 0.0, 0.6)


func set_hero(hp: int, max_hp: int, potions: int, status := "") -> void:
	_potions = potions
	hero_hp_bar.max_value = max_hp
	if not _hero_shown:   # the first time, as it is
		_hero_shown = true
		hero_hp_bar.value = hp
	else:
		var tw := create_tween()
		tw.tween_property(hero_hp_bar, "value", float(hp), 0.3)
	hero_hp_label.text = "Hình %d / %d      Thuốc ×%d" % [hp, max_hp, potions]
	hero_status.text = status


func set_tinh(n: int) -> void:
	for k in 3:
		var ic: TextureRect = tinh_box.get_child(k + 1)
		var on := k < n
		var tw := ic.create_tween()
		tw.tween_property(ic, "modulate", Color(1, 1, 1, 1.0) if on else Color(0.5, 0.5, 0.55, 0.35), 0.2)
		if on and k == n - 1:
			ic.pivot_offset = Vector2(10, 10)
			ic.scale = Vector2.ONE * 1.6
			ic.create_tween().tween_property(ic, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	_refresh_menu()


func show_summary(st: Dictionary) -> void:
	## After a won fight: how cleanly it was fought.
	if summary:
		summary.queue_free()
	for c in order_box.get_children():   # the fight is over: no one's turn
		c.queue_free()
	summary = PanelContainer.new()
	summary.anchor_left = 0.5
	summary.anchor_right = 0.5
	summary.offset_left = -230
	summary.offset_right = 230
	summary.offset_top = 92
	summary.offset_bottom = 196
	Assets.paper(summary)
	root.add_child(summary)
	var v := VBoxContainer.new()
	summary.add_child(v)
	var verdict := "Tịnh"
	if st["qua"] >= 3:
		verdict = "Loạn"
	elif st["qua"] > 0 or st["dut"] < 2:
		verdict = "Vững"
	var h := Label.new()
	h.text = "Nét: %s" % verdict
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_theme_font_override("font", Assets.serif(true))
	h.add_theme_font_size_override("font_size", 28)
	h.add_theme_color_override("font_color", {"Tịnh": Assets.BLUE, "Vững": Assets.GOLD, "Loạn": Assets.SON}[verdict])
	v.add_child(h)
	var d := Label.new()
	d.text = "Chém dứt %d    Đỡ chuẩn %d    Quá đà %d" % [st["dut"], st["do"], st["qua"]]
	if int(st.get("noi", 0)) > 1:
		d.text += "    Nối %d nét" % int(st["noi"])
	if int(st.get("the", 0)) > 0:
		d.text += "    Nối thế %d" % int(st["the"])
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d.add_theme_font_size_override("font_size", 18)
	v.add_child(d)
	summary.modulate.a = 0.0
	summary.create_tween().tween_property(summary, "modulate:a", 1.0, 0.25)


func set_order(list: Array) -> void:
	for c in order_box.get_children():
		c.queue_free()
	var title := Label.new()
	title.text = "Lượt:"
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(0.9, 0.87, 0.8))
	title.add_theme_color_override("font_outline_color", Color(0.04, 0.03, 0.05))
	title.add_theme_constant_override("outline_size", 5)
	order_box.add_child(title)
	for i in list.size():
		var u = list[i]
		if i > 0:
			var dot := Label.new()
			dot.text = "·"
			dot.add_theme_font_size_override("font_size", 15)
			dot.add_theme_color_override("font_color", Assets.GOLD)
			dot.add_theme_color_override("font_outline_color", Color(0.04, 0.03, 0.05))
			dot.add_theme_constant_override("outline_size", 5)
			order_box.add_child(dot)
		var l := Label.new()
		l.text = Game.player_name if u == null else str(u["name"])
		l.add_theme_font_size_override("font_size", 15)
		l.add_theme_color_override("font_color", Color(1, 0.9, 0.7) if u == null else Color(0.8, 0.84, 0.9))
		l.add_theme_color_override("font_outline_color", Color(0.04, 0.03, 0.05))
		l.add_theme_constant_override("outline_size", 5)
		order_box.add_child(l)


# ---------------------------------------------------------------- enemies
func add_enemy(u: Dictionary) -> void:
	var r := VBoxContainer.new()
	r.add_theme_constant_override("separation", 2)
	r.custom_minimum_size = Vector2(150, 0)
	var nm := Label.new()
	nm.text = u["name"]
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_color_override("font_color", Color(0.94, 0.92, 0.88))
	nm.add_theme_font_override("font", Assets.serif(true))
	nm.add_theme_font_size_override("font_size", 15)
	nm.add_theme_color_override("font_outline_color", Color(0.04, 0.03, 0.05))
	nm.add_theme_constant_override("outline_size", 5)
	r.add_child(nm)
	var hp := _bar(Color(0.8, 0.25, 0.22))
	hp.custom_minimum_size = Vector2(130, 9)
	hp.max_value = u["max_hp"]
	hp.value = u["hp"]
	r.add_child(hp)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 1)
	r.add_child(row)
	root.add_child(r)
	enemy_ui[u["name"]] = {"root": r, "hp": hp, "row": row, "u": u}
	refresh_enemy(u)


func _icon(i: int, size := 20) -> TextureRect:
	var ic := TextureRect.new()
	var at := AtlasTexture.new()
	at.atlas = icons
	at.region = Rect2(i * 16, 0, 16, 16)
	ic.texture = at
	ic.custom_minimum_size = Vector2(size, size)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return ic


func refresh_enemy(u: Dictionary) -> void:
	if not enemy_ui.has(u["name"]):
		return
	var e: Dictionary = enemy_ui[u["name"]]
	var tw := create_tween()
	tw.tween_property(e["hp"], "value", float(u["hp"]), 0.25)
	var row: HBoxContainer = e["row"]
	for c in row.get_children():
		c.queue_free()
	if u["broken"] > 0:
		var b := Label.new()
		b.text = "VỠ"
		b.add_theme_font_override("font", Assets.serif(true))
		b.add_theme_font_size_override("font_size", 15)
		b.add_theme_color_override("font_color", Color(0.75, 0.9, 1.0))
		row.add_child(b)
	else:
		for k in u["chap"]:
			row.add_child(_icon(5, 18))
	for k in u.get("xam", 0):
		row.add_child(_icon(9, 18))
	for key in ["ho", "ran", "chao"]:   # Nối thế: what the last move left on it
		if u.get(key, false):
			var m := Label.new()
			m.text = " " + battle.MARKS[key][0]
			m.add_theme_font_override("font", Assets.serif(true))
			m.add_theme_font_size_override("font_size", 14)
			m.add_theme_color_override("font_color", battle.MARKS[key][1])
			m.add_theme_color_override("font_outline_color", Color(0.04, 0.03, 0.05))
			m.add_theme_constant_override("outline_size", 4)
			row.add_child(m)
	var sep := Control.new()
	sep.custom_minimum_size = Vector2(8, 1)
	row.add_child(sep)
	for w in u["weak"]:
		if u["revealed"]:
			row.add_child(_icon(0 if w == "bo" else 1, 18))
		else:
			row.add_child(_icon(6, 18))


func set_track(text: String) -> void:
	## Chắn đường: how far Lúa still has to go, and how far Trắng Tay still has to come.
	if track == null:
		track = Label.new()
		track.offset_left = 16
		track.offset_right = 520
		track.offset_top = 40
		track.offset_bottom = 100
		track.add_theme_font_override("font", Assets.serif(true))
		track.add_theme_font_size_override("font_size", 19)
		track.add_theme_color_override("font_color", Color(0.95, 0.82, 0.6))
		track.add_theme_color_override("font_outline_color", Color(0.04, 0.03, 0.05))
		track.add_theme_constant_override("outline_size", 6)
		root.add_child(track)
	track.text = text


func set_blind(on: bool) -> void:
	## Bịt Mắt: the bars that float over the Nghiệt go with the rest of the field.
	blind = on
	for key in enemy_ui:
		(enemy_ui[key]["root"] as Control).visible = not on


func remove_enemy(u: Dictionary) -> void:
	if enemy_ui.has(u["name"]):
		enemy_ui[u["name"]]["root"].queue_free()
		enemy_ui.erase(u["name"])


func _process(_delta: float) -> void:
	if battle == null or battle.world == null:
		return
	var cam: Camera3D = battle.world.rig.cam
	for key in enemy_ui:
		var e: Dictionary = enemy_ui[key]
		var u: Dictionary = e["u"]
		var spr: Sprite3D = u["node"]
		if not is_instance_valid(spr):
			continue
		var h: float = spr.texture.get_height() * spr.pixel_size * 0.5 + 0.25
		var p := cam.unproject_position(spr.global_position + Vector3(0, h, 0))
		var r: Control = e["root"]
		var vps := root.size
		var at := p - Vector2(r.size.x * 0.5, r.size.y + 4)
		at.x = clampf(at.x, 4.0, vps.x - r.size.x - 4.0)
		at.y = clampf(at.y, 50.0, vps.y - r.size.y - 4.0)   # below the turn order, never off the top
		r.position = at
		r.visible = not blind
		# a plate under the battle line while it is up goes faint, so the line reads
		var over := msg_box.modulate.a > 0.05 and Rect2(at, r.size).intersects(msg_box.get_global_rect())
		r.modulate.a = 0.2 if over else 1.0
	if _mode == "target" and _targets.size() > 0:
		var t: Dictionary = _targets[_sel]
		var spr2: Sprite3D = t["node"]
		var h2: float = spr2.texture.get_height() * spr2.pixel_size * 0.5 + 0.9
		var p2 := cam.unproject_position(spr2.global_position + Vector3(0, h2, 0))
		cursor.position = p2 - Vector2(13, 13 - sin(Time.get_ticks_msec() * 0.008) * 4)


# ---------------------------------------------------------------- menus
func _refresh_menu() -> void:
	for i in menu_rows.size():
		var r: Dictionary = menu_rows[i]
		var sel := i == _sel
		var l: Label = r["label"]
		var nm: String = CMDS[i]["name"]
		if r["id"] == "thuoc":
			nm += " ×%d" % _potions
		var lead := _lead(r["id"])
		l.text = nm + ("" if lead == "" else "  · " + lead)
		var dim: bool = (r["id"] == "thuoc" and _potions <= 0) or (r["id"] == "nhatnet" and battle != null and battle.tinh < 3)
		var col := Assets.SON if lead != "" else (Assets.TEXT_DIM if dim else Assets.TEXT)
		l.add_theme_color_override("font_color", Assets.GOLD_PALE if sel else col)
		l.add_theme_stylebox_override("normal", _sel_box if sel else _none_box)
	var id: String = CMDS[_sel]["id"]
	menu_desc.text = CMDS[_sel]["desc"]
	if _lead(id) == "hở":
		menu_desc.text += "\nCó Nghiệt đang HỞ: Bổ vào nó nặng gấp rưỡi, tính như trúng điểm yếu."
	elif _lead(id) == "rạn":
		menu_desc.text += "\nCó Nghiệt đang RẠN: Quét bung vết rạn, nặng gấp đôi lên nó."


func _lead(id: String) -> String:
	## Nối thế: a command the field has been set up for (by the last moves) is marked in the menu.
	if battle == null:
		return ""
	var alive: Array = battle._alive()
	if id == "bo" and alive.any(func(u): return u["ho"]):
		return "hở"
	if id == "quet" and alive.any(func(u): return u["ran"]):
		return "rạn"
	return ""


func menu(potions: int) -> String:
	_potions = potions
	_mode = "menu"
	_sel = _menu_sel
	menu_box.visible = true
	_refresh_menu()
	if Game.auto:
		await get_tree().create_timer(0.05 if Game.fast else 0.4).timeout
		if not _lead_shot and (_lead("bo") != "" or _lead("quet") != ""):
			_lead_shot = true   # the menu pointing at what the last moves set up
			_sel = 0 if _lead("bo") != "" else 1
			_refresh_menu()
			await AutoTest.shot("b_menu_lead")
		_mode = ""
		menu_box.visible = false
		return _auto_cmd()
	var v = await _picked
	menu_box.visible = false
	return v


func hide_menu() -> void:
	menu_box.visible = false
	cursor.visible = false
	_mode = ""


func pick_target(list: Array, prefer = null):
	if list.is_empty():
		return null
	if list.size() == 1 and not Game.auto:
		return list[0]
	_targets = list
	_sel = maxi(0, list.find(prefer)) if prefer != null else 0
	_mode = "target"
	cursor.visible = true
	if Game.auto:
		await get_tree().create_timer(0.05).timeout
		_mode = ""
		cursor.visible = false
		return _auto_target(list)
	var v = await _picked
	cursor.visible = false
	return v


func tutorial(text: String, info := false, shot := "") -> void:
	tut_text.text = text
	tut_panel.visible = true
	tut_panel.move_to_front()   # over the bars that float above the Nghiệt
	tut_panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(tut_panel, "modulate:a", 1.0, 0.2)
	_mode = "tut"
	if Game.auto:
		if shot != "":
			await get_tree().create_timer(0.3).timeout
			AutoTest.shot(shot)
		await get_tree().create_timer(0.05 if Game.fast else 0.6).timeout
	else:
		await _tut_closed
	_mode = ""
	tut_panel.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if Game.auto:
		return
	match _mode:
		"menu":
			if event.is_action_pressed("move_up"):
				_sel = (_sel - 1 + CMDS.size()) % CMDS.size()
				Audio.sfx("ui_move", -8.0)
				_refresh_menu()
			elif event.is_action_pressed("move_down"):
				_sel = (_sel + 1) % CMDS.size()
				Audio.sfx("ui_move", -8.0)
				_refresh_menu()
			elif event.is_action_pressed("act"):
				Audio.sfx("ui_ok", -6.0)
				_mode = ""
				_menu_sel = _sel
				_picked.emit(CMDS[_sel]["id"])
			else:
				return
			get_viewport().set_input_as_handled()
		"target":
			if event.is_action_pressed("move_left") or event.is_action_pressed("move_up"):
				_sel = (_sel - 1 + _targets.size()) % _targets.size()
				Audio.sfx("ui_move", -8.0)
			elif event.is_action_pressed("move_right") or event.is_action_pressed("move_down"):
				_sel = (_sel + 1) % _targets.size()
				Audio.sfx("ui_move", -8.0)
			elif event.is_action_pressed("act"):
				Audio.sfx("ui_ok", -6.0)
				_mode = ""
				_picked.emit(_targets[_sel])
			elif event.is_action_pressed("back"):
				Audio.sfx("ui_back", -6.0)
				_mode = ""
				_picked.emit(null)
			else:
				return
			get_viewport().set_input_as_handled()
		"tut":
			if event.is_action_pressed("act"):
				get_viewport().set_input_as_handled()
				_tut_closed.emit()


# ---------------------------------------------------------------- auto play (tests)
func _auto_cmd() -> String:
	var alive: Array = battle._alive()
	var scripted: Array = battle.cfg.get("auto_cmds", [])
	if scripted.size() > 0:
		var c: String = scripted.pop_front()
		if c != "nhatnet" or battle.tinh >= 3:
			return c
	if not battle.thau_used and not battle.cfg.get("glimpse_on_touch", false):
		return "thau"
	if battle.tinh >= 3:
		return "nhatnet"
	if battle.hero_hp < 26 and battle.potions > 0:
		return "thuoc"
	for u in alive:
		if u["windup"]:   # break the stance with a clean stroke, or brace for the flurry
			return "bo" if Game.auto_timing == "perfect" else "thu"
	var opened := alive.filter(func(u): return u["ho"])
	var cracked := alive.filter(func(u): return u["ran"])
	if not battle.esc.is_empty():   # at Lúa's side: a sure hand cuts at the arms, an unsure one stands in Thủ
		if Game.auto_timing == "perfect" and not cracked.is_empty() and opened.is_empty():
			return "quet"
		return "bo" if Game.auto_timing == "perfect" else "thu"
	if not opened.is_empty():   # Nối thế: use what the last moves set up
		return "bo"
	if not cracked.is_empty():
		return "quet"
	for u in alive:
		if u["broken"] > 0:
			return "bo"
	var quet_weak := alive.filter(func(u): return u["weak"].has("quet"))
	if alive.size() > 1 or quet_weak.size() > 0:
		if quet_weak.size() > 0 or alive.size() > 2:
			return "quet"
	return "bo"


func _auto_target(list: Array):
	for u in list:
		if u.get("ho", false):
			return u
	for u in list:
		if u["broken"] > 0 or u.get("windup", false):
			return u
	if not battle.esc.is_empty():
		for u in list:
			if u["id"] == "nghiet_tinh":
				return u
	var best = list[0]
	for u in list:
		if u["hp"] < best["hp"]:
			best = u
	return best
