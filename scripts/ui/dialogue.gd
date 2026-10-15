extends CanvasLayer
## Bottom dialogue box: typewriter text, speaker name plate, choices.
## await dialogue.say("Ông", "...") ; var i = await dialogue.choose(["a", "b"])

signal advanced
signal chosen(index: int)

var _root: Control
var _panel: Control
var _frame: TextureRect
var _name_plate: NinePatchRect
var _name: Label
var _text: RichTextLabel
var _arrow: Label
var _choices: VBoxContainer
var _typing := false
var _waiting := false
var _choosing := false
var _choice_i := 0
var _choice_btns: Array[Label] = []
var _t := 0.0
var _last_tick := 0
var open := false
var _reveal: ShaderMaterial
var _reveal_tw: Tween
var _choice_shot := false


func _ready() -> void:
	layer = 40
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = Assets.theme
	add_child(_root)
	# a board of black lacquer in a cánh gián frame, ruled in gold, a hồi văn at each corner (tools/art/lacquer_ui.py;
	# the ink-and-mai box of paper_ui.py read as a Tết card); it opens from the middle like a scroll unrolled
	# (shaders/unroll.gdshader). The picture is drawn at its real size: the box is 940x176 and the picture overhangs
	# it by 30 / 32 px for the shadow.
	_panel = Control.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = -470
	_panel.offset_right = 470
	_panel.offset_top = -200
	_panel.offset_bottom = -24
	_frame = TextureRect.new()
	_frame.texture = Assets.tex("res://assets/ui/dlg_lacquer.png")
	_frame.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_frame.position = Vector2(-30, -32)
	_frame.size = Vector2(1000, 240)
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_frame)
	_reveal = ShaderMaterial.new()
	_reveal.shader = Assets.shader("res://shaders/unroll.gdshader")
	_reveal.set_shader_parameter("reveal", 1.0)
	_frame.material = _reveal
	_root.add_child(_panel)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.scroll_active = false
	_text.position = Vector2(92, 44)
	_text.size = Vector2(770, 110)
	_text.add_theme_font_override("normal_font", Assets.serif(false))
	_text.add_theme_font_override("bold_font", Assets.serif(true))
	_text.add_theme_font_size_override("normal_font_size", 25)
	_text.add_theme_font_size_override("bold_font_size", 25)
	_text.add_theme_constant_override("line_separation", 6)
	_text.add_theme_color_override("default_color", Assets.PAPER)
	_panel.add_child(_text)
	_arrow = Label.new()
	_arrow.text = "▼"
	_arrow.position = Vector2(846, 122)
	_arrow.add_theme_color_override("font_color", GOLD)
	_arrow.add_theme_font_size_override("font_size", 18)
	_panel.add_child(_arrow)
	# the speaker's name on a small plaque of dark son edged in gold, set over the top of the board
	_name_plate = NinePatchRect.new()
	_name_plate.texture = Assets.tex("res://assets/ui/name_plaque.png")
	_name_plate.patch_margin_left = 22
	_name_plate.patch_margin_right = 22
	_name_plate.patch_margin_top = 12
	_name_plate.patch_margin_bottom = 12
	_name_plate.position = Vector2(64, -22)
	_name_plate.size = Vector2(150, 46)
	_name_plate.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_panel.add_child(_name_plate)
	_name = Label.new()
	_name.position = Vector2(0, 1)
	_name.size = Vector2(150, 44)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name.add_theme_font_override("font", Assets.serif(true))
	_name.add_theme_font_size_override("font_size", 21)
	_name.add_theme_color_override("font_color", GOLD_PALE)
	_name_plate.add_child(_name)
	_choices = VBoxContainer.new()
	_choices.anchor_left = 0.5
	_choices.anchor_right = 0.5
	_choices.anchor_top = 1.0
	_choices.anchor_bottom = 1.0
	_choices.offset_left = -260
	_choices.offset_right = 470
	_choices.offset_top = -330
	_choices.offset_bottom = -210
	_choices.alignment = BoxContainer.ALIGNMENT_END
	_choices.add_theme_constant_override("separation", 6)
	_root.add_child(_choices)
	_set_visible(false)


func _set_visible(v: bool) -> void:
	if v and not _panel.visible:
		_open_fx()
	_panel.visible = v
	open = v


func _open_fx() -> void:
	## The board opens from its middle, the words and the name come up with it.
	if _reveal_tw and _reveal_tw.is_valid():
		_reveal_tw.kill()
	_reveal.set_shader_parameter("reveal", 0.0)
	_reveal_tw = create_tween()
	_reveal_tw.tween_method(func(v: float): _reveal.set_shader_parameter("reveal", v), 0.0, 1.0, 0.05 if Game.fast else 0.22) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_frame.modulate.a = 0.0
	_reveal_tw.parallel().tween_property(_frame, "modulate:a", 1.0, 0.05 if Game.fast else 0.16)
	# the words come up with the paper, not before it
	_text.modulate.a = 0.0
	_name_plate.modulate.a = 0.0
	_reveal_tw.parallel().tween_property(_text, "modulate:a", 1.0, 0.05 if Game.fast else 0.26).set_delay(0.03 if Game.fast else 0.08)
	_reveal_tw.parallel().tween_property(_name_plate, "modulate:a", 1.0, 0.05 if Game.fast else 0.22).set_delay(0.0 if Game.fast else 0.12)


func say(speaker: String, text: String) -> void:
	_set_visible(true)
	_name_plate.visible = speaker != ""
	_name.text = speaker
	if speaker != "":   # the seal fits the name
		var w := Assets.serif(true).get_string_size(speaker, HORIZONTAL_ALIGNMENT_LEFT, -1, 21).x
		_name_plate.size.x = maxf(96.0, w + 48.0)
		_name.size.x = _name_plate.size.x
	_text.text = text
	_text.visible_characters = 0
	_arrow.visible = false
	_typing = true
	_waiting = false
	_t = 0.0
	_last_tick = 0
	if Game.auto:
		if Game.watch:   # at reading speed: the words type out, then a pause long enough to read them
			while _typing:
				await get_tree().process_frame
			await get_tree().create_timer(1.1 + text.length() * 0.04).timeout
			_waiting = false
			_arrow.visible = false
			return
		_text.visible_characters = -1
		_typing = false
		await get_tree().create_timer(0.04 if Game.fast else 0.25).timeout
		return
	await advanced


func hide_box() -> void:
	_set_visible(false)


const GOLD := Color(0.84, 0.7, 0.44)
const GOLD_PALE := Color(0.95, 0.86, 0.64)
const CHOICE_DIM := Color(0.84, 0.8, 0.72)
var _sel_box := Assets.lacquer_bar(true)
var _unsel_box := Assets.lacquer_bar(false)


func choose(options: Array) -> int:
	_choosing = true
	_choice_i = 0
	for c in _choices.get_children():
		c.queue_free()
	_choice_btns.clear()
	for i in options.size():
		# each choice on a lacquer bar: black under the others, cánh gián edged brighter under the one picked
		var l := Label.new()
		l.text = str(options[i])
		l.add_theme_font_override("font", Assets.serif(false))
		l.add_theme_font_size_override("font_size", 23)
		l.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		l.size_flags_horizontal = Control.SIZE_SHRINK_END   # each stroke as long as its words, against the right
		_choices.add_child(l)
		_choice_btns.append(l)
	_refresh_choices()
	if Game.auto:
		await get_tree().create_timer(0.05).timeout
		if not _choice_shot:   # the choices as they look, once
			_choice_shot = true
			await AutoTest.shot("choice")
		var pick: int = clamp(Game.auto_choice, 0, options.size() - 1)
		if Game.watch:   # let the choices be read, then the pick move onto its line
			await get_tree().create_timer(2.0).timeout
			_choice_i = pick
			_refresh_choices()
			Audio.sfx("ui_move", -6.0)
			await get_tree().create_timer(0.9).timeout
		_choosing = false
		for c in _choices.get_children():
			c.queue_free()
		return pick
	var idx: int = await chosen
	return idx


func _refresh_choices() -> void:
	for i in _choice_btns.size():
		var l := _choice_btns[i]
		var sel := i == _choice_i
		l.add_theme_color_override("font_color", GOLD_PALE if sel else CHOICE_DIM)
		l.add_theme_stylebox_override("normal", _sel_box if sel else _unsel_box)


func _process(delta: float) -> void:
	if _typing:
		_t += delta * 46.0 * Game.text_speed
		var total := _text.get_total_character_count()
		var shown := int(_t)
		_text.visible_characters = shown
		if shown / 3 != _last_tick:
			_last_tick = shown / 3
			Audio.sfx("text", -10.0, 0.08)
		if shown >= total:
			_typing = false
			_waiting = true
			_text.visible_characters = -1
	if _waiting:   # the ink arrow bobs, waiting
		_arrow.visible = true
		_arrow.position.y = 122.0 + sin(Time.get_ticks_msec() * 0.008) * 3.0


func _unhandled_input(event: InputEvent) -> void:
	if _choosing and not Game.auto:
		if event.is_action_pressed("move_up"):
			_choice_i = (_choice_i - 1 + _choice_btns.size()) % _choice_btns.size()
			_refresh_choices()
			Audio.sfx("ui_move", -6.0)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("move_down"):
			_choice_i = (_choice_i + 1) % _choice_btns.size()
			_refresh_choices()
			Audio.sfx("ui_move", -6.0)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("act"):
			_choosing = false
			Audio.sfx("ui_ok", -4.0)
			for c in _choices.get_children():
				c.queue_free()
			get_viewport().set_input_as_handled()
			chosen.emit(_choice_i)
		return
	if not open:
		return
	if event.is_action_pressed("act"):
		get_viewport().set_input_as_handled()
		if _typing:
			_typing = false
			_waiting = true
			_text.visible_characters = -1
		elif _waiting:
			_waiting = false
			_arrow.visible = false
			advanced.emit()
