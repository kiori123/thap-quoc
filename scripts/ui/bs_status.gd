extends CanvasLayer
## Bạch Sơn, Part C (docs/N_bach_son.md 9.1): the day and the part of it, and the Ty's suspicion (Nghi), on a small
## lacquer board at the top right. The Nghi bar fills with son.

var _root: Control
var _when: Label
var _bar_bg: Panel
var _bar: Panel
var _hint: Label
var _nghi := 0.0
var _shown := 0.0


func _ready() -> void:
	layer = 31
	_root = PanelContainer.new()
	_root.anchor_left = 1.0
	_root.anchor_right = 1.0
	_root.offset_left = -252
	_root.offset_right = -20
	_root.offset_top = 18
	_root.offset_bottom = 112
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = Assets.theme
	Assets.paper(_root)
	add_child(_root)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	_root.add_child(v)
	_when = Label.new()
	_when.add_theme_font_override("font", Assets.serif(true))
	_when.add_theme_font_size_override("font_size", 20)
	_when.add_theme_color_override("font_color", Assets.TEXT)
	v.add_child(_when)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	v.add_child(row)
	var lab := Label.new()
	lab.text = "Nghi"
	lab.add_theme_font_size_override("font_size", 16)
	lab.add_theme_color_override("font_color", Assets.TEXT_SOFT)
	row.add_child(lab)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(150, 18)
	row.add_child(holder)
	_bar_bg = Panel.new()
	_bar_bg.size = Vector2(150, 12)
	_bar_bg.position = Vector2(0, 4)
	var bars := Assets.bar_styles(Assets.SON)
	_bar_bg.add_theme_stylebox_override("panel", bars[0])
	holder.add_child(_bar_bg)
	_bar = Panel.new()
	_bar.size = Vector2(0, 12)
	_bar.position = Vector2(0, 4)
	_bar.add_theme_stylebox_override("panel", bars[1])
	holder.add_child(_bar)
	_hint = Label.new()
	_hint.text = "Tab: Sổ ghi"
	_hint.add_theme_font_size_override("font_size", 13)
	_hint.add_theme_color_override("font_color", Assets.TEXT_DIM)
	v.add_child(_hint)


func set_when(day: int, part: String) -> void:
	_when.text = "Ngày %d · %s" % [day, part]


func set_nghi(v: float) -> void:
	_nghi = clampf(v, 0.0, 100.0)


func _process(delta: float) -> void:
	_shown = move_toward(_shown, _nghi, delta * 60.0)
	_bar.size.x = 150.0 * _shown / 100.0
	_bar.visible = _shown > 0.5
