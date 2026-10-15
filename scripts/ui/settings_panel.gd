extends PanelContainer
## Settings: music / effects volume, fullscreen, timing assist, text speed. Keyboard navigable.

signal closed

var _first: Control


func _ready() -> void:
	theme = Assets.theme
	custom_minimum_size = Vector2(520, 0)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	add_child(vb)
	var title := Label.new()
	title.text = "Thiết lập"
	title.add_theme_font_override("font", Assets.serif(true))
	title.add_theme_color_override("font_color", Assets.GOLD_PALE)
	title.add_theme_font_size_override("font_size", 28)
	vb.add_child(title)
	_first = _slider(vb, "Âm nhạc", Game.music_vol, 0.0, 1.0, func(v): Game.music_vol = v)
	_slider(vb, "Hiệu ứng", Game.sfx_vol, 0.0, 1.0, func(v): Game.sfx_vol = v)
	_slider(vb, "Tốc độ chữ", Game.text_speed, 0.5, 2.5, func(v): Game.text_speed = v)
	_check(vb, "Toàn màn hình (F11)", Game.fullscreen, func(v): Game.fullscreen = v)
	_check(vb, "Hỗ trợ bấm nhịp (khung bấm rộng hơn)", Game.timing_assist, func(v): Game.timing_assist = v)
	_check(vb, "Đồ họa cao (sương, tia nắng)", Game.quality_high, func(v): Game.quality_high = v)
	var back := Button.new()
	back.text = "◀  Xong"
	back.alignment = HORIZONTAL_ALIGNMENT_LEFT
	back.pressed.connect(_close)
	vb.add_child(back)


func open() -> void:
	visible = true
	if _first:
		_first.grab_focus()


func _close() -> void:
	Game.apply_settings()
	Game.save_settings()
	Audio.sfx("ui_back", -6.0)
	visible = false
	closed.emit()


func _slider(parent: Control, label: String, value: float, lo: float, hi: float, cb: Callable) -> HSlider:
	var hb := HBoxContainer.new()
	var l := Label.new()
	l.text = label
	l.custom_minimum_size = Vector2(200, 0)
	hb.add_child(l)
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = 0.05
	s.value = value
	s.custom_minimum_size = Vector2(260, 24)
	s.value_changed.connect(func(v):
		cb.call(v)
		Game.apply_settings()
	)
	hb.add_child(s)
	parent.add_child(hb)
	return s


func _check(parent: Control, label: String, value: bool, cb: Callable) -> void:
	var c := CheckButton.new()
	c.text = label
	c.button_pressed = value
	c.alignment = HORIZONTAL_ALIGNMENT_LEFT
	c.add_theme_constant_override("h_separation", 24)
	for st in ["normal", "hover", "pressed", "focus", "hover_pressed", "disabled"]:   # no bar behind: the switch says it
		var sb := StyleBoxEmpty.new()
		sb.content_margin_left = 0
		sb.content_margin_top = 4
		sb.content_margin_bottom = 4
		c.add_theme_stylebox_override(st, sb)
	c.add_theme_color_override("font_focus_color", Assets.GOLD_PALE)
	c.add_theme_color_override("font_hover_color", Assets.GOLD_PALE)
	c.add_theme_color_override("font_pressed_color", Assets.TEXT)
	c.add_theme_color_override("font_hover_pressed_color", Assets.GOLD_PALE)
	for k in ["checked", "checked_disabled"]:
		c.add_theme_icon_override(k, Assets.tex("res://assets/ui/toggle_on.png"))
	for k in ["unchecked", "unchecked_disabled"]:
		c.add_theme_icon_override(k, Assets.tex("res://assets/ui/toggle_off.png"))
	c.toggled.connect(func(v):
		cb.call(v)
		Game.apply_settings()
		Audio.sfx("ui_ok", -8.0)
	)
	parent.add_child(c)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("back"):
		get_viewport().set_input_as_handled()
		_close()
