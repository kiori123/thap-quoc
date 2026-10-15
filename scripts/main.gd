extends Node
## The title over its vista (the protagonist sitting on a ledge over the ten countries); play is a cut: they stand,
## cut once, the screen smears along the stroke, and the chosen chapter's world is built while it is dark and comes
## up out of the smear.

const World = preload("res://scripts/world/world.gd")
const Prologue = preload("res://scripts/story/prologue.gd")
const Title = preload("res://scripts/ui/title.gd")
const Pause = preload("res://scripts/ui/pause.gd")
const BachSonWorld = preload("res://scripts/world/bach_son.gd")
const BachSonStory = preload("res://scripts/story/bach_son_story.gd")
const Vista = preload("res://scripts/world/vista.gd")

var world
var pause
var story
var _smear: ColorRect
var _smear_mat: ShaderMaterial


func _ready() -> void:
	Overlay.set_black(true)
	pause = Pause.new()
	add_child(pause)
	_build_smear()
	if AutoTest.active and not AutoTest.scenario in ["title", "title_input"]:
		world = World.new()
		add_child(world)
		await get_tree().process_frame
		await AutoTest.run(self)
		return
	await show_title()


func _build_smear() -> void:
	## The cut's smear (shaders/cut_smear.gdshader): over the 3D picture and the title, under the fade.
	var layer := CanvasLayer.new()
	layer.layer = 85
	add_child(layer)
	_smear = ColorRect.new()
	_smear.set_anchors_preset(Control.PRESET_FULL_RECT)
	_smear.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_smear_mat = ShaderMaterial.new()
	_smear_mat.shader = Assets.shader("res://shaders/cut_smear.gdshader")
	_smear.material = _smear_mat
	_smear.visible = false
	layer.add_child(_smear)


func show_title() -> void:
	world = Vista.new()
	add_child(world)
	world.frame_camera()
	Audio.play_music("village", 2.0)
	var title = Title.new()
	add_child(title)
	await get_tree().process_frame
	await Overlay.fade_in(1.4)
	if AutoTest.active and AutoTest.scenario == "title_input":   # driven by key presses, as a player would
		AutoTest.title_input(self, title)
		var picked: String = await title.chosen
		AutoTest.note("chosen_" + picked)
		await _cut_out(title)
		await _enter(picked)
		return
	if AutoTest.active:   # the title as it looks, and the cut out of it
		await get_tree().create_timer(AutoTest.title_wait).timeout
		await AutoTest.shot("t01_title")
		await _cut_out(title)
		await AutoTest.shot("t04_dark")
		if AutoTest.title_play == "":
			AutoTest.finish()
			return
		await _enter(AutoTest.title_play)   # --title-play=new|bachson: on into the game, as a player would
		AutoTest.note("story_done")
		AutoTest.finish()
		return
	var action: String = await title.chosen
	await _cut_out(title)
	await _enter(action)


func _cut_out(title) -> void:
	## The menu goes; the protagonist stands and cuts: a line of light across the screen where the blade went, held a
	## breath, then the clouds of the sky and the cloud sea part along it, and the camera goes in down the opened
	## channel, the picture smearing as it goes, into the dark.
	Audio.stop_music(1.2)   # the music goes as the protagonist rises: the cut is heard in the quiet
	await title.leave()
	var f := 0.35 if Game.fast else 1.0
	_smear_mat.set_shader_parameter("amount", 0.0)
	_smear_mat.set_shader_parameter("cut", 0.0)
	var vp := get_viewport().get_visible_rect().size
	_smear_mat.set_shader_parameter("origin", world.blade_on_screen() / vp)
	_smear.visible = true
	var struck := func():   # the line across the screen: struck, then held through the breath
		var tw := create_tween()
		tw.tween_method(func(v): _smear_mat.set_shader_parameter("cut", v), 0.0, 1.0, 0.05 * f)
		tw.tween_method(func(v): _smear_mat.set_shader_parameter("cut", v), 1.0, 0.5, 0.3 * f)
	var gives := func():    # it flares as the cloud gives, then goes
		var tw := create_tween()
		tw.tween_method(func(v): _smear_mat.set_shader_parameter("cut", v), 0.5, 1.0, 0.04 * f)
		tw.tween_method(func(v): _smear_mat.set_shader_parameter("cut", v), 1.0, 0.0, 0.6 * f).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await world.cut(struck, gives)
	await get_tree().create_timer(0.12 * f).timeout
	AutoTest.shot("t03_cut")
	await world.part_and_go_in(func():
		var tw := create_tween()
		tw.tween_interval(1.0 * f)
		tw.tween_method(func(v): _smear_mat.set_shader_parameter("amount", v), 0.0, 0.9, 1.1 * f).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	)
	await Overlay.fade_out(0.3)
	AutoTest.note("black")
	title.queue_free()


func _clear_smear() -> void:
	## The new world comes up out of the smear as the story fades it in.
	var tw := create_tween()
	tw.tween_method(func(v): _smear_mat.set_shader_parameter("amount", v), 1.0, 0.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): _smear.visible = false)


func _enter(action: String) -> void:
	AutoTest.note("enter_" + action)
	if world:
		world.queue_free()
		world = null
	await get_tree().process_frame
	if action == "bachson":   # the first chapter, bản thử (docs/N_bach_son.md)
		await start_bach_son("arrive")
		return
	if action == "continue" and Game.checkpoint.begins_with("bs_"):
		await start_bach_son(Game.checkpoint.substr(3))
		return
	if action == "new":
		Game.flags = {}
	world = World.new()
	add_child(world)
	AutoTest.note("world_built")
	await get_tree().process_frame
	await start("morning" if action == "new" else Game.checkpoint)


func start_bach_son(beat := "arrive") -> void:
	## Leave for Bạch Sơn: its own world (scripts/world/bach_son.gd) and chapter script, built while it is dark.
	Overlay.set_black(true)
	if world:
		world.queue_free()
	await get_tree().process_frame
	world = BachSonWorld.new()
	add_child(world)
	await get_tree().process_frame
	while Overlay.card_busy():   # (the title card the prologue ends on, held while this was built)
		await get_tree().process_frame
	pause.enabled = true
	story = BachSonStory.new()
	story.world = world
	story.main = self
	add_child(story)
	if _smear.visible:
		_clear_smear()
	await story.run(beat)
	pause.enabled = false
	if AutoTest.active:
		return
	get_tree().reload_current_scene()


func start(beat: String) -> void:
	pause.enabled = true
	story = Prologue.new()
	story.world = world
	story.main = self
	add_child(story)
	if _smear.visible:
		_clear_smear()
	await story.run(beat)
	pause.enabled = false
	# the prologue ends as the protagonist walks out of Vô Danh Cốc: the road goes on to Bạch Sơn (its first beat is the
	# arrival, "three days after leaving"), unless a test of the prologue alone is running
	if Game.checkpoint == "bs_arrive" and not (AutoTest.active and AutoTest.scenario != "title" and not AutoTest.chain):
		story.queue_free()
		story = null
		await start_bach_son("arrive")
		return
	if AutoTest.active:
		return
	get_tree().reload_current_scene()
