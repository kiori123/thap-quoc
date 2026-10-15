extends CanvasLayer
## The Sổ ghi (docs/N_bach_son.md 9.1): no quest list, only what the protagonist has seen, and what two things seen
## together have made them realise (Nhận ra). Opens on a lacquer board over the game (Tab); the game does not stop.

signal closed

var _root: Control
var _card: PanelContainer
var _list: VBoxContainer
var open := false
var nhan_ra: Array = []     # [text]
var notes: Array = []       # [text]


func _ready() -> void:
	layer = 41
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = Assets.theme
	add_child(_root)
	_card = PanelContainer.new()
	_card.anchor_left = 0.5
	_card.anchor_right = 0.5
	_card.anchor_top = 0.5
	_card.anchor_bottom = 0.5
	_card.offset_left = -330
	_card.offset_right = 330
	_card.offset_top = -270
	_card.offset_bottom = 270
	Assets.paper(_card)
	_root.add_child(_card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	_card.add_child(v)
	var t := Label.new()
	t.text = "Sổ ghi"
	t.add_theme_font_override("font", Assets.serif(true))
	t.add_theme_font_size_override("font_size", 32)
	t.add_theme_color_override("font_color", Assets.GOLD_PALE)
	v.add_child(t)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(600, 430)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 5)
	_list.custom_minimum_size = Vector2(590, 0)
	sc.add_child(_list)
	var h := Label.new()
	h.text = "Tab: đóng"
	h.add_theme_font_size_override("font_size", 13)
	h.add_theme_color_override("font_color", Assets.TEXT_DIM)
	v.add_child(h)
	_root.visible = false


func set_entries(nr: Array, ns: Array) -> void:
	nhan_ra = nr
	notes = ns
	if open:
		_fill()


func _line(text: String, size: int, col: Color, bold := false) -> void:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(580, 0)
	l.add_theme_font_override("font", Assets.serif(bold))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	_list.add_child(l)


func _fill() -> void:
	for c in _list.get_children():
		c.queue_free()
	_line("Nhận ra", 22, Assets.GOLD, true)
	if nhan_ra.is_empty():
		_line("(chưa có)", 17, Assets.TEXT_DIM)
	for n in nhan_ra:
		_line("◆ " + str(n), 18, Assets.TEXT, true)
	_line(" ", 8, Assets.TEXT)
	_line("Điều thấy", 22, Assets.GOLD, true)
	if notes.is_empty():
		_line("(chưa có)", 17, Assets.TEXT_DIM)
	for n in notes:
		_line("· " + str(n), 17, Assets.TEXT_SOFT)


func toggle() -> void:
	open = not open
	_root.visible = open
	if open:
		_fill()
		Audio.sfx("ui_ok", -8.0)
	else:
		closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("journal"):
		toggle()
		get_viewport().set_input_as_handled()
	elif open and event.is_action_pressed("back"):
		toggle()
		get_viewport().set_input_as_handled()
