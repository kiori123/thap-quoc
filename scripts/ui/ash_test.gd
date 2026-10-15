extends CanvasLayer
## Thử Tro, seen close (docs/N_bach_son.md 4.2, 9.2): the palm laid on a sheet of paper; ash rubbed into the palm
## and the wrist; the hand held still while it is done (the story runs the yoke's rhythm, the tremor of a
## frightened hand); water from the head spring poured over; what the ash still clings to is what is left.
##   var at = AshTest.new(); add_child(at); await at.open()
##   await at.rub(); ...; await at.wash(0.6); await at.stamp("XÁM"); await at.close()

var _root: Control
var _card: PanelContainer
var _palm: TextureRect
var _ash: TextureRect
var _streak: TextureRect
var _stamp: PanelContainer   # the cinnabar seal the Ty presses on the paper, in the corner, clear of the hand
var _stamp_text: Label
var _caption: Label
var _shake := 0.0


func _ready() -> void:
	layer = 38
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
	_card.offset_left = -470
	_card.offset_right = -130
	_card.offset_top = -250
	_card.offset_bottom = 124
	Assets.paper(_card)
	_root.add_child(_card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	_card.add_child(v)
	_caption = Label.new()
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.add_theme_font_override("font", Assets.serif(true))
	_caption.add_theme_font_size_override("font_size", 22)
	_caption.add_theme_color_override("font_color", Assets.GOLD)
	v.add_child(_caption)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(256, 288)
	v.add_child(holder)
	# the khám sư's sheet: the palm is read, and stamped, on paper laid on the board
	var sheet := Panel.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.92, 0.88, 0.79)
	ps.border_color = Color(0.55, 0.47, 0.34)
	ps.set_border_width_all(1)
	sheet.add_theme_stylebox_override("panel", ps)
	sheet.position = Vector2(2, -4)
	sheet.size = Vector2(274, 296)
	holder.add_child(sheet)
	for i in 3:
		var tr := TextureRect.new()
		tr.texture = Assets.tex(["res://assets/ui/palm.png", "res://assets/ui/palm_streak.png", "res://assets/ui/palm_ash.png"][i])
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.size = Vector2(256, 288)
		tr.position = Vector2(10, 0)
		holder.add_child(tr)
		match i:
			0: _palm = tr
			1: _streak = tr
			2: _ash = tr
	_streak.modulate.a = 0.0
	_ash.modulate.a = 0.0
	_stamp = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(Assets.CINNABAR, 0.08)
	sb.border_color = Assets.CINNABAR
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 12   # room for the stacked marks over Ắ
	sb.content_margin_bottom = 2
	_stamp.add_theme_stylebox_override("panel", sb)
	_stamp_text = Label.new()
	_stamp_text.add_theme_font_override("font", Assets.serif(true))
	_stamp_text.add_theme_font_size_override("font_size", 36)
	_stamp_text.add_theme_color_override("font_color", Assets.CINNABAR)
	_stamp.add_child(_stamp_text)
	_stamp.position = Vector2(176, 226)
	_stamp.rotation = -0.1
	_stamp.modulate.a = 0.0
	holder.add_child(_stamp)
	_card.modulate.a = 0.0


func _process(delta: float) -> void:
	if _palm == null:
		return
	_shake = maxf(0.0, _shake - delta * 2.0)
	var o := Vector2(sin(Time.get_ticks_msec() * 0.06) * 3.0, cos(Time.get_ticks_msec() * 0.047) * 2.0) * _shake
	for tr in [_palm, _streak, _ash]:
		tr.position = Vector2(10, 0) + o


func open(caption := "Lòng bàn tay, cổ tay") -> void:
	_caption.text = caption
	var tw := create_tween()
	tw.tween_property(_card, "modulate:a", 1.0, 0.25)
	await tw.finished


func tremble(amount := 1.0) -> void:
	## The hand shakes (a missed beat of the steadying rhythm).
	_shake = maxf(_shake, amount)


func rub(t := 1.0) -> void:
	## Ash from the Lò Thanh rubbed into the palm.
	Audio.sfx("sweep", -8.0, 0.1, 0.7)
	var tw := create_tween()
	tw.tween_property(_ash, "modulate:a", 1.0, t * (0.3 if Game.fast else 1.0))
	await tw.finished


func show_glaze(a := 0.45, t := 0.6) -> void:
	## No ash, no water: what shows of the glaze in the lines of a palm to an eye that knows it (Part D).
	var tw := create_tween()
	tw.tween_property(_streak, "modulate:a", clampf(a, 0.0, 1.0), t * (0.3 if Game.fast else 1.0))
	await tw.finished


func wash(streak: float, t := 1.4) -> void:
	## Water from the head spring: the ash runs off, except where it holds (`streak` = how much stays).
	Audio.sfx("water", -4.0, 0.1)
	var f := 0.3 if Game.fast else 1.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_ash, "modulate:a", 0.0, t * f)
	tw.tween_property(_streak, "modulate:a", clampf(streak, 0.0, 1.0), t * f * 0.8).set_delay(t * f * 0.2)
	await tw.finished


func stamp(text: String) -> void:
	_stamp_text.text = text
	_stamp.reset_size()
	var ss := _stamp.get_combined_minimum_size()
	_stamp.position = Vector2(266.0 - ss.x, 282.0 - ss.y)   # low in the corner, clear of the arm, inside the paper
	_stamp.pivot_offset = _stamp.get_combined_minimum_size() * 0.5
	_stamp.scale = Vector2.ONE * 1.6
	Audio.sfx("chop", -6.0, 0.0, 0.8)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_stamp, "modulate:a", 1.0, 0.08)
	tw.tween_property(_stamp, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished


func clear_stamp() -> void:
	create_tween().tween_property(_stamp, "modulate:a", 0.0, 0.2)


func close() -> void:
	var tw := create_tween()
	tw.tween_property(_card, "modulate:a", 0.0, 0.3)
	await tw.finished
	queue_free()
