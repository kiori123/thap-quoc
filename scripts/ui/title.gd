extends CanvasLayer
## Title screen over the vista (scripts/world/vista.gd): the name in brush across the sky (十字, tools/art/
## loading_title.py), THẬP TỰ · ĐOẠN NGHIỆT under it, the menu on a lacquer board at the lower left, clear of the
## protagonist sitting at the bottom in the middle; and the naming prompt.

signal chosen(action: String)

const SettingsPanel = preload("res://scripts/ui/settings_panel.gd")

var root: Control
var menu: VBoxContainer
var settings
var name_box: PanelContainer
var name_edit: LineEdit
var _buttons: Array[Button] = []
var _title: TextureRect
var _name: Label
var _sub: Label
var _panel: PanelContainer
var _fade: Array[CanvasItem] = []
var _dim: ColorRect


func _ready() -> void:
	layer = 50
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = Assets.theme
	add_child(root)
	# a faint shade in the sky behind the name, so the brush and the letters hold against bright cloud (no edge to it)
	var scrim := TextureRect.new()
	var gt := GradientTexture2D.new()
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	var gr := Gradient.new()
	gr.set_color(0, Color(0.03, 0.04, 0.07, 0.26))
	gr.set_color(1, Color(0.03, 0.04, 0.07, 0.0))
	gr.add_point(0.55, Color(0.03, 0.04, 0.07, 0.14))
	gt.gradient = gr
	gt.width = 128
	gt.height = 128
	scrim.texture = gt
	scrim.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scrim.stretch_mode = TextureRect.STRETCH_SCALE
	scrim.anchor_left = 0.5
	scrim.anchor_right = 0.5
	scrim.offset_left = -300
	scrim.offset_right = 300
	scrim.offset_top = -40
	scrim.offset_bottom = 380
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(scrim)
	# the name, brushed across the open sky in the middle of the vista
	_title = TextureRect.new()
	_title.texture = Assets.tex("res://assets/ui/title_hanzi.png")
	_title.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_title.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_title.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_title.anchor_left = 0.5
	_title.anchor_right = 0.5
	_title.offset_left = -70
	_title.offset_right = 70
	_title.offset_top = 22
	_title.offset_bottom = 272
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_title)
	_name = _label(Assets.serif(true), 30, Assets.TEXT, 12, 268)
	_name.text = "THẬP TỰ"
	_sub = _label(Assets.serif(false), 16, Assets.GOLD_PALE, 6, 308)
	_sub.text = "ĐOẠN NGHIỆT"
	_panel = PanelContainer.new()
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = 56
	_panel.offset_right = 336
	_panel.offset_top = -318
	_panel.offset_bottom = -56
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	Assets.paper(_panel)
	root.add_child(_panel)
	menu = VBoxContainer.new()
	menu.add_theme_constant_override("separation", 2)
	_panel.add_child(menu)
	_button("Bắt đầu", "new")
	if Game.checkpoint != "":
		_button("Tiếp tục", "continue")
	_button("Bạch Sơn (bản thử)", "bachson")
	_button("Thiết lập", "settings")
	_button("Thoát", "quit")
	var tag := _foot("Bản thử nghiệm · Chương Mở Đầu", true)
	var hint := _foot("[color=#d8bb7c]↑ ↓[/color] chọn · [color=#d8bb7c]Space[/color] xác nhận · [color=#d8bb7c]F11[/color] toàn màn hình", false)
	_fade = [scrim, _title, _name, _sub, _panel, tag, hint]
	# a board opened over the title (the settings, the naming box) dims what is behind it
	_dim = ColorRect.new()
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.color = Color(0.02, 0.02, 0.03, 0.62)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.visible = false
	root.add_child(_dim)
	settings = SettingsPanel.new()
	settings.anchor_left = 0.5
	settings.anchor_right = 0.5
	settings.anchor_top = 0.5
	settings.anchor_bottom = 0.5
	settings.offset_left = -270
	settings.offset_right = 270
	settings.offset_top = -190
	settings.offset_bottom = 190
	settings.visible = false
	settings.closed.connect(func(): _buttons[0].grab_focus())
	root.add_child(settings)
	_build_name_box()
	await get_tree().process_frame
	_buttons[0].grab_focus()


func _process(_delta: float) -> void:
	_dim.visible = settings.visible or name_box.visible


func _label(font: Font, size: int, col: Color, spacing: int, top: float) -> Label:
	var fv := FontVariation.new()
	fv.base_font = font
	fv.spacing_glyph = spacing
	var l := Label.new()
	l.anchor_left = 0.5
	l.anchor_right = 0.5
	l.offset_left = -400
	l.offset_right = 400
	l.offset_top = top
	l.offset_bottom = top + 40
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", fv)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_shadow_color", Color(0.02, 0.03, 0.05, 0.6))
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.add_theme_constant_override("shadow_outline_size", 2)   # a soft shadow under the letters, not a dark rim round them
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(l)
	return l


func _foot(bbcode: String, right: bool) -> Control:
	## A line at the foot of the screen (the keys, the build) on the lacquer strip of the game's objective line
	## (assets/ui/obj_strip.png, its hồi văn at the outer end, fading inwards), level with the menu board's edge.
	var box := Control.new()
	box.anchor_top = 1.0
	box.anchor_bottom = 1.0
	box.offset_top = -50
	box.offset_bottom = -14
	if right:
		box.anchor_left = 1.0
		box.anchor_right = 1.0
		box.offset_left = -440
		box.offset_right = -40
	else:
		box.offset_left = 40
		box.offset_right = 500
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(box)
	var strip := NinePatchRect.new()
	strip.texture = Assets.tex("res://assets/ui/obj_strip.png")
	strip.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	strip.patch_margin_left = 44
	strip.patch_margin_right = 200
	strip.set_anchors_preset(Control.PRESET_FULL_RECT)
	strip.modulate.a = 0.85
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(strip)
	if right:   # (the strip turned round: its head at the right)
		strip.pivot_offset = Vector2(200, 18)
		strip.scale = Vector2(-1, 1)
	var t := RichTextLabel.new()
	t.bbcode_enabled = true
	t.fit_content = true
	t.scroll_active = false
	t.autowrap_mode = TextServer.AUTOWRAP_OFF
	t.text = ("[right]%s[/right]" % bbcode) if right else bbcode
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	t.offset_left = 18 if right else 52   # (clear of the hồi văn at the strip's head)
	t.offset_right = -52 if right else -18
	t.offset_top = 8
	t.add_theme_font_override("normal_font", Assets.serif(false))
	t.add_theme_font_size_override("normal_font_size", 16)
	t.add_theme_color_override("default_color", Assets.TEXT_SOFT)
	t.add_theme_color_override("font_outline_color", Color(0.03, 0.03, 0.05, 0.55))
	t.add_theme_constant_override("outline_size", 3)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(t)
	return box


func _button(text: String, action: String) -> void:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", Assets.serif(true))
	b.add_theme_font_size_override("font_size", 23)
	b.focus_entered.connect(func(): Audio.sfx("ui_move", -10.0))
	b.pressed.connect(func(): _on(action))
	menu.add_child(b)
	_buttons.append(b)


func _on(action: String) -> void:
	Audio.sfx("ui_ok", -4.0)
	match action:
		"settings":
			settings.open()
		"quit":
			get_tree().quit()
		"new":
			_ask_name()
		_:
			chosen.emit(action)


func leave() -> void:
	## Before the cut: the menu and the words go, the vista stays.
	for b in _buttons:
		b.focus_mode = Control.FOCUS_NONE
		b.disabled = true
	name_box.visible = false
	var tw := create_tween().set_parallel(true)
	for c in _fade:
		tw.tween_property(c, "modulate:a", 0.0, 0.08 if Game.fast else 0.35)
	await tw.finished


func _build_name_box() -> void:
	name_box = PanelContainer.new()
	name_box.anchor_left = 0.5
	name_box.anchor_right = 0.5
	name_box.anchor_top = 0.5
	name_box.anchor_bottom = 0.5
	name_box.offset_left = -280
	name_box.offset_right = 280
	name_box.offset_top = -110
	name_box.offset_bottom = 110
	name_box.visible = false
	Assets.paper(name_box)
	root.add_child(name_box)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	name_box.add_child(vb)
	var q := Label.new()
	q.text = "Ông gọi con là gì?"
	q.add_theme_font_override("font", Assets.serif(true))
	q.add_theme_font_size_override("font_size", 26)
	vb.add_child(q)
	name_edit = LineEdit.new()
	name_edit.text = "Bến"
	name_edit.max_length = 14
	name_edit.custom_minimum_size = Vector2(0, 54)
	name_edit.add_theme_font_size_override("font_size", 26)
	name_edit.text_submitted.connect(func(_t): _confirm_name())
	vb.add_child(name_edit)
	var h := Label.new()
	h.text = "Gõ tên rồi nhấn Enter. Tên này có thể đổi ở lần chơi sau."
	h.add_theme_font_size_override("font_size", 17)
	h.add_theme_color_override("font_color", Assets.TEXT_SOFT)
	vb.add_child(h)


func _ask_name() -> void:
	name_box.visible = true
	name_edit.grab_focus()
	name_edit.edit()   # (a focused LineEdit only takes typing once it is being edited)
	name_edit.select_all()


func _confirm_name() -> void:
	var n := name_edit.text.strip_edges()
	if n == "":
		n = "Bến"
	Game.player_name = n
	name_box.visible = false
	chosen.emit("new")


func _input(event: InputEvent) -> void:
	# Esc leaves the naming box (before the LineEdit, which would take Esc to stop editing and keep the box open);
	# Backspace stays the LineEdit's, for rubbing out a letter
	if name_box.visible and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		name_edit.unedit()
		name_box.visible = false
		_buttons[0].grab_focus()
