extends Node
## Loads raw PNG / WAV / TTF files at runtime (no import step needed) and caches them; the interface theme.

var _tex := {}
var _wav := {}
var _font := {}
var _shader := {}
var theme: Theme
# paper and ink: what is written on paper in the world (the Sổ Tro, the stamp on a palm)
const INK := Color(0.13, 0.11, 0.11)
const INK_SOFT := Color(0.38, 0.33, 0.29)
const INK_DIM := Color(0.58, 0.53, 0.47)
const CINNABAR := Color(0.64, 0.18, 0.13)
const PAPER := Color(0.95, 0.91, 0.82)
# lacquer (cổ trang; tools/art/lacquer_ui.py): every frame of the interface is black lacquer in a cánh gián band,
# ruled in gold; words on it are the colour of paper, headings gold, a warning in bright son
const TEXT := Color(0.93, 0.89, 0.8)
const TEXT_SOFT := Color(0.78, 0.73, 0.64)
const TEXT_DIM := Color(0.56, 0.52, 0.46)
const GOLD := Color(0.84, 0.7, 0.44)
const GOLD_PALE := Color(0.95, 0.86, 0.64)
const SON := Color(0.88, 0.4, 0.3)
const BLUE := Color(0.62, 0.78, 0.95)    # Tịnh, on lacquer


func _ready() -> void:
	theme = _build_theme()


func tex(path: String, mipmaps := false) -> Texture2D:
	var key := path + ("#m" if mipmaps else "")
	if _tex.has(key):
		return _tex[key]
	var img := Image.load_from_file(path)
	if img == null or img.is_empty():
		push_error("Assets: cannot load image " + path)
		img = Image.create(2, 2, false, Image.FORMAT_RGBA8)
		img.fill(Color.MAGENTA)
	if mipmaps:
		img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_tex[key] = t
	return t


func wav(path: String, loop := false) -> AudioStreamWAV:
	var key := path + ("#loop" if loop else "")
	if _wav.has(key):
		return _wav[key]
	var bytes := FileAccess.get_file_as_bytes(path)
	var s := AudioStreamWAV.new()
	if bytes.size() < 44:
		push_error("Assets: cannot load wav " + path)
		return s
	var pos := 12
	var channels := 1
	var rate := 32000
	var bits := 16
	var data := PackedByteArray()
	while pos + 8 <= bytes.size():
		var id := bytes.slice(pos, pos + 4).get_string_from_ascii()
		var size := bytes.decode_u32(pos + 4)
		var body := pos + 8
		if id == "fmt ":
			channels = bytes.decode_u16(body + 2)
			rate = bytes.decode_u32(body + 4)
			bits = bytes.decode_u16(body + 14)
		elif id == "data":
			data = bytes.slice(body, body + size)
		pos = body + size + (size % 2)
	s.format = AudioStreamWAV.FORMAT_16_BITS if bits == 16 else AudioStreamWAV.FORMAT_8_BITS
	s.mix_rate = rate
	s.stereo = channels == 2
	s.data = data
	if loop:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = data.size() / (2 * channels)
	_wav[key] = s
	return s


func serif(bold := false) -> Font:
	## Noto Serif (OFL), for what is read on paper: dialogue, choices, guides, menus.
	var key := "serif_b" if bold else "serif"
	if _font.has(key):
		return _font[key]
	if not _font.has("serif_file"):
		var f := FontFile.new()
		if f.load_dynamic_font("res://assets/fonts/NotoSerif.ttf") != OK:
			push_error("Assets: cannot load font NotoSerif")
		f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
		_font["serif_file"] = f
	var v := FontVariation.new()
	v.base_font = _font["serif_file"]
	v.variation_opentype = {"wght": 640 if bold else 420}
	_font[key] = v
	return v


func brush() -> Font:
	## Sedgwick Ave Display (OFL), a heavy brush hand: a big Nghiệt's name, the title.
	if not _font.has("brush"):
		var f := FontFile.new()
		if f.load_dynamic_font("res://assets/fonts/SedgwickAveDisplay-Regular.ttf") != OK:
			push_error("Assets: cannot load font SedgwickAveDisplay")
		f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
		_font["brush"] = f
	return _font["brush"]


func font(bold := false) -> FontFile:
	var path := "res://assets/fonts/BeVietnamPro-%s.ttf" % ("Bold" if bold else "Regular")
	if _font.has(path):
		return _font[path]
	var f := FontFile.new()
	var err := f.load_dynamic_font(path)
	if err != OK:
		push_error("Assets: cannot load font " + path)
	f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	f.hinting = TextServer.HINTING_LIGHT
	_font[path] = f
	return f


func shader(path: String) -> Shader:
	if not _shader.has(path):
		_shader[path] = load(path)
	return _shader[path]


func ink_stroke(col: Color) -> StyleBoxTexture:
	## A brush stroke behind a chosen row or choice (tools/art/paper_ui.py ink_stroke), tinted `col`.
	var sb := StyleBoxTexture.new()
	sb.texture = tex("res://assets/ui/ink_stroke.png")
	sb.texture_margin_left = 60
	sb.texture_margin_right = 70
	sb.modulate_color = col
	sb.content_margin_left = 30
	sb.content_margin_right = 40
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb


func lacquer_bar(sel: bool) -> StyleBoxTexture:
	## A lacquer bar under a choice or a menu row (tools/art/lacquer_ui.py choice_bar): black under the others,
	## cánh gián edged brighter, a gold lozenge at each end, under the one picked.
	var sb := StyleBoxTexture.new()
	sb.texture = tex("res://assets/ui/choice_bar_sel.png" if sel else "res://assets/ui/choice_bar.png")
	sb.texture_margin_left = 26
	sb.texture_margin_right = 26
	sb.texture_margin_top = 10
	sb.texture_margin_bottom = 10
	sb.content_margin_left = 30
	sb.content_margin_right = 34
	sb.content_margin_top = 7
	sb.content_margin_bottom = 9
	return sb


func panel_solid() -> StyleBoxTexture:
	## The lacquer board without its see-through field (tools/art/lacquer_ui.py panel, solid): for a lesson over a
	## fight, where bars and marks float behind it.
	var sb := StyleBoxTexture.new()
	sb.texture = tex("res://assets/ui/panel_lacquer_solid.png")
	sb.texture_margin_left = 32
	sb.texture_margin_right = 32
	sb.texture_margin_top = 32
	sb.texture_margin_bottom = 32
	sb.content_margin_left = 30
	sb.content_margin_right = 30
	sb.content_margin_top = 24
	sb.content_margin_bottom = 26
	return sb


func bar_styles(col: Color) -> Array:
	## [trough, fill] for a ProgressBar or a hand-made bar: a dark trough edged in old gold, a fill tinted `col`.
	var bg := StyleBoxTexture.new()
	bg.texture = tex("res://assets/ui/bar_trough.png")
	bg.texture_margin_left = 6
	bg.texture_margin_right = 6
	bg.texture_margin_top = 6
	bg.texture_margin_bottom = 6
	var fg := StyleBoxTexture.new()
	fg.texture = tex("res://assets/ui/bar_fill_flat.png")
	fg.texture_margin_left = 4
	fg.texture_margin_right = 4
	fg.texture_margin_top = 4
	fg.texture_margin_bottom = 4
	fg.modulate_color = col
	return [bg, fg]


func paper(c: CanvasItem) -> CanvasItem:
	## A control drawn on a lacquer frame: smooth filtering (the frames are painted, not pixel art).
	## Pixel icons inside set their own nearest filter.
	c.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return c


func _build_theme() -> Theme:
	var th := Theme.new()
	th.default_font = serif(false)
	th.default_font_size = 22
	# every panel is a board of lacquer, a hồi văn in each corner (tools/art/lacquer_ui.py panel; it was paper and
	# ink, which read as a Tết card); the controls that carry one draw it smoothly (see paper())
	var panel := StyleBoxTexture.new()
	panel.texture = tex("res://assets/ui/panel_lacquer.png")
	panel.texture_margin_left = 32
	panel.texture_margin_right = 32
	panel.texture_margin_top = 32
	panel.texture_margin_bottom = 32
	panel.content_margin_left = 30
	panel.content_margin_right = 30
	panel.content_margin_top = 24
	panel.content_margin_bottom = 26
	th.set_stylebox("panel", "PanelContainer", panel)
	th.set_stylebox("panel", "Panel", panel)
	var empty := StyleBoxEmpty.new()
	# the button under the cursor: a lacquer bar behind it, the words gold
	var hover := lacquer_bar(true)
	var normal := StyleBoxEmpty.new()
	normal.content_margin_left = hover.content_margin_left
	normal.content_margin_right = hover.content_margin_right
	normal.content_margin_top = hover.content_margin_top
	normal.content_margin_bottom = hover.content_margin_bottom
	for st in ["normal", "disabled"]:
		th.set_stylebox(st, "Button", normal)
	for st in ["hover", "pressed", "focus", "hover_pressed"]:
		th.set_stylebox(st, "Button", hover)
	th.set_color("font_color", "Button", TEXT)
	th.set_color("font_hover_color", "Button", GOLD_PALE)
	th.set_color("font_focus_color", "Button", GOLD_PALE)
	th.set_color("font_pressed_color", "Button", GOLD_PALE)
	th.set_color("font_hover_pressed_color", "Button", GOLD_PALE)
	th.set_color("font_disabled_color", "Button", TEXT_DIM)
	th.set_color("font_color", "Label", TEXT)
	th.set_color("default_color", "RichTextLabel", TEXT)
	th.set_stylebox("normal", "LineEdit", panel)
	th.set_stylebox("focus", "LineEdit", empty)
	th.set_color("font_color", "LineEdit", TEXT)
	th.set_color("caret_color", "LineEdit", GOLD)
	th.set_color("selection_color", "LineEdit", Color(GOLD, 0.35))
	var grab := StyleBoxFlat.new()
	grab.bg_color = GOLD
	grab.set_corner_radius_all(3)
	var slider := StyleBoxFlat.new()
	slider.bg_color = Color(0.1, 0.08, 0.07)
	slider.border_color = Color(0.45, 0.35, 0.2)
	slider.set_border_width_all(1)
	slider.content_margin_top = 3
	slider.content_margin_bottom = 3
	th.set_stylebox("slider", "HSlider", slider)
	th.set_stylebox("grabber_area", "HSlider", grab)
	th.set_stylebox("grabber_area_highlight", "HSlider", grab)
	return th
