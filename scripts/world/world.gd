extends Node3D
## Vô Danh Cốc: the valley village, built entirely in code as a 2.5D diorama
## (3D terrain, houses and light; pixel sprites for people, plants and props).

const B = preload("res://scripts/world/builder.gd")
const Actor = preload("res://scripts/world/actor.gd")
const Player = preload("res://scripts/world/player.gd")
const CameraRig = preload("res://scripts/world/camera_rig.gd")
const Life = preload("res://scripts/world/life.gd")
const Dialogue = preload("res://scripts/ui/dialogue.gd")
const Hud = preload("res://scripts/ui/hud.gd")

signal interacted(id: String)
signal trigger_entered(id: String)

# --- key places (metres). x east, z south (toward camera), y up
const HOUSE := Vector3(16, 0, -6)
const KITCHEN := Vector3(24, 0, -5.5)
const VILLAGE := Vector3(-8, 0, -6)
const STELE := Vector3(-29.0, 0, -18.4)
const MARKER := Vector3(-35.2, 0, -22.6)
const ROAD_OUT := Vector3(-44.0, 0, -32.0)
const PASS_OUT := Vector2(-0.7263, -0.6874)   # unit vector from the village road toward the marker and beyond

var env: Environment
var world_env: WorldEnvironment
var sun: DirectionalLight3D
var rig
var hero
var dialogue
var hud
var actors := {}
var props := {}
var lights_night: Array[Light3D] = []
var night_nodes: Array[Node3D] = []
var interactables := {}     # id -> {pos, radius, prompt, enabled}
var triggers := {}          # id -> {pos, radius, enabled, inside}
var markers := {}
var control_enabled := false
var time_name := ""
var _cloud_amount := 0.4   # the "cloud_amount" global shader parameter, as last set
var _terrain_mat: ShaderMaterial
var _sky_mat: ShaderMaterial
var _post_mat: ShaderMaterial


func set_diorama(strength: float, centre := 0.56) -> void:
	## How strongly the top and bottom of the frame go soft (HD-2D). Fights turn it down: the Nghiệt stand
	## tall and their heads must stay sharp.
	_post_mat.set_shader_parameter("tilt", strength)
	_post_mat.set_shader_parameter("tilt_centre", centre)
var _lanterns: Array[OmniLight3D] = []
var _lantern_sprites: Array[Sprite3D] = []
var _motes: GPUParticles3D
var _markers: Array[Sprite3D] = []           # gold arrows bobbing over where the player should go next
var _trail: Array[Sprite3D] = []
var _bucket_hang: Node3D                     # the well bucket and its rope, swinging a little under the pulley             # gold arrows laid along the road when the way is long                   # dust in the light, around wherever the camera looks, by day   # the porch lanterns: they swing from their hooks, lit at night
var _mist_mat: FogMaterial
var life
var _active := true


func _ready() -> void:
	_build_environment()
	_build_terrain()
	_build_far_mountains()
	_build_water()
	_build_house()
	_build_kitchen_and_yard()
	_build_village()
	_build_paddies()
	_build_pass()
	_build_vegetation()
	_build_atmosphere()
	_define_markers()
	rig = CameraRig.new()
	add_child(rig)
	hud = Hud.new()
	add_child(hud)
	dialogue = Dialogue.new()
	add_child(dialogue)
	hero = spawn("hero", "res://assets/sprites/chars/hero.png", markers["yard_center"], "down", true)
	rig.follow(hero)
	life = Life.new()
	add_child(life)
	life.setup(self)
	set_time("dawn", true)


# ===================================================================== environment
func _build_environment() -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	_sky_mat = ShaderMaterial.new()
	_sky_mat.shader = Assets.shader("res://shaders/sky.gdshader")
	_sky_mat.set_shader_parameter("noise_tex", Assets.tex("res://assets/tex/clouds.png"))
	_sky_mat.set_shader_parameter("pix", 360.0)   # finer cloud pixels, as on the title: no great steps across the sky
	sky.sky_material = _sky_mat
	sky.process_mode = Sky.PROCESS_MODE_INCREMENTAL
	sky.radiance_size = Sky.RADIANCE_SIZE_64
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_white = 6.0
	env.tonemap_exposure = 1.05
	env.ssao_enabled = true
	env.ssao_radius = 1.4
	env.ssao_intensity = 2.0
	env.ssao_power = 1.6
	# HD-2D bloom: wide and soft, so lit sky, lanterns and sunlit edges glow
	env.glow_enabled = true
	for i in 7:
		env.set_glow_level(i, 1.0 if i >= 1 and i <= 5 else 0.0)
	env.glow_normalized = true
	env.glow_intensity = 0.9
	env.glow_strength = 1.0
	env.glow_bloom = 0.12
	env.glow_hdr_threshold = 0.85
	env.glow_hdr_scale = 2.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	env.fog_enabled = true
	env.fog_sky_affect = 0.25
	# volumetric fog: sun shafts through eaves and leaves, halos round lanterns
	env.volumetric_fog_enabled = Game.quality_high
	env.volumetric_fog_anisotropy = 0.6
	env.volumetric_fog_length = 48.0
	env.volumetric_fog_detail_spread = 2.0
	env.volumetric_fog_ambient_inject = 0.12
	env.volumetric_fog_sky_affect = 0.15
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.04
	env.adjustment_saturation = 1.08
	world_env = WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_split_1 = 0.25
	sun.directional_shadow_max_distance = 55.0
	sun.light_angular_distance = 0.6
	sun.shadow_bias = 0.04
	sun.shadow_normal_bias = 1.2
	sun.light_volumetric_fog_energy = 1.4
	add_child(sun)
	# final grade, drawn under every UI layer
	var post_layer := CanvasLayer.new()
	post_layer.layer = 1
	add_child(post_layer)
	var post := ColorRect.new()
	post.set_anchors_preset(Control.PRESET_FULL_RECT)
	post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_post_mat = ShaderMaterial.new()
	_post_mat.shader = Assets.shader("res://shaders/post.gdshader")
	# a touch of ink-wash, lighter than on the title (which sets its own: scripts/world/vista.gd)
	_post_mat.set_shader_parameter("ink", 0.2)
	_post_mat.set_shader_parameter("paper_tex", Assets.tex("res://assets/tex/cloud_noise.png", true))
	post.material = _post_mat
	post_layer.add_child(post)


const TIMES := {
	"dawn": {"elev": 13.0, "azim": -118.0, "sun": Color(1.0, 0.72, 0.52), "energy": 1.45,
		"top": Color(0.36, 0.46, 0.66), "hor": Color(0.98, 0.76, 0.62), "ground": Color(0.36, 0.31, 0.3),
		"amb": 0.6, "fog": Color(0.88, 0.8, 0.76), "fog_d": 0.0007, "fog_h": 0.25, "fog_hd": 0.04,
		"vfog": 0.0018, "mist": 0.018, "cloud": 0.12, "cover": 0.42, "stars": 0.0,
		"sh": Color(0.9, 0.92, 1.1), "hi": Color(1.09, 0.99, 0.88),
		"sat": 1.06, "vig": 0.42, "night": false},
	"day": {"elev": 46.0, "azim": -140.0, "sun": Color(1.0, 0.95, 0.86), "energy": 1.85,
		"top": Color(0.3, 0.5, 0.82), "hor": Color(0.76, 0.84, 0.9), "ground": Color(0.32, 0.3, 0.27),
		"amb": 0.56, "fog": Color(0.78, 0.84, 0.9), "fog_d": 0.0012, "fog_h": 0.0, "fog_hd": 0.0,
		"vfog": 0.0025, "mist": 0.0, "cloud": 0.3, "cover": 0.4, "stars": 0.0,
		"sh": Color(0.92, 0.97, 1.08), "hi": Color(1.06, 1.01, 0.92),
		"sat": 1.12, "vig": 0.34, "night": false},
	"gloom": {"elev": 30.0, "azim": -160.0, "sun": Color(0.82, 0.86, 0.94), "energy": 0.85,
		"top": Color(0.46, 0.5, 0.58), "hor": Color(0.78, 0.79, 0.8), "ground": Color(0.3, 0.3, 0.3),
		"amb": 0.62, "fog": Color(0.82, 0.84, 0.86), "fog_d": 0.004, "fog_h": 0.8, "fog_hd": 0.06,
		"vfog": 0.012, "mist": 0.07, "cloud": 0.0, "cover": 0.85, "stars": 0.0,
		"sh": Color(0.95, 0.99, 1.05), "hi": Color(1.0, 1.0, 0.99),
		"sat": 0.8, "vig": 0.5, "night": false},
	# Bạch Sơn (scripts/world/bach_son.gd): high, cold, bright, the mist never quite off the ground; lime white
	# (the sun from the south-east: the city faces south, toward the camp, so its fronts take the light and the
	# shadows of the eaves fall up the mountain)
	"highland": {"elev": 42.0, "azim": 28.0, "sun": Color(1.0, 0.91, 0.78), "energy": 1.55,
		"top": Color(0.34, 0.5, 0.78), "hor": Color(0.8, 0.84, 0.9), "ground": Color(0.3, 0.29, 0.28),
		"amb": 0.38, "fog": Color(0.74, 0.8, 0.88), "fog_d": 0.0006, "fog_h": 0.6, "fog_hd": 0.03,
		"vfog": 0.0015, "mist": 0.007, "cloud": 0.32, "cover": 0.58, "stars": 0.0,
		"sh": Color(0.9, 0.95, 1.1), "hi": Color(1.08, 1.0, 0.9),
		"sat": 0.93, "vig": 0.44, "night": false},
	"highland_dusk": {"elev": 7.0, "azim": 70.0, "sun": Color(1.0, 0.66, 0.46), "energy": 1.1,
		"top": Color(0.26, 0.28, 0.44), "hor": Color(0.92, 0.62, 0.5), "ground": Color(0.25, 0.22, 0.24),
		"amb": 0.48, "fog": Color(0.66, 0.56, 0.56), "fog_d": 0.003, "fog_h": 0.6, "fog_hd": 0.05,
		"vfog": 0.006, "mist": 0.04, "cloud": 0.1, "cover": 0.5, "stars": 0.0,
		"sh": Color(0.92, 0.9, 1.1), "hi": Color(1.06, 0.99, 0.9),
		"sat": 0.9, "vig": 0.5, "night": false},
	# Trắng Tay is near: the light goes out of the day, the mist turns the colour of slate, and only the porcelain
	# stays white (it is unshaded, and backlit in the fog)
	"dread": {"elev": 22.0, "azim": -165.0, "sun": Color(0.62, 0.68, 0.84), "energy": 0.55,
		"top": Color(0.14, 0.16, 0.22), "hor": Color(0.34, 0.37, 0.44), "ground": Color(0.12, 0.12, 0.14),
		"amb": 0.4, "fog": Color(0.27, 0.3, 0.37), "fog_d": 0.006, "fog_h": 0.8, "fog_hd": 0.08,
		"vfog": 0.016, "mist": 0.08, "cloud": 0.0, "cover": 0.95, "stars": 0.0,
		"sh": Color(0.9, 0.96, 1.12), "hi": Color(0.98, 1.0, 1.06),
		"sat": 0.62, "vig": 0.66, "night": false},
	"dusk": {"elev": 8.0, "azim": 65.0, "sun": Color(1.0, 0.62, 0.42), "energy": 1.2,
		"top": Color(0.24, 0.26, 0.46), "hor": Color(0.98, 0.58, 0.42), "ground": Color(0.25, 0.2, 0.22),
		"amb": 0.5, "fog": Color(0.7, 0.52, 0.48), "fog_d": 0.0025, "fog_h": 0.5, "fog_hd": 0.04,
		"vfog": 0.004, "mist": 0.02, "cloud": 0.1, "cover": 0.5, "stars": 0.0,
		"sh": Color(0.93, 0.9, 1.1), "hi": Color(1.08, 0.99, 0.88),
		"sat": 1.0, "vig": 0.48, "night": false},
	"night": {"elev": 38.0, "azim": 30.0, "sun": Color(0.5, 0.6, 0.95), "energy": 0.32,
		"top": Color(0.02, 0.03, 0.07), "hor": Color(0.08, 0.1, 0.18), "ground": Color(0.03, 0.03, 0.05),
		"amb": 0.3, "fog": Color(0.1, 0.12, 0.2), "fog_d": 0.004, "fog_h": 0.4, "fog_hd": 0.04,
		"vfog": 0.006, "mist": 0.03, "cloud": 0.0, "cover": 0.3, "stars": 1.0,
		"sh": Color(0.9, 0.95, 1.14), "hi": Color(1.1, 1.0, 0.88),
		"sat": 0.95, "vig": 0.56, "night": true},
	"dawn2": {"elev": 9.0, "azim": -112.0, "sun": Color(1.0, 0.68, 0.6), "energy": 1.3,
		"top": Color(0.42, 0.44, 0.62), "hor": Color(1.0, 0.74, 0.7), "ground": Color(0.38, 0.32, 0.34),
		"amb": 0.62, "fog": Color(0.92, 0.84, 0.84), "fog_d": 0.002, "fog_h": 0.6, "fog_hd": 0.05,
		"vfog": 0.005, "mist": 0.05, "cloud": 0.08, "cover": 0.5, "stars": 0.0,
		"sh": Color(0.92, 0.92, 1.1), "hi": Color(1.08, 0.98, 0.92),
		"sat": 1.02, "vig": 0.46, "night": false},
}


func set_time(name: String, instant := false) -> void:
	time_name = name
	var p: Dictionary = TIMES[name]
	var target_rot := Vector3(-p["elev"], p["azim"], 0)
	var hor: Color = p["hor"]
	var top: Color = p["top"]
	var sky_vals := {
		"top_color": top, "horizon_color": hor, "ground_color": p["ground"],
		"cloud_lit": hor.lerp(Color(1, 1, 1), 0.55), "cloud_shade": top.lerp(hor, 0.35).darkened(0.12),
		"cloud_cover": p["cover"], "stars": p["stars"]}
	var post_vals := {"shadow_tint": p["sh"], "high_tint": p["hi"]}
	var vf: Color = p["fog"]
	if instant or Game.fast:
		sun.rotation_degrees = target_rot
		sun.light_color = p["sun"]
		sun.light_energy = p["energy"]
		for k in sky_vals:
			_sky_mat.set_shader_parameter(k, sky_vals[k])
		for k in post_vals:
			_post_mat.set_shader_parameter(k, post_vals[k])
		env.ambient_light_energy = p["amb"]
		env.fog_light_color = p["fog"]
		env.fog_density = p["fog_d"]
		env.fog_height = p["fog_h"]
		env.fog_height_density = p["fog_hd"]
		env.volumetric_fog_density = p["vfog"]
		_mist_mat.density = p["mist"]
		env.volumetric_fog_albedo = vf.lightened(0.2)
		env.adjustment_saturation = p["sat"]
		RenderingServer.global_shader_parameter_set("cloud_amount", p["cloud"])
		_cloud_amount = p["cloud"]
	else:
		var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
		var d := 2.5
		tw.tween_property(sun, "rotation_degrees", target_rot, d)
		tw.tween_property(sun, "light_color", p["sun"], d)
		tw.tween_property(sun, "light_energy", p["energy"], d)
		for k in sky_vals:
			tw.tween_method(func(v): _sky_mat.set_shader_parameter(k, v), _sky_mat.get_shader_parameter(k), sky_vals[k], d)
		for k in post_vals:
			tw.tween_method(func(v): _post_mat.set_shader_parameter(k, v), _post_mat.get_shader_parameter(k), post_vals[k], d)
		tw.tween_property(env, "ambient_light_energy", p["amb"], d)
		tw.tween_property(env, "fog_light_color", p["fog"], d)
		tw.tween_property(env, "fog_density", p["fog_d"], d)
		tw.tween_property(env, "fog_height", p["fog_h"], d)
		tw.tween_property(env, "fog_height_density", p["fog_hd"], d)
		tw.tween_property(env, "volumetric_fog_density", p["vfog"], d)
		tw.tween_property(_mist_mat, "density", p["mist"], d)
		tw.tween_property(env, "volumetric_fog_albedo", vf.lightened(0.2), d)
		tw.tween_property(env, "adjustment_saturation", p["sat"], d)
		# (from the value kept here: reading a global shader parameter back only works in the editor, and in the game
		# it returned nothing and stopped the rest of this function)
		tw.tween_method(func(v):
			_cloud_amount = v
			RenderingServer.global_shader_parameter_set("cloud_amount", v), _cloud_amount, p["cloud"], d)
	Overlay.set_vignette(p["vig"])
	var night: bool = p["night"]
	for l in lights_night:
		l.visible = night
	for n in night_nodes:
		n.visible = night
	if _motes:
		_motes.visible = not night and name != "gloom" and name != "dread"
	env.glow_hdr_threshold = 0.7 if night else 0.85


# ===================================================================== terrain
func height_at(x: float, z: float) -> float:
	var ex := (x + 4.0) / 47.0
	var ez := (z + 2.0) / (27.0 if z < -2.0 else 31.0)
	var r := sqrt(ex * ex + ez * ez)
	var h := 0.0
	if r > 1.0:
		var th := atan2(ez, ex)
		var ridge := 0.8 + 0.22 * sin(th * 5.0 + 1.3) + 0.14 * sin(th * 11.0 + 0.4)
		h = 34.0 * (1.0 - exp(-pow(r - 1.0, 1.25) * 2.0))
		h *= lerpf(1.0, ridge, smoothstep(1.1, 1.8, r))
		h += (sin(x * 0.23) * cos(z * 0.19) + sin(x * 0.07 + z * 0.11)) * 1.6 * clampf((r - 1.0) * 4.0, 0.0, 1.0)
	# the pass: a road climbing out to the north-west
	var dp := _dist_seg(Vector2(x, z), Vector2(MARKER.x + 4, MARKER.z + 4), Vector2(-75, -60))
	if dp < 7.0:
		var along := clampf((-(x - MARKER.x) - (z - MARKER.z)) * 0.5, 0.0, 999.0)
		var road_h := along * 0.08
		var w := smoothstep(7.0, 3.5, dp)
		h = lerpf(h, minf(h, road_h), w)
	# the clearing outside the marker (where the fight happens): wide and nearly flat
	var cc := Vector2(MARKER.x, MARKER.z) + PASS_OUT * 5.0
	var dc := Vector2(x, z).distance_to(cc)
	if dc < 24.0:
		var wc := smoothstep(24.0, 14.0, dc)
		var floor_h := maxf(0.0, (Vector2(x, z) - Vector2(MARKER.x, MARKER.z)).dot(PASS_OUT)) * 0.03
		h = lerpf(h, minf(h, floor_h), wc)
	# stream channel in the south
	var dz := absf(z - 19.5)
	if dz < 2.0 and r < 1.25:
		h -= 0.5 * (1.0 - dz / 2.0)
	return h


func _dist_seg(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)


const PATHS := [
	[Vector2(15, 7.2), Vector2(11, 9), Vector2(2, 7), Vector2(-5, 2), Vector2(-8, -2)],
	[Vector2(-8, -2), Vector2(-15, -9), Vector2(-23, -13.5), Vector2(-30, -17.5), Vector2(-36, -23.5), Vector2(-48, -36)],
	[Vector2(-8, -2), Vector2(-13, 1), Vector2(-17, 3)],
	[Vector2(2, 7), Vector2(7, 12), Vector2(11, 17)],
	[Vector2(-8, -2), Vector2(-5, -11), Vector2(2, -12.5)],
	[Vector2(-15, -9), Vector2(-20, -11.5)],
]


func _path_weight(x: float, z: float) -> float:
	var best := 99.0
	var p := Vector2(x, z)
	for path in PATHS:
		for i in range(path.size() - 1):
			best = min(best, _dist_seg(p, path[i], path[i + 1]))
	var wobble := sin(x * 1.7) * 0.2 + cos(z * 1.3) * 0.2
	return clamp(1.0 - (best - 0.9 - wobble) / 0.8, 0.0, 1.0)


func _yard_weight(x: float, z: float) -> float:
	var dx: float = max(abs(x - 16.5) - 7.6, 0.0)
	var dz: float = max(abs(z - 1.4) - 5.0, 0.0)
	var d: float = max(dx, dz)
	var inner := 0.0
	# village square under the banyan
	var dv := Vector2(x, z).distance_to(Vector2(VILLAGE.x, VILLAGE.z + 1.0))
	inner = clamp(1.0 - (dv - 4.5) / 1.2, 0.0, 1.0)
	return max(clamp(1.0 - d / 0.9, 0.0, 1.0), inner)


func _build_terrain() -> void:
	var x0 := -84.0
	var z0 := -72.0
	var nx := 168
	var nz := 112
	var step := 1.0
	var verts := PackedVector3Array()
	var cols := PackedColorArray()
	var norms := PackedVector3Array()
	var idx := PackedInt32Array()
	verts.resize((nx + 1) * (nz + 1))
	cols.resize(verts.size())
	norms.resize(verts.size())
	for j in nz + 1:
		for i in nx + 1:
			var x := x0 + i * step
			var z := z0 + j * step
			var h := height_at(x, z)
			var k := j * (nx + 1) + i
			verts[k] = Vector3(x, h, z)
			var hx := height_at(x + 0.5, z) - height_at(x - 0.5, z)
			var hz := height_at(x, z + 0.5) - height_at(x, z - 0.5)
			var n := Vector3(-hx, 1.0, -hz).normalized()
			norms[k] = n
			var slope := 1.0 - n.y
			# grassy slopes broken by outcrops; bare rock only where steep or high
			var rock := clampf((slope - 0.3) * 4.0, 0.0, 1.0)
			var outcrop := sin(x * 0.21 + cos(z * 0.17) * 2.3) * cos(z * 0.19 - sin(x * 0.13) * 1.9)
			if h > 4.0:
				rock = maxf(rock, clampf((outcrop - 0.25) * 3.0, 0.0, 1.0) * clampf((h - 4.0) / 6.0, 0.0, 1.0))
			if h > 22.0:
				rock = maxf(rock, clampf((h - 22.0) / 8.0, 0.0, 0.8))
			var path := _path_weight(x, z) if h < 3.0 else 0.0
			var bank: float = clamp(1.0 - abs(z - 19.5) / 3.2, 0.0, 1.0) if h < 0.6 else 0.0
			cols[k] = Color(max(path, bank * 0.9), _yard_weight(x, z), rock, 1.0)
	for j in nz:
		for i in nx:
			var a := j * (nx + 1) + i
			var b := a + 1
			var c := a + (nx + 1)
			var d := c + 1
			idx.append_array([a, b, c, b, d, c])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance3D.new()
	mi.mesh = am
	_terrain_mat = ShaderMaterial.new()
	_terrain_mat.shader = Assets.shader("res://shaders/terrain.gdshader")
	_terrain_mat.set_shader_parameter("tex_grass", Assets.tex("res://assets/tex/grass.png", true))
	_terrain_mat.set_shader_parameter("tex_dirt", Assets.tex("res://assets/tex/dirt.png", true))
	_terrain_mat.set_shader_parameter("tex_yard", Assets.tex("res://assets/tex/yard.png", true))
	_terrain_mat.set_shader_parameter("tex_rock", Assets.tex("res://assets/tex/rock.png", true))
	_terrain_mat.set_shader_parameter("tex_noise", Assets.tex("res://assets/tex/water_noise.png"))
	_terrain_mat.set_shader_parameter("tex_clouds", Assets.tex("res://assets/tex/clouds.png"))
	_terrain_mat.set_shader_parameter("tile", 0.72)
	mi.material_override = _terrain_mat
	add_child(mi)


func _build_far_mountains() -> void:
	var rock := B.karst_mat(Color(0.6, 0.66, 0.62), Color(0, 0, 0), 1.0)   # the title's limestone, greened with moss
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	for i in 26:
		var a := TAU * i / 26.0 + rng.randf_range(-0.08, 0.08)
		var dist := rng.randf_range(108.0, 150.0)
		var pos := Vector3(cos(a) * dist * 1.1 - 4, 0, sin(a) * dist * 0.85 - 6)
		if pos.z > 30:
			pos.z += 20
		var top_r := rng.randf_range(0.3, 2.5)
		var foot_r := rng.randf_range(26.0, 42.0)
		var hgt := rng.randf_range(52.0, 92.0)
		rng.randf()   # (the old cone's turn: the numbers after it, the pines', stay as they were)
		var own := RandomNumberGenerator.new()
		own.seed = hash(pos)
		B.crag(self, pos + Vector3(0, -6.0, 0), foot_r, maxf(top_r * 3.0, foot_r * 0.18), hgt, rock, own, 18, 10)
	# pines climbing the near slopes (one multimesh, billboarded by the material)
	var t := Assets.tex("res://assets/sprites/props/pine.png")
	var qm := QuadMesh.new()
	qm.size = Vector2(t.get_width(), t.get_height()) * 0.05
	qm.center_offset = Vector3(0, qm.size.y * 0.5, 0)
	var m := StandardMaterial3D.new()
	m.albedo_texture = t
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	m.billboard_keep_scale = true
	m.roughness = 1.0
	qm.material = m
	var pts := []
	for k in 2200:
		var x := rng.randf_range(-84, 84)
		var z := rng.randf_range(-72, 40)
		var h := height_at(x, z)
		var clump := sin(x * 0.17 + 1.1) * cos(z * 0.21 - 0.6)
		if h > 2.5 and h < 30.0 and clump > -0.25:
			pts.append(Vector3(x, h - 0.2, z))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = qm
	mm.instance_count = pts.size()
	for k in pts.size():
		var s := rng.randf_range(0.8, 1.5)
		mm.set_instance_transform(k, Transform3D(Basis().scaled(Vector3(s, s, s)), pts[k]))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)


func _build_water() -> void:
	var wm := ShaderMaterial.new()
	wm.shader = Assets.shader("res://shaders/water.gdshader")
	wm.set_shader_parameter("noise_tex", Assets.tex("res://assets/tex/water_noise.png"))
	var stream := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(170, 4.2)
	stream.mesh = pm
	stream.material_override = wm
	stream.position = Vector3(0, -0.22, 19.5)
	add_child(stream)
	# bamboo bridge + a small landing (the "bến")
	var planks := B.mat("res://assets/tex/planks.png", 1.0, Vector3.ONE, {"triplanar": true})
	B.box(self, Vector3(2.0, 0.14, 5.2), Vector3(6, 0.05, 19.5), planks, 0, false, 0.035)
	for sx in [-0.9, 0.9]:
		for sz in [17.4, 21.6]:
			B.cylinder(self, 0.07, 1.2, Vector3(6 + sx, 0.45, sz), planks, false, 6)
	B.box(self, Vector3(3.0, 0.14, 1.8), Vector3(12.5, 0.06, 17.9), planks, 0, false, 0.035)
	for i in 14:
		B.billboard(self, "res://assets/sprites/props/reeds.png", Vector3(-30 + i * 4.3 + sin(i) * 1.5, -0.1, 17.6 + (i % 3) * 0.3), B.PX, false)


# ===================================================================== the old man's house
func _build_house() -> void:
	var H := HOUSE
	var mud := "res://assets/tex/mudwall.png"
	var plinth := B.mat("res://assets/tex/cobble.png", 0.9, Vector3.ONE, {"triplanar": true, "tint": Color(0.85, 0.82, 0.78)})
	B.box(self, Vector3(11.4, 0.3, 5.9), H + Vector3(0, 0.15, 0.05), plinth, 0, false, 0.035)
	_blocker(Vector3(1.5, 2.5, 0.3), H + Vector3(0, 1.55, 0.85))
	# interior darkness so the doorway and windows read as deep
	var dark := B.color_mat(Color(0.05, 0.04, 0.04))
	dark.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	B.box(self, Vector3(10.4, 2.4, 3.0), H + Vector3(0, 1.5, -0.95), dark, 0, false)
	# walls
	B.tri_box(self, Vector3(11.0, 2.5, 0.25), H + Vector3(0, 1.55, -2.6), mud)
	B.tri_box(self, Vector3(0.25, 2.5, 3.6), H + Vector3(-5.4, 1.55, -0.85), mud)
	B.tri_box(self, Vector3(0.25, 2.5, 3.6), H + Vector3(5.4, 1.55, -0.85), mud)
	var fz := 0.85
	for seg in [[-5.4, -3.2], [-2.0, -0.7], [0.7, 2.0], [3.2, 5.4]]:
		var w: float = seg[1] - seg[0]
		B.tri_box(self, Vector3(w, 2.5, 0.22), H + Vector3((seg[0] + seg[1]) * 0.5, 1.55, fz), mud)
	for wx in [-2.6, 2.6]:
		B.tri_box(self, Vector3(1.2, 0.9, 0.22), H + Vector3(wx, 0.75, fz), mud)
		B.tri_box(self, Vector3(1.2, 0.7, 0.22), H + Vector3(wx, 2.45, fz), mud)
		var lattice := B.mat("res://assets/tex/bamboo_weave.png", 1.6, Vector3.ONE, {"triplanar": true})
		B.box(self, Vector3(1.2, 0.9, 0.06), H + Vector3(wx, 1.65, fz), lattice, 0, false)
	B.tri_box(self, Vector3(1.4, 0.5, 0.22), H + Vector3(0, 2.55, fz), mud)
	# door frame
	var beam := B.mat("res://assets/tex/beam.png", 1.2, Vector3.ONE, {"triplanar": true})
	# timber frame: corner posts and a wall plate under the eaves, stone steps up to the porch
	for wx in [-5.4, 5.4]:
		for wz in [fz, -2.6]:
			B.box(self, Vector3(0.28, 2.6, 0.28), H + Vector3(wx, 1.6, wz), beam, 0, false, 0.04)
	B.box(self, Vector3(11.1, 0.22, 0.32), H + Vector3(0, 2.78, fz), beam, 0, false, 0.04)
	B.box(self, Vector3(2.6, 0.16, 0.5), H + Vector3(0, 0.08, 3.25), plinth, 0, false, 0.05)
	for dx in [-0.72, 0.72]:
		B.box(self, Vector3(0.12, 2.0, 0.28), H + Vector3(dx, 1.3, fz + 0.02), beam, 0, false, 0.035)
	# porch pillars and the main front beam (xà)
	for px in [-5.0, -1.7, 1.7, 5.0]:
		B.cylinder(self, 0.12, 2.5, H + Vector3(px, 1.55, 2.6), beam, true, 8)
		B.box(self, Vector3(0.36, 0.12, 0.36), H + Vector3(px, 0.36, 2.6), plinth, 0, false, 0.035)
	props["beam"] = B.box(self, Vector3(10.8, 0.24, 0.26), H + Vector3(0, 2.32, 2.6), beam, 0, false, 0.035)
	B.box(self, Vector3(10.8, 0.16, 0.2), H + Vector3(0, 2.84, 2.6), beam, 0, false, 0.035)
	B.box(self, Vector3(0.2, 0.2, 2.0), H + Vector3(-5.0, 2.32, 1.7), beam, 0, false, 0.035)
	B.box(self, Vector3(0.2, 0.2, 2.0), H + Vector3(5.0, 2.32, 1.7), beam, 0, false, 0.035)
	# roof
	B.roof(self, 12.4, 4.25, 2.6, 2.85, 5.0, H + Vector3(0, 0, -0.95), "res://assets/tex/thatch.png")
	# porch details: pegs, the dull sword, the mat, coin jar, broom, lanterns
	props["pegs"] = B.sprite_mat_quad(self, "res://assets/tex/pegboard.png", H + Vector3(-1.45, 1.75, fz + 0.13), Vector3.ZERO, 0.022)
	props["sword_wall"] = B.sprite_mat_quad(self, "res://assets/sprites/props/sword_dull.png", H + Vector3(0, 2.18, fz + 0.14), Vector3.ZERO, 0.03)
	var matm := B.mat("res://assets/tex/mat.png", 1.0)
	matm.uv1_scale = Vector3(1.6, 1.0, 1.0)
	B.quad(self, Vector2(2.6, 1.5), H + Vector3(-2.6, 0.315, 1.75), Vector3(-90, 0, 0), matm)
	props["coinjar"] = B.billboard(self, "res://assets/sprites/props/coinjar.png", H + Vector3(3.9, 0.3, 1.25), B.PX)
	props["broom"] = B.billboard(self, "res://assets/sprites/props/broom.png", H + Vector3(-5.35, 0.3, 2.95), B.PX)
	for lx in [-3.3, 3.3]:
		# hung from the eave by a cord: the image hangs below its origin (the hook) so it can swing from there;
		# frames 0-3 lit from inside (the flame flickering), 4 unlit for the day
		var hook: Vector3 = H + Vector3(lx, 2.36, 2.7)
		var lan := B.billboard(self, "res://assets/sprites/props/lantern.png", hook, 0.03, false, 5, 4)   # as tall as the old one
		lan.position = hook
		lan.offset = Vector2(0, -13)
		lan.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		lan.set_meta("hook", hook)
		lan.set_meta("phase", lx * 0.7)
		_lantern_sprites.append(lan)
		var om := OmniLight3D.new()
		om.light_color = Color(1.0, 0.62, 0.36)
		om.light_energy = 2.2
		om.omni_range = 7.5
		om.shadow_enabled = lx < 0
		om.position = H + Vector3(lx, 1.95, 2.95)
		om.set_meta("lantern", _lantern_sprites.size() - 1)
		add_child(om)
		lights_night.append(om)
	props["tray"] = B.billboard(self, "res://assets/sprites/props/tray.png", H + Vector3(-2.7, 0.33, 1.95), 0.024)
	# behind the tray, ten clean bowls laid out upside down (the old man sets them out every evening)
	props["bowl_up"] = B.billboard(self, "res://assets/sprites/props/bowls_ten.png", H + Vector3(-2.65, 0.33, 1.35), 0.022)
	props["tray"].visible = false
	props["bowl_up"].visible = false


func _laundry() -> void:
	## A line of washing at the south edge of the yard, billowing in the gusts.
	var pole := B.mat("res://assets/tex/bamboo_weave.png", 1.0, Vector3.ONE, {"triplanar": true, "tint": Color(0.75, 0.8, 0.55)})
	for x in [19.3, 23.7]:
		B.box(self, Vector3(0.09, 2.0, 0.09), Vector3(x, 1.0, 6.9), pole, 0, false, 0.02)
	B.box(self, Vector3(4.5, 0.025, 0.025), Vector3(21.5, 1.92, 6.9), B.color_mat(Color(0.55, 0.48, 0.38)), 0, false)
	var cloths := ["cloth_a", "cloth_b", "cloth_c"]
	for i in 3:
		var t := Assets.tex("res://assets/sprites/props/%s.png" % cloths[i])
		var qm := QuadMesh.new()
		qm.size = Vector2(t.get_width(), t.get_height()) * 0.042
		qm.subdivide_width = 3
		qm.subdivide_depth = 6
		var sm := ShaderMaterial.new()
		sm.shader = Assets.shader("res://shaders/cloth.gdshader")
		sm.set_shader_parameter("tex", t)
		sm.set_shader_parameter("phase", i * 1.9)
		qm.material = sm
		var mi := MeshInstance3D.new()
		mi.mesh = qm
		mi.position = Vector3(20.2 + i * 1.25, 1.9 - qm.size.y * 0.5, 6.9)
		add_child(mi)


func _build_kitchen_and_yard() -> void:
	_laundry()
	var K := KITCHEN
	var mud := "res://assets/tex/mudwall.png"
	B.tri_box(self, Vector3(3.4, 2.2, 3.0), K + Vector3(0, 1.1, 0), mud)
	var dark := B.color_mat(Color(0.05, 0.04, 0.04))
	dark.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	B.box(self, Vector3(1.0, 1.6, 0.05), K + Vector3(-0.6, 0.85, 1.53), dark, 0, false)
	B.roof(self, 4.0, 2.1, 2.1, 2.2, 3.4, K, "res://assets/tex/thatch.png")
	props["smoke"] = B.particles(self, "res://assets/sprites/props/smoke.png", 14, 4.0, Vector3(0.3, 0.1, 0.3), K + Vector3(0.9, 3.4, 0),
		{"vmin": 0.25, "vmax": 0.5, "smin": 1.0, "smax": 2.6, "size": 0.9, "color": Color(0.85, 0.85, 0.85, 0.55), "turb": 0.4})
	props["chum"] = B.billboard(self, "res://assets/sprites/props/chum.png", K + Vector3(-2.3, 0, 2.2), B.PX)
	props["pots"] = B.billboard(self, "res://assets/sprites/props/pots.png", K + Vector3(1.6, 0, 1.9), B.PX)
	_block(K + Vector3(-2.3, 0, 2.2), 0.45)
	# well
	var stone := B.mat("res://assets/tex/cobble.png", 1.4, Vector3.ONE, {"triplanar": true})
	var W := HOUSE + Vector3(-6.0, 0, 6.2)
	# an open ring of stone (no lid on it), a stone lip round the top, the shaft inside dark, water well down
	var ring := B.cylinder(self, 0.75, 0.85, W + Vector3(0, 0.42, 0), stone, true, 14)
	(ring.mesh as CylinderMesh).cap_top = false
	var stone2: StandardMaterial3D = stone.duplicate()
	stone2.cull_mode = BaseMaterial3D.CULL_DISABLED
	ring.material_override = stone2
	var lip := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.6
	tm.outer_radius = 0.84
	tm.rings = 18
	tm.ring_segments = 6
	lip.mesh = tm
	lip.material_override = stone
	lip.position = W + Vector3(0, 0.86, 0)
	lip.scale = Vector3(1.0, 0.55, 1.0)
	add_child(lip)
	var shaft := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = 0.62
	sm.bottom_radius = 0.62
	sm.height = 0.8
	sm.cap_top = false
	sm.radial_segments = 14
	shaft.mesh = sm
	var shaft_m := StandardMaterial3D.new()
	shaft_m.albedo_color = Color(0.05, 0.05, 0.06)
	shaft_m.cull_mode = BaseMaterial3D.CULL_DISABLED
	shaft_m.roughness = 1.0
	shaft.material_override = shaft_m
	shaft.position = W + Vector3(0, 0.45, 0)
	add_child(shaft)
	var wm := ShaderMaterial.new()
	wm.shader = Assets.shader("res://shaders/water.gdshader")
	wm.set_shader_parameter("noise_tex", Assets.tex("res://assets/tex/water_noise.png"))
	wm.set_shader_parameter("deep", Color(0.04, 0.08, 0.1))
	wm.set_shader_parameter("shallow", Color(0.1, 0.18, 0.2))
	var disc := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.6
	cm.bottom_radius = 0.6
	cm.height = 0.02
	disc.mesh = cm
	disc.material_override = wm
	disc.position = W + Vector3(0, 0.3, 0)
	add_child(disc)
	var wood := B.mat("res://assets/tex/planks.png", 1.4, Vector3.ONE, {"triplanar": true})
	for sx in [-0.85, 0.85]:
		B.box(self, Vector3(0.14, 1.9, 0.14), W + Vector3(sx, 0.95, 0), wood, 0, false, 0.035)
	B.box(self, Vector3(1.9, 0.12, 0.12), W + Vector3(0, 1.85, 0), wood, 0, false, 0.035)
	# a pulley under the middle of the beam; the bucket hangs from it on a rope, lowered half into the open mouth
	# (it sways a little in _animate_ambience)
	var pulley := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.1
	pm.bottom_radius = 0.1
	pm.height = 0.07
	pm.radial_segments = 10
	pulley.mesh = pm
	pulley.material_override = wood
	pulley.rotation_degrees = Vector3(0, 0, 90)
	pulley.position = W + Vector3(0, 1.69, 0)
	add_child(pulley)
	_bucket_hang = Node3D.new()
	_bucket_hang.position = W + Vector3(0, 1.69, 0)
	add_child(_bucket_hang)
	var bucket_px := 0.028
	var bucket_top := 0.8 + 16 * bucket_px    # lowered into the mouth, its top just above the lip
	var rope := MeshInstance3D.new()
	var rm := CylinderMesh.new()
	rm.top_radius = 0.014
	rm.bottom_radius = 0.014
	rm.height = 1.69 - bucket_top
	rm.radial_segments = 5
	rope.mesh = rm
	var rope_m := StandardMaterial3D.new()
	rope_m.albedo_color = Color(0.42, 0.34, 0.21)
	rope_m.roughness = 1.0
	rope.material_override = rope_m
	rope.position = Vector3(0, -(1.69 - bucket_top) * 0.5, 0)
	_bucket_hang.add_child(rope)
	props["bucket"] = B.billboard(_bucket_hang, "res://assets/sprites/props/well_bucket.png", Vector3(0, 0.8 - 1.69, 0), bucket_px, false)
	props["yoke"] = B.billboard(self, "res://assets/sprites/props/yoke.png", W + Vector3(1.4, 0, 0.7), B.PX)
	# woodpile and chopping block
	props["woodpile"] = B.billboard(self, "res://assets/sprites/props/woodpile.png", HOUSE + Vector3(6.4, 0, 4.0), B.PX)
	_block(HOUSE + Vector3(6.4, 0, 4.0), 0.9)
	var blockm := B.mat("res://assets/tex/planks.png", 1.6, Vector3.ONE, {"triplanar": true})
	B.cylinder(self, 0.36, 0.5, HOUSE + Vector3(4.2, 0.25, 5.2), blockm, true, 10)
	var endm := B.mat("res://assets/tex/wood_end.png", 1.0)
	endm.uv1_scale = Vector3.ONE
	B.quad(self, Vector2(0.72, 0.72), HOUSE + Vector3(4.2, 0.505, 5.2), Vector3(-90, 0, 0), endm)
	props["log"] = B.billboard(self, "res://assets/sprites/props/log.png", HOUSE + Vector3(4.2, 0.5, 5.2), B.PX)
	props["log_split"] = B.billboard(self, "res://assets/sprites/props/log_split.png", HOUSE + Vector3(4.2, 0.5, 5.2), B.PX)
	props["log_split"].visible = false
	props["axe_block"] = B.billboard(self, "res://assets/sprites/props/axe_block.png", HOUSE + Vector3(4.5, 0.48, 5.35), B.PX)
	# leaf piles to sweep
	for i in 3:
		var p: Vector3 = HOUSE + [Vector3(-3.4, 0, 4.6), Vector3(-0.4, 0, 6.1), Vector3(2.0, 0, 4.4)][i]
		props["leaves_%d" % i] = B.billboard(self, "res://assets/sprites/props/leaves_pile.png", p, B.PX, false)
	# fence around the yard with a gate on the south side
	var fence := "res://assets/sprites/props/fence.png"
	var fw := 32 * B.PX
	var z_s := 7.6
	var x := 7.9
	while x < 24.6:
		if not (x > 13.9 and x < 16.9):
			B.sprite_mat_quad(self, fence, Vector3(x + fw * 0.5, 0.45, z_s), Vector3.ZERO)
		x += fw
	for zz in range(0, 9):
		var z := -2.6 + zz * fw
		B.sprite_mat_quad(self, fence, Vector3(7.9, 0.45, z + fw * 0.5), Vector3(0, 90, 0))
		B.sprite_mat_quad(self, fence, Vector3(24.8, 0.45, z + fw * 0.5), Vector3(0, 90, 0))
	_wall(Vector3(7.9, 0, 7.6), Vector3(14.0, 0, 7.6))
	_wall(Vector3(16.8, 0, 7.6), Vector3(24.8, 0, 7.6))
	_wall(Vector3(7.9, 0, -2.6), Vector3(7.9, 0, 7.6))
	_wall(Vector3(24.8, 0, -2.6), Vector3(24.8, 0, 7.6))
	props["strawstack"] = B.billboard(self, "res://assets/sprites/props/strawstack.png", Vector3(5.2, 0, -2.0), B.PX * 1.2)
	_block(Vector3(5.2, 0, -2.0), 1.1)


func _wall(a: Vector3, b: Vector3) -> void:
	var mid := (a + b) * 0.5
	var length := a.distance_to(b)
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(length if absf(a.z - b.z) < 0.01 else 0.2, 2.0, 0.2 if absf(a.z - b.z) < 0.01 else length)
	cs.shape = sh
	sb.add_child(cs)
	sb.position = mid + Vector3(0, 1, 0)
	add_child(sb)


func _block(p: Vector3, r: float) -> void:
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = r
	sh.height = 2.0
	cs.shape = sh
	sb.add_child(cs)
	sb.position = p + Vector3(0, 1, 0)
	add_child(sb)


# ===================================================================== village
func _simple_house(pos: Vector3, size: Vector3, roof_tex: String, rot := 0.0) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = deg_to_rad(rot)
	add_child(root)
	var plinth := B.mat("res://assets/tex/cobble.png", 0.9, Vector3.ONE, {"triplanar": true, "tint": Color(0.85, 0.82, 0.78)})
	B.box(root, Vector3(size.x + 0.4, 0.25, size.z + 1.6), Vector3(0, 0.12, 0.6), plinth, 0, true, 0.06)
	B.tri_box(root, Vector3(size.x, size.y, size.z), Vector3(0, size.y * 0.5 + 0.25, 0), "res://assets/tex/mudwall.png")
	var dark := B.color_mat(Color(0.05, 0.04, 0.04))
	dark.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	B.box(root, Vector3(1.0, 1.8, 0.04), Vector3(0, 1.15, size.z * 0.5 + 0.01), dark, 0, false)
	var lattice := B.mat("res://assets/tex/bamboo_weave.png", 1.6, Vector3.ONE, {"triplanar": true})
	for wx in [-size.x * 0.3, size.x * 0.3]:
		B.box(root, Vector3(0.9, 0.7, 0.04), Vector3(wx, 1.5, size.z * 0.5 + 0.01), lattice, 0, false)
	var beam := B.mat("res://assets/tex/beam.png", 1.2, Vector3.ONE, {"triplanar": true})
	for px in [-size.x * 0.5 + 0.3, size.x * 0.5 - 0.3]:
		B.cylinder(root, 0.1, size.y, Vector3(px, size.y * 0.5 + 0.25, size.z * 0.5 + 1.2), beam, true, 8)
	B.roof(root, size.x + 1.2, size.z * 0.5 + 1.8, size.z * 0.5 + 0.6, size.y + 0.2, size.y + 2.2, Vector3.ZERO, roof_tex)


func _build_village() -> void:
	var V := VILLAGE
	props["banyan"] = _banyan(V + Vector3(0, 0, -3.2))
	_block(V + Vector3(0, 0, -3.2), 1.7)
	B.billboard(self, "res://assets/sprites/props/shrine.png", V + Vector3(3.6, 0, -1.6), B.PX * 1.3)
	_block(V + Vector3(3.6, 0, -1.6), 0.7)
	var shrine_light := OmniLight3D.new()
	shrine_light.light_color = Color(1.0, 0.6, 0.3)
	shrine_light.light_energy = 1.4
	shrine_light.omni_range = 4.5
	shrine_light.position = V + Vector3(3.6, 0.9, -1.0)
	add_child(shrine_light)
	lights_night.append(shrine_light)
	var bench := B.mat("res://assets/tex/cobble.png", 1.2, Vector3.ONE, {"triplanar": true})
	B.box(self, Vector3(2.2, 0.42, 0.62), V + Vector3(-2.6, 0.21, 0.6), bench, 0, true, 0.06)
	props["leaves_fall"] = B.particles(self, "res://assets/sprites/props/leaf.png", 10, 6.0, Vector3(5, 0.5, 3), V + Vector3(0, 6.5, -2.5),
		{"dir": Vector3(0.3, -1, 0), "vmin": 0.2, "vmax": 0.5, "gravity": Vector3(0, -0.25, 0), "size": 0.16, "turb": 1.2, "color": Color(1, 1, 1)})
	_simple_house(Vector3(-22, 0, -16), Vector3(8.0, 2.4, 4.2), "res://assets/tex/roof_tile.png")
	_simple_house(Vector3(2, 0, -17), Vector3(7.0, 2.3, 4.0), "res://assets/tex/thatch.png")
	_simple_house(Vector3(-27, 0, -3.5), Vector3(6.0, 2.2, 3.8), "res://assets/tex/thatch.png", 8.0)
	for p in [Vector3(-16, 0, -18.5), Vector3(8, 0, -19), Vector3(-31, 0, 0.5)]:
		B.billboard(self, "res://assets/sprites/props/strawstack.png", p, B.PX * 1.1)


func _bark_mat() -> StandardMaterial3D:
	return B.mat("res://assets/tex/bark.png", 1.1, Vector3.ONE, {"triplanar": true})


func _crown(center: Vector3, radii: Vector3, count: int, seed: int, texs: Array, scale := 1.0) -> Array:
	## Leaf clumps spread over an ellipsoid crown: lit on top, darker underneath and inside.
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var clumps := []
	for i in count:
		var u := rng.randf_range(-1.0, 1.0)
		var a := rng.randf() * TAU
		var shell := 1.0 if rng.randf() < 0.8 else rng.randf_range(0.45, 0.8)
		var r := sqrt(1.0 - u * u)
		var dir := Vector3(r * cos(a), u, r * sin(a))
		if dir.y < -0.55:
			dir.y = -0.55 + rng.randf() * 0.2  # flat-ish underside
		var p := center + Vector3(dir.x * radii.x, dir.y * radii.y, dir.z * radii.z) * shell
		var lit := clampf(0.62 + (dir.y + 0.6) * 0.38, 0.55, 1.15) * (1.0 if shell > 0.9 else 0.78)
		lit *= rng.randf_range(0.93, 1.06)
		var tex: String = texs[rng.randi() % texs.size()]
		clumps.append([tex, p, rng.randf_range(0.9, 1.35) * scale, Color(lit, lit, lit * 0.97)])
	return clumps


func _banyan(base: Vector3) -> Node3D:
	## The village banyan (cây đa): a real trunk with limbs and hanging roots under a deep crown.
	var root := Node3D.new()
	add_child(root)
	var bark := _bark_mat()
	B.trunk(root, base + Vector3(0, -0.2, 0), base + Vector3(0, 4.6, 0), 1.05, 0.62, bark, 12)
	# buttress flare
	for k in 6:
		var a := TAU * k / 6.0 + 0.3
		B.trunk(root, base + Vector3(cos(a) * 1.4, -0.1, sin(a) * 1.4), base + Vector3(cos(a) * 0.5, 1.6, sin(a) * 0.5), 0.32, 0.18, bark, 6)
	var limbs := [Vector3(-3.4, 6.6, 0.6), Vector3(3.2, 6.8, -0.4), Vector3(0.4, 7.4, -2.6), Vector3(-1.2, 6.9, 2.4), Vector3(2.0, 6.2, 2.2)]
	for l in limbs:
		B.trunk(root, base + Vector3(0, 4.2, 0), base + l, 0.42, 0.14, bark, 6)
	# aerial roots hanging close round the trunk
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	for k in 11:
		var a := rng.randf() * TAU
		var rr := rng.randf_range(1.15, 1.65)
		var top := base + Vector3(cos(a) * rr * 1.3, rng.randf_range(4.6, 5.6), sin(a) * rr * 1.3)
		B.trunk(root, base + Vector3(cos(a) * rr, -0.05, sin(a) * rr), top, 0.07, 0.04, bark, 5)
	var texs := ["res://assets/sprites/props/leafclump.png", "res://assets/sprites/props/leafclump2.png",
		"res://assets/sprites/props/leafclump_dark.png"]
	var clumps := _crown(base + Vector3(0, 7.2, 0), Vector3(6.2, 2.6, 5.2), 230, 17, texs, 1.15)
	clumps += _crown(base + Vector3(-2.4, 6.3, 1.0), Vector3(3.2, 1.6, 2.6), 40, 18, texs, 1.0)
	B.canopy(root, clumps, 0.05, 0.06)
	return root


func _broadleaf(base: Vector3, size := 1.0, seed := 1, autumn := false) -> void:
	## A smaller shade tree (mít, nhãn...): trunk, two limbs, round crown.
	base.y = height_at(base.x, base.z)
	var bark := _bark_mat()
	B.trunk(self, base + Vector3(0, -0.1, 0), base + Vector3(0, 2.6 * size, 0), 0.32 * size, 0.2 * size, bark, 8)
	B.trunk(self, base + Vector3(0, 2.2 * size, 0), base + Vector3(-1.0, 3.6, 0.3) * size + Vector3(0, 0, 0), 0.16 * size, 0.07 * size, bark, 6)
	B.trunk(self, base + Vector3(0, 2.0 * size, 0), base + Vector3(1.1, 3.4, -0.4) * size, 0.15 * size, 0.07 * size, bark, 6)
	var texs := ["res://assets/sprites/props/leafclump.png", "res://assets/sprites/props/leafclump_dark.png"]
	if autumn:
		texs = ["res://assets/sprites/props/leafclump_yel.png", "res://assets/sprites/props/leafclump.png"]
	B.canopy(self, _crown(base + Vector3(0, 3.9 * size, 0), Vector3(2.3, 1.5, 2.0) * size, int(70 * size), seed, texs, 0.95 * size), 0.05, 0.07)
	_block(base, 0.35 * size)


func _build_paddies() -> void:
	var wm := ShaderMaterial.new()
	wm.shader = Assets.shader("res://shaders/water.gdshader")
	wm.set_shader_parameter("noise_tex", Assets.tex("res://assets/tex/water_noise.png"))
	wm.set_shader_parameter("deep", Color(0.2, 0.26, 0.2))
	wm.set_shader_parameter("shallow", Color(0.32, 0.38, 0.3))
	wm.set_shader_parameter("glint", Color(0.85, 0.85, 0.78))
	wm.set_shader_parameter("speed", 0.012)
	wm.set_shader_parameter("glint_amount", 0.35)
	var dyke := B.mat("res://assets/tex/dirt.png", 1.0, Vector3.ONE, {"triplanar": true})
	var pts := PackedVector3Array()
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var cells := [Rect2(-36, 4.0, 9.5, 4.6), Rect2(-26, 4.0, 9.5, 4.6), Rect2(-36, 9.2, 9.5, 4.6), Rect2(-26, 9.2, 9.5, 4.6)]
	for r in cells:
		var w := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = r.size
		w.mesh = pm
		w.material_override = wm
		w.position = Vector3(r.position.x + r.size.x * 0.5, 0.03, r.position.y + r.size.y * 0.5)
		add_child(w)
		var gx: float = r.position.x + 0.5
		while gx < r.end.x - 0.3:
			var gz: float = r.position.y + 0.4
			while gz < r.end.y - 0.3:
				pts.append(Vector3(gx + rng.randf_range(-0.08, 0.08), 0.0, gz + rng.randf_range(-0.08, 0.08)))
				gz += 0.55
			gx += 0.62
	for z in [3.9, 8.9, 14.0]:
		B.box(self, Vector3(20.0, 0.18, 0.45), Vector3(-26.0, 0.09, z), dyke, 0, false, 0.035)
	for xx in [-36.2, -26.3, -16.2]:
		B.box(self, Vector3(0.45, 0.18, 10.4), Vector3(xx, 0.09, 9.0), dyke, 0, false, 0.035)
	B.scatter(self, "res://assets/sprites/props/rice.png", pts, 0.04, 0.05, PackedColorArray([Color(1, 1, 1), Color(0.92, 1.0, 0.85), Color(1.05, 1.02, 0.9)]))


func _build_pass() -> void:
	var sn := Vector3(sin(deg_to_rad(-30.0)), 0, cos(deg_to_rad(-30.0)))
	props["stele"] = B.tri_box(self, Vector3(1.4, 2.0, 0.45), STELE + Vector3(0, 1.0, 0), "res://assets/tex/cobble.png", 1.2, -30.0)
	B.sprite_mat_quad(self, "res://assets/tex/stele.png", STELE + sn * 0.235 + Vector3(0, 1.0, 0), Vector3(0, -30, 0), 0.026)
	var mn := Vector3(sin(deg_to_rad(-40.0)), 0, cos(deg_to_rad(-40.0)))
	props["marker"] = B.tri_box(self, Vector3(0.38, 1.05, 0.38), MARKER + Vector3(0, 0.52, 0), "res://assets/tex/cobble.png", 1.6, -40.0)
	B.sprite_mat_quad(self, "res://assets/tex/marker.png", MARKER + mn * 0.2 + Vector3(0, 0.6, 0), Vector3(0, -40, 0), 0.022)
	# boulders flanking the road out, starting past the marker so they never block the fight
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	var rockm := B.mat("res://assets/tex/rock.png", 0.9, Vector3.ONE, {"triplanar": true, "world": true})
	var out := (MARKER - Vector3(-24, 0, -12)).normalized()
	var lat := Vector3(-out.z, 0, out.x)
	var cam_side := lat
	if lat.cross(Vector3.UP).dot(-out) < 0:
		cam_side = -lat
	for i in 16:
		var side := -1.0 if i % 2 == 0 else 1.0
		var along := 9.0 + i * 1.5
		var p := MARKER + out * along + lat * side * rng.randf_range(7.0, 10.0)
		if (lat * side).dot(cam_side) < 0 and along < 24.0:
			continue  # this side faces the battle camera
		p.y = height_at(p.x, p.z)
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		var r := rng.randf_range(1.0, 2.2)
		sm.radius = r
		sm.height = r * rng.randf_range(1.2, 1.9)
		sm.radial_segments = 7
		sm.rings = 4
		mi.mesh = sm
		mi.material_override = rockm
		mi.position = p + Vector3(0, r * 0.35, 0)
		mi.rotation = Vector3(rng.randf_range(-0.3, 0.3), rng.randf() * TAU, rng.randf_range(-0.3, 0.3))
		add_child(mi)


func _build_vegetation() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	# bamboo hedges (lũy tre) ring the village
	var bamboo_spots := []
	for i in 9:
		bamboo_spots.append(Vector3(26.2 + rng.randf_range(-0.4, 0.4), 0, -8 + i * 2.0))
	for i in 7:
		bamboo_spots.append(Vector3(9 + i * 2.6, 0, -10.5 + rng.randf_range(-0.4, 0.4)))
	for i in 10:
		var a := PI * 1.05 + i * 0.16
		bamboo_spots.append(Vector3(-4 + cos(a) * 40.0, 0, -2 + sin(a) * 22.5))
	for i in 8:
		bamboo_spots.append(Vector3(-40 + i * 4.6, 0, 16.2 + rng.randf_range(-0.6, 0.6)))
	for p in bamboo_spots:
		p.y = height_at(p.x, p.z)
		if p.y > 1.2:
			continue
		if _dist_seg(Vector2(p.x, p.z), Vector2(-24, -12), Vector2(MARKER.x, MARKER.z)) < 7.0:
			continue
		B.plant(self, "res://assets/sprites/props/bamboo.png", p, B.PX * rng.randf_range(0.9, 1.15), 0.28, 1.0)
		_block(p, 0.5)
	for p in [HOUSE + Vector3(-4.0, 0, -4.4), HOUSE + Vector3(1.2, 0, -4.8), HOUSE + Vector3(4.8, 0, -4.2), Vector3(-14, 0, -17),
			Vector3(-1, 0, -19), Vector3(-30, 0, -6.5), Vector3(-12, 0, 6.5)]:
		B.plant(self, "res://assets/sprites/props/banana.png", p, B.PX * 1.15, 0.14, 0.6)
		_block(p, 0.35)
	for p in [HOUSE + Vector3(-7.0, 0, -3.6), HOUSE + Vector3(7.6, 0, -3.8), Vector3(-17, 0, -10.8), Vector3(5, 0, -13),
			Vector3(-10, 0, 4.5), Vector3(-24, 0, -9)]:
		B.plant(self, "res://assets/sprites/props/areca.png", p, B.PX * 1.2, 0.32, 0.5)
		_block(p, 0.25)
	for i in 34:
		var x := rng.randf_range(-42, 36)
		var z := rng.randf_range(-22, 16)
		if not _free_spot(x, z, 1.5):
			continue
		B.plant(self, "res://assets/sprites/props/%s.png" % ("bush" if i % 2 else "bush2"), Vector3(x, 0, z), B.PX, 0.04, 1.0)
	for i in 40:
		var x := rng.randf_range(-40, 34)
		var z := rng.randf_range(-20, 16)
		if not _free_spot(x, z, 0.8):
			continue
		B.plant(self, "res://assets/sprites/props/flowers.png", Vector3(x, 0, z), B.PX, 0.03, 0.0, false)
	# shade trees behind the houses and round the square (kept north of paths so they never hide the player)
	_broadleaf(HOUSE + Vector3(-9.5, 0, -7.5), 1.15, 3)
	_broadleaf(KITCHEN + Vector3(5.5, 0, -6.0), 1.0, 4)
	_broadleaf(VILLAGE + Vector3(-10.5, 0, -9.0), 1.25, 5)
	_broadleaf(VILLAGE + Vector3(9.5, 0, -10.5), 1.1, 6, true)
	_broadleaf(Vector3(-36, 0, -9.5), 1.2, 7)
	_broadleaf(Vector3(12.5, 0, -21.0), 1.3, 8)
	_broadleaf(Vector3(-14, 0, -24.0), 1.2, 9, true)
	# grass tufts everywhere that is not path, yard, water or building
	var pts := PackedVector3Array()
	var tints := PackedColorArray([Color(1, 1, 1), Color(0.9, 1.0, 0.85), Color(1.08, 1.05, 0.85), Color(0.85, 0.95, 0.8)])
	var tries := 0
	while pts.size() < 5200 and tries < 40000:
		tries += 1
		var x := rng.randf_range(-48, 40)
		var z := rng.randf_range(-30, 18)
		var h := height_at(x, z)
		if h > 2.0:
			continue
		if not _free_spot(x, z, 0.3):
			continue
		pts.append(Vector3(x, h, z))
	B.scatter(self, "res://assets/sprites/props/tuft.png", pts, 0.035, 0.06, tints)


func _free_spot(x: float, z: float, margin: float) -> bool:
	if _path_weight(x, z) > 0.05 or _yard_weight(x, z) > 0.05:
		return false
	if abs(z - 19.5) < 3.0:
		return false
	if x > -36.5 and x < -15.8 and z > 3.6 and z < 14.4:
		return false  # paddies
	for r in [Rect2(HOUSE.x - 6.5, HOUSE.z - 3.5, 13, 7), Rect2(KITCHEN.x - 2.5, KITCHEN.z - 2, 5, 5),
			Rect2(-27, -19, 10, 7), Rect2(-2, -20, 8, 6.5), Rect2(-31, -6.5, 8, 6.5)]:
		if r.grow(margin).has_point(Vector2(x, z)):
			return false
	if Vector2(x, z).distance_to(Vector2(VILLAGE.x, VILLAGE.z - 3.2)) < 2.5 + margin:
		return false
	return true


func _animate_ambience() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	if env.volumetric_fog_enabled != Game.quality_high:
		env.volumetric_fog_enabled = Game.quality_high
		env.ssao_enabled = Game.quality_high
	if hero:
		RenderingServer.global_shader_parameter_set("player_pos", hero.global_position)
	# gusts come and go
	RenderingServer.global_shader_parameter_set("gust", 0.75 + 0.35 * sin(t * 0.31) + 0.2 * sin(t * 0.83 + 1.7))
	if _bucket_hang:
		_bucket_hang.rotation = Vector3(sin(t * 0.9) * 0.03, 0, sin(t * 0.7 + 1.0) * 0.045)
	for i in _trail.size():
		var glow := 0.5 + 0.5 * sin(t * 5.0 - i * 0.55)
		_trail[i].modulate = Color(1.0, 0.86, 0.45, 0.35 + 0.55 * glow)
	for i in _markers.size():
		var mk := _markers[i]
		mk.global_position = (mk.get_meta("at") as Vector3) + Vector3(0, 0.14 * sin(t * 4.2 + i), 0)
	if _motes and rig:
		_motes.global_position = rig._focus_point + Vector3(0, 1.4, 0)
	# the porch lanterns swing a little from their hooks in the gusts; at night the flame inside flickers
	# (the frame and the brightness of the paper) and the light thrown on the porch flickers with it
	var night: bool = time_name != "" and TIMES[time_name]["night"]
	var g: float = 0.75 + 0.35 * sin(t * 0.31) + 0.2 * sin(t * 0.83 + 1.7)
	var flick: Array[float] = []
	for s in _lantern_sprites:
		var ph: float = s.get_meta("phase")
		var ang := (sin(t * 1.6 + ph) * 0.06 + sin(t * 2.7 + ph * 1.7) * 0.025) * g
		var hook: Vector3 = s.get_meta("hook")
		var yaw := 0.0
		if rig and rig.cam:
			var to_cam: Vector3 = rig.cam.global_position - hook
			yaw = atan2(to_cam.x, to_cam.z)
		s.global_transform = Transform3D(Basis(Vector3.UP, yaw) * Basis(Vector3(0, 0, 1), ang), hook)
		var n := sin(t * 7.3 + ph * 3.0) * 0.55 + sin(t * 12.9 + ph * 1.7) * 0.3 + sin(t * 23.1 + ph) * 0.15
		var b := clampf(n * 0.5 + 0.5, 0.0, 1.0)
		flick.append(b)
		if s.shaded == night:   # at night it gives light (its own colours, not lit again by the lamp inside it)
			s.shaded = not night
		if night:
			s.frame = [2, 0, 3, 1][mini(int(b * 4.0), 3)]
			s.modulate = Color(1.0, 0.94, 0.88) * (0.9 + 0.16 * b)
		else:
			s.frame = 4
			s.modulate = Color.WHITE
	for i in _lanterns.size():
		var l := _lanterns[i]
		var base: float = l.get_meta("base_energy", l.light_energy)
		if l.has_meta("lantern") and int(l.get_meta("lantern")) < flick.size():
			l.light_energy = base * (0.78 + 0.34 * flick[int(l.get_meta("lantern"))])
		else:
			l.light_energy = base * (0.9 + 0.07 * sin(t * 7.3 + i * 2.1) + 0.05 * sin(t * 13.7 + i))


func _build_atmosphere() -> void:
	# ground mist: thick at the valley floor, thinning with height
	var fv := FogVolume.new()
	fv.shape = RenderingServer.FOG_VOLUME_SHAPE_BOX
	fv.size = Vector3(130, 9, 90)
	fv.position = Vector3(-6, 1.5, -4)
	_mist_mat = FogMaterial.new()
	_mist_mat.density = 0.0
	_mist_mat.height_falloff = 0.9
	_mist_mat.edge_fade = 0.3
	fv.material = _mist_mat
	add_child(fv)
	for l in lights_night:
		if l is OmniLight3D:
			l.set_meta("base_energy", l.light_energy)
			l.light_volumetric_fog_energy = 2.5
			_lanterns.append(l)
	# dust motes by day: a few warm specks drifting in the light near the camera's focus; the ones that pass
	# close to the lens blur into soft discs with the depth of field
	_motes = B.particles(self, "res://assets/sprites/props/firefly.png", 46, 8.0, Vector3(8.0, 2.2, 6.0), Vector3(0, 1.6, 0),
		{"spread": 180.0, "vmin": 0.02, "vmax": 0.09, "size": 0.07, "unshaded": true, "turb": 0.35,
		"color": Color(1.0, 0.97, 0.86, 0.55)})
	# fireflies at night
	var ff := B.particles(self, "res://assets/sprites/props/firefly.png", 60, 6.0, Vector3(22, 1.2, 12), Vector3(0, 1.4, 0),
		{"spread": 180.0, "vmin": 0.05, "vmax": 0.2, "size": 0.12, "unshaded": true, "turb": 0.6,
		"emission": Color(1.0, 0.85, 0.4), "emission_energy": 4.0, "color": Color(1, 0.95, 0.6)})
	night_nodes.append(ff)
	# (the low mist is the ground fog volume above; no floating sprite blobs)


func _define_markers() -> void:
	markers = {
		"yard_center": HOUSE + Vector3(0.5, 0, 5.2),
		"porch_ong": HOUSE + Vector3(-1.0, 0.3, 2.0),
		"door": HOUSE + Vector3(0, 0.3, 1.4),
		"chop_spot": HOUSE + Vector3(5.3, 0, 5.4),
		"chop_block": HOUSE + Vector3(4.2, 0, 5.2),
		"broom_prop": HOUSE + Vector3(-5.35, 0, 2.95),
		"well_center": HOUSE + Vector3(-6.0, 0, 6.2),
		"chop_ong": HOUSE + Vector3(3.0, 0, 6.6),
		"broom": HOUSE + Vector3(-4.8, 0, 3.6),
		"sweep_0": HOUSE + Vector3(-2.4, 0, 4.7),
		"sweep_1": HOUSE + Vector3(0.6, 0, 6.2),
		"sweep_2": HOUSE + Vector3(3.0, 0, 4.5),
		"well": HOUSE + Vector3(-4.7, 0, 6.5),
		"jar": KITCHEN + Vector3(-2.2, 0, 3.2),
		"gate": Vector3(15.4, 0, 8.4),
		"bench": VILLAGE + Vector3(-2.6, 0, 1.0),
		"baca": VILLAGE + Vector3(-2.9, 0.42, 0.75),
		"kids": VILLAGE + Vector3(4.2, 0, 3.4),
		"chunam": Vector3(-19.5, 0, 3.0),
		"peddler": STELE + Vector3(3.0, 0, 2.6),
		"stele_view": STELE + Vector3(1.8, 0, 2.2),
		"marker": MARKER,
		"marker_in": MARKER + Vector3(2.2, 0, 2.2),
		"pass_trigger": Vector3(-30.5, 0, -18.0),
		"outside": MARKER + Vector3(-4.0, 0, -4.2),
		"beam_spot": HOUSE + Vector3(-2.3, 0.3, 2.62),
		"mat_hero": HOUSE + Vector3(-3.4, 0.3, 1.9),
		"mat_ong": HOUSE + Vector3(-1.9, 0.3, 1.5),
		"mat_lua": HOUSE + Vector3(-4.35, 0.32, 1.45),
	}


# ===================================================================== actors & interaction
func _blocker(size: Vector3, pos: Vector3) -> void:
	## Invisible wall.
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	sb.add_child(cs)
	sb.position = pos
	add_child(sb)


func ground_at(p: Vector3) -> float:
	## Height actors stand at: the old man's porch is a raised floor, elsewhere the terrain (0 on the valley floor).
	if absf(p.x - HOUSE.x) < 5.7 and absf(p.z - (HOUSE.z + 0.05)) < 2.95:
		return 0.3
	return maxf(height_at(p.x, p.z), 0.0)


func spawn(actor_id: String, sheet: String, pos: Vector3, facing := "down", player := false):
	var a = Player.new() if player else Actor.new()
	add_child(a)
	a.ground_fn = ground_at
	a.setup(actor_id, sheet)
	a.global_position = pos
	a.face(facing)
	if player:
		a.world = self
		a.footsteps = true
	actors[actor_id] = a
	return a


func actor(actor_id: String):
	return actors.get(actor_id)


func despawn(actor_id: String) -> void:
	if actors.has(actor_id):
		actors[actor_id].queue_free()
		actors.erase(actor_id)


func set_markers(points: Array, height := 2.2) -> void:
	## Gold arrows bobbing over where the player should go next (empty: none). The HUD points to the first one
	## from the edge of the screen while it is out of view.
	for m in _markers:
		m.queue_free()
	_markers.clear()
	for pt in points:
		var m := Sprite3D.new()
		m.texture = Assets.tex("res://assets/sprites/props/marker.png")
		m.pixel_size = 0.042
		m.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		m.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		m.no_depth_test = true
		m.shaded = false
		m.render_priority = 10
		m.set_meta("at", (pt as Vector3) + Vector3(0, height, 0))
		add_child(m)
		m.global_position = m.get_meta("at")
		_markers.append(m)
	if hud:
		hud.point_to(_markers[0].get_meta("at") if _markers.size() > 0 else null)


func set_trail(points: Array, spacing := 2.4) -> void:
	## Gold arrows lying on the ground along a route (points: Vector2 x/z, in order); a glow runs along them
	## toward the end. Empty: none.
	for a in _trail:
		a.queue_free()
	_trail.clear()
	var tex := Assets.tex("res://assets/sprites/props/marker.png")
	for i in range(points.size() - 1):
		var p0: Vector2 = points[i]
		var p1: Vector2 = points[i + 1]
		var seg := p1 - p0
		var n := int(seg.length() / spacing)
		for k in n:
			var q := p0 + seg * ((k + 0.5) / float(maxi(n, 1)))
			var d := Vector3(seg.x, 0, seg.y).normalized()
			var a := Sprite3D.new()
			a.texture = tex
			a.pixel_size = 0.05
			a.billboard = BaseMaterial3D.BILLBOARD_DISABLED
			a.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			a.shaded = false
			a.double_sided = true
			add_child(a)
			# lying flat, the arrow's tip (the bottom of the picture) pointing along the road
			a.global_transform = Transform3D(Basis((-d).cross(Vector3.UP), -d, Vector3.UP), Vector3(q.x, height_at(q.x, q.y) + 0.09, q.y))
			_trail.append(a)


func add_interact(iid: String, pos: Vector3, prompt: String, radius := 1.7) -> void:
	interactables[iid] = {"pos": pos, "radius": radius, "prompt": prompt, "enabled": true}


func remove_interact(iid: String) -> void:
	interactables.erase(iid)


func add_trigger(tid: String, pos: Vector3, radius: float) -> void:
	triggers[tid] = {"pos": pos, "radius": radius, "enabled": true, "inside": false}


func remove_trigger(tid: String) -> void:
	triggers.erase(tid)


func nearest_interact() -> String:
	if hero == null:
		return ""
	var best := ""
	var best_d := 99.0
	for iid in interactables:
		var it: Dictionary = interactables[iid]
		if not it["enabled"]:
			continue
		var d: float = Vector2(hero.global_position.x, hero.global_position.z).distance_to(Vector2(it["pos"].x, it["pos"].z))
		if d < it["radius"] and d < best_d:
			best = iid
			best_d = d
	return best


func _process(_delta: float) -> void:
	if not _active:
		return
	_animate_ambience()
	if control_enabled and hero:
		var iid := nearest_interact()
		hud.show_prompt(interactables[iid]["prompt"] if iid != "" else "")
		for tid in triggers:
			var t: Dictionary = triggers[tid]
			if not t["enabled"]:
				continue
			var inside: bool = hero.global_position.distance_to(t["pos"]) < t["radius"]
			if inside and not t["inside"]:
				t["inside"] = true
				trigger_entered.emit(tid)
			elif not inside:
				t["inside"] = false
	else:
		hud.show_prompt("")


func try_interact() -> void:
	var iid := nearest_interact()
	if iid != "":
		hud.show_prompt("")
		interacted.emit(iid)


func set_control(on: bool) -> void:
	control_enabled = on
	if on:
		clear_emotes()   # (the player takes over: no face or gesture left hanging from the scene)
	if on and rig and hero and (rig._manual or rig.target != hero):
		rig.follow(hero, false)  # whenever the player can move, the camera follows them
	if hero:
		hero.control = on
		if not on:
			hero.moving = false


func is_walkable(p: Vector3) -> bool:
	var ex := (p.x + 4.0) / 41.0
	var ez := (p.z + 2.0) / 22.5
	var inside := ex * ex + ez * ez < 1.0 and p.z < 16.4
	var pass_ok := _dist_seg(Vector2(p.x, p.z), Vector2(-24, -12), Vector2(MARKER.x - 0.6, MARKER.z - 0.6)) < 3.2
	if p.x > -36.6 and p.x < -15.9 and p.z > 3.5 and p.z < 14.5:
		return false
	return inside or pass_ok


var talkers := {}   # a speaker's name -> the actor id (or ids: the one nearest the hero) who says it (story scripts set it)


func talker(speaker: String):
	## The actor who speaks under this name: the hero under the player's name, others from `talkers`.
	if speaker == "":
		return null
	if speaker == Game.player_name:
		return hero
	var ids = talkers.get(speaker)
	if ids is String:
		ids = [ids]
	var best = null
	var best_d := INF
	for i in (ids if ids is Array else []):   # (the same office worn by several: the one in the scene, by the hero)
		var a = actor(i)
		if a and a.visible:
			var d: float = a.global_position.distance_to(hero.global_position) if hero else 0.0
			if d < best_d:
				best = a
				best_d = d
	return best


func emo(actor_id: String, name: String) -> void:
	## A listener's face (scripts/world/actor.gd emo()); "hero" for the protagonist.
	var a = hero if actor_id == "hero" else actor(actor_id)
	if a:
		a.emo(name)


func clear_emotes() -> void:
	for a in actors.values():
		if is_instance_valid(a):
			a.clear_emo()


func say(speaker: String, text: String, emote := "") -> void:
	var a = talker(speaker)
	if a:
		if emote != "":
			a.emo(emote)
		else:
			a.end_moment()
		a.speak_bob()
	await dialogue.say(speaker, text)


func choose(options: Array) -> int:
	return await dialogue.choose(options)


func set_active(on: bool) -> void:
	## Hide the village while a battle owns the screen.
	_active = on
	visible = on
	process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
	world_env.environment = env if on else null
	hud.visible = on
	if on:
		rig.cam.current = true
