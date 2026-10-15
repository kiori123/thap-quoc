extends CanvasLayer
## Esc menu: resume, settings, back to title, quit.

const SettingsPanel = preload("res://scripts/ui/settings_panel.gd")

var root: Control
var panel: PanelContainer
var settings
var enabled := false
var _first: Button


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = Assets.theme
	root.visible = false
	add_child(root)
	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.02, 0.02, 0.03, 0.6)
	root.add_child(shade)
	panel = PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -170
	panel.offset_right = 170
	panel.offset_top = -128
	panel.offset_bottom = 128
	Assets.paper(panel)
	root.add_child(panel)
	var vb := VBoxContainer.new()
	panel.add_child(vb)
	var t := Label.new()
	t.text = "Tạm dừng"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_override("font", Assets.serif(true))
	t.add_theme_color_override("font_color", Assets.GOLD_PALE)
	t.add_theme_font_size_override("font_size", 28)
	vb.add_child(t)
	_first = _btn(vb, "Tiếp tục", _resume)
	_btn(vb, "Thiết lập", func():
		panel.visible = false
		settings.open()
	)
	_btn(vb, "Về màn hình chính", func():
		get_tree().paused = false
		get_tree().reload_current_scene()
	)
	_btn(vb, "Thoát game", func(): get_tree().quit())
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
	settings.closed.connect(func():
		panel.visible = true
		_first.grab_focus()
	)
	root.add_child(settings)


func _btn(parent: Control, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 24)
	b.pressed.connect(func():
		Audio.sfx("ui_ok", -6.0)
		cb.call()
	)
	parent.add_child(b)
	return b


func _resume() -> void:
	root.visible = false
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if not enabled or Game.auto:
		return
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		if root.visible:
			if settings.visible:
				return
			_resume()
		else:
			root.visible = true
			panel.visible = true
			get_tree().paused = true
			_first.grab_focus()
