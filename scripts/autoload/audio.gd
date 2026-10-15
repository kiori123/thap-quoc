extends Node
## Music with crossfades + a small pool of sound-effect players.

const MUSIC_GAIN := {"village": -3.0, "night": -3.5, "battle": -4.0, "tension": -1.5}   # (for tools/gen_game_audio.py's levels)

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _current := ""
var _pool: Array[AudioStreamPlayer] = []
var _pool_i := 0
var _tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music_a = AudioStreamPlayer.new()
	_music_b = AudioStreamPlayer.new()
	add_child(_music_a)
	add_child(_music_b)
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	Game.settings_changed.connect(_on_settings)
	# the whole mix up 3 dB (it peaked near -11 dBFS: quiet beside other games), then a ceiling on everything at once,
	# so a blow on top of the music and a voice never clips
	var amp := AudioEffectAmplify.new()
	amp.volume_db = 3.0
	AudioServer.add_bus_effect(0, amp)
	var lim := AudioEffectHardLimiter.new()
	lim.ceiling_db = -0.8
	AudioServer.add_bus_effect(0, lim)


func _music_db(name: String) -> float:
	return MUSIC_GAIN.get(name, 0.0) + linear_to_db(max(Game.music_vol, 0.0001))


func play_music(name: String, fade := 1.5) -> void:
	if name == _current:
		return
	_current = name
	var incoming := _music_b if _music_a.playing else _music_a
	var outgoing := _music_a if incoming == _music_b else _music_b
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	if name != "":
		incoming.stream = Assets.wav("res://assets/audio/music/%s.wav" % name, true)
		incoming.volume_db = -60.0
		incoming.play()
		_tween.tween_property(incoming, "volume_db", _music_db(name), fade)
	if outgoing.playing:
		_tween.tween_property(outgoing, "volume_db", -60.0, fade)
		_tween.chain().tween_callback(outgoing.stop)


func stop_music(fade := 1.5) -> void:
	play_music("", fade)


func current_music() -> String:
	return _current


func sfx(name: String, db := 0.0, pitch_jitter := 0.0, pitch := 1.0) -> void:
	var p := _pool[_pool_i]
	_pool_i = (_pool_i + 1) % _pool.size()
	p.stream = Assets.wav("res://assets/audio/sfx/%s.wav" % name)
	p.volume_db = db + linear_to_db(max(Game.sfx_vol, 0.0001))
	p.pitch_scale = pitch * (1.0 + randf_range(-pitch_jitter, pitch_jitter))
	p.play()


func _on_settings() -> void:
	for p in [_music_a, _music_b]:
		if p.playing and _current != "":
			p.volume_db = _music_db(_current)
