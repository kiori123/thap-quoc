extends CanvasLayer
## Screen-space effects shared by every scene: fades, ink wipe, letterbox bars,
## title cards, the vignette, and the Nối vision (thoáng thấy).

var _fade: ColorRect
var _wipe: ColorRect
var _bar_top: ColorRect
var _bar_bot: ColorRect
var _vignette: ColorRect
var _card: Control
var _card_title: Label
var _card_sub: Label
var _card_brush: TextureRect
var _name: Control              # a big Nghiệt's name, brushed across the lower third when it first appears
var _name_brush: TextureRect
var _name_title: Label
var _name_sub: Label
var _name_seal: ColorRect
var _name_line: ColorRect
var _vision_root: Control
var _vision_img: TextureRect
var _vision_flash: ColorRect
var _vision_text: Label


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_vignette = ColorRect.new()
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vm := ShaderMaterial.new()
	vm.shader = Assets.shader("res://shaders/vignette.gdshader")
	_vignette.material = vm
	add_child(_vignette)

	_bar_top = _mk_bar()
	_bar_bot = _mk_bar()
	_bar_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_bar_bot.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_bar_top.offset_top = 0
	_bar_top.offset_bottom = 0
	_bar_bot.offset_top = 0
	_bar_bot.offset_bottom = 0

	_vision_root = Control.new()
	_vision_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vision_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vision_root.visible = false
	add_child(_vision_root)
	var paper := ColorRect.new()
	paper.color = Color(0.9, 0.88, 0.84)
	paper.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vision_root.add_child(paper)
	_vision_img = TextureRect.new()
	_vision_img.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vision_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vision_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_vision_img.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var vis := ShaderMaterial.new()
	vis.shader = Assets.shader("res://shaders/vision.gdshader")
	_vision_img.material = vis
	_vision_root.add_child(_vision_img)
	_vision_text = Label.new()
	_vision_text.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_vision_text.offset_top = -120
	_vision_text.offset_bottom = -60
	_vision_text.offset_left = -500
	_vision_text.offset_right = 500
	_vision_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vision_text.add_theme_font_override("font", Assets.font(false))
	_vision_text.add_theme_font_size_override("font_size", 32)
	_vision_text.add_theme_color_override("font_color", Color(0.98, 0.96, 0.9))
	_vision_text.add_theme_color_override("font_outline_color", Color(0.06, 0.04, 0.05))
	_vision_text.add_theme_constant_override("outline_size", 12)
	_vision_root.add_child(_vision_text)
	_vision_flash = ColorRect.new()
	_vision_flash.color = Color(1, 1, 1, 0)
	_vision_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vision_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vision_flash)

	_card = Control.new()
	_card.set_anchors_preset(Control.PRESET_FULL_RECT)
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.modulate.a = 0.0
	add_child(_card)
	_card_brush = TextureRect.new()
	_card_brush.texture = Assets.tex("res://assets/ui/band_center.png")   # a band of lacquer (lacquer_ui.py)
	_card_brush.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_card_brush.set_anchors_preset(Control.PRESET_CENTER)
	_card_brush.offset_left = -450
	_card_brush.offset_right = 450
	_card_brush.offset_top = -88 - CARD_UP
	_card_brush.offset_bottom = 62 - CARD_UP
	_card_brush.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_card.add_child(_card_brush)
	_card_title = _mk_label(48, true)
	_card_title.add_theme_color_override("font_color", Assets.GOLD_PALE)
	_card_title.offset_top = -64 - CARD_UP
	_card_title.offset_bottom = 0 - CARD_UP
	_card.add_child(_card_title)
	_card_sub = _mk_label(24, false)
	_card_sub.offset_top = 6 - CARD_UP
	_card_sub.offset_bottom = 46 - CARD_UP
	_card.add_child(_card_sub)

	_wipe = ColorRect.new()
	_wipe.set_anchors_preset(Control.PRESET_FULL_RECT)
	_wipe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var wm := ShaderMaterial.new()
	wm.shader = Assets.shader("res://shaders/wipe.gdshader")
	wm.set_shader_parameter("progress", 0.0)
	wm.set_shader_parameter("noise_tex", Assets.tex("res://assets/tex/water_noise.png"))
	_wipe.material = wm
	add_child(_wipe)

	_fade = ColorRect.new()
	_fade.color = Color(0.03, 0.025, 0.035, 1.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)


func _mk_bar() -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(0.02, 0.018, 0.024)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	return r


func _mk_label(size: int, bold: bool) -> Label:
	var l := Label.new()
	l.set_anchors_preset(Control.PRESET_CENTER)
	l.offset_left = -560
	l.offset_right = 560
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", Assets.serif(bold))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.05))
	l.add_theme_constant_override("outline_size", 8)
	return l


func _shot_soon(n: String, t: float) -> void:
	if not AutoTest.active:
		return
	await get_tree().create_timer(t).timeout
	AutoTest.shot(n)


func flash(col: Color, t := 0.3) -> void:
	## Brief full-screen tint (hits, special attacks).
	_vision_flash.color = col
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_property(_vision_flash, "color:a", 0.0, t)


func set_vignette(strength: float) -> void:
	(_vignette.material as ShaderMaterial).set_shader_parameter("strength", strength)


func fade_out(t := 0.6) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, t * (0.3 if Game.fast else 1.0))
	await tw.finished


func fade_in(t := 0.8) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, t * (0.3 if Game.fast else 1.0))
	await tw.finished


func set_black(on: bool) -> void:
	_fade.color.a = 1.0 if on else 0.0


func wipe_out(t := 0.55) -> void:
	var m := _wipe.material as ShaderMaterial
	var tw := create_tween()
	tw.tween_method(func(v): m.set_shader_parameter("progress", v), 0.0, 1.0, t * (0.4 if Game.fast else 1.0))
	await tw.finished


func wipe_in(t := 0.55) -> void:
	var m := _wipe.material as ShaderMaterial
	var tw := create_tween()
	tw.tween_method(func(v): m.set_shader_parameter("progress", v), 1.0, 0.0, t * (0.4 if Game.fast else 1.0))
	await tw.finished


func letterbox(on: bool, t := 0.5) -> void:
	var h := 64.0 if on else 0.0
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_bar_top, "offset_bottom", h, t)
	tw.tween_property(_bar_bot, "offset_top", -h, t)
	await tw.finished


const CARD_UP := 130.0   # the chapter card sits in the upper third, off the people in the middle of the screen


func card(title: String, sub := "", hold := 2.4) -> void:
	_card_title.text = title
	_card_sub.text = sub
	# always on its band; a card with only the small line (a time of day) has it in the middle of the band
	_card_sub.offset_top = (-38.0 if title == "" else 6.0) - CARD_UP
	_card_sub.offset_bottom = _card_sub.offset_top + 40.0
	move_child(_card, get_child_count() - 1)   # over the fade: a card is often shown while the screen is black
	var tw := create_tween()
	tw.tween_property(_card, "modulate:a", 1.0, 0.9)
	tw.tween_interval(hold * (0.2 if Game.fast else 1.0))
	tw.tween_property(_card, "modulate:a", 0.0, 0.9)
	await tw.finished


func card_busy() -> bool:
	## A card still on screen (fading in, held, or fading out).
	return _card.modulate.a > 0.01


func name_card(title: String, sub := "", hold := 1.8) -> void:
	## Over the live scene: a band of lacquer sweeps in across the lower third, a gold lozenge is set, the name
	## settles on the band with what it is in small letters above.
	if _name == null:
		_build_name_card()
	_name_title.text = title
	_name_sub.text = sub
	_name.modulate.a = 1.0
	_name_brush.scale = Vector2(0.0, 1.0)
	_name_title.modulate.a = 0.0
	_name_sub.modulate.a = 0.0
	_name_seal.modulate.a = 0.0
	_name_seal.scale = Vector2.ONE * 1.8
	_name_line.scale = Vector2(0.0, 1.0)
	_name_title.scale = Vector2.ONE * 1.25
	_name_title.pivot_offset = Vector2(0, 56)
	var title_x := _name_title.position.x
	_name_title.position.x = title_x - 40.0
	var f := 0.3 if Game.fast else 1.0
	var tw := create_tween()
	tw.tween_property(_name_brush, "scale:x", 1.0, 0.4 * f).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_name_title, "modulate:a", 1.0, 0.35 * f).set_delay(0.15 * f)
	tw.parallel().tween_property(_name_title, "position:x", title_x, 0.6 * f).set_delay(0.15 * f).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_name_title, "scale", Vector2.ONE, 0.25 * f).set_delay(0.15 * f).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_name_line, "scale:x", 1.0, 0.5 * f).set_delay(0.4 * f).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_name_sub, "modulate:a", 1.0, 0.4 * f).set_delay(0.35 * f)
	tw.parallel().tween_property(_name_seal, "modulate:a", 1.0, 0.12 * f).set_delay(0.45 * f)
	tw.parallel().tween_property(_name_seal, "scale", Vector2.ONE, 0.18 * f).set_delay(0.45 * f).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(hold * f)
	tw.tween_property(_name, "modulate:a", 0.0, 0.6 * f)
	_shot_soon("name_card", 0.9 * f)
	await tw.finished


func _build_name_card() -> void:
	_name = Control.new()
	_name.set_anchors_preset(Control.PRESET_FULL_RECT)
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name)
	move_child(_name, _fade.get_index())   # under the fade and the wipe
	_name_brush = TextureRect.new()
	_name_brush.texture = Assets.tex("res://assets/ui/band_left.png")   # a band of lacquer (lacquer_ui.py)
	_name_brush.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_name_brush.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_name_brush.anchor_top = 0.66
	_name_brush.anchor_bottom = 0.66
	_name_brush.offset_left = -30
	_name_brush.offset_right = 800
	_name_brush.offset_top = -92
	_name_brush.offset_bottom = 92
	_name_brush.pivot_offset = Vector2(0, 92)
	_name.add_child(_name_brush)
	_name_line = ColorRect.new()   # a thin gold line drawn under the name
	_name_line.color = Color(Assets.GOLD, 0.9)
	_name_line.anchor_top = 0.66
	_name_line.anchor_bottom = 0.66
	_name_line.offset_left = 150
	_name_line.offset_right = 690
	_name_line.offset_top = 48
	_name_line.offset_bottom = 50
	_name_line.pivot_offset = Vector2(0, 1)
	_name.add_child(_name_line)
	_name_seal = ColorRect.new()   # a gold lozenge before the name
	_name_seal.color = Color(Assets.GOLD, 0.95)
	_name_seal.anchor_top = 0.66
	_name_seal.anchor_bottom = 0.66
	_name_seal.offset_left = 104
	_name_seal.offset_right = 122
	_name_seal.offset_top = -4
	_name_seal.offset_bottom = 14
	_name_seal.pivot_offset = Vector2(9, 9)
	_name_seal.rotation = PI * 0.25
	_name.add_child(_name_seal)
	# the name in tall serif capitals, spaced like letters cut in a board
	var fv := FontVariation.new()
	fv.base_font = Assets.serif(true)
	fv.spacing_glyph = 10
	_name_title = Label.new()
	_name_title.add_theme_font_override("font", fv)
	_name_title.add_theme_font_size_override("font_size", 64)
	_name_title.add_theme_color_override("font_color", Assets.GOLD_PALE)
	_name_title.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.05))
	_name_title.add_theme_constant_override("outline_size", 10)
	_name_title.anchor_top = 0.66
	_name_title.anchor_bottom = 0.66
	_name_title.offset_left = 150
	_name_title.offset_right = 950
	_name_title.offset_top = -46
	_name_title.offset_bottom = 60
	_name.add_child(_name_title)
	_name_sub = Label.new()
	_name_sub.add_theme_font_override("font", Assets.serif(false))
	_name_sub.add_theme_font_size_override("font_size", 22)
	_name_sub.add_theme_color_override("font_color", Assets.GOLD)
	_name_sub.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.05))
	_name_sub.add_theme_constant_override("outline_size", 6)
	_name_sub.anchor_top = 0.66
	_name_sub.anchor_bottom = 0.66
	_name_sub.offset_left = 156
	_name_sub.offset_right = 900
	_name_sub.offset_top = -72
	_name_sub.offset_bottom = -42
	_name.add_child(_name_sub)


func vision_stage(stage_script: Script, lines: Array, hold := 1.4) -> void:
	## The Duyên glimpse, staged live: a small 3D scene in its own world, filmed beat by beat through the ink
	## filter. The stage builds itself; each caption starts one of its beats (stage.beat(i) returns its length).
	Audio.sfx("vision", -2.0)
	# go to paper first, then build the little world behind it: its first frames are slow (shaders warming up)
	_vision_flash.color = Color(0.95, 0.93, 0.88, 0.0)
	var m := _vision_img.material as ShaderMaterial
	var tw := create_tween()
	tw.tween_property(_vision_flash, "color:a", 1.0, 0.18)
	await tw.finished
	var stage: Node = stage_script.new()
	add_child(stage)
	for f in 4:
		await get_tree().process_frame
	_vision_img.texture = stage.viewport.get_texture()
	_vision_img.scale = Vector2.ONE
	_vision_root.visible = true
	_vision_text.text = ""
	m.set_shader_parameter("reveal", 0.0)
	tw = create_tween().set_parallel(true)
	tw.tween_property(_vision_flash, "color:a", 0.0, 0.5)
	tw.tween_method(func(v): m.set_shader_parameter("reveal", v), 0.0, 1.0, 1.0)
	var speed := 0.35 if Game.fast else 1.0
	for i in lines.size():
		if i > 0:   # a wash of paper over each cut, so one beat flows into the next
			var dip := create_tween()
			dip.tween_property(_vision_flash, "color:a", 0.8, 0.12)
			await dip.finished
			create_tween().tween_property(_vision_flash, "color:a", 0.0, 0.35)
		var d: float = stage.beat(i)
		_shot_soon("v_stage_%d" % (i + 1), d * 0.6 * speed)
		_vision_text.text = lines[i]
		_vision_text.modulate.a = 0.0
		var t2 := create_tween()
		t2.tween_property(_vision_text, "modulate:a", 1.0, 0.35)
		t2.tween_interval(maxf(d, hold) * speed - 0.7)
		t2.tween_property(_vision_text, "modulate:a", 0.0, 0.35)
		await t2.finished
	tw = create_tween()
	tw.tween_property(_vision_flash, "color:a", 1.0, 0.25)
	await tw.finished
	_vision_root.visible = false
	_vision_img.texture = null
	stage.queue_free()
	tw = create_tween()
	tw.tween_property(_vision_flash, "color:a", 0.0, 0.5)
	await tw.finished


func vision(path: String, lines: Array, hold := 1.6) -> void:
	## The Nối glimpse: white flash, an ink painting that slowly pushes in, whispered lines.
	Audio.sfx("vision", -2.0)
	var m := _vision_img.material as ShaderMaterial
	_vision_img.texture = Assets.tex(path)
	_vision_img.pivot_offset = get_viewport().get_visible_rect().size * 0.5
	_vision_img.scale = Vector2.ONE * 1.02
	var tw := create_tween()
	tw.tween_property(_vision_flash, "color:a", 1.0, 0.18)
	await tw.finished
	_vision_root.visible = true
	_vision_text.text = ""
	m.set_shader_parameter("reveal", 0.0)
	tw = create_tween().set_parallel(true)
	tw.tween_property(_vision_flash, "color:a", 0.0, 0.5)
	tw.tween_method(func(v): m.set_shader_parameter("reveal", v), 0.0, 1.0, 1.2)
	tw.tween_property(_vision_img, "scale", Vector2.ONE * 1.12, 2.0 + hold * lines.size())
	_shot_soon("v_" + path.get_file().get_basename(), 0.9)
	for line in lines:
		_vision_text.text = line
		_vision_text.modulate.a = 0.0
		var t2 := create_tween()
		t2.tween_property(_vision_text, "modulate:a", 1.0, 0.35)
		t2.tween_interval(hold * (0.25 if Game.fast else 1.0))
		t2.tween_property(_vision_text, "modulate:a", 0.0, 0.35)
		await t2.finished
	tw = create_tween()
	tw.tween_property(_vision_flash, "color:a", 1.0, 0.25)
	await tw.finished
	_vision_root.visible = false
	tw = create_tween()
	tw.tween_property(_vision_flash, "color:a", 0.0, 0.5)
	await tw.finished
