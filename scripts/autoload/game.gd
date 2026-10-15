extends Node
## Global state: input map, settings, checkpoint, player name, auto-play flags for testing.

signal settings_changed

const SAVE_PATH := "user://thapquoc.cfg"

var player_name := "Bến"
var flags := {}
var checkpoint := ""          # beat id to resume from ("" = no save)

# settings
var music_vol := 0.8
var sfx_vol := 0.9
var fullscreen := false
var timing_assist := false
var quality_high := true
var text_speed := 1.0         # 1 = normal

# testing / automation (set by AutoTest)
var auto := false             # dialogues advance by themselves, prompts auto-resolve
var auto_timing := "perfect"  # "perfect" | "good" | "miss" | "mixed"
var auto_choice := 0
var fast := false             # shorten waits during automated runs
var watch := false            # automated play at reading speed, to be watched (--watch): words type out, then wait


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	load_settings()
	apply_settings()


func _setup_input() -> void:
	_bind("move_left", [KEY_A, KEY_LEFT], [JOY_BUTTON_DPAD_LEFT], [[JOY_AXIS_LEFT_X, -1.0]])
	_bind("move_right", [KEY_D, KEY_RIGHT], [JOY_BUTTON_DPAD_RIGHT], [[JOY_AXIS_LEFT_X, 1.0]])
	_bind("move_up", [KEY_W, KEY_UP], [JOY_BUTTON_DPAD_UP], [[JOY_AXIS_LEFT_Y, -1.0]])
	_bind("move_down", [KEY_S, KEY_DOWN], [JOY_BUTTON_DPAD_DOWN], [[JOY_AXIS_LEFT_Y, 1.0]])
	_bind("act", [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_E, KEY_J], [JOY_BUTTON_A], [])
	_bind("back", [KEY_ESCAPE, KEY_BACKSPACE, KEY_K], [JOY_BUTTON_B], [])
	_bind("run", [KEY_SHIFT], [JOY_BUTTON_RIGHT_SHOULDER], [])
	_bind("pause", [KEY_ESCAPE, KEY_P], [JOY_BUTTON_START], [])
	_bind("fullscreen", [KEY_F11], [], [])
	_bind("journal", [KEY_TAB, KEY_L], [JOY_BUTTON_Y], [])


func _bind(action: String, keys: Array, buttons: Array, axes: Array) -> void:
	if InputMap.has_action(action):
		InputMap.erase_action(action)
	InputMap.add_action(action, 0.35)
	for k in keys:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(action, e)
	for b in buttons:
		var j := InputEventJoypadButton.new()
		j.button_index = b
		InputMap.action_add_event(action, j)
	for ax in axes:
		var m := InputEventJoypadMotion.new()
		m.axis = ax[0]
		m.axis_value = ax[1]
		InputMap.action_add_event(action, m)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("fullscreen"):
		fullscreen = not fullscreen
		apply_settings()
		save_settings()


func apply_settings() -> void:
	if not DisplayServer.get_name().begins_with("headless"):
		var want := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != want:
			DisplayServer.window_set_mode(want)
	settings_changed.emit()


func load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) != OK:
		return
	music_vol = cf.get_value("settings", "music", music_vol)
	sfx_vol = cf.get_value("settings", "sfx", sfx_vol)
	fullscreen = cf.get_value("settings", "fullscreen", fullscreen)
	timing_assist = cf.get_value("settings", "timing_assist", timing_assist)
	quality_high = cf.get_value("settings", "quality_high", quality_high)
	text_speed = cf.get_value("settings", "text_speed", text_speed)
	checkpoint = cf.get_value("save", "checkpoint", "")
	player_name = cf.get_value("save", "name", player_name)
	flags = cf.get_value("save", "flags", {})


func save_settings() -> void:
	if auto or AutoTest.active:
		return  # automated runs never touch the player's save
	var cf := ConfigFile.new()
	cf.load(SAVE_PATH)
	cf.set_value("settings", "music", music_vol)
	cf.set_value("settings", "sfx", sfx_vol)
	cf.set_value("settings", "fullscreen", fullscreen)
	cf.set_value("settings", "timing_assist", timing_assist)
	cf.set_value("settings", "quality_high", quality_high)
	cf.set_value("settings", "text_speed", text_speed)
	cf.set_value("save", "checkpoint", checkpoint)
	cf.set_value("save", "name", player_name)
	cf.set_value("save", "flags", flags)
	cf.save(SAVE_PATH)


func set_checkpoint(beat: String) -> void:
	checkpoint = beat
	save_settings()


func clear_save() -> void:
	checkpoint = ""
	flags = {}
	save_settings()


func wait(t: float) -> void:
	## await Game.wait(1.0) - shortened in fast automated runs
	await get_tree().create_timer(t * (0.15 if fast else 1.0), false).timeout


func timing_window_scale() -> float:
	return 1.6 if timing_assist else 1.0
