extends CanvasLayer
## Objective banner (top-left, on a strip of lacquer), interaction prompt, control hints, toasts, the arrow at
## the screen edge pointing to where to go next, and the step-by-step guide card for a new action.

signal _guide_closed

var _obj_root: Control
var _obj_label: Label
var _obj_brush: NinePatchRect
var _prompt: PanelContainer
var _prompt_label: Label
var _hint: Label
var _toast: Label
var _toast_box: PanelContainer
var _current_prompt := ""
var _edge: TextureRect              # points to the current marker when it is out of view
var _edge_target = null             # Vector3 or null
var _guide: PanelContainer
var _guide_title: Label
var _guide_steps: VBoxContainer
var _guide_open := false


func _ready() -> void:
	layer = 30
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = Assets.theme
	add_child(root)
	_obj_root = Control.new()
	_obj_root.position = Vector2(24, 22)
	_obj_root.modulate.a = 0.0
	root.add_child(_obj_root)
	# a strip of lacquer ruled in gold, a hồi văn at its head, fading out to the right (tools/art/lacquer_ui.py)
	_obj_brush = NinePatchRect.new()
	_obj_brush.texture = Assets.tex("res://assets/ui/obj_strip.png")
	_obj_brush.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_obj_brush.patch_margin_left = 44
	_obj_brush.patch_margin_right = 200
	_obj_brush.size = Vector2(430, 66)
	_obj_brush.position = Vector2(-24, -12)
	_obj_root.add_child(_obj_brush)
	var tag := Label.new()
	tag.text = "VIỆC CẦN LÀM"
	tag.position = Vector2(14, -1)
	tag.add_theme_font_override("font", Assets.serif(true))
	tag.add_theme_font_size_override("font_size", 13)
	tag.add_theme_color_override("font_color", Assets.GOLD)
	_obj_root.add_child(tag)
	_obj_label = Label.new()
	_obj_label.position = Vector2(14, 14)
	_obj_label.add_theme_font_override("font", Assets.serif(true))
	_obj_label.add_theme_font_size_override("font_size", 20)
	_obj_label.add_theme_color_override("font_color", Assets.TEXT)
	_obj_label.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.05))
	_obj_label.add_theme_constant_override("outline_size", 5)
	_obj_root.add_child(_obj_label)

	_prompt = PanelContainer.new()
	_prompt.anchor_left = 0.5
	_prompt.anchor_right = 0.5
	_prompt.anchor_top = 1.0
	_prompt.anchor_bottom = 1.0
	_prompt.offset_top = -92
	_prompt.offset_bottom = -40
	_prompt.offset_left = -170
	_prompt.offset_right = 170
	_prompt.visible = false
	Assets.paper(_prompt)
	root.add_child(_prompt)
	_prompt_label = Label.new()
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.add_theme_font_size_override("font_size", 20)
	_prompt.add_child(_prompt_label)

	_hint = Label.new()
	_hint.anchor_left = 1.0
	_hint.anchor_right = 1.0
	_hint.anchor_top = 1.0
	_hint.anchor_bottom = 1.0
	_hint.offset_left = -470
	_hint.offset_right = -18
	_hint.offset_top = -30
	_hint.offset_bottom = -8
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.text = "WASD di chuyển · Shift chạy · Space / E tương tác · Esc tạm dừng"
	_hint.add_theme_font_size_override("font_size", 15)
	_hint.add_theme_color_override("font_color", Color(0.92, 0.9, 0.84, 0.55))
	_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	_hint.add_theme_constant_override("outline_size", 4)
	_hint.visible = false
	root.add_child(_hint)

	# a passing word (Nghi tăng, Nhận ra: ...): on a lacquer chip below the boards at the top, wrapped, never under them
	_toast_box = PanelContainer.new()
	_toast_box.add_theme_stylebox_override("panel", Assets.lacquer_bar(false))
	_toast_box.anchor_left = 0.5
	_toast_box.anchor_right = 0.5
	_toast_box.offset_top = 124
	_toast_box.offset_bottom = 124
	_toast_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_box.modulate.a = 0.0
	Assets.paper(_toast_box)
	root.add_child(_toast_box)
	_toast = Label.new()
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast.add_theme_font_override("font", Assets.serif(true))
	_toast.add_theme_font_size_override("font_size", 19)
	_toast.add_theme_color_override("font_color", Assets.GOLD_PALE)
	_toast_box.add_child(_toast)

	_edge = TextureRect.new()
	_edge.texture = Assets.tex("res://assets/sprites/props/marker.png")
	_edge.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_edge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_edge.size = Vector2(42, 48)
	_edge.pivot_offset = _edge.size * 0.5
	_edge.visible = false
	root.add_child(_edge)

	_guide = PanelContainer.new()
	_guide.anchor_left = 0.5
	_guide.anchor_right = 0.5
	_guide.anchor_top = 0.5
	_guide.anchor_bottom = 0.5
	_guide.offset_left = -330
	_guide.offset_right = 330
	_guide.offset_top = -150
	_guide.offset_bottom = 150
	_guide.visible = false
	Assets.paper(_guide)
	root.add_child(_guide)
	var gm := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		gm.add_theme_constant_override("margin_" + side, 22)
	_guide.add_child(gm)
	var gv := VBoxContainer.new()
	gv.add_theme_constant_override("separation", 10)
	gm.add_child(gv)
	_guide_title = Label.new()
	_guide_title.add_theme_font_override("font", Assets.serif(true))
	_guide_title.add_theme_font_size_override("font_size", 26)
	_guide_title.add_theme_color_override("font_color", Assets.GOLD)
	gv.add_child(_guide_title)
	_guide_steps = VBoxContainer.new()
	_guide_steps.add_theme_constant_override("separation", 8)
	gv.add_child(_guide_steps)
	var foot := Label.new()
	foot.text = "[Space]  Hiểu rồi"
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	foot.add_theme_font_size_override("font_size", 17)
	foot.add_theme_color_override("font_color", Assets.TEXT_SOFT)
	gv.add_child(foot)


var _obj_tw: Tween


func objective(text: String) -> void:
	if _obj_tw and _obj_tw.is_valid():
		_obj_tw.kill()   # a clear right after a set (or the other way) must win, not race it
	if text == "":
		_obj_tw = create_tween()
		_obj_tw.tween_property(_obj_root, "modulate:a", 0.0, 0.4)
		return
	_obj_label.text = text
	_obj_brush.size.x = max(330.0, _obj_label.get_minimum_size().x + 170.0)
	_obj_tw = create_tween()
	var tw := _obj_tw
	_obj_root.position.x = 0
	tw.set_parallel(true)
	tw.tween_property(_obj_root, "modulate:a", 1.0, 0.5)
	tw.tween_property(_obj_root, "position:x", 24.0, 0.5).set_trans(Tween.TRANS_BACK)


func show_prompt(text: String) -> void:
	if text == _current_prompt:
		return
	_current_prompt = text
	_prompt.visible = text != ""
	_prompt_label.text = "[Space]  " + text


var _hints_on := false


func show_hints(on: bool) -> void:
	_hints_on = on


func point_to(target) -> void:
	## The world position of where to go next (or null): an arrow at the screen edge points to it when out of view.
	_edge_target = target
	if target == null:
		_edge.visible = false


func _process(_delta: float) -> void:
	# the keys at the corner and the [Space] prompt only while the player can act (not in a cutscene, not under a
	# board or the pause menu)
	var w = get_parent()
	var can_act: bool = w != null and w.get("control_enabled") == true and not get_tree().paused
	_hint.visible = _hints_on and can_act
	_prompt.visible = _current_prompt != "" and can_act
	if _edge_target == null:
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		_edge.visible = false
		return
	var vp := get_viewport().get_visible_rect().size
	var p := cam.unproject_position(_edge_target)
	var behind := cam.is_position_behind(_edge_target)
	var margin := 46.0
	# on the screen at all (even near an edge): the marker there shows the way, no arrow over it
	var inside := not behind and p.x > 6.0 and p.x < vp.x - 6.0 and p.y > 6.0 and p.y < vp.y - 6.0
	_edge.visible = not inside and not _guide_open
	if inside:
		return
	var c := vp * 0.5
	var d := p - c
	if behind:
		d = -d
	if d.length() < 1.0:
		d = Vector2(0, 1)
	# clamp onto a rectangle just inside the screen edge
	var hx := c.x - margin
	var hy := c.y - margin
	var k := minf(hx / maxf(absf(d.x), 0.001), hy / maxf(absf(d.y), 0.001))
	var at := c + d * k
	var pulse := 1.0 + 0.12 * sin(Time.get_ticks_msec() * 0.008)
	_edge.scale = Vector2.ONE * pulse
	_edge.position = at - _edge.size * 0.5
	_edge.rotation = d.angle() - PI * 0.5   # the arrow art points down (+y)


func guide(title: String, steps: Array) -> void:
	## A how-to card for a new action: a title and a few numbered steps. Stays until Space, E or Enter.
	_guide_title.text = title
	for c in _guide_steps.get_children():
		c.queue_free()
	for i in steps.size():
		var l := Label.new()
		l.text = "%d.  %s" % [i + 1, steps[i]]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(600, 0)
		l.add_theme_font_size_override("font_size", 20)
		l.add_theme_color_override("font_color", Assets.TEXT)
		_guide_steps.add_child(l)
	_guide.visible = true
	_guide_open = true
	_guide.modulate.a = 0.0
	create_tween().tween_property(_guide, "modulate:a", 1.0, 0.2)
	if Game.auto:
		await get_tree().create_timer(0.3).timeout
		await AutoTest.shot("guide_" + str(abs(title.hash()) % 1000))
		await get_tree().create_timer(0.3 if not Game.fast else 0.05).timeout
	else:
		await get_tree().create_timer(0.35).timeout   # a press already held from before does not close it
		await _guide_closed
	_guide.visible = false
	_guide_open = false


func _input(event: InputEvent) -> void:
	# before anything else sees it: the card takes the press (or the player would interact through it)
	if _guide_open and event.is_action_pressed("act"):   # Space, Enter, E
		get_viewport().set_input_as_handled()
		_guide_closed.emit()


var _toast_tw: Tween


func toast(text: String, hold := 1.8) -> void:
	_toast.text = text
	var w := Assets.serif(true).get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x
	_toast.custom_minimum_size = Vector2(minf(w + 4.0, 620.0), 0)
	var bw := _toast_box.get_combined_minimum_size().x
	_toast_box.offset_left = -bw * 0.5   # centred, as wide as its words (wrapped past 620 px)
	_toast_box.offset_right = bw * 0.5
	if _toast_tw and _toast_tw.is_valid():
		_toast_tw.kill()
	_toast_tw = create_tween()
	_toast_tw.tween_property(_toast_box, "modulate:a", 1.0, 0.3)
	_toast_tw.tween_interval(hold)
	_toast_tw.tween_property(_toast_box, "modulate:a", 0.0, 0.5)
