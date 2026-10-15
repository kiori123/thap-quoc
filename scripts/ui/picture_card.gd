extends CanvasLayer
## A thing looked at closely, on a sheet of paper: the painting in the Đền Thầy, a page of the Sổ Tro.
##   var pc = PictureCard.new(); add_child(pc); await pc.open(tex_path, caption) ... await pc.close()

var _card: PanelContainer
var _img: TextureRect
var _cap: Label
var _note: Label


func _ready() -> void:
	layer = 38
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = Assets.theme
	add_child(root)
	_card = PanelContainer.new()
	_card.anchor_left = 0.5
	_card.anchor_right = 0.5
	_card.anchor_top = 0.5
	_card.anchor_bottom = 0.5
	_card.offset_left = -300
	_card.offset_right = 300
	_card.offset_top = -300
	_card.offset_bottom = 150
	Assets.paper(_card)
	root.add_child(_card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	_card.add_child(v)
	_cap = Label.new()
	_cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cap.add_theme_font_override("font", Assets.serif(true))
	_cap.add_theme_font_size_override("font_size", 21)
	_cap.add_theme_color_override("font_color", Assets.GOLD)
	v.add_child(_cap)
	_img = TextureRect.new()
	_img.custom_minimum_size = Vector2(520, 330)
	_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_img.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	v.add_child(_img)
	_note = Label.new()
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note.custom_minimum_size = Vector2(520, 0)
	_note.add_theme_font_size_override("font_size", 17)
	_note.add_theme_color_override("font_color", Assets.TEXT_SOFT)
	v.add_child(_note)
	_card.modulate.a = 0.0


func _fit() -> void:
	## The card as wide and tall as its picture (within 520 x 330), centred.
	var ts: Vector2 = _img.texture.get_size()
	var k := minf(520.0 / ts.x, 330.0 / ts.y)
	var sz := (ts * k).round()
	sz.x = maxf(sz.x, 300.0)
	_img.custom_minimum_size = sz
	_note.custom_minimum_size = Vector2(sz.x, 0)
	var half := sz.x * 0.5 + 40.0
	_card.offset_left = -half
	_card.offset_right = half


func open(tex_path: String, caption := "") -> void:
	_img.texture = Assets.tex(tex_path)
	_fit()
	_cap.text = caption
	_note.text = ""
	var tw := create_tween()
	tw.tween_property(_card, "modulate:a", 1.0, 0.25)
	await tw.finished


func swap(tex_path: String, caption := "") -> void:
	## Turn to another page / another thing, without closing the card.
	var tw := create_tween()
	tw.tween_property(_img, "modulate:a", 0.0, 0.15)
	await tw.finished
	_img.texture = Assets.tex(tex_path)
	_fit()
	if caption != "":
		_cap.text = caption
	_note.text = ""
	tw = create_tween()
	tw.tween_property(_img, "modulate:a", 1.0, 0.2)
	await tw.finished


func note(text: String) -> void:
	_note.text = text


func close() -> void:
	var tw := create_tween()
	tw.tween_property(_card, "modulate:a", 0.0, 0.25)
	await tw.finished
	queue_free()
