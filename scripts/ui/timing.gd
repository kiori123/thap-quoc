extends Control
## Timing prompts shared by chores and battle. Every function is awaited and returns a grade:
## "perfect" | "good" | "miss", and for the stroke and the hold also "over" (went past where it should stop).
## (pendulum returns the number of steadied swings)

signal _done

const GOLD := Color(0.95, 0.78, 0.38)
const RED := Color(0.86, 0.32, 0.24)
const WHITE := Color(0.97, 0.95, 0.9)
const INK := Color(0.09, 0.08, 0.1)
const PAPER := Color(0.93, 0.89, 0.8, 0.88)
const LACQ := Color(0.08, 0.06, 0.06, 0.92)       # the frame of the strip: black lacquer edged in gold
const LINE := INK                                  # the stroke: ink, written on the paper inside

var mode := ""
var center := Vector2(640, 360)
var t := 0.0
var dur := 1.0
var result := ""
var _font: Font
# ring
var ring_target := 30.0
var ring_start := 130.0
# hold
var hold_started := false
var hold_v := 0.0
var zone := Vector2(0.70, 0.88)
var pzone := Vector2(0.76, 0.83)
# defend
var from_pos := Vector2.ZERO
# pendulum
var swings := 6
var swing_i := 0
var swing_pressed := false
var steadied := 0
var spills := 0
var _flash_text := ""
var _flash_col := WHITE
var _flash_t := 0.0
var _auto_pressed := false
var label_hint := ""
var _counter := "Nước"
# stroke (Một nét): hold to draw, release at the mark
var stroke_v := 0.0
var stroke_mark := 0.6
var stroke_fuzz := 0.0
var stroke_started := false
var _hold_t := 0.0
# offer (Nối nét): a short window after a clean stroke to go on
var offer_auto := false
var offer_mark := -1.0        # where the next stroke will stop, laid out on the strip while the window is open
var offer_draw := 1.1         # the next stroke's draw time (its perfect band is drawn to match)
# Bịt Mắt: the eyes glazed over and the field hidden. No ring, no strip, no stop mark: each prompt counts in
# instead, two taps on an even beat, then nothing, and the moment to act (parry, or let go of the stroke or the
# sweep) is the fourth beat. The last thing heard is two beats (0.44 s or more) before the moment, so it cannot
# be caught by reacting: the beat has to be kept through the silence, which is harder than watching a ring.
# The taps are a sound and two dots filling in, so it can be played with the sound off.
var blind := false
# Xem mẫu: the prompt plays itself once, cleanly, so the player sees when to hold and when to let go
var demo := false
var _beats := 0               # taps given so far in this prompt
var _beat_len := 0.0          # length of one beat of the count-in (s)
var _pulse := 0.0             # glow of the last tap, fading
var _blind_prompt := false    # this prompt began blind (eyes glazed over in the middle of one change nothing)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = Assets.serif(true)


func _scale() -> float:
	return Game.timing_window_scale()


func _auto_grade(allow_over := false) -> String:
	match Game.auto_timing:
		"perfect": return "perfect"
		"good": return "good"
		"miss": return "miss"
		"over": return "over" if allow_over else "miss"
	var r := randf()
	if allow_over:
		return "perfect" if r < 0.42 else ("good" if r < 0.7 else ("over" if r < 0.85 else "miss"))
	return "perfect" if r < 0.45 else ("good" if r < 0.8 else "miss")


# ------------------------------------------------------------------ ring
func ring(at: Vector2, duration := 0.95, hint := "Space") -> String:
	mode = "ring"
	_cached_grade = ""
	_auto_pressed = false
	center = at
	dur = duration
	t = 0.0
	result = ""
	label_hint = hint
	_auto_pressed = false
	visible = true
	await _done
	return result


func _ring_radius() -> float:
	return lerpf(ring_start, 0.0, clampf(t / dur, 0.0, 1.0))


func _ring_grade() -> String:
	var d := absf(_ring_radius() - ring_target)
	if d <= 7.0 * _scale():
		return "perfect"
	if d <= 18.0 * _scale():
		return "good"
	return "miss"


# ------------------------------------------------------------------ stroke (Một nét)
func stroke(at: Vector2, mark := 0.6, draw_time := 1.1, known := true, hint := "Giữ Space, thả ở vạch", held := false) -> String:
	## The stroke grows (and strengthens) while Space is held, faster and faster.
	## Released at the mark: "perfect". A little early: "good". Early: "miss". Past it: "over".
	mode = "stroke"
	_beats = 0
	_beat_len = 0.0
	_blind_prompt = blind
	_cached_grade = ""
	_auto_pressed = false
	center = at
	dur = draw_time
	t = 0.0
	_hold_t = 0.0
	stroke_v = 0.0
	stroke_mark = mark
	stroke_fuzz = 0.0 if known else 0.07
	# `held`: Space is already down from the press that asked for this stroke, so the line starts drawing now
	stroke_started = held and not Game.auto and Input.is_action_pressed("act")
	result = ""
	label_hint = hint
	visible = true
	await _done
	return result


func _stroke_curve(x: float) -> float:
	return pow(clampf(x, 0.0, 1.0), 1.45)


func _stroke_w() -> float:
	return _stroke_w_for(dur)


func _stroke_w_for(draw_time: float) -> float:
	## The perfect band, as a share of the strip. A faster stroke (a chained one) gets a wider band, so the
	## moment to let go lasts as long as on the first stroke instead of shrinking with the speed.
	return 0.045 * _scale() * maxf(1.0, 1.1 / maxf(draw_time, 0.1))


func _stroke_grade() -> String:
	var w := _stroke_w()
	var d := stroke_v - stroke_mark
	if absf(d) <= w:
		return "perfect"
	if d > w:
		return "over"
	if d >= -3.0 * w:
		return "good"
	return "miss"


# ------------------------------------------------------------------ offer (Nối nét)
func offer(window := 1.2, auto_yes := false, hint := "Nhấn giữ Space: nối nét", next_mark := -1.0, next_draw := 1.1) -> bool:
	## After a clean stroke: press (and keep holding) to draw the next stroke, or leave it and stop. The next
	## stroke's stop mark is already on the strip. A press made a moment early (while the blow was landing) and
	## still held when the window opens counts.
	mode = "offer"
	dur = window
	t = 0.0
	result = ""
	label_hint = hint
	offer_auto = auto_yes
	offer_mark = next_mark
	offer_draw = next_draw
	visible = true
	if not Game.auto and Input.is_action_pressed("act"):
		_finish_offer("yes")
	await _done
	return result == "yes"


func _finish_offer(r: String) -> void:
	result = r
	_flash_t = 0.5
	_flash_mode = "stroke"
	_flash_text = "NỐI NÉT" if r == "yes" else "DỪNG TAY"
	_flash_col = GOLD if r == "yes" else Color(0.65, 0.9, 1.0)
	mode = ""
	await get_tree().process_frame
	_done.emit()


# ------------------------------------------------------------------ hold
func hold(at: Vector2, fill_time := 1.15, hint := "Giữ Space") -> String:
	mode = "hold"
	_beats = 0
	_beat_len = 0.0
	_blind_prompt = blind
	_cached_grade = ""
	_auto_pressed = false
	center = at
	dur = fill_time
	t = 0.0
	hold_v = 0.0
	hold_started = false
	result = ""
	label_hint = hint
	var s := _scale()
	zone = Vector2(0.72 - 0.05 * (s - 1.0), 0.88 + 0.04 * (s - 1.0))
	pzone = Vector2(0.77 - 0.03 * (s - 1.0), 0.83 + 0.03 * (s - 1.0))
	visible = true
	await _done
	return result


func _hold_grade() -> String:
	if hold_v >= pzone.x and hold_v <= pzone.y:
		return "perfect"
	if hold_v >= zone.x and hold_v <= zone.y:
		return "good"
	if hold_v > zone.y:
		return "over"
	return "miss"


# ------------------------------------------------------------------ defend
func defend(at: Vector2, origin: Vector2, travel := 0.75, hint := "Space để đỡ") -> String:
	mode = "defend"
	_beats = 0
	_beat_len = 0.0
	_blind_prompt = blind
	_cached_grade = ""
	_auto_pressed = false
	center = at
	from_pos = origin
	dur = travel
	t = 0.0
	result = ""
	label_hint = hint
	visible = true
	await _done
	return result


func close_defend() -> void:
	## The battle has already settled the blow (no press in time): end the prompt now, not a moment later.
	if mode == "defend":
		_finish("miss")


func _defend_grade() -> String:
	var off := absf(t - dur)
	if off <= 0.075 * _scale():
		return "perfect"
	if off <= 0.17 * _scale():
		return "good"
	return "miss"


# ------------------------------------------------------------------ demos (Xem mẫu)
func demo_stroke(at: Vector2, mark := 0.6, draw_time := 1.3, hint := "Giữ Space... thả khi vệt mực chạm vạch vàng") -> void:
	demo = true
	get_tree().create_timer(1.35).timeout.connect(func(): AutoTest.shot("demo_stroke"))
	await stroke(at, mark, draw_time, true, hint)
	await get_tree().create_timer(0.6 if not Game.fast else 0.1).timeout
	demo = false


func demo_hold(at: Vector2, hint := "Giữ Space... thả khi vòng vào khúc vàng") -> void:
	demo = true
	await hold(at, 1.3, hint)
	await get_tree().create_timer(0.6 if not Game.fast else 0.1).timeout
	demo = false


func demo_pendulum(at: Vector2) -> void:
	demo = true
	get_tree().create_timer(1.2).timeout.connect(func(): AutoTest.shot("demo_pendulum"))
	await pendulum(at, 3, 1.4)
	await get_tree().create_timer(0.4 if not Game.fast else 0.1).timeout
	demo = false


# ------------------------------------------------------------------ pendulum (carrying water)
func pendulum(at: Vector2, n := 6, period := 1.25, hint := "Space khi thùng văng ra mép", counter := "Nước") -> int:
	mode = "pendulum"
	_cached_grade = ""
	_auto_pressed = false
	center = at
	swings = n
	swing_i = 0
	swing_pressed = false
	steadied = 0
	spills = 0
	dur = period
	t = 0.0
	label_hint = hint
	_counter = counter
	visible = true
	await _done
	return steadied


func _pend_phase() -> float:
	return fmod(t, dur * 0.5) / (dur * 0.5)


# ------------------------------------------------------------------ loop
func _finish(r: String) -> void:
	result = r
	_flash(r)
	var instant := mode == "stroke" or mode == "hold"
	mode = ""
	if instant:
		# the strike follows the release on the next frame; waiting here made every blow feel late
		await get_tree().process_frame
	else:
		await get_tree().create_timer(0.35 if not Game.fast else 0.05).timeout
	_done.emit()


var _flash_mode := ""


func _flash(r: String) -> void:
	_flash_t = 0.7
	_flash_mode = mode
	var defend := mode == "defend"
	match r:
		"perfect":
			_flash_text = "ĐỠ!" if defend else "DỨT!"
			_flash_col = GOLD
		"good":
			_flash_text = "CHẶN" if defend else "ĐƯỢC"
			_flash_col = WHITE
		"over":
			_flash_text = "QUÁ ĐÀ"
			_flash_col = RED
		_:
			if defend:
				_flash_text = "TRÚNG"
			elif mode == "stroke":
				_flash_text = "NON TAY"
			else:
				_flash_text = "TRƯỢT"
			_flash_col = Color(0.65, 0.65, 0.7)


func _blind_target() -> Vector2:
	## (seconds since the count began, seconds from then to the moment to act); x < 0 while it has not begun.
	match mode:
		"defend":
			return Vector2(t, dur)
		"stroke":
			if stroke_started:
				return Vector2(_hold_t, dur * pow(stroke_mark, 1.0 / 1.45))
		"hold":
			if hold_started:
				return Vector2(hold_v * dur, (pzone.x + pzone.y) * 0.5 * dur)
	return Vector2(-1.0, 1.0)


func _count_in() -> void:
	var bt := _blind_target()
	if bt.x < 0.0:
		return
	if _beats == 0 and _beat_len == 0.0:
		_beat_len = bt.y / 4.0
		_check_blind(bt.y)
	while _beats < 2 and bt.x >= bt.y * float(_beats + 1) / 4.0:
		_beats += 1
		_pulse = 1.0
		Audio.sfx("tick", -3.0 + _beats * 1.5, 0.0, [1.0, 1.12][_beats - 1])


func _check_blind(target: float) -> void:
	## Automated runs: is the count-in fair, and no easier than seeing? The beat must be slow enough to follow
	## (at least 0.2 s); the last tap must come at least 0.4 s before the moment (no catching it by reflex);
	## acting exactly on the fourth beat must be a clean grade; a tenth of a beat off must not be a miss.
	if not AutoTest.active:
		return
	var beat := target / 4.0
	var exact := _grade_at(target)
	var early := _grade_at(target - beat * 0.1)
	var late := _grade_at(target + beat * 0.1)
	var lead := target - 2.0 * beat
	var ok := beat >= 0.2 and lead >= 0.4 and exact == "perfect" and early in ["perfect", "good"] and late in ["perfect", "good"]
	AutoTest.note("blind_%s beat %.0f ms, last tap %.0f ms before, at 4th beat %s, early %s, late %s" % [mode, beat * 1000.0, lead * 1000.0, exact, early, late])
	AutoTest.note("check blind_%s: %s" % [mode, "PASS" if ok else "FAIL"])


func _grade_at(el: float) -> String:
	## The grade this prompt would give for acting `el` seconds after its count began.
	match mode:
		"defend":
			var off := absf(el - dur)
			if off <= 0.075 * _scale():
				return "perfect"
			return "good" if off <= 0.17 * _scale() else "miss"
		"stroke":
			var keep := stroke_v
			stroke_v = _stroke_curve(el / dur)
			var g := _stroke_grade()
			stroke_v = keep
			return g
		"hold":
			var keep2 := hold_v
			hold_v = el / dur
			var g2 := _hold_grade()
			hold_v = keep2
			return g2
	return "miss"


func _process(delta: float) -> void:
	if _flash_t > 0.0:
		_flash_t -= delta
	_pulse = maxf(0.0, _pulse - delta * 3.0)
	queue_redraw()
	if mode == "":
		return
	t += delta
	if _blind_prompt and (mode == "defend" or mode == "stroke" or mode == "hold"):
		_count_in()
	elif mode != "offer":
		_beat_len = 0.0
	match mode:
		"ring":
			if Game.auto and not _auto_pressed:
				var g := _auto_grade()
				var want := 0.0
				match g:
					"perfect": want = (ring_start - ring_target) / ring_start * dur
					"good": want = (ring_start - ring_target - 13.0) / ring_start * dur
					_: want = 0.25 * dur
				if t >= want:
					_auto_pressed = true
					_finish(_ring_grade())
			elif t >= dur * 1.05:
				_finish("miss")
		"hold":
			if Game.auto or demo:
				var lag := 0.7 if demo else 0.0   # the demo shows "Giữ Space" a moment before it presses
				if t < lag:
					return
				if not hold_started:
					hold_started = true
				hold_v = (t - lag) / dur
				var target := (pzone.x + pzone.y) * 0.5
				match _auto_grade_cached(true):
					"good": target = zone.x + 0.01
					"miss": target = 0.4
					"over": target = minf(zone.y + 0.05, 0.99)
				if hold_v >= target:
					_finish(_hold_grade())
			else:
				if not hold_started:
					if t > 4.0:
						_finish("miss")
					return
				hold_v = clampf(hold_v + delta / dur, 0.0, 1.0)
				if hold_v >= 1.0:
					_finish("over")
		"defend":
			if Game.auto and not _auto_pressed:
				var g2 := _auto_grade_cached()
				var want2 := dur
				if g2 == "good":
					want2 = dur + 0.12 * _scale()
				if g2 == "miss":
					want2 = dur + 0.4
				if t >= want2:
					_auto_pressed = true
					_finish(_defend_grade() if g2 != "miss" else "miss")
			elif t > dur + 0.25 * _scale():
				_finish("miss")
		"stroke":
			if Game.auto or demo:
				if demo and t < 0.7:
					return
				if not stroke_started:
					stroke_started = true
					_hold_t = 0.0
				_hold_t += delta
				stroke_v = _stroke_curve(_hold_t / dur)
				var w := _stroke_w()
				var target := stroke_mark
				match _auto_grade_cached(true):
					"good": target = stroke_mark - 2.0 * w
					"miss": target = stroke_mark * 0.45
					"over": target = minf(stroke_mark + 4.0 * w, 0.99)
				if stroke_v >= target:
					stroke_v = target
					_finish(_stroke_grade())
			elif stroke_started:
				_hold_t += delta
				stroke_v = _stroke_curve(_hold_t / dur)
				if stroke_v >= 1.0:
					stroke_v = 1.0
					_finish("over")
			elif t > 5.0:
				_finish("miss")
		"offer":
			if Game.auto and offer_auto and t >= dur * 0.3:
				_finish_offer("yes")
			elif t >= dur:
				_finish_offer("no")
		"pendulum":
			var ph := _pend_phase()
			var idx := int(t / (dur * 0.5))
			if idx != swing_i:
				if not swing_pressed:
					spills += 1
					_flash_t = 0.6
					_flash_text = "Sóng sánh!"
					_flash_col = Color(0.6, 0.75, 0.9)
					Audio.sfx("water", -6.0, 0.1)
				swing_i = idx
				swing_pressed = false
				if swing_i >= swings:
					mode = ""
					_end_later()
					return
			if (Game.auto or demo) and not swing_pressed and ph > 0.9:
				if _auto_grade_cached() != "miss" or randf() < 0.5:
					_pend_press()


var _cached_grade := ""


func _end_later() -> void:
	await get_tree().create_timer(0.3 if not Game.fast else 0.05).timeout
	_done.emit()


func _auto_grade_cached(allow_over := false) -> String:
	if demo:
		return "perfect"
	if _cached_grade == "":
		_cached_grade = _auto_grade(allow_over)
	return _cached_grade


func _pend_press() -> void:
	if swing_pressed:
		return
	swing_pressed = true
	var ph := _pend_phase()
	var window := 0.16 * _scale()
	if ph > 1.0 - window:
		steadied += 1
		_flash_t = 0.5
		_flash_text = "Vững"
		_flash_col = GOLD
		Audio.sfx("ui_ok", -8.0)
	else:
		spills += 1
		_flash_t = 0.5
		_flash_text = "Sớm quá"
		_flash_col = Color(0.65, 0.65, 0.7)
		Audio.sfx("water", -6.0, 0.1)


func _unhandled_input(event: InputEvent) -> void:
	if mode == "" or Game.auto or demo:
		return
	match mode:
		"ring":
			if event.is_action_pressed("act"):
				get_viewport().set_input_as_handled()
				_finish(_ring_grade())
		"hold":
			if event.is_action_pressed("act") and not hold_started:
				get_viewport().set_input_as_handled()
				hold_started = true
				hold_v = 0.0
				Audio.sfx("whoosh", -12.0)
			elif event.is_action_released("act") and hold_started:
				get_viewport().set_input_as_handled()
				_finish(_hold_grade())
		"stroke":
			if event.is_action_pressed("act") and not stroke_started:
				get_viewport().set_input_as_handled()
				stroke_started = true
				_hold_t = 0.0
				Audio.sfx("whoosh", -14.0)
			elif event.is_action_released("act") and stroke_started:
				get_viewport().set_input_as_handled()
				_finish(_stroke_grade())
		"offer":
			if event.is_action_pressed("act"):
				get_viewport().set_input_as_handled()
				_finish_offer("yes")
		"defend":
			if event.is_action_pressed("act"):
				get_viewport().set_input_as_handled()
				if t < dur - 0.25 * _scale():
					_finish("miss")
				else:
					_finish(_defend_grade())
		"pendulum":
			if event.is_action_pressed("act"):
				get_viewport().set_input_as_handled()
				_pend_press()


func _draw() -> void:
	if _flash_t > 0.0:
		var a := clampf(_flash_t / 0.4, 0.0, 1.0)
		var pos := center + Vector2(0, -60 - (0.7 - _flash_t) * 30.0)
		if _flash_mode == "stroke":
			pos = Vector2(get_viewport_rect().size.x * 0.5, get_viewport_rect().size.y - 190.0 - (0.7 - _flash_t) * 40.0)
		_text(_flash_text, pos, 34, Color(_flash_col, a), true)
	if _blind_prompt and (mode == "defend" or mode == "stroke" or mode == "hold"):
		_draw_blind()
		return
	if demo and mode != "":
		var vpd := get_viewport_rect().size
		var tag_at := center + Vector2(0, -96)
		if mode == "stroke":
			tag_at = Vector2(vpd.x * 0.5, vpd.y - 238.0)
		_text("XEM MẪU", tag_at, 22, Color(GOLD, 0.95), true)
	match mode:
		"ring":
			draw_arc(center, ring_target, 0, TAU, 48, Color(WHITE, 0.9), 2.0, true)
			for k in 4:
				var ang := k * TAU / 4.0 + PI / 4.0
				draw_line(center + Vector2.from_angle(ang) * (ring_target - 6), center + Vector2.from_angle(ang) * (ring_target + 6), WHITE, 2.0)
			var r := _ring_radius()
			var col := GOLD if absf(r - ring_target) < 18.0 * _scale() else RED
			draw_arc(center, r, 0, TAU, 64, col, 5.0, true)
			_text(label_hint, center + Vector2(0, 62), 18, Color(WHITE, 0.85))
		"stroke":
			# a strip of paper above the target; the ink line grows across it toward the mark
			# always in the same place (lower middle), so the hand learns it; the target is shown by the camera
			var vp := get_viewport_rect().size
			var x0 := vp.x * 0.5 - 170.0
			var x1 := vp.x * 0.5 + 170.0
			var y := vp.y - 132.0
			_strip(Rect2(x0 - 14.0, y - 20.0, (x1 - x0) + 28.0, 40.0), 1.0)
			draw_line(Vector2(x0, y), Vector2(x1, y), Color(0.55, 0.5, 0.42, 0.5), 1.0)
			var xm := lerpf(x0, x1, stroke_mark)
			if stroke_fuzz > 0.0:
				var fw := stroke_fuzz * (x1 - x0)
				draw_rect(Rect2(xm - fw, y - 17.0, fw * 2.0, 34.0), Color(GOLD, 0.35))
			else:
				var ww := _stroke_w() * (x1 - x0)
				draw_rect(Rect2(xm - ww, y - 17.0, ww * 2.0, 34.0), Color(GOLD, 0.3))
				draw_line(Vector2(xm, y - 18.0), Vector2(xm, y + 18.0), GOLD, 3.0)
			var xv := lerpf(x0, x1, stroke_v)
			var steps := 20
			for i in steps:
				var a := lerpf(x0, xv, float(i) / steps)
				var b := lerpf(x0, xv, float(i + 1) / steps)
				var past := b > xm + 1.0
				var jy: float = sin(t * 45.0 + i * 1.7) * 2.0 if past else 0.0
				draw_line(Vector2(a, y + jy), Vector2(b, y + jy), RED if past else LINE, lerpf(10.0, 5.0, float(i) / steps))
			if stroke_started and mode == "stroke":
				draw_circle(Vector2(xv, y), 5.5, LINE)
			_text(label_hint if not stroke_started else "Thả!", Vector2(vp.x * 0.5, y + 46.0), 18, Color(WHITE, 0.9))
		"offer":
			# the next stroke's strip, already laid out with its new stop mark, so the hand knows where it is going
			# before it commits; the time left burns down under it from both ends toward the middle
			var vo := get_viewport_rect().size
			var ox0 := vo.x * 0.5 - 170.0
			var ox1 := vo.x * 0.5 + 170.0
			var y2 := vo.y - 132.0
			_strip(Rect2(ox0 - 14.0, y2 - 20.0, (ox1 - ox0) + 28.0, 40.0), 0.85)
			draw_line(Vector2(ox0, y2), Vector2(ox1, y2), Color(0.55, 0.5, 0.42, 0.5), 1.0)
			if offer_mark >= 0.0:
				var xm2 := lerpf(ox0, ox1, offer_mark)
				var ww2 := _stroke_w_for(offer_draw) * (ox1 - ox0)
				draw_rect(Rect2(xm2 - ww2, y2 - 17.0, ww2 * 2.0, 34.0), Color(GOLD, 0.3))
				draw_line(Vector2(xm2, y2 - 18.0), Vector2(xm2, y2 + 18.0), GOLD, 3.0)
			var half := 177.0 * (1.0 - clampf(t / dur, 0.0, 1.0))
			draw_rect(Rect2(vo.x * 0.5 - half, y2 + 22.0, half * 2.0, 4.0), Color(GOLD, 0.9))
			var pulse := 0.75 + 0.25 * sin(t * 18.0)
			_text(label_hint, Vector2(vo.x * 0.5, y2 + 48.0), 22, Color(GOLD, pulse), true)
			_text("Để yên: dừng tay, tâm thêm một giọt Tịnh", Vector2(vo.x * 0.5, y2 + 76.0), 16, Color(0.75, 0.9, 1.0, 0.9))
		"hold":
			var rad := 54.0
			var a0 := PI * 0.75
			var span := PI * 1.5
			draw_arc(center, rad, a0, a0 + span, 48, Color(0.1, 0.09, 0.1, 0.8), 12.0, true)
			draw_arc(center, rad, a0 + span * zone.x, a0 + span * zone.y, 24, Color(GOLD, 0.45), 12.0, true)
			draw_arc(center, rad, a0 + span * pzone.x, a0 + span * pzone.y, 16, Color(GOLD, 0.95), 12.0, true)
			if hold_v > 0.0:
				draw_arc(center, rad, a0, a0 + span * minf(hold_v, zone.y), 48, Color(WHITE, 0.95), 6.0, true)
				if hold_v > zone.y:
					draw_arc(center, rad, a0 + span * zone.y, a0 + span * hold_v, 24, RED, 6.0, true)
			_text(label_hint if not hold_started else "Thả!", center + Vector2(0, 80), 18, Color(WHITE, 0.85))
		"defend":
			# a red ring closes on the hero; it meets the white ring exactly when the blow lands
			var k := clampf(t / dur, 0.0, 1.15)
			var near := absf(t - dur) < 0.17 * _scale()
			draw_arc(center, 28, 0, TAU, 40, Color(WHITE, 0.9), 2.5, true)
			var r := lerpf(120.0, 28.0, k)
			var col := GOLD if near else RED
			draw_arc(center, r, 0, TAU, 56, Color(col, clampf(k * 2.0, 0.0, 1.0)), 5.0, true)
			for q in 4:
				var ang := q * TAU / 4.0 + PI / 4.0
				draw_line(center + Vector2.from_angle(ang) * (r + 4), center + Vector2.from_angle(ang) * (r + 14), Color(col, k), 3.0)
			_text(label_hint, center + Vector2(0, 62), 18, Color(WHITE, 0.85))
		"pendulum":
			var w := 220.0
			_strip(Rect2(center + Vector2(-w, -6), Vector2(w * 2, 12)), 1.0)
			var win := 0.16 * _scale()
			draw_rect(Rect2(center + Vector2(-w, -6), Vector2(w * win * 1.6, 12)), Color(GOLD, 0.6))
			draw_rect(Rect2(center + Vector2(w - w * win * 1.6, -6), Vector2(w * win * 1.6, 12)), Color(GOLD, 0.6))
			var ph := _pend_phase()
			var dirn := 1.0 if (int(t / (dur * 0.5)) % 2 == 0) else -1.0
			var x := lerpf(-1.0, 1.0, ph) * dirn
			x = sin(x * PI * 0.5)
			draw_circle(center + Vector2(x * w, 0), 9.0, INK)
			_text(label_hint, center + Vector2(0, 40), 18, Color(WHITE, 0.85))
			_text("%s: %d / %d" % [_counter, max(swings - spills, 0), swings], center + Vector2(0, -34), 18, Color(0.7, 0.85, 1.0))


func _draw_blind() -> void:
	## Bịt Mắt: two dots that fill in with the taps, a silent third beat (a faint dash), and the ring of the
	## fourth beat, the one to act on. Nothing marks the third or fourth beat as it passes.
	var vp := get_viewport_rect().size
	var c := Vector2(vp.x * 0.5, vp.y - 150.0)
	var ink := Color(0.16, 0.2, 0.3)
	for k in 4:
		var p := c + Vector2((k - 1.5) * 46.0, 0)
		if k < 2:
			if k < _beats:
				draw_circle(p, 9.0 + (6.0 * _pulse if k == _beats - 1 else 0.0), ink)
			else:
				draw_arc(p, 9.0, 0, TAU, 24, Color(ink, 0.45), 2.0, true)
		elif k == 2:
			draw_line(p - Vector2(7, 0), p + Vector2(7, 0), Color(ink, 0.35), 2.0)
		else:
			draw_arc(p, 14.0, 0, TAU, 32, Color(ink, 0.6), 3.0, true)
	var started := mode == "defend" or (mode == "stroke" and stroke_started) or (mode == "hold" and hold_started)
	var line := "Hai tiếng gõ, nhịp thứ tư thì đỡ" if mode == "defend" else ("Hai tiếng gõ, nhịp thứ tư thì thả" if started else "Giữ Space")
	_text(line, c + Vector2(0, 44), 20, Color(ink, 0.95))


func _strip(r: Rect2, a: float) -> void:
	## A strip of paper (the stroke is written in ink on it, as the guides say) in a frame of black lacquer, ruled in
	## gold like every board of the interface.
	draw_rect(r.grow(5.0), Color(LACQ, LACQ.a * a))
	draw_rect(r.grow(4.0), Color(GOLD, 0.85 * a), false, 1.5)
	draw_rect(r, Color(PAPER, 0.96 * a))


func _text(s: String, pos: Vector2, size: int, col: Color, big := false) -> void:
	var w := _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var p := pos - Vector2(w * 0.5, 0)
	draw_string_outline(_font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 6 if big else 4, Color(0.04, 0.03, 0.05, col.a))
	draw_string(_font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
