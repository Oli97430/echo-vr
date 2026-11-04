## ÉCHO VR — explore une épave dans le noir, guidé par le gilet bHaptics X40.
## PCVR (OpenXR : Virtual Desktop / SteamVR / Quest Link) et Quest autonome (export Android).
##
## Main gauche : stick = bouger, grip = courir, gâchette = faisceau sonar visé à la main,
##   X = recommencer / suivant, Y = menu. Montre au poignet : O₂, balises, munitions.
## Main droite : gâchette = arme, A = sonar, B = arme suivante, stick = rotation.
## Armes : couteau électrique (frappe physique), fusil-harpon, découpeur plasma (maintenir),
##   grenade sonique et leurre (maintenir la gâchette, lancer, relâcher).
extends Node3D

const LEVELS := [
	[
		"################",
		"#P.....#.......#",
		"#......#...B...#",
		"#..##..#.......#",
		"#..##......##..#",
		"#..........##..#",
		"#####..#########",
		"#......A.......#",
		"#.........X....#",
		"################",
	],
	[
		"######################",
		"#P.......#...........#",
		"#........#....B......#",
		"#..####..#...........#",
		"#..#A....#####..###..#",
		"#..#..B.........#....#",
		"#..#######..#...#..M.#",
		"#.....H.....#...#....#",
		"#####..######...####.#",
		"#......#....B........#",
		"#..X...#.............#",
		"######################",
	],
	[
		"##########################",
		"#P...#.........#.........#",
		"#....#..B......#....B....#",
		"#....#...####..#..####...#",
		"#....#...#.....#.....#...#",
		"#........#..M........#...#",
		"######.###########...#####",
		"#......#....A....#.......#",
		"#..B...#...###...#...##..#",
		"#......#...#..H..#....#..#",
		"#..........#.........A#..#",
		"#####..#####..######..#B.#",
		"#X.........T.............#",
		"##########################",
	],
]
# fin de campagne : épaves générées à graine fixe [graine, profondeur]
const CAMPAIGN_GEN := [[1001, 3], [2002, 5]]

const WALL_H := 2.6
const WALK_SPEED := 1.6
const RUN_SPEED := 2.6
const PLAYER_R := 0.22
const SMOOTH_TURN := 120.0
const STEP_LEN := 0.55
const PING_SPEED := 7.0
const PING_RANGE := 12.0
const PING_COOLDOWN := 1.2
const PING_NOISE := 14.0
const RAYS := 96
const BEAM_RANGE := 22.0
const BEAM_HALF := 18.0
const BEAM_RAYS := 31
const BEAM_COOLDOWN := 2.0
const BEAM_NOISE := 6.0
const RUN_NOISE := 5.0
const DECOY_NOISE := 16.0
const OXYGEN := 150.0
const OXYGEN_BEACON := 20.0
const OXYGEN_LOW := 30.0
const PLAYER_HP := 3
const MONSTER_DMG := {"M": 1, "T": 1, "C": 2}
const ATTACK_CD := 1.2
const ATTACK_RECOVER := 0.6
const ROAR_RADIUS := 10.0
const HEARING_DETOUR := 1.6     # un bruit derrière un mur porte moins loin
const CHARGE_RANGE := 4.0
const BREATH_RANGE := 5.0
const HEART_RANGE := 10.0
const TREMOR_RANGE := 8.0
const MARK_LIFE := 3.5
const HAPTIC_TICK := 0.05
const BODY_DEADZONE := 35.0
const ALL_ROWS := [0, 1, 2, 3, 4]
const POINT_HEIGHTS := [0.35, 0.9, 1.45, 2.0]

const MONSTER_KINDS := {
	"M": {"name": "rôdeur", "hp": 3.0, "scale": 1.0, "tremor": 1.0,
		"speed": {"wander": 0.6, "hunt": 1.15, "charge": 2.0}, "step": {"wander": 0.8, "hunt": 0.55, "charge": 0.32}},
	"T": {"name": "traqueur", "hp": 2.0, "scale": 0.8, "tremor": 0.6,
		"speed": {"wander": 0.9, "hunt": 1.6, "charge": 2.5}, "step": {"wander": 0.5, "hunt": 0.36, "charge": 0.22}},
	"C": {"name": "colosse", "hp": 7.0, "scale": 1.45, "tremor": 1.8,
		"speed": {"wander": 0.4, "hunt": 0.8, "charge": 1.7}, "step": {"wander": 1.2, "hunt": 0.85, "charge": 0.5}},
}

const WEAPONS := ["knife", "harpoon", "nailgun", "plasma", "torpedo", "grenade", "decoy"]
const WEAPON_NAMES := {"knife": "Couteau électrique", "harpoon": "Fusil-harpon",
	"nailgun": "Riveteuse", "plasma": "Découpeur plasma", "torpedo": "Lance-torpille",
	"grenade": "Grenade sonique", "decoy": "Leurre"}
const START_AMMO := {"harpoon": 4, "nailgun": 6, "plasma": 6.0, "torpedo": 2, "grenade": 1, "decoy": 2}
const SUPPLY := {"harpoon": 2, "nailgun": 3, "plasma": 3.0, "torpedo": 1, "grenade": 1, "decoy": 1}
const MAX_AMMO := {"harpoon": 8, "nailgun": 12, "plasma": 12.0, "torpedo": 4, "grenade": 3, "decoy": 4}
# Modèles (res://assets/models) : [fichier, plus grande dimension en m, correction de lacet en °].
# Si une arme pointe dans le mauvais sens en jeu, ajuster son 3e nombre (180 = demi-tour).
const WEAPON_MODELS := {
	"knife": ["gauntlet_pickup", 0.32, 0.0],
	"harpoon": ["railgun_pickup", 0.75, 0.0],
	"nailgun": ["shotgun_pickup", 0.6, 0.0],
	"plasma": ["lightninggun_pickup", 0.55, 0.0],
	"torpedo": ["rocketlauncher_pickup", 0.8, 0.0],
	"grenade": ["grenade_ammo", 0.1, 0.0],
	"decoy": ["cell_ammo", 0.09, 0.0],
}
# Silhouettes révélées par le sonar : [fichier, hauteur en m]
const MONSTER_MODELS := {"M": ["ogre_zombie", 1.9], "T": ["hellhound", 1.1], "C": ["ogre_zombie", 2.7]}
const NAIL_PELLETS := 7
const NAIL_SPREAD := 12.0
const NAIL_RANGE := 9.0
const NAIL_DMG := 0.7
const NAIL_RELOAD := 0.8
const TORPEDO_SPEED := 9.0
const TORPEDO_RADIUS := 3.0
const TORPEDO_DMG := 4.0
const TORPEDO_RELOAD := 1.5
const KNIFE_SPEED := 2.2
const KNIFE_DMG := 1.0
const HARPOON_DMG := 2.0
const HARPOON_RANGE := 25.0
const HARPOON_RELOAD := 1.0
const PLASMA_DPS := 1.6
const PLASMA_RANGE := 2.8
const GRENADE_FUSE := 1.6
const GRENADE_RADIUS := 3.5
const WEAPON_NOISE := {"knife": 3.0, "harpoon": 8.0, "nailgun": 9.0, "plasma": 6.0, "torpedo": 16.0, "grenade": 18.0}

const FX_DUR := {"wall": 0.11, "monster": 0.45, "beacon": 0.4, "exit": 0.5, "bump": 0.15,
	"ping": 0.07, "pickup": 0.45, "death": 0.9, "win": 1.0, "beam": 0.3, "decoy": 0.36,
	"charge": 0.6, "step": 0.06, "mstep": 0.09, "heart": 0.26, "squeeze": 0.4, "tick": 0.05,
	"recoil": 0.14, "hit": 0.12, "kill": 0.7, "blast": 0.6, "supply": 0.4, "resupply": 0.36,
	"slash": 0.08, "throw": 0.2, "wound": 0.45, "medkit": 0.5, "heal": 0.6, "ready": 0.06,
	"touch": 0.05, "roar": 0.8}

# Lexique : [libellé, effet, angle, intensité], chaque entrée joue 2 fois.
const LEX := [
	["Mur devant (écho du sonar)", "wall", 0.0, 0.9],
	["Mur à droite", "wall", 90.0, 0.9],
	["Balise, devant à droite", "beacon", 45.0, 0.7],
	["Caisse de munitions, à gauche", "supply", -60.0, 0.7],
	["Sortie ouverte, devant", "exit", 0.0, 0.8],
	["Monstre repéré, à gauche", "monster", -90.0, 1.0],
	["Pas du monstre derrière toi : le sol tremble", "mstep", 180.0, 0.45],
	["Souffle du monstre, dans le dos", "breath", 180.0, 0.6],
	["Le monstre CHARGE à droite : cours ou frappe !", "charge", 90.0, 1.0],
	["Rugissement au loin, derrière : la meute est alertée", "roar", 180.0, 0.6],
	["Blessure : coup de griffe à gauche", "wound", -90.0, 1.0],
	["Trousse de soin repérée, à droite", "medkit", 90.0, 0.7],
	["Soigné (+1 vie)", "heal", 0.0, 0.8],
	["Arme rechargée", "ready", 25.0, 0.5],
	["Ta main touche un mur", "touch", 45.0, 0.4],
	["Ton cœur : plus il bat vite, plus le monstre est proche", "heart", -20.0, 0.55],
	["Tes pas", "step", 0.0, 0.35],
	["Choc contre un mur", "bump", 0.0, 1.0],
	["Faisceau : sonar visé à la main gauche, discret", "beam", 0.0, 0.7],
	["Recul du fusil-harpon", "recoil", 25.0, 1.0],
	["Monstre touché, devant", "hit", 0.0, 0.8],
	["Monstre abattu, devant", "kill", 0.0, 1.0],
	["Explosion de grenade sonique, à droite", "blast", 90.0, 1.0],
	["Objet lancé", "throw", 0.0, 0.6],
	["Balise ramassée (+20 s d'oxygène)", "pickup", 0.0, 1.0],
	["Munitions ramassées", "resupply", 0.0, 0.7],
	["Oxygène bas", "squeeze", 0.0, 0.7],
]
const LEX_STEP := 2.6
const CONFIG := "user://echo.cfg"

const BLUE := Color(0.27, 0.63, 1.0)
const AMBER := Color(1.0, 0.69, 0.24)
const RED := Color(1.0, 0.24, 0.2)
const WHITE := Color(0.85, 0.92, 1.0)

const VIGNETTE_SHADER := """
shader_type spatial;
render_mode unshaded, depth_test_disabled, cull_disabled, blend_mix, shadows_disabled;
uniform float strength = 0.0;
uniform vec3 tint = vec3(0.0);
void fragment() {
	float d = distance(UV, vec2(0.5));
	ALBEDO = tint;
	ALPHA = smoothstep(0.16, 0.34, d) * strength;  // ~25° → ~45° hors axe
}
"""


class Monster:
	var kind := "M"
	var pos := Vector2.ZERO
	var hp := 3.0
	var target := Vector2i.ZERO
	var has_target := false
	var mode := "wander"
	var step_t := 0.0
	var stun_t := 0.0
	var attack_cd := 0.0
	var last_cell := Vector2i(-1, -1)
	var last_target := Vector2i(-1, -1)
	var nxt: Variant = null


var vest: Vest
var sfx := {}
var cfg := ConfigFile.new()
var calibrated := false
var vr := false
var mobile := false
var selftest := false
var xr_interface: XRInterface

var origin: XROrigin3D
var camera: XRCamera3D
var left: XRController3D
var right: XRController3D
var wrist: Label3D
var wrist_alert: Label3D
var panel: Node3D
var panel_title: Label3D
var panel_items: Array[Label3D] = []
var panel_text: Label3D
var laser: MeshInstance3D
var vignette_mat: ShaderMaterial
var vignette := 0.0
var ring: MeshInstance3D
var ring_mat: StandardMaterial3D
var world: Node3D
var wall_mat: StandardMaterial3D
var point_mesh: SphereMesh
var ambient: AudioStreamPlayer
var plasma_audio: AudioStreamPlayer3D
var plasma_light: OmniLight3D
var weapon_models := {}
var plasma_beam: Node3D
var _model_cache := {}
var _fitted := {}
var torpedoes := []

# niveau
var grid: Array[String] = []
var gw := 0
var gh := 0
var floor_cells: Array[Vector2i] = []
var start_pos := Vector2.ZERO
var exit_pos := Vector2.ZERO
var has_exit := false
var beacons: Array[Vector2] = []
var supplies: Array[Vector2] = []
var medkits: Array[Vector2] = []
var total_beacons := 0
var monsters: Array[Monster] = []

# partie
var game_mode := ""          # "campaign" ou "endless"
var game_active := false
var level_idx := 0
var endless_depth := 0
var endless_seed := 0
var level_time := 0.0
var total_time := 0.0
var pings_used := 0
var kills := 0
var hp := PLAYER_HP
var wound_flash := 0.0
var muzzle: OmniLight3D
var touch_t := {}
var oxygen := OXYGEN
var ammo := {}
var weapon := "harpoon"
var reload_t := 0.0
var knife_cd := 0.0
var trigger_held := false
var holding := ""            # "grenade" / "decoy" tenu en main avant le lancer
var plasma_noise_t := 0.0
var death_cause := ""
var new_record := false

var effects := []
var marks := []
var waves := []
var decoys := []
var throws := []
var traces := []
var ping_t := -99.0
var beam_t := -99.0
var ping_origin := Vector2.ZERO
var last_bump := -99.0
var last_haptic := 0.0
var last_valid_head := Vector2.ZERO
var recenter_frames := 0
var snap_ready := true
var step_acc := 0.0
var step_left := false
var next_heart := 0.0
var next_squeeze := 0.0
var next_alarm := 0.0
var body_yaw := 0.0
var hand_prev := Vector3.ZERO
var hand_fresh := true
var panel_pending := false
var pause_t0 := -1.0
var recenter_to := Vector2.ZERO
var hand_vel := Vector3.ZERO
var state := "menu"
var turn_mode := "snap30"
var comfort := true
var seated := false
var now := 0.0
var state_t0 := 0.0
var calib_step := 0
var calib_return := "menu"
var lex_idx := 0
var lex_fired := 0
var lex_return := "menu"
var menu_items: Array[String] = []
var menu_hover := -1
var menu_hover_x := 0.0

# auto-test (-- --selftest) : entrées simulées sans casque
var test_move := Vector2.ZERO
var test_run := false
var test_hand_vel := Vector3.ZERO
var _test_kinds := {}
var _test_fail := 0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	selftest = "--selftest" in args
	mobile = OS.has_feature("android")
	vest = Vest.new()
	vest.enabled = not selftest
	add_child(vest)
	sfx = Sfx.build()
	_load_config()
	xr_interface = XRServer.find_interface("OpenXR")
	vr = xr_interface != null and xr_interface.is_initialized() and not selftest
	_build_env()
	_build_rig()
	_build_ui()
	ambient = AudioStreamPlayer.new()
	ambient.stream = sfx["ambient"]
	ambient.volume_db = -6.0
	add_child(ambient)
	ambient.play()
	if selftest:
		_run_selftest()
		return
	if not vr:
		_no_headset()
		return
	get_viewport().use_xr = true
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	# fréquence max sur PC ; plafonnée à 90 Hz sur Quest (budget CPU du GDScript)
	var best_rate := 0.0
	for r in xr_interface.get_available_display_refresh_rates():
		if (not mobile or r <= 90.0) and r > best_rate:
			best_rate = r
	if best_rate > 0.0:
		xr_interface.display_refresh_rate = best_rate
	if xr_interface.has_signal("pose_recentered"):
		xr_interface.connect("pose_recentered", _on_pose_recentered)
	if not calibrated:
		start_calib("menu")
	else:
		open_menu()


func _no_headset() -> void:
	var l := Label.new()
	l.text = "ÉCHO VR\n\nAucun casque détecté.\nConnecte Virtual Desktop (ou SteamVR / Quest Link), puis relance le jeu."
	l.add_theme_font_size_override("font_size", 28)
	l.add_theme_color_override("font_color", AMBER)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	var cl := CanvasLayer.new()
	cl.add_child(l)
	add_child(cl)


# ---------------------------------------------------------------- réglages et records

func _load_config() -> void:
	if cfg.load(CONFIG) == OK:
		calibrated = cfg.has_section_key("vest", "mirror_front")
	vest.mirror_front = cfg.get_value("vest", "mirror_front", false)
	vest.mirror_back = cfg.get_value("vest", "mirror_back", false)
	vest.gain = cfg.get_value("vest", "gain", 1.0)
	turn_mode = cfg.get_value("options", "turn", "snap30")
	comfort = cfg.get_value("options", "comfort", true)
	seated = cfg.get_value("options", "seated", false)


func _save_config() -> void:
	cfg.set_value("vest", "mirror_front", vest.mirror_front)
	cfg.set_value("vest", "mirror_back", vest.mirror_back)
	cfg.set_value("vest", "gain", vest.gain)
	cfg.set_value("options", "turn", turn_mode)
	cfg.set_value("options", "comfort", comfort)
	cfg.set_value("options", "seated", seated)
	if not selftest:
		cfg.save(CONFIG)


func _fmt_time(t: float) -> String:
	var s := int(t)
	return "%d:%02d" % [s / 60, s % 60]


# ---------------------------------------------------------------- construction

func _glow(color: Color, alpha: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(color, alpha)
	return m


func _build_env() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.0, 0.0, 0.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.03, 0.04, 0.06)
	if not mobile:
		env.glow_enabled = true
		env.glow_intensity = 0.9
		env.glow_bloom = 0.15
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	world = Node3D.new()
	add_child(world)
	wall_mat = StandardMaterial3D.new()
	wall_mat.roughness = 1.0
	wall_mat.albedo_color = Color(0.04, 0.045, 0.055)  # quasi noir, mais un flash de tir révèle la tôle
	point_mesh = SphereMesh.new()
	point_mesh.radius = 0.03
	point_mesh.height = 0.06
	point_mesh.radial_segments = 6
	point_mesh.rings = 3


func _build_rig() -> void:
	origin = XROrigin3D.new()
	add_child(origin)
	camera = XRCamera3D.new()
	camera.near = 0.05
	origin.add_child(camera)
	if not vr:
		camera.position.y = 1.6
	left = XRController3D.new()
	left.tracker = &"left_hand"
	origin.add_child(left)
	right = XRController3D.new()
	right.tracker = &"right_hand"
	origin.add_child(right)
	if not vr:
		left.position = Vector3(-0.2, 1.3, -0.3)
		right.position = Vector3(0.2, 1.3, -0.3)
	left.button_pressed.connect(_on_left)
	right.button_pressed.connect(_on_right)
	right.button_released.connect(_on_right_released)

	# mains : petits repères lumineux
	for c in [left, right]:
		var hm := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.04, 0.03, 0.09)
		hm.mesh = bm
		hm.material_override = _glow(BLUE, 0.35)
		c.add_child(hm)

	# armes dans la main droite : tes modèles GLB, sinon une forme simple
	for w in WEAPONS:
		var spec: Array = WEAPON_MODELS[w]
		var holder := _fit_model(spec[0], spec[1], spec[2], false)
		if holder == null:
			var fallback: Array = {"knife": [BoxMesh.new(), Vector3(0.012, 0.03, 0.28)],
				"grenade": [SphereMesh.new(), Vector3(0.05, 0.05, 0.05)],
				"decoy": [SphereMesh.new(), Vector3(0.04, 0.04, 0.04)]}.get(w, [BoxMesh.new(), Vector3(0.05, 0.06, spec[1] * 0.6)])
			weapon_models[w] = _model(fallback[0], fallback[1], Vector3(0, 0, -0.15), WHITE)
			continue
		var length: float = spec[1]
		holder.position = Vector3(0.0, -0.02, 0.06 - length / 2.0) if length > 0.2 else Vector3(0, 0, -0.06)
		holder.visible = false
		_set_layers(holder, 2)
		right.add_child(holder)
		weapon_models[w] = holder

	# petite lampe qui n'éclaire QUE l'arme en main (calque 2), pas l'épave
	var hand_light := OmniLight3D.new()
	hand_light.omni_range = 1.2
	hand_light.light_energy = 0.8
	hand_light.light_color = Color(0.7, 0.85, 1.0)
	hand_light.light_cull_mask = 2
	hand_light.position = Vector3(0.1, 0.15, 0.1)
	right.add_child(hand_light)

	# faisceau du découpeur plasma
	plasma_beam = _fit_model("lightning_beam", 1.0, 0.0, false)
	if plasma_beam == null:
		var bm := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.03, 0.03, 1.0)
		bm.mesh = box
		plasma_beam = Node3D.new()
		plasma_beam.add_child(bm)
	_ghost(plasma_beam, _glow(Color(0.55, 0.85, 1.0), 0.8))
	plasma_beam.visible = false
	right.add_child(plasma_beam)

	plasma_light = OmniLight3D.new()
	plasma_light.light_color = Color(0.55, 0.8, 1.0)
	plasma_light.omni_range = 4.5
	plasma_light.light_energy = 0.0
	plasma_light.position = Vector3(0, 0, -0.3)
	right.add_child(plasma_light)
	# flash de tir : éclaire brièvement l'épave autour de toi (révèle, mais trahit)
	muzzle = OmniLight3D.new()
	muzzle.light_color = Color(1.0, 0.85, 0.6)
	muzzle.omni_range = 7.0
	muzzle.light_energy = 0.0
	muzzle.position = Vector3(0, 0, -0.5)
	right.add_child(muzzle)
	plasma_audio = AudioStreamPlayer3D.new()
	plasma_audio.stream = sfx["plasma"]
	right.add_child(plasma_audio)

	# montre au poignet gauche
	wrist = Label3D.new()
	wrist.pixel_size = 0.00045
	wrist.font_size = 40
	wrist.modulate = AMBER
	wrist.position = Vector3(0.0, 0.05, 0.1)
	wrist.rotation_degrees = Vector3(-70.0, 0.0, 0.0)
	wrist.no_depth_test = true
	left.add_child(wrist)
	wrist_alert = Label3D.new()
	wrist_alert.pixel_size = 0.0005
	wrist_alert.font_size = 40
	wrist_alert.modulate = RED
	wrist_alert.position = Vector3(0.0, 0.07, 0.04)
	wrist_alert.rotation_degrees = Vector3(-70.0, 0.0, 0.0)
	wrist_alert.no_depth_test = true
	left.add_child(wrist_alert)

	# vignette de confort
	var vq := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.35, 0.35)  # à 12 cm de l'œil : couvre le champ de vision
	vq.mesh = qm
	var sh := Shader.new()
	sh.code = VIGNETTE_SHADER
	vignette_mat = ShaderMaterial.new()
	vignette_mat.shader = sh
	vignette_mat.render_priority = 10
	vq.material_override = vignette_mat
	vq.position = Vector3(0, 0, -0.12)
	camera.add_child(vq)

	ring = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.97
	tm.outer_radius = 1.0
	tm.rings = 96
	ring.mesh = tm
	ring_mat = _glow(BLUE, 0.0)
	ring.material_override = ring_mat
	ring.visible = false
	add_child(ring)


## Instancie res://assets/models/<name>.glb, centré et mis à l'échelle :
## upright = false → plus grande dimension ramenée sur l'axe -Z (arme) de longueur size ;
## upright = true → hauteur = size, posé au sol, centré en X/Z (monstre).
func _fit_model(name: String, size: float, yaw_fix: float, upright: bool) -> Node3D:
	# ajusté une seule fois puis dupliqué : un écho ne refait ni l'instanciation ni la boîte englobante
	var key := "%s|%s|%s|%s" % [name, size, yaw_fix, upright]
	if not _fitted.has(key):
		_fitted[key] = _fit_model_build(name, size, yaw_fix, upright)
	var tpl: Node3D = _fitted[key]
	return tpl.duplicate() if tpl != null else null


func _fit_model_build(name: String, size: float, yaw_fix: float, upright: bool) -> Node3D:
	var path := "res://assets/models/%s.glb" % name
	if not _model_cache.has(name):
		_model_cache[name] = load(path) if ResourceLoader.exists(path) else null
	var ps: PackedScene = _model_cache[name]
	if ps == null:
		return null
	var inst: Node3D = ps.instantiate()
	var acc := [null]
	_collect_aabb(inst, Transform3D(), acc)
	if acc[0] == null:
		return null
	var box: AABB = acc[0]
	var holder := Node3D.new()
	var pivot := Node3D.new()
	holder.add_child(pivot)
	pivot.add_child(inst)
	var c := box.get_center()
	if upright:
		inst.position = Vector3(-c.x, -box.position.y, -c.z)
		holder.scale = Vector3.ONE * (size / maxf(box.size.y, 0.001))
	else:
		inst.position = -c
		var s := box.size
		if s.x >= s.y and s.x >= s.z:
			pivot.rotation.y = PI / 2.0      # X le plus long → Z
		elif s.y > s.z:
			pivot.rotation.x = PI / 2.0      # Y le plus long → Z
		holder.scale = Vector3.ONE * (size / maxf(maxf(s.x, s.y), maxf(s.z, 0.001)))
	pivot.rotation.y += deg_to_rad(yaw_fix)
	return holder


func _collect_aabb(n: Node, xf: Transform3D, acc: Array) -> void:
	if n is Node3D:
		xf = xf * (n as Node3D).transform
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		var a: AABB = xf * (n as MeshInstance3D).mesh.get_aabb()
		acc[0] = a if acc[0] == null else (acc[0] as AABB).merge(a)
	for ch in n.get_children():
		_collect_aabb(ch, xf, acc)


func _set_layers(n: Node, layers: int) -> void:
	if n is VisualInstance3D:
		(n as VisualInstance3D).layers = layers
	for ch in n.get_children():
		_set_layers(ch, layers)


## Remplace tous les matériaux d'un modèle (silhouette lumineuse du sonar).
func _ghost(n: Node, mat: Material) -> void:
	if n is MeshInstance3D:
		(n as MeshInstance3D).material_override = mat
		(n as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for ch in n.get_children():
		_ghost(ch, mat)


func _model(mesh: PrimitiveMesh, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	if mesh is BoxMesh:
		mesh.size = size
	elif mesh is SphereMesh:
		mesh.radius = size.x
		mesh.height = size.x * 2.0
	mi.mesh = mesh
	mi.material_override = _glow(color, 0.8)
	mi.position = pos
	mi.visible = false
	right.add_child(mi)
	return mi


func _build_ui() -> void:
	panel = Node3D.new()
	add_child(panel)
	var bg := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(1.5, 1.1)
	bg.mesh = qm
	bg.material_override = _glow(Color(0.01, 0.02, 0.04), 0.85)
	bg.position = Vector3(0, 0, -0.01)
	panel.add_child(bg)
	panel_title = _panel_label(Vector3(0, 0.44, 0), 64, AMBER)
	for i in 12:
		panel_items.append(_panel_label(Vector3(0, 0.3 - i * 0.075, 0), 38, AMBER))
	panel_text = _panel_label(Vector3(0, 0.05, 0), 40, BLUE)
	panel_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_text.width = 1300.0

	laser = MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(0.003, 0.003, 1.0)
	laser.mesh = lm
	laser.material_override = _glow(BLUE, 0.7)
	laser.visible = false
	right.add_child(laser)


func _panel_label(pos: Vector3, size: int, color: Color) -> Label3D:
	var l := Label3D.new()
	l.position = pos
	l.pixel_size = 0.001
	l.font_size = size
	l.modulate = color
	l.outline_size = 0
	panel.add_child(l)
	return l


## Place le panneau 1,4 m devant le regard, tourné vers le joueur.
func _place_panel() -> void:
	var f := forward2()
	var c := camera.global_position
	panel.global_position = Vector3(c.x + f.x * 1.4, c.y, c.z + f.y * 1.4)
	panel.look_at(Vector3(c.x, c.y, c.z), Vector3.UP, true)


func _clear_level() -> void:
	for c in world.get_children():
		c.queue_free()
	for list in [marks, waves, decoys, throws, traces, torpedoes]:
		for e in list:
			e["node"].queue_free()
		list.clear()
	effects.clear()
	monsters.clear()


func load_level(rows: Array) -> void:
	_clear_level()
	grid.clear()
	floor_cells.clear()
	beacons.clear()
	supplies.clear()
	medkits.clear()
	has_exit = false
	ping_t = -99.0
	beam_t = -99.0
	level_time = 0.0
	pings_used = 0
	kills = 0
	hp = PLAYER_HP
	wound_flash = 0.0
	oxygen = OXYGEN
	ammo = START_AMMO.duplicate()
	reload_t = 0.0
	trigger_held = false
	holding = ""
	step_acc = 0.0
	next_heart = 0.0
	state = "play"
	panel.visible = false

	gw = 0
	for r in rows:
		gw = maxi(gw, String(r).length())
	gh = rows.size()
	for r in rows:
		grid.append(String(r).rpad(gw, "#"))

	var box := BoxMesh.new()
	box.size = Vector3(1.0, WALL_H, 1.0)
	for y in gh:
		for x in gw:
			var ch := grid[y][x]
			var p := Vector2(x + 0.5, y + 0.5)
			if ch == "#":
				var mi := MeshInstance3D.new()
				mi.mesh = box
				mi.material_override = wall_mat
				mi.position = Vector3(p.x, WALL_H / 2.0, p.y)
				world.add_child(mi)
				continue
			floor_cells.append(Vector2i(x, y))
			match ch:
				"P": start_pos = p
				"B": beacons.append(p)
				"A": supplies.append(p)
				"H": medkits.append(p)
				"X":
					exit_pos = p
					has_exit = true
				"M", "T", "C":
					var m := Monster.new()
					m.kind = ch
					m.pos = p
					m.hp = MONSTER_KINDS[ch]["hp"]
					monsters.append(m)
	total_beacons = beacons.size()

	var fl := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(gw, gh)
	fl.mesh = pm
	fl.material_override = wall_mat
	fl.position = Vector3(gw / 2.0, 0.0, gh / 2.0)
	world.add_child(fl)

	# regard vers la direction la plus ouverte, puis recentrage sur la tête
	var yaw := -PI / 2.0
	var best := -1.0
	for k in 4:
		var a := k * PI / 2.0
		var d := cast(start_pos, Vector2(cos(a), sin(a)), 20.0)
		if d < 0.0:
			d = 99.0  # aucun mur à 20 m : le plus ouvert
		if d > best:
			best = d
			yaw = -PI / 2.0 - a
	origin.global_transform = Transform3D(Basis(Vector3.UP, yaw),
		Vector3(start_pos.x, 0.45 if seated else 0.0, start_pos.y))
	last_valid_head = start_pos
	recenter_to = start_pos
	recenter_frames = 3
	hand_fresh = true
	pause_t0 = -1.0
	_select_weapon(weapon)


func level_count() -> int:
	return LEVELS.size() + CAMPAIGN_GEN.size()


func _campaign_rows(i: int) -> Array:
	if i < LEVELS.size():
		return LEVELS[i]
	var g: Array = CAMPAIGN_GEN[i - LEVELS.size()]
	return MazeGen.generate(g[0], g[1])


func start_campaign(i: int = 0) -> void:
	game_mode = "campaign"
	game_active = true
	level_idx = i
	if i == 0:
		total_time = 0.0
	load_level(_campaign_rows(i))


func start_endless() -> void:
	game_mode = "endless"
	game_active = true
	endless_depth = 0
	endless_seed = randi()
	load_level(MazeGen.generate(endless_seed, endless_depth))


func restart_level() -> void:
	if game_mode == "campaign":
		start_campaign(level_idx)
	elif game_mode == "endless":
		load_level(MazeGen.generate(endless_seed, endless_depth))


# ---------------------------------------------------------------- géométrie

func wall(x: float, y: float) -> bool:
	var ix := floori(x)
	var iy := floori(y)
	if ix < 0 or iy < 0 or ix >= gw or iy >= gh:
		return true
	return grid[iy][ix] == "#"


## Distance jusqu'au premier mur, ou -1 si rien avant maxd (dir normalisé).
## Parcours case par case (DDA) : exact et ~20× moins d'appels qu'un pas fixe.
func cast(o: Vector2, dir: Vector2, maxd: float) -> float:
	var cx := floori(o.x)
	var cy := floori(o.y)
	if wall(o.x, o.y):
		return 0.0
	var sx := 1 if dir.x > 0.0 else -1
	var sy := 1 if dir.y > 0.0 else -1
	var tdx := absf(1.0 / dir.x) if dir.x != 0.0 else INF
	var tdy := absf(1.0 / dir.y) if dir.y != 0.0 else INF
	var tx := ((cx + 1.0 - o.x) if dir.x > 0.0 else (o.x - cx)) * tdx if dir.x != 0.0 else INF
	var ty := ((cy + 1.0 - o.y) if dir.y > 0.0 else (o.y - cy)) * tdy if dir.y != 0.0 else INF
	while true:
		var t: float
		if tx < ty:
			t = tx
			tx += tdx
			cx += sx
		else:
			t = ty
			ty += tdy
			cy += sy
		if t > maxd:
			return -1.0
		if wall(cx + 0.5, cy + 0.5):
			return t
	return -1.0


func is_visible_from(a: Vector2, b: Vector2) -> bool:
	return cast(a, (b - a).normalized(), a.distance_to(b)) < 0.0


func collides(p: Vector2) -> bool:
	for ox in [-PLAYER_R, PLAYER_R]:
		for oy in [-PLAYER_R, PLAYER_R]:
			if wall(p.x + ox, p.y + oy):
				return true
	return false


func cell_of(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x), floori(p.y))


func head_pos() -> Vector2:
	var g := camera.global_position
	return Vector2(g.x, g.z)


func forward2() -> Vector2:
	var z := camera.global_basis.z
	return Vector2(-z.x, -z.z).normalized()


func right2() -> Vector2:
	var x := camera.global_basis.x
	return Vector2(x.x, x.z).normalized()


func hand_pos() -> Vector3:
	return right.global_position


func hand_dir() -> Vector3:
	return -right.global_basis.z


## Lacet estimé du torse : suit la tête avec une zone morte (le gilet est sur le torse).
func _update_body(dt: float, moving: bool) -> void:
	var f := forward2()
	var head_yaw := rad_to_deg(atan2(f.x, -f.y))
	var diff := Vest.angle_diff(head_yaw, body_yaw)
	if absf(diff) > BODY_DEADZONE:
		body_yaw += diff - signf(diff) * BODY_DEADZONE
		diff = Vest.angle_diff(head_yaw, body_yaw)
	body_yaw += diff * minf(1.0, dt * (2.5 if moving else 0.4))


## Angle (degrés) d'un point vu depuis le torse : + = droite.
func rel_angle(p: Vector2) -> float:
	var d := p - head_pos()
	return Vest.angle_diff(rad_to_deg(atan2(d.x, -d.y)), body_yaw)


func next_step(start: Vector2i, goal: Vector2i) -> Variant:
	if start == goal:
		return goal
	var prev := {start: start}
	var q: Array[Vector2i] = [start]
	while not q.is_empty():
		var cur: Vector2i = q.pop_front()
		if cur == goal:
			break
		for n in [cur + Vector2i.RIGHT, cur + Vector2i.LEFT, cur + Vector2i.DOWN, cur + Vector2i.UP]:
			if not prev.has(n) and not wall(n.x + 0.5, n.y + 0.5):
				prev[n] = cur
				q.append(n)
	if not prev.has(goal):
		return null
	var c: Vector2i = goal
	while prev[c] != start:
		c = prev[c]
	return c


# ---------------------------------------------------------------- outils communs

func _fx(kind: String, p: Variant = null, rel: float = 0.0, inten: float = 1.0) -> Dictionary:
	return {"kind": kind, "t0": now, "dur": FX_DUR[kind], "point": p, "rel": rel, "i": inten}


func _play(name: String, at: Variant = null, db: float = 0.0) -> void:
	if not sfx.has(name):
		return
	if at == null:
		var a := AudioStreamPlayer.new()
		a.stream = sfx[name]
		a.volume_db = db
		add_child(a)
		a.play()
		a.finished.connect(a.queue_free)
	else:
		var a3 := AudioStreamPlayer3D.new()
		a3.stream = sfx[name]
		a3.volume_db = db
		a3.unit_size = 4.0
		add_child(a3)
		a3.global_position = Vector3(at.x, 1.2, at.y)
		a3.play()
		a3.finished.connect(a3.queue_free)


## Vibration de manette (no-op sans casque).
func _rumble(c: XRController3D, amp: float, dur: float) -> void:
	if vr:
		c.trigger_haptic_pulse("haptic", 0.0, amp, dur, 0.0)


## Le bruit attire les monstres à portée d'oreille. Il contourne les murs :
## un monstre l'entend si le chemin jusqu'à lui reste court (portée × HEARING_DETOUR).
func noise(p: Vector2, radius: float) -> void:
	for m in monsters:
		if m.pos.distance_to(p) > radius:
			continue
		if not is_visible_from(p, m.pos) and path_len(cell_of(p), cell_of(m.pos), int(radius * HEARING_DETOUR)) < 0:
			continue
		m.target = cell_of(p)
		m.has_target = true
		if m.mode != "charge":
			m.mode = "hunt"


## Longueur du chemin en cases (BFS), ou -1 s'il dépasse limit.
func path_len(a: Vector2i, b: Vector2i, limit: int) -> int:
	if a == b:
		return 0
	var dist := {a: 0}
	var q: Array[Vector2i] = [a]
	while not q.is_empty():
		var c: Vector2i = q.pop_front()
		var dc: int = dist[c]
		if dc >= limit:
			continue
		for n in [c + Vector2i.RIGHT, c + Vector2i.LEFT, c + Vector2i.DOWN, c + Vector2i.UP]:
			if not dist.has(n) and not wall(n.x + 0.5, n.y + 0.5):
				if n == b:
					return dc + 1
				dist[n] = dc + 1
				q.append(n)
	return -1


# ---------------------------------------------------------------- sonar

func ping() -> void:
	if state != "play" or now - ping_t < PING_COOLDOWN:
		return
	ping_t = now
	pings_used += 1
	var o := head_pos()
	ping_origin = o
	var dirs := []
	for k in RAYS:
		var a := TAU * k / RAYS
		dirs.append(Vector2(cos(a), sin(a)))
	_emit_wave(o, dirs, PING_RANGE, -1.0, Vector2.ZERO)
	effects.append(_fx("ping"))
	_play("ping")
	_rumble(right, 0.3, 0.05)
	noise(o, PING_NOISE)


## Faisceau : visé avec la main gauche.
func beam() -> void:
	if state != "play" or now - beam_t < BEAM_COOLDOWN:
		return
	beam_t = now
	pings_used += 1
	var o := head_pos()
	var d3 := -left.global_basis.z
	var f := Vector2(d3.x, d3.z).normalized()
	if f == Vector2.ZERO:
		f = forward2()
	var base := atan2(f.y, f.x)
	var dirs := []
	for k in BEAM_RAYS:
		var a := base + deg_to_rad(lerpf(-BEAM_HALF, BEAM_HALF, float(k) / (BEAM_RAYS - 1)))
		dirs.append(Vector2(cos(a), sin(a)))
	_emit_wave(o, dirs, BEAM_RANGE, BEAM_HALF + 5.0, f)
	effects.append(_fx("beam", null, rel_angle(o + f)))
	_play("beam")
	_rumble(left, 0.4, 0.15)
	noise(o, BEAM_NOISE)


## Onde d'écho : cone_half < 0 = sonar omnidirectionnel, sinon faisceau autour de axis.
func _emit_wave(o: Vector2, dirs: Array, maxd: float, cone_half: float, axis: Vector2) -> void:
	var entries := []
	for dir in dirs:
		var d := cast(o, dir, maxd)
		if d >= 0.0:
			entries.append({"d": d, "kind": "wall", "p": o + dir * d,
				"i": 0.3 + 0.7 * pow(1.0 - d / maxd, 1.5)})
	var targets := []
	for b in beacons:
		targets.append(["beacon", b, 0.7])
	for s in supplies:
		targets.append(["supply", s, 0.7])
	for s in medkits:
		targets.append(["medkit", s, 0.7])
	if has_exit:
		targets.append(["exit", exit_pos, 0.8 if beacons.is_empty() else 0.35])
	for m in monsters:
		targets.append(["monster", m.pos, 1.0, m.kind])
	for t in targets:
		var p: Vector2 = t[1]
		var d := o.distance_to(p)
		if d > maxd or not is_visible_from(o, p):
			continue
		if cone_half > 0.0 and absf(rad_to_deg(axis.angle_to(p - o))) > cone_half:
			continue
		var e := {"d": d, "kind": t[0], "p": p, "i": t[2]}
		if t.size() > 3:
			e["mkind"] = t[3]
		entries.append(e)
	entries.sort_custom(func(a, b): return a["d"] < b["d"])

	# nuage de points des murs révélé au fil de l'onde
	var walls := entries.filter(func(e): return e["kind"] == "wall")
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = point_mesh
	mm.instance_count = walls.size() * POINT_HEIGHTS.size()
	mm.visible_instance_count = 0
	for j in walls.size():
		var e: Dictionary = walls[j]
		e["mi"] = j
		var p: Vector2 = e["p"]
		var bright: float = 0.35 + 0.65 * e["i"]
		for k in POINT_HEIGHTS.size():
			var idx := j * POINT_HEIGHTS.size() + k
			mm.set_instance_transform(idx, Transform3D(Basis(), Vector3(p.x, POINT_HEIGHTS[k], p.y)))
			mm.set_instance_color(idx, Color(BLUE.r * bright, BLUE.g * bright, BLUE.b * bright))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	var mat := _glow(Color.WHITE, 1.0)
	mat.vertex_color_use_as_albedo = true
	mmi.material_override = mat
	add_child(mmi)
	waves.append({"t0": now, "entries": entries, "node": mmi, "mm": mm, "mat": mat})


func _update_waves() -> void:
	var keep := []
	for w in waves:
		var r: float = (now - w["t0"]) * PING_SPEED
		var entries: Array = w["entries"]
		var mm: MultiMesh = w["mm"]
		while not entries.is_empty() and entries[0]["d"] <= r:
			var e: Dictionary = entries.pop_front()
			var kind: String = e["kind"]
			effects.append(_fx(kind, e["p"], 0.0, e["i"]))
			if kind == "wall":
				mm.visible_instance_count = maxi(mm.visible_instance_count, (int(e["mi"]) + 1) * POINT_HEIGHTS.size())
				continue
			_spawn_mark(e["p"], kind, e.get("mkind", "M"))
			_play("growl" if kind == "monster" else "relay", e["p"])
		var age: float = now - w["t0"]
		w["mat"].albedo_color = Color(1, 1, 1, clampf(1.0 - (age - 0.5) / MARK_LIFE, 0.0, 1.0))
		if entries.is_empty() and age > MARK_LIFE + 0.5:
			w["node"].queue_free()
		else:
			keep.append(w)
	waves = keep


# ---------------------------------------------------------------- armes

func _select_weapon(w: String) -> void:
	weapon = w
	trigger_held = false
	holding = ""
	for k in weapon_models:
		weapon_models[k].visible = k == w and state == "play"


func next_weapon() -> void:
	_select_weapon(WEAPONS[(WEAPONS.find(weapon) + 1) % WEAPONS.size()])
	effects.append(_fx("tick", null, 0.0, 0.5))
	_rumble(right, 0.25, 0.04)
	_play("relay", null, -6.0)


func weapon_press() -> void:
	if state != "play":
		return
	match weapon:
		"harpoon":
			fire_harpoon()
		"nailgun":
			fire_nailgun()
		"torpedo":
			fire_torpedo()
		"plasma":
			trigger_held = true
		"grenade", "decoy":
			if ammo[weapon] > 0:
				holding = weapon


func weapon_release() -> void:
	trigger_held = false
	if holding != "" and state == "play":
		throw_held()


func _hit(m: Monster, dmg: float, from: Vector2) -> void:
	m.hp -= dmg
	m.stun_t = maxf(m.stun_t, 0.35)
	m.target = cell_of(head_pos())
	m.has_target = true
	if m.mode == "wander":
		m.mode = "hunt"
	effects.append(_fx("hit", m.pos))
	_play("hit", m.pos)
	if m.hp <= 0.0:
		monsters.erase(m)
		kills += 1
		effects.append(_fx("kill", m.pos))
		_play("collapse", m.pos)
		_spawn_mark(m.pos, "corpse", m.kind)
	else:
		# recul : le coup le repousse un peu
		var push := (m.pos - from).normalized() * 0.35
		if not wall(m.pos.x + push.x, m.pos.y + push.y):
			m.pos += push


## Portée horizontale d'un tir en tenant compte de l'inclinaison :
## il s'arrête là où il touche le sol ou le plafond.
func _aim_reach(o3: Vector3, d3: Vector3, rng: float) -> float:
	var hl := Vector2(d3.x, d3.z).length()
	if hl < 0.2:
		return 0.0  # tir quasi vertical : droit dans le plancher ou le plafond
	var t := INF
	if d3.y < -0.001:
		t = o3.y / -d3.y
	elif d3.y > 0.001:
		t = (WALL_H - o3.y) / d3.y
	return minf(rng, t * hl)


## Rayon dans le plan : [monstre touché ou null, point d'arrêt, distance].
func _ray(o: Vector2, dir: Vector2, maxd: float) -> Array:
	var p := o
	var dist := 0.0
	while dist < maxd:
		p += dir * 0.05
		dist += 0.05
		if wall(p.x, p.y):
			return [null, p, dist]
		for m in monsters:
			if p.distance_to(m.pos) < 0.4 * MONSTER_KINDS[m.kind]["scale"]:
				return [m, p, dist]
	return [null, p, dist]


## Tâter les murs à la main : la manette vibre, le gilet frémit de ce côté.
func _check_touch(c: XRController3D) -> void:
	var p := c.global_position
	if not wall(p.x, p.z) or now - touch_t.get(c, -1.0) < 0.12:
		return
	touch_t[c] = now
	_rumble(c, 0.35, 0.05)
	effects.append(_fx("touch", Vector2(p.x, p.z), 0.0, 0.3))


## Contrôle munitions + recharge ; renvoie false (clic à vide) si on ne peut pas tirer.
func _can_fire(w: String, reload: float) -> bool:
	if reload_t > 0.0 or ammo[w] <= 0:
		_play("relay", null, -10.0)
		_rumble(right, 0.1, 0.02)
		return false
	ammo[w] -= 1
	reload_t = reload
	muzzle.light_energy = 3.0
	return true


func fire_harpoon() -> void:
	if not _can_fire("harpoon", HARPOON_RELOAD):
		return
	var o3 := hand_pos()
	var o := Vector2(o3.x, o3.z)
	var d3 := hand_dir()
	var hl := maxf(Vector2(d3.x, d3.z).length(), 0.001)
	var r := _ray(o, Vector2(d3.x, d3.z) / hl, _aim_reach(o3, d3, HARPOON_RANGE))
	var p: Vector2 = r[1]
	_trace(o3, Vector3(p.x, o3.y + d3.y / hl * float(r[2]), p.y), WHITE)
	effects.append(_fx("recoil", null, 25.0))
	_rumble(right, 0.9, 0.12)
	_play("harpoon", o)
	noise(o, WEAPON_NOISE["harpoon"])
	if r[0] != null:
		_hit(r[0], HARPOON_DMG, o)
	else:
		_play("relay", p)  # le harpon se plante dans la tôle


## Riveteuse : gerbe de rivets à courte portée.
func fire_nailgun() -> void:
	if not _can_fire("nailgun", NAIL_RELOAD):
		return
	var o3 := hand_pos()
	var o := Vector2(o3.x, o3.z)
	var d3 := hand_dir()
	var hl := maxf(Vector2(d3.x, d3.z).length(), 0.001)
	var base := Vector2(d3.x, d3.z) / hl
	var reach := _aim_reach(o3, d3, NAIL_RANGE)
	var dmg := {}
	for k in NAIL_PELLETS:
		var dir := base.rotated(deg_to_rad(randf_range(-NAIL_SPREAD, NAIL_SPREAD)))
		var r := _ray(o, dir, reach)
		var p: Vector2 = r[1]
		_trace(o3, Vector3(p.x, o3.y + d3.y / hl * float(r[2]), p.y), AMBER)
		if r[0] != null:
			dmg[r[0]] = dmg.get(r[0], 0.0) + NAIL_DMG
	for m in dmg:
		_hit(m, dmg[m], o)
	effects.append(_fx("recoil", null, 25.0, 1.0))
	effects.append(_fx("bump", null, 0.0))
	_rumble(right, 1.0, 0.15)
	_play("harpoon", o, 3.0)
	_play("zap", o)
	noise(o, WEAPON_NOISE["nailgun"])


## Lance-torpille : projectile qui explose au contact.
func fire_torpedo() -> void:
	if not _can_fire("torpedo", TORPEDO_RELOAD):
		return
	var o3 := hand_pos() + hand_dir() * 0.4
	var node: Node3D = _fit_model("rocket_ammo", 0.35, 0.0, false)
	if node == null:
		node = MeshInstance3D.new()
		var cm := CapsuleMesh.new()
		cm.radius = 0.05
		cm.height = 0.3
		(node as MeshInstance3D).mesh = cm
	_ghost(node, _glow(AMBER, 1.0))
	add_child(node)
	node.global_position = o3
	var v := hand_dir() * TORPEDO_SPEED
	if v.length() > 0.01:
		node.look_at(o3 + v, Vector3.UP if absf(v.normalized().y) < 0.99 else Vector3.RIGHT)
	torpedoes.append({"pos": o3, "vel": v, "t0": now, "node": node})
	effects.append(_fx("recoil", null, 25.0, 1.0))
	_rumble(right, 0.8, 0.2)
	_play("beam", Vector2(o3.x, o3.z))
	noise(Vector2(o3.x, o3.z), WEAPON_NOISE["torpedo"] * 0.5)


func _update_torpedoes(dt: float) -> void:
	var keep := []
	for t in torpedoes:
		var prev: Vector3 = t["pos"]
		var p: Vector3 = prev + t["vel"] * dt
		var p2 := Vector2(p.x, p.z)
		var boom: bool = p.y < 0.05 or p.y > WALL_H or now - t["t0"] > 4.0
		if wall(p.x, p.z):
			# explose contre la paroi, pas dedans : sinon le souffle serait bloqué par le mur
			boom = true
			p = prev
			p2 = Vector2(prev.x, prev.z)
		t["pos"] = p
		t["node"].global_position = p
		for m in monsters:
			if p2.distance_to(m.pos) < 0.45 * MONSTER_KINDS[m.kind]["scale"]:
				boom = true
		if boom:
			t["node"].queue_free()
			_explode(p2, TORPEDO_RADIUS, TORPEDO_DMG)
		else:
			keep.append(t)
	torpedoes = keep


func _update_weapons(dt: float) -> void:
	if reload_t > 0.0 and reload_t - dt <= 0.0 and weapon in ["harpoon", "nailgun", "torpedo"] and ammo[weapon] > 0:
		effects.append(_fx("ready", null, 25.0, 0.5))  # clic de réarmement senti
		_rumble(right, 0.25, 0.03)
		_play("relay", null, -8.0)
	reload_t = maxf(0.0, reload_t - dt)
	muzzle.light_energy = maxf(0.0, muzzle.light_energy - dt * 30.0)
	_check_touch(left)
	_check_touch(right)
	knife_cd = maxf(0.0, knife_cd - dt)
	var hp3 := hand_pos()
	# vitesse de la main dans le repère du joueur : déplacement au stick, rotations,
	# recul et téléportations ne comptent pas comme un geste
	var local := origin.global_transform.affine_inverse() * hp3
	if hand_fresh:
		hand_fresh = false
		hand_prev = local
	hand_vel = origin.global_basis * ((local - hand_prev) / maxf(dt, 0.001))
	if selftest and test_hand_vel != Vector3.ZERO:
		hand_vel = test_hand_vel
	hand_prev = local
	var hp := Vector2(hp3.x, hp3.z)

	# couteau électrique : frappe physique
	if weapon == "knife" and knife_cd <= 0.0 and hand_vel.length() > KNIFE_SPEED:
		var tip3 := hp3 + hand_dir() * 0.3
		var tip := Vector2(tip3.x, tip3.z)
		for m in monsters:
			if tip.distance_to(m.pos) < 0.45 * MONSTER_KINDS[m.kind]["scale"] + 0.2:
				knife_cd = 0.35
				_hit(m, KNIFE_DMG, hp)
				_play("zap", tip)
				_rumble(right, 1.0, 0.1)
				effects.append(_fx("slash", null, 30.0))
				noise(hp, WEAPON_NOISE["knife"])
				break
		if knife_cd <= 0.0 and wall(tip.x, tip.y):
			knife_cd = 0.3
			_play("zap", tip, -6.0)
			_rumble(right, 0.6, 0.05)

	# découpeur plasma : maintenu, éclaire autour de toi mais fait du bruit
	var firing: bool = weapon == "plasma" and trigger_held and ammo["plasma"] > 0.0
	if firing:
		ammo["plasma"] = maxf(0.0, ammo["plasma"] - dt)
		var dir := Vector2(hand_dir().x, hand_dir().z).normalized()
		var reach := cast(hp, dir, PLASMA_RANGE)
		if reach < 0.0:
			reach = PLASMA_RANGE
		for m in monsters.duplicate():
			var rel: Vector2 = m.pos - hp
			var along := rel.dot(dir)
			if along > 0.0 and along < reach and absf(rel.cross(dir)) < 0.45 * MONSTER_KINDS[m.kind]["scale"]:
				m.hp -= PLASMA_DPS * dt
				m.stun_t = maxf(m.stun_t, 0.1)
				if m.hp <= 0.0:
					_hit(m, 0.0, hp)
		plasma_noise_t -= dt
		if plasma_noise_t <= 0.0:
			plasma_noise_t = 0.5
			noise(hp, WEAPON_NOISE["plasma"])
		_rumble(right, 0.35, 0.06)
		if not plasma_audio.playing:
			plasma_audio.play()
	elif plasma_audio.playing:
		plasma_audio.stop()
	plasma_light.light_energy = lerpf(plasma_light.light_energy, (1.6 + randf() * 0.6) if firing else 0.0, 0.3)
	plasma_beam.visible = firing
	if firing:
		var reach2 := cast(hp, Vector2(hand_dir().x, hand_dir().z).normalized(), PLASMA_RANGE)
		var L := PLASMA_RANGE if reach2 < 0.0 else reach2
		plasma_beam.position = Vector3(0, 0, -0.3 - L / 2.0)
		plasma_beam.scale = Vector3(0.25 + randf() * 0.1, 0.25 + randf() * 0.1, L)

	_update_throws(dt)
	_update_torpedoes(dt)


func throw_held() -> void:
	var kind := holding
	holding = ""
	if ammo[kind] <= 0:
		return
	ammo[kind] -= 1
	var spec: Array = WEAPON_MODELS[kind]
	var mi: Node3D = _fit_model(spec[0], spec[1], 0.0, false)
	if mi == null:
		var sph := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.07 if kind == "grenade" else 0.05
		sm.height = sm.radius * 2.0
		sph.mesh = sm
		mi = sph
	_ghost(mi, _glow(AMBER, 1.0))
	add_child(mi)
	var p3 := hand_pos()
	mi.global_position = p3
	var v := hand_vel
	if v.length() < 1.0:  # simple lâcher : il tombe devant toi
		v = hand_dir() * 1.0
	throws.append({"kind": kind, "pos": p3, "vel": v.limit_length(14.0), "t0": now, "node": mi, "rest": false})
	effects.append(_fx("throw", null, 20.0, 0.6))
	_rumble(right, 0.5, 0.06)


## Physique simple des objets lancés : gravité, rebonds sur sol et murs.
func _update_throws(dt: float) -> void:
	var keep := []
	for t in throws:
		var p: Vector3 = t["pos"]
		var v: Vector3 = t["vel"]
		if not t["rest"]:
			v.y -= 9.8 * dt
			var np := p + v * dt
			if wall(np.x, p.z):
				v.x = -v.x * 0.5
				np.x = p.x
				_play("relay", Vector2(p.x, p.z), -8.0)
			if wall(np.x, np.z):
				v.z = -v.z * 0.5
				np.z = p.z
				_play("relay", Vector2(p.x, p.z), -8.0)
			if np.y < 0.06:
				np.y = 0.06
				v.y = -v.y * 0.35
				v.x *= 0.6
				v.z *= 0.6
				if v.length() < 0.4:
					t["rest"] = true
					v = Vector3.ZERO
			p = np
			t["pos"] = p
			t["vel"] = v
			t["node"].global_position = p
		var age: float = now - t["t0"]
		var p2 := Vector2(p.x, p.z)
		if t["kind"] == "grenade" and age >= GRENADE_FUSE:
			_explode(p2, GRENADE_RADIUS, 4.0)
			t["node"].queue_free()
			continue
		if t["kind"] == "decoy" and (t["rest"] or age > 1.5):
			decoys.append({"pos": p2, "left": 3, "next": now + 0.5, "node": t["node"]})
			continue
		keep.append(t)
	throws = keep


func _explode(p: Vector2, radius: float, dmg: float) -> void:
	_play("blast", p, 4.0)
	noise(p, WEAPON_NOISE["grenade"])
	var flash := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	flash.mesh = sm
	var mat := _glow(AMBER, 0.6)
	flash.material_override = mat
	flash.position = Vector3(p.x, 0.8, p.y)
	add_child(flash)
	marks.append({"node": flash, "mat": mat, "color": AMBER, "alpha": 0.6, "t0": now, "life": 0.6, "grow": radius})
	for m in monsters.duplicate():
		var d: float = m.pos.distance_to(p)
		if d < radius and (d < 0.8 or is_visible_from(p, m.pos)):
			m.stun_t = maxf(m.stun_t, 2.0)
			_hit(m, dmg * (1.0 - 0.5 * d / radius), p)
	var dp := head_pos().distance_to(p)
	if dp < 8.0:
		effects.append(_fx("blast", p, 0.0, clampf(1.2 - dp / 8.0, 0.25, 1.0)))
		_rumble(left, 0.8, 0.3)
		_rumble(right, 0.8, 0.3)
	if dp < 2.0 and is_visible_from(p, head_pos()):
		oxygen -= 15.0  # le souffle t'arrache de l'air


# ---------------------------------------------------------------- simulation

func _bump(rel: float) -> void:
	last_bump = now
	effects.append(_fx("bump", null, rel))
	_play("relay")
	_rumble(left, 0.5, 0.06)


## Déplace l'origine en glissant le long des murs. Renvoie true si un mur bloque.
func try_move(delta: Vector2) -> bool:
	var h := head_pos()
	var applied := Vector2.ZERO
	var bumped := false
	if collides(h + Vector2(delta.x, 0.0)):
		bumped = true
	else:
		applied.x = delta.x
	if collides(h + Vector2(applied.x, delta.y)):
		bumped = true
	else:
		applied.y = delta.y
	origin.global_position += Vector3(applied.x, 0.0, applied.y)
	return bumped


func teleport(p: Vector2) -> void:
	var off := p - head_pos()
	origin.global_position += Vector3(off.x, 0.0, off.y)
	last_valid_head = p


func _rotate_origin(deg: float) -> void:
	var pivot := camera.global_position
	var t := origin.global_transform
	t.origin -= pivot
	t = t.rotated(Vector3.UP, deg_to_rad(deg))
	t.origin += pivot
	origin.global_transform = t


func die(cause: String) -> void:
	state = "dead"
	death_cause = cause
	effects.append(_fx("death"))
	_play("drone")
	_rumble(left, 1.0, 0.5)
	_rumble(right, 1.0, 0.5)
	new_record = false
	if game_mode == "endless":
		var best: int = cfg.get_value("scores", "endless_best", 0)
		if endless_depth + 1 > best:
			cfg.set_value("scores", "endless_best", endless_depth + 1)
			new_record = true
			_save_config()
	_show_panel()


func _win() -> void:
	state = "win"
	total_time += level_time
	effects.append(_fx("win"))
	_play("servo")
	_play("relay")
	new_record = false
	if game_mode == "campaign" and level_idx + 1 >= level_count():
		state = "done"
		var best: float = cfg.get_value("scores", "campaign_best", 0.0)
		if best <= 0.0 or total_time < best:
			cfg.set_value("scores", "campaign_best", total_time)
			new_record = true
			_save_config()
	_show_panel()


func _advance() -> void:
	match state:
		"dead":
			if game_mode == "endless":
				game_active = false
				open_menu()
			else:
				restart_level()
		"win":
			if game_mode == "campaign":
				start_campaign(level_idx + 1)
			else:
				endless_depth += 1
				endless_seed = randi()
				load_level(MazeGen.generate(endless_seed, endless_depth))
		"done":
			game_active = false
			open_menu()


func _update(dt: float) -> void:
	if state != "play":
		_update_body(dt, false)
		return
	level_time += dt
	oxygen -= dt
	if oxygen <= 0.0:
		oxygen = 0.0
		die("oxygen")
		return

	# la tête physique ne traverse pas les murs : on repousse l'origine
	var h := head_pos()
	var seg := h - last_valid_head
	var crossed := seg.length() > 0.05 and cast(last_valid_head, seg.normalized(), seg.length()) >= 0.0
	if collides(h) or crossed:  # y compris un mur franchi d'un coup (pause, recentrage)
		var push := h - last_valid_head
		if now - last_bump > 0.35:
			_bump(rel_angle(h + push.normalized()))
		origin.global_position -= Vector3(push.x, 0.0, push.y)
	else:
		last_valid_head = h

	var mv := Vector2.ZERO  # x = pas de côté, y = avant
	var running := false
	var turning := false
	if vr:
		mv = left.get_vector2("primary")
		running = left.get_float("grip") > 0.5
		var tx := right.get_vector2("primary").x
		if turn_mode == "smooth":
			if absf(tx) > 0.2:
				_rotate_origin(-tx * SMOOTH_TURN * dt)
				turning = true
		elif absf(tx) > 0.7 and snap_ready:
			snap_ready = false
			_rotate_origin(-signf(tx) * (45.0 if turn_mode == "snap45" else 30.0))
		elif absf(tx) < 0.3:
			snap_ready = true
	else:
		mv = test_move
		running = test_run
	var moving := mv.length() > 0.15
	if moving:
		var speed := RUN_SPEED if running else WALK_SPEED
		var delta := (forward2() * mv.y + right2() * mv.x).limit_length(1.0) * speed * dt
		var before := head_pos()
		if try_move(delta) and now - last_bump > 0.35:
			_bump(rad_to_deg(atan2(mv.x, mv.y)))
		last_valid_head = head_pos()
		step_acc += before.distance_to(last_valid_head)
		if step_acc >= STEP_LEN:
			step_acc = 0.0
			step_left = not step_left
			effects.append(_fx("step", null, -30.0 if step_left else 30.0, 0.4 if running else 0.22))
			_play("step", null, 0.0 if running else -8.0)
			if running:
				noise(last_valid_head, RUN_NOISE)
	_update_body(dt, moving)
	var vt := 0.85 if comfort and (moving or turning) else 0.0
	vignette = lerpf(vignette, vt, minf(1.0, dt * 6.0))

	_update_waves()
	_update_weapons(dt)
	if state != "play":
		return

	# balises, munitions et sortie
	h = head_pos()
	for b in beacons.duplicate():
		if h.distance_to(b) < 0.6:
			beacons.erase(b)
			oxygen += OXYGEN_BEACON
			effects.append(_fx("pickup"))
			_play("servo")
			_rumble(left, 0.6, 0.2)
	for s in supplies.duplicate():
		if h.distance_to(s) < 0.6:
			supplies.erase(s)
			for k in SUPPLY:
				ammo[k] = minf(ammo[k] + SUPPLY[k], MAX_AMMO[k]) if k == "plasma" else mini(ammo[k] + SUPPLY[k], MAX_AMMO[k])
			effects.append(_fx("resupply"))
			_play("servo")
			_rumble(right, 0.6, 0.2)
	for s in medkits.duplicate():
		if h.distance_to(s) < 0.6 and hp < PLAYER_HP:
			medkits.erase(s)
			hp += 1
			effects.append(_fx("heal", null, 0.0, 0.8))
			_play("servo")
			_rumble(left, 0.5, 0.25)
	if has_exit and beacons.is_empty() and h.distance_to(exit_pos) < 0.6:
		_win()
		return

	# leurres : 3 impulsions bruyantes loin de toi
	for d in decoys.duplicate():
		if now >= d["next"]:
			noise(d["pos"], DECOY_NOISE)
			_play("decoy", d["pos"])
			d["left"] -= 1
			d["next"] = now + 2.0
			if d["left"] <= 0:
				d["node"].queue_free()
				decoys.erase(d)

	var nearest := INF
	for m in monsters:
		_update_monster(m, dt)
		var dm := h.distance_to(m.pos)
		nearest = minf(nearest, dm)
		m.attack_cd = maxf(0.0, m.attack_cd - dt)
		if dm < 0.6 * MONSTER_KINDS[m.kind]["scale"] and m.attack_cd <= 0.0:
			_wounded(m)
			if hp <= 0:
				die("monster")
				return
	if hp == 1:
		nearest = minf(nearest, HEART_RANGE * 0.4)  # blessé : le cœur cogne

	# ton cœur s'emballe quand un monstre approche
	if nearest < HEART_RANGE and now >= next_heart:
		var bpm := lerpf(70.0, 165.0, 1.0 - nearest / HEART_RANGE)
		next_heart = now + 60.0 / bpm
		effects.append(_fx("heart", null, -20.0, 0.25 + 0.35 * (1.0 - nearest / HEART_RANGE)))
		_play("heart", null, -10.0 + 8.0 * (1.0 - nearest / HEART_RANGE))
	if oxygen < OXYGEN_LOW:
		if now >= next_squeeze:
			next_squeeze = now + 1.5
			effects.append(_fx("squeeze", null, 0.0, 0.7))
		if now >= next_alarm:
			next_alarm = now + 3.0
			_play("alarm")


## Quand un monstre te voit, il rugit : la meute proche converge vers lui.
func _roar(src: Monster) -> void:
	var others := 0
	for o in monsters:
		if o != src and o.pos.distance_to(src.pos) < ROAR_RADIUS and o.mode == "wander":
			o.target = cell_of(src.pos)
			o.has_target = true
			o.mode = "hunt"
			others += 1
	if others > 0 or head_pos().distance_to(src.pos) > CHARGE_RANGE:
		effects.append(_fx("roar", src.pos, 0.0, 0.6))


## Coup de griffe : tu perds une vie et tu es projeté en arrière.
func _wounded(m: Monster) -> void:
	hp -= MONSTER_DMG[m.kind]
	m.attack_cd = ATTACK_CD
	m.stun_t = maxf(m.stun_t, ATTACK_RECOVER)  # il reprend son élan : ta chance de fuir
	var away := (head_pos() - m.pos).normalized()
	if away == Vector2.ZERO:
		away = -forward2()
	try_move(away * 0.6)
	last_valid_head = head_pos()
	wound_flash = 1.0
	effects.append(_fx("wound", m.pos))
	_play("hit", m.pos, 2.0)
	_play("growl", m.pos, 4.0)
	_rumble(left, 1.0, 0.25)
	_rumble(right, 1.0, 0.25)


func _update_monster(m: Monster, dt: float) -> void:
	if m.stun_t > 0.0:
		m.stun_t -= dt
		return
	var spec: Dictionary = MONSTER_KINDS[m.kind]
	var h := head_pos()
	var d := m.pos.distance_to(h)
	if d < CHARGE_RANGE and is_visible_from(m.pos, h):
		if m.mode != "charge":
			effects.append(_fx("charge", m.pos))
			_play("growl", m.pos, 4.0)
			_roar(m)
		m.mode = "charge"
		m.target = cell_of(h)
		m.has_target = true
	elif m.mode == "charge":
		m.mode = "hunt"  # perdu de vue : il fonce vers la dernière position connue
	if not m.has_target:
		m.target = floor_cells.pick_random()
		m.has_target = true
		m.mode = "wander"
	var cell := cell_of(m.pos)
	var centre := Vector2(cell.x + 0.5, cell.y + 0.5)
	if cell == m.target and m.pos.distance_to(centre) < 0.1:
		m.has_target = false
		return
	if cell != m.last_cell or m.target != m.last_target:
		m.last_cell = cell
		m.last_target = m.target
		m.nxt = next_step(cell, m.target)
	if m.nxt == null:
		m.has_target = false
		return
	var goal := Vector2(m.nxt.x + 0.5, m.nxt.y + 0.5)
	if m.mode == "charge" and cell == cell_of(h):
		goal = h
	m.pos = m.pos.move_toward(goal, spec["speed"][m.mode] * dt)

	# ses pas : le sol tremble sous toi
	m.step_t -= dt
	if m.step_t <= 0.0:
		m.step_t = spec["step"][m.mode]
		if d < TREMOR_RANGE:
			effects.append(_fx("mstep", m.pos, 0.0, minf(1.0, (0.12 + 0.35 * (1.0 - d / TREMOR_RANGE)) * spec["tremor"])))
		if d < 14.0:
			_play("mstep", m.pos, -4.0 + 4.0 * (spec["tremor"] - 1.0))


# ---------------------------------------------------------------- calibration, lexique, menu

func start_calib(ret: String) -> void:
	state = "calib"
	calib_return = ret
	calib_step = 0
	state_t0 = now
	vest.mirror_front = false
	vest.mirror_back = false
	_show_panel()


## Le joueur indique de quel côté il a senti la vibration (prévue à SA gauche).
func calib_answer(felt_left: bool) -> void:
	if calib_step == 0:
		vest.mirror_front = not felt_left
		calib_step = 1
		state_t0 = now
	else:
		vest.mirror_back = not felt_left
		calibrated = true
		_save_config()
		start_lexique(calib_return)


func start_lexique(ret: String) -> void:
	state = "lexique"
	lex_return = ret
	lex_idx = 0
	lex_fired = 0
	state_t0 = now
	_show_panel()


func _next_lex() -> void:
	lex_fired = 0
	state_t0 = now
	lex_idx += 1
	if lex_idx >= LEX.size():
		if lex_return == "menu":
			open_menu()
		else:
			state = lex_return


func _update_lexique() -> void:
	var t := now - state_t0
	var e: Array = LEX[lex_idx]
	if e[1] != "breath" and ((lex_fired == 0 and t > 0.3) or (lex_fired == 1 and t > 1.4)):
		lex_fired += 1
		effects.append(_fx(e[1], null, e[2], e[3]))
	if t > LEX_STEP:
		_next_lex()


func open_menu() -> void:
	state = "menu"
	_build_menu()
	_show_panel()


func _show_panel() -> void:
	panel.visible = true
	panel_pending = true  # placé dès que la tête est suivie (au lancement elle est encore au sol)
	_place_panel()
	for k in weapon_models:
		weapon_models[k].visible = false
	# rien ne doit continuer à tourner derrière un panneau
	trigger_held = false
	holding = ""
	plasma_audio.stop()
	plasma_beam.visible = false
	plasma_light.light_energy = 0.0
	muzzle.light_energy = 0.0


func _build_menu() -> void:
	menu_items.clear()
	if game_active:
		menu_items.append("resume")
	menu_items.append_array(["campaign", "endless", "lexique", "calib", "gain", "turn", "comfort", "seated", "quit"])


func _menu_label(item: String) -> String:
	match item:
		"resume": return "Reprendre"
		"campaign":
			var best: float = cfg.get_value("scores", "campaign_best", 0.0)
			return "Campagne (%d épaves)%s" % [level_count(), "  · record %s" % _fmt_time(best) if best > 0.0 else ""]
		"endless":
			var bd: int = cfg.get_value("scores", "endless_best", 0)
			return "Plongée infinie%s" % ("  · record profondeur %d" % bd if bd > 0 else "")
		"lexique": return "Lexique des vibrations"
		"calib": return "Calibrer le gilet (%s : %s)" % [vest.backend(), "connecté" if vest.is_connected_to_player() else "non connecté"]
		"gain": return "◀  Intensité du gilet : %d %%  ▶" % int(round(vest.gain * 100.0))
		"turn": return "Rotation : %s" % {"snap30": "crans de 30°", "snap45": "crans de 45°", "smooth": "fluide"}[turn_mode]
		"comfort": return "Vignette de confort : %s" % ("oui" if comfort else "non")
		"seated": return "Position : %s" % ("assis" if seated else "debout")
		"quit": return "Quitter"
	return item


func menu_select(item: String, side: float = 1.0) -> void:
	match item:
		"resume":
			state = "play"
			panel.visible = false
			if pause_t0 >= 0.0:
				_shift_time(now - pause_t0)
				pause_t0 = -1.0
			hand_fresh = true
			_select_weapon(weapon)
		"campaign": start_campaign(0)
		"endless": start_endless()
		"lexique": start_lexique("menu")
		"calib": start_calib("menu")
		"gain":
			vest.gain = clampf(vest.gain + (0.1 if side >= 0.0 else -0.1), 0.3, 1.6)
			effects.append(_fx("tick", null, 0.0, 0.8))
		"turn":
			turn_mode = {"snap30": "snap45", "snap45": "smooth", "smooth": "snap30"}[turn_mode]
		"comfort": comfort = not comfort
		"seated":
			seated = not seated
			origin.global_position.y = 0.45 if seated else 0.0
		"quit": get_tree().quit()
	_save_config()
	_play("relay")
	_rumble(right, 0.4, 0.05)


func toggle_menu() -> void:
	if state == "menu":
		if game_active:
			menu_select("resume")
	elif state == "play":
		pause_t0 = now
		open_menu()
	elif state in ["dead", "win", "done", "lexique"]:
		if state != "lexique":
			game_active = false  # pas de « Reprendre » après une mort ou une victoire
		open_menu()


## Pendant la pause l'horloge tourne : on décale tous les minutages en cours
## pour que grenades, torpilles, échos et leurres reprennent là où ils étaient.
func _shift_time(d: float) -> void:
	ping_t += d
	beam_t += d
	last_bump += d
	next_heart += d
	next_squeeze += d
	next_alarm += d
	for list in [effects, waves, throws, torpedoes, marks, traces]:
		for e in list:
			e["t0"] += d
	for dc in decoys:
		dc["next"] += d


func _on_pose_recentered() -> void:
	# le joueur a recentré son casque : on le replace là où il était dans l'épave
	recenter_to = last_valid_head
	recenter_frames = 2


## Pointeur laser de la main droite sur le panneau.
func _update_pointer() -> void:
	laser.visible = vr and panel.visible and state == "menu"
	var prev_hover := menu_hover
	menu_hover = -1
	if not laser.visible:
		return
	var o := hand_pos()
	var d := hand_dir()
	var n := panel.global_basis.z
	var denom := d.dot(n)
	var length := 3.0
	if absf(denom) > 1e-4:
		var t := (panel.global_position - o).dot(n) / denom
		if t > 0.0:
			length = t
			var local := panel.to_local(o + d * t)
			menu_hover_x = local.x
			if absf(local.x) < 0.7:
				var idx := int(round((0.3 - local.y) / 0.075))
				if idx >= 0 and idx < menu_items.size():
					if idx != prev_hover:
						_rumble(right, 0.15, 0.02)
					menu_hover = idx
	laser.scale = Vector3(1, 1, length)
	laser.position = Vector3(0, 0, -length / 2.0)


func _on_trigger_right() -> void:
	match state:
		"calib": calib_answer(false)
		"lexique": _next_lex()
		"menu":
			if menu_hover >= 0:
				menu_select(menu_items[menu_hover], menu_hover_x)
		"play": weapon_press()
		"dead", "win", "done": _advance()


func _on_right(name: String) -> void:
	match name:
		"trigger_click": _on_trigger_right()
		"ax_button":
			if state == "play":
				ping()
		"by_button":
			if state == "play":
				next_weapon()


func _on_right_released(name: String) -> void:
	if name == "trigger_click":
		weapon_release()


func _on_left(name: String) -> void:
	match name:
		"trigger_click":
			match state:
				"calib": calib_answer(true)
				"play": beam()
				"lexique": _next_lex()
				"dead", "win", "done": _advance()
		"ax_button": _advance()
		"by_button": toggle_menu()
		"menu_button": toggle_menu()


# ---------------------------------------------------------------- haptique

func _render_fx(fx: Dictionary, t: float) -> void:
	var ang: float = fx["rel"] if fx["point"] == null else rel_angle(fx["point"])
	var inten: float = fx["i"]
	match fx["kind"]:
		"wall":
			vest.point(ang, inten, [1, 2, 3])
		"monster":
			if int(t / 0.08) % 2 == 0:
				vest.point(ang, 1.0, ALL_ROWS, 60.0)
		"beacon":
			if t < 0.12 or (t > 0.24 and t < 0.36):
				vest.point(ang, 0.7, [0, 1])
		"supply":
			if t < 0.35 and int(t / 0.07) % 2 == 0:
				vest.point(ang, inten, [3, 4])
		"exit":
			vest.point(ang, inten, [maxi(0, 4 - int(t / 0.1))])
		"bump":
			vest.point(ang, 1.0)
		"ping":
			vest.point(0.0, 0.45, [0], 40.0)
		"tick":
			vest.point(0.0, inten, [1], 30.0)
		"pickup":
			var row := maxi(0, 4 - int(t / 0.09))
			for a in range(0, 360, 45):
				vest.point(a, 0.8, [row])
		"resupply":
			vest.point(0.0, inten, [maxi(2, 4 - int(t / 0.12))], 90.0)
		"death":
			vest.fill(1.0)
		"win":
			vest.point(t * 720.0, 0.9)
		"beam":
			vest.point(ang, inten * (1.0 - t / 0.3), [1, 2, 3], 30.0)
		"decoy", "throw":
			vest.point(ang, inten, [maxi(0, 2 - int(t / 0.08))], 35.0)
		"charge":
			vest.point(ang, 1.0, [int(t / 0.06) % 5], 70.0)
			vest.point(ang, 0.5, ALL_ROWS, 60.0)
		"step":
			vest.point(ang, inten, [4], 30.0)
		"mstep":
			vest.point(ang, inten, [3, 4], 45.0)
		"heart":
			if t < 0.08:
				vest.point(ang, inten, [1, 2], 30.0)
			elif t > 0.15 and t < 0.23:
				vest.point(ang, inten * 0.65, [1, 2], 30.0)
		"squeeze":
			var s := sin(PI * t / 0.4) * inten
			for a in range(0, 360, 45):
				vest.point(a, s, [0])
		"recoil":
			vest.point(ang, 1.0 if t < 0.06 else 0.45, [0, 1], 40.0)
		"hit":
			vest.point(ang, inten, [1, 2], 30.0)
		"slash":
			vest.point(ang, 0.5, [1], 30.0)
		"kill":
			vest.point(ang, inten * (1.0 - t / 0.7), ALL_ROWS, 50.0 + 120.0 * t)
		"blast":
			var k := 1.0 - t / 0.6
			vest.point(ang, inten * k, ALL_ROWS, 120.0)
			vest.fill(inten * 0.3 * k)
		"wound":  # impact violent du côté du coup, puis brûlure qui s'estompe
			vest.point(ang, 1.0 if t < 0.12 else 0.7 * (1.0 - t / 0.45), ALL_ROWS, 80.0)
			if t < 0.12:
				vest.fill(0.4)
		"medkit":
			if t < 0.15 or (t > 0.3 and t < 0.45):
				vest.point(ang, inten, [2], 40.0)
		"heal":  # chaleur qui se diffuse depuis le centre du torse
			vest.point(0.0, inten * sin(PI * t / 0.6), [1, 2, 3], 40.0 + 140.0 * t)
		"ready":
			vest.point(ang, inten, [1], 25.0)
		"touch":
			vest.point(ang, inten, [1, 2], 25.0)
		"roar":
			vest.point(ang, inten * (0.5 + 0.5 * sin(t * 40.0)), [0, 1, 2], 70.0)


func _haptics() -> void:
	var alive := []
	for fx in effects:
		var t: float = now - fx["t0"]
		if t <= fx["dur"]:
			_render_fx(fx, t)
			_test_kinds[fx["kind"]] = true
			alive.append(fx)
	effects = alive
	if state == "calib":
		if fmod(now - state_t0, 1.0) < 0.6:
			for r in Vest.ROWS:
				vest.dot(calib_step == 0, 0, r, 0.9)
		return
	if state == "lexique":
		var e: Array = LEX[lex_idx]
		if e[1] == "breath":
			_test_kinds["breath"] = true
			vest.point(e[2], pow(sin((now - state_t0) * PI / 1.2), 2) * e[3], [2, 3, 4])
		return
	if state != "play":
		return
	var h := head_pos()
	for k in 12:
		var a := deg_to_rad(body_yaw + k * 30.0)
		var d := cast(h, Vector2(sin(a), -cos(a)), 0.9)
		if d >= 0.0:
			vest.point(k * 30.0, 0.1 + 0.3 * (1.0 - d / 0.9), [2], 35.0)
	for m in monsters:
		var d := h.distance_to(m.pos)
		if d < BREATH_RANGE:
			var breath := pow(sin(now * PI / 1.6), 2)
			vest.point(rel_angle(m.pos), breath * (0.1 + 0.5 * (1.0 - d / BREATH_RANGE)), [2, 3, 4])
			_test_kinds["breath"] = true
	if weapon == "plasma" and trigger_held and ammo["plasma"] > 0.0:
		vest.point(25.0, 0.35 + randf() * 0.25, [1, 2], 35.0)
		_test_kinds["plasma"] = true


# ---------------------------------------------------------------- visuel

func _spawn_mark(p: Vector2, kind: String, mkind: String = "M") -> void:
	# silhouettes à partir de tes modèles (monstres, caisses), sinon formes simples
	var model: Node3D = null
	if kind == "monster" or kind == "corpse":
		var spec: Array = MONSTER_MODELS[mkind]
		model = _fit_model(spec[0], spec[1], 0.0, true)
	elif kind == "supply":
		model = _fit_model("ammo_crate", 0.45, 0.0, false)
	elif kind == "medkit":
		model = _fit_model("health_pack", 0.4, 0.0, false)
	if model != null:
		var color2 := RED if kind in ["monster", "corpse"] else Color(0.5, 1.0, 0.6)
		var alpha2 := 0.7 if kind == "monster" else 0.5
		var mat2 := _glow(color2, alpha2)
		_ghost(model, mat2)
		add_child(model)
		var pickup := kind == "supply" or kind == "medkit"
		model.global_position = Vector3(p.x, 0.2 if pickup else 0.0, p.y)
		var h := head_pos()
		if not pickup and h.distance_to(p) > 0.1:
			model.look_at(Vector3(h.x, 0.0, h.y), Vector3.UP, true)  # il te fait face
		if kind == "corpse":
			model.rotate_object_local(Vector3.RIGHT, PI / 2.0)
		marks.append({"node": model, "mat": mat2, "color": color2, "alpha": alpha2, "t0": now,
			"life": 1.8 if kind == "monster" else 2.5})
		return
	var mi := MeshInstance3D.new()
	var color := BLUE
	var life := 3.0
	var alpha := 1.0
	match kind:
		"monster", "corpse":
			var sc: float = MONSTER_KINDS[mkind]["scale"]
			var cm := CapsuleMesh.new()
			cm.radius = 0.3 * sc
			cm.height = 1.8 * sc
			mi.mesh = cm
			mi.position = Vector3(p.x, 0.9 * sc, p.y)
			color = RED
			life = 1.8
			alpha = 0.7
			if kind == "corpse":
				mi.rotation_degrees.x = 90.0
				mi.position.y = 0.3 * sc
				life = 2.5
				alpha = 0.5
		"exit":
			var cy := CylinderMesh.new()
			cy.top_radius = 0.12
			cy.bottom_radius = 0.12
			cy.height = 3.0
			mi.mesh = cy
			mi.position = Vector3(p.x, 1.5, p.y)
			alpha = 0.7 if beacons.is_empty() else 0.25
		"supply":
			var bm := BoxMesh.new()
			bm.size = Vector3(0.4, 0.3, 0.3)
			mi.mesh = bm
			mi.position = Vector3(p.x, 0.15, p.y)
			color = Color(0.5, 1.0, 0.6)
		_:
			var sm := SphereMesh.new()
			sm.radius = 0.12
			sm.height = 0.24
			mi.mesh = sm
			mi.position = Vector3(p.x, 1.2, p.y)
			color = AMBER
	var mat := _glow(color, alpha)
	mi.material_override = mat
	add_child(mi)
	marks.append({"node": mi, "mat": mat, "color": color, "alpha": alpha, "t0": now, "life": life})


func _trace(a: Vector3, b: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	var len := a.distance_to(b)
	bm.size = Vector3(0.01, 0.01, maxf(len, 0.01))
	mi.mesh = bm
	var mat := _glow(color, 0.9)
	mi.material_override = mat
	add_child(mi)
	mi.global_position = (a + b) / 2.0
	if len > 0.01:
		mi.look_at(b, Vector3.UP if absf((b - a).normalized().y) < 0.99 else Vector3.RIGHT)
	traces.append({"node": mi, "mat": mat, "t0": now})


func _draw_fx() -> void:
	var r := (now - ping_t) * PING_SPEED
	ring.visible = r < PING_RANGE and state == "play"
	if ring.visible:
		ring.position = Vector3(ping_origin.x, 1.2, ping_origin.y)
		ring.scale = Vector3(maxf(r, 0.05), 1.0, maxf(r, 0.05))
		ring_mat.albedo_color = Color(BLUE, 0.5 * (1.0 - r / PING_RANGE))
	var keep := []
	for m in marks:
		var age: float = now - m["t0"]
		if age < m["life"]:
			var k: float = 1.0 - age / m["life"]
			m["mat"].albedo_color = Color(m["color"], m["alpha"] * k)
			if m.has("grow"):
				var s: float = lerpf(0.3, m["grow"], age / m["life"])
				m["node"].scale = Vector3(s, s, s)
			keep.append(m)
		else:
			m["node"].queue_free()
	marks = keep
	var kt := []
	for t in traces:
		var age: float = now - t["t0"]
		if age < 0.4:
			t["mat"].albedo_color = Color(WHITE, 0.9 * (1.0 - age / 0.4))
			kt.append(t)
		else:
			t["node"].queue_free()
	traces = kt
	for d in decoys:
		d["node"].visible = fmod(now, 0.5) < 0.25
	wound_flash = maxf(0.0, wound_flash - get_process_delta_time() * 1.5)
	var red := wound_flash if state == "play" else 0.0
	vignette_mat.set_shader_parameter("strength", maxf(vignette if state == "play" else 0.0, red))
	vignette_mat.set_shader_parameter("tint", Vector3(0.6, 0.0, 0.0) if red > 0.02 else Vector3.ZERO)
	_update_pointer()
	_draw_text()


func _draw_text() -> void:
	var in_game := state == "play"
	wrist.visible = in_game
	wrist_alert.visible = in_game
	for k in weapon_models:
		weapon_models[k].visible = in_game and k == weapon
	if in_game:
		var where := "épave %d/%d" % [level_idx + 1, level_count()] if game_mode == "campaign" \
			else "profondeur %d" % (endless_depth + 1)
		var a := ""
		match weapon:
			"knife": a = "∞"
			"harpoon": a = "%d harpons%s" % [ammo["harpoon"], " · recharge" if reload_t > 0.0 else ""]
			"nailgun": a = "%d chargeurs%s" % [ammo["nailgun"], " · recharge" if reload_t > 0.0 else ""]
			"torpedo": a = "%d torpilles%s" % [ammo["torpedo"], " · recharge" if reload_t > 0.0 else ""]
			"plasma": a = "%.1f s" % ammo["plasma"]
			_: a = "×%d" % ammo[weapon]
		_txt(wrist, "%s · vie %s\nO₂ %s · balises %d/%d\n%s : %s\nsortie %s · gilet %s" % [
			where, "■".repeat(maxi(hp, 0)) + "□".repeat(maxi(PLAYER_HP - hp, 0)),
			_fmt_time(oxygen), total_beacons - beacons.size(), total_beacons,
			WEAPON_NAMES[weapon], a, "OUVERTE" if beacons.is_empty() else "fermée",
			"ok" if vest.is_connected_to_player() else "absent"])
		_txt(wrist_alert, "OXYGÈNE BAS" if oxygen < OXYGEN_LOW else "")
	if not panel.visible:
		return

	# textes calculés puis appliqués seulement s'ils changent (Label3D se recompose à chaque affectation)
	var items_txt := []
	items_txt.resize(panel_items.size())
	items_txt.fill("")
	var title := ""
	var body := ""
	match state:
		"menu":
			title = "É C H O"
			panel_title.modulate = AMBER
			for i in menu_items.size():
				items_txt[i] = _menu_label(menu_items[i])
				panel_items[i].modulate = BLUE if i == menu_hover else AMBER
			items_txt[menu_items.size() + 1] = "Vise avec la main droite · gâchette pour valider"
			panel_items[menu_items.size() + 1].modulate = Color(AMBER, 0.5)
		"calib":
			title = "CALIBRATION %d/2" % (calib_step + 1)
			panel_text.modulate = AMBER
			body = "Vibration %s.\nAppuie sur la gâchette du côté où tu la sens." % [
				"DEVANT" if calib_step == 0 else "DANS LE DOS"]
		"lexique":
			title = "LEXIQUE %d/%d" % [lex_idx + 1, LEX.size()]
			panel_text.modulate = BLUE
			body = "%s\n\n(gâchette : suivant · Y : menu)" % LEX[lex_idx][0]
		"dead":
			title = "PERDU"
			panel_text.modulate = RED
			var why := "Attrapé par la créature." if death_cause == "monster" else "Plus d'oxygène."
			if game_mode == "endless":
				body = "%s\nPlongée terminée : profondeur %d%s\n\nGâchette : menu" % [
					why, endless_depth + 1, "  · NOUVEAU RECORD" if new_record else ""]
			else:
				body = "%s\n\nGâchette : recommencer" % why
		"win":
			title = "ÉPAVE TERMINÉE"
			panel_text.modulate = BLUE
			body = "Temps %s · %d sonars · %d monstre(s) abattu(s)\nO₂ restant %s\n\nGâchette : épave suivante" % [
				_fmt_time(level_time), pings_used, kills, _fmt_time(oxygen)]
		"done":
			title = "CAMPAGNE TERMINÉE"
			panel_text.modulate = BLUE
			body = "Temps total %s%s\n\nGâchette : menu" % [
				_fmt_time(total_time), "  · NOUVEAU RECORD" if new_record else ""]
	_txt(panel_title, title)
	_txt(panel_text, body)
	for i in panel_items.size():
		_txt(panel_items[i], items_txt[i])


func _exit_tree() -> void:
	for t in _fitted.values():
		if t != null:
			t.free()  # gabarits de modèles gardés hors de l'arbre
	_fitted.clear()


func _txt(l: Label3D, s: String) -> void:
	if l.text != s:
		l.text = s


# ---------------------------------------------------------------- boucle

func _process(delta: float) -> void:
	now += delta
	if recenter_frames > 0:
		recenter_frames -= 1
		if recenter_frames == 0:
			teleport(recenter_to)
			body_yaw = rad_to_deg(atan2(forward2().x, -forward2().y))
	if panel_pending and panel.visible and (not vr or camera.position.y > 0.5):
		panel_pending = false
		_place_panel()
	if state == "lexique":
		_update_lexique()
	_update(minf(delta, 0.05))
	if now - last_haptic >= HAPTIC_TICK:
		last_haptic = now
		_haptics()
		vest.flush()
	_draw_fx()


# ---------------------------------------------------------------- auto-test

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _check(cond: bool, what: String) -> void:
	print(("  ok  " if cond else "  ÉCHEC  ") + what)
	if not cond:
		_test_fail += 1


func _reachable(rows: Array) -> bool:
	var g: Array[String] = []
	for r in rows:
		g.append(String(r))
	var start := Vector2i(-1, -1)
	var goals := []
	for y in g.size():
		for x in g[y].length():
			match g[y][x]:
				"P": start = Vector2i(x, y)
				"B", "X", "A", "H": goals.append(Vector2i(x, y))
	if start.x < 0 or goals.is_empty():
		return false
	var seen := {start: true}
	var q: Array[Vector2i] = [start]
	while not q.is_empty():
		var c: Vector2i = q.pop_front()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if n.y >= 0 and n.y < g.size() and n.x >= 0 and n.x < g[n.y].length() \
					and g[n.y][n.x] != "#" and not seen.has(n):
				seen[n] = true
				q.append(n)
	for goal in goals:
		if not seen.has(goal):
			return false
	return true


## Place un monstre sur une case libre à la distance voulue, en vue directe si possible.
func _put_monster(m: Monster, dist: float) -> void:
	var h := head_pos()
	var best := Vector2.ZERO
	var best_err := INF
	for c in floor_cells:
		var p := Vector2(c.x + 0.5, c.y + 0.5)
		var err := absf(h.distance_to(p) - dist) + (0.0 if is_visible_from(h, p) else 5.0)
		if err < best_err:
			best_err = err
			best = p
	m.pos = best
	m.has_target = false
	m.mode = "wander"


## Oriente la tête (simulée) et la main droite vers un point.
func _aim_at(p: Vector2) -> void:
	var h := head_pos()
	var f := forward2()
	_rotate_origin(-rad_to_deg(f.angle_to(p - h)))
	await _frames(1)


func _run_selftest() -> void:
	print("SELFTEST — générateur")
	var bad := 0
	for depth in 10:
		for s in 6:
			if not _reachable(MazeGen.generate(s * 7919 + depth * 31, depth)):
				bad += 1
	_check(bad == 0, "60 épaves générées : balises, munitions et sortie toutes reliées (%d échecs)" % bad)
	var txt := "\n".join(PackedStringArray(MazeGen.generate(42, 8)))
	_check(txt.count("B") >= 3 and txt.count("A") >= 2 and (txt.count("T") + txt.count("C")) >= 1,
		"profondeur 9 : %d balises, %d caisses, monstres M%d T%d C%d" % [
			txt.count("B"), txt.count("A"), txt.count("M"), txt.count("T"), txt.count("C")])

	print("SELFTEST — campagne")
	for i in level_count():
		_test_kinds.clear()
		start_campaign(i)
		await _frames(5)
		ping()
		test_move = Vector2(0.0, 1.0)
		test_run = true
		await _frames(90)
		test_move = Vector2.ZERO
		test_run = false
		beam()
		await _frames(200)
		_check(state in ["play", "dead"], "épave %d : %d×%d, %d monstres, effets %s" % [
			i + 1, gw, gh, monsters.size(), _test_kinds.keys()])

	print("SELFTEST — monstres")
	start_campaign(1)
	await _frames(5)
	_test_kinds.clear()
	var m: Monster = monsters[0]
	m.pos = head_pos() + forward2() * 2.5
	await _frames(20)
	_check(m.mode == "charge" and _test_kinds.has("charge"), "rôdeur à 2,5 m en vue → charge")
	await _frames(60)
	_check(hp < PLAYER_HP and _test_kinds.has("wound"), "coup de griffe : vie %d/%d, blessure ressentie" % [hp, PLAYER_HP])
	await _frames(420)
	_check(state == "dead" and death_cause == "monster", "immobile, tu finis par succomber (3 coups)")
	_on_trigger_right()
	await _frames(5)
	_check(state == "play" and level_idx == 1, "gâchette → recommencer la même épave")
	_test_kinds.clear()
	_put_monster(monsters[0], 6.0)
	await _frames(70)
	_check(_test_kinds.has("heart") and _test_kinds.has("mstep"), "monstre à ~6 m : cœur + tremblement")
	hp = 1
	_test_kinds.clear()
	monsters[0].pos = Vector2(1000, 1000)
	teleport(medkits[0])
	await _frames(5)
	_check(hp == 2 and medkits.is_empty() and _test_kinds.has("heal"), "trousse de soin : vie 1 → %d" % hp)
	var a := cell_of(start_pos)
	_check(path_len(a, a + Vector2i(1, 0), 5) == 1 and path_len(a, cell_of(exit_pos), 3) == -1,
		"chemin d'écoute : 1 case = 1, sortie lointaine hors limite")

	start_campaign(2)
	await _frames(5)
	var m1: Monster = monsters[0]
	var m2: Monster = monsters[1]
	m2.pos = m1.pos + Vector2(0.0, 0.0)
	_put_monster(m1, 2.5)
	m2.pos = m1.pos
	for c in floor_cells:
		var cp := Vector2(c.x + 0.5, c.y + 0.5)
		if cp.distance_to(m1.pos) > 4.0 and cp.distance_to(m1.pos) < 8.0 and cp.distance_to(head_pos()) > 6.0:
			m2.pos = cp
			break
	m2.has_target = true
	m2.target = cell_of(m2.pos)
	m2.mode = "wander"
	await _aim_at(m1.pos)
	await _frames(10)
	_check(m1.mode == "charge" and m2.mode == "hunt", "rugissement : le 2e monstre (%.1f m) rejoint la chasse" % m2.pos.distance_to(m1.pos))

	print("SELFTEST — armes")
	m = monsters[0]
	_put_monster(m, 6.0)
	m.stun_t = 99.0
	await _aim_at(m.pos)
	_select_weapon("harpoon")
	var hp0 := m.hp
	weapon_press()
	await _frames(5)
	_check(m.hp < hp0 and ammo["harpoon"] == START_AMMO["harpoon"] - 1 and _test_kinds.has("recoil"),
		"harpon : touché (%.1f → %.1f PV), recul ressenti" % [hp0, m.hp])
	weapon_press()
	_check(ammo["harpoon"] == START_AMMO["harpoon"] - 1, "harpon : recharge empêche un 2e tir immédiat")
	await _frames(70)
	await _aim_at(m.pos)
	weapon_press()
	await _frames(5)
	_check(not monsters.has(m) and kills == 1 and _test_kinds.has("kill"), "harpon : 2e tir → rôdeur abattu")

	start_campaign(2)
	await _frames(5)
	m = monsters[0]
	_put_monster(m, 0.9)
	m.stun_t = 99.0
	await _aim_at(m.pos)
	_select_weapon("knife")
	_test_kinds.clear()
	test_hand_vel = Vector3(0, 0, -3.5)
	await _frames(3)
	test_hand_vel = Vector3.ZERO
	await _frames(4)
	print("    couteau : monstre à %.2f m de la lame, PV %.1f" % [
		Vector2(hand_pos().x + hand_dir().x * 0.3, hand_pos().z + hand_dir().z * 0.3).distance_to(m.pos), m.hp])
	_check(m.hp < MONSTER_KINDS[m.kind]["hp"] and _test_kinds.has("slash"), "couteau : frappe rapide → touché")
	_select_weapon("plasma")
	m.hp = 1.5
	weapon_press()
	await _frames(70)
	weapon_release()
	_check(not monsters.has(m) and ammo["plasma"] < START_AMMO["plasma"] and _test_kinds.has("plasma"),
		"plasma maintenu ~1 s : monstre grillé, énergie %.1f s" % ammo["plasma"])

	m = monsters[0]
	_put_monster(m, 4.0)
	m.stun_t = 99.0
	await _aim_at(m.pos)
	_select_weapon("grenade")
	weapon_press()
	var toward := (m.pos - head_pos()).normalized()
	test_hand_vel = Vector3(toward.x, 1.2, toward.y) * 3.6
	weapon_release()
	test_hand_vel = Vector3.ZERO
	await _frames(int(GRENADE_FUSE * 60.0) + 10)
	_check(ammo["grenade"] == 0 and not monsters.has(m) and _test_kinds.has("blast"), "grenade lancée : explosion, monstre abattu")
	_select_weapon("decoy")
	weapon_press()
	test_hand_vel = Vector3(forward2().x, 0.8, forward2().y) * 3.0
	weapon_release()
	test_hand_vel = Vector3.ZERO
	await _frames(150)
	_check(ammo["decoy"] == START_AMMO["decoy"] - 1 and (decoys.size() == 1 or _test_kinds.has("throw")), "leurre lancé puis actif")
	var a0: int = ammo["harpoon"]
	teleport(supplies[0])
	await _frames(5)
	_check(ammo["harpoon"] == mini(a0 + SUPPLY["harpoon"], MAX_AMMO["harpoon"]) and _test_kinds.has("resupply"), "caisse : munitions ramassées")
	next_weapon()
	_check(weapon == "knife", "B : arme suivante (boucle)")

	start_campaign(4)
	await _frames(5)
	m = monsters[0]
	_put_monster(m, 3.0)
	m.stun_t = 99.0
	m.hp = 1.0
	await _aim_at(m.pos)
	_select_weapon("nailgun")
	weapon_press()
	await _frames(2)
	_check(not monsters.has(m) and ammo["nailgun"] == START_AMMO["nailgun"] - 1, "riveteuse à 3 m : monstre abattu")
	m = monsters[0]
	_put_monster(m, 6.0)
	m.stun_t = 99.0
	m.hp = 3.0
	await _aim_at(m.pos)
	_select_weapon("torpedo")
	await _frames(60)  # fin de la recharge de la riveteuse
	_test_kinds.clear()
	weapon_press()
	await _frames(60)
	if monsters.has(m):
		print("    torpille : monstre à %.1f m, PV %.1f, torpilles en vol %d, munitions %d" % [
			head_pos().distance_to(m.pos), m.hp, torpedoes.size(), ammo["torpedo"]])
	_check(not monsters.has(m) and torpedoes.is_empty() and _test_kinds.has("blast"), "torpille : impact et explosion")
	var vis := 0
	for w in WEAPONS:
		if weapon_models[w] is Node3D and not (weapon_models[w] is MeshInstance3D):
			vis += 1
	_check(vis == WEAPONS.size(), "modèles GLB chargés pour %d/%d armes" % [vis, WEAPONS.size()])

	print("SELFTEST — corrections de la revue")
	start_campaign(2)
	await _frames(5)
	m = monsters[0]
	_put_monster(m, 1.0)
	m.stun_t = 99.0
	var hp_m := m.hp
	await _aim_at(m.pos)
	_select_weapon("knife")
	await _frames(2)
	_rotate_origin(30.0)     # rotation par cran : la main « saute » sans geste
	await _frames(1)
	try_move(forward2() * 0.04)
	await _frames(3)
	_check(is_equal_approx(m.hp, hp_m), "couteau : rotation et déplacement ne comptent pas comme une frappe")
	_select_weapon("grenade")
	monsters.clear()
	weapon_press()
	test_hand_vel = Vector3(forward2().x, 1.0, forward2().y) * 2.0
	weapon_release()
	test_hand_vel = Vector3.ZERO
	toggle_menu()
	_check(state == "menu" and menu_items[0] == "resume", "pause en jeu : « Reprendre » proposé")
	await _frames(200)
	menu_select("resume")
	await _frames(2)
	_check(throws.size() == 1, "pause de 3 s : la grenade n'a pas explosé pendant le menu")
	await _frames(120)
	_check(throws.is_empty(), "elle explose ensuite normalement")
	var hb := head_pos()
	var cross := Vector2.ZERO
	for d in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
		var wd := cast(hb, d, 8.0)
		if wd > 0.0 and not wall(hb.x + d.x * (wd + 1.5), hb.y + d.y * (wd + 1.5)):
			cross = d * (wd + 1.5)
			break
	if cross != Vector2.ZERO:
		origin.global_position += Vector3(cross.x, 0.0, cross.y)  # « marche physique » à travers la cloison
		await _frames(2)
		_check(head_pos().distance_to(hb) < 0.3, "traverser une cloison d'un coup : repoussé (%.2f m)" % head_pos().distance_to(hb))
	else:
		_check(false, "test cloison : aucune cloison trouvée autour du départ")
	die("monster")
	toggle_menu()
	_check(menu_items[0] != "resume", "après une mort : pas de « Reprendre »")
	start_campaign(2)
	await _frames(5)
	monsters.clear()
	var fw := forward2()
	var wd2 := cast(head_pos(), fw, 20.0)
	_select_weapon("torpedo")
	weapon_press()
	await _frames(int((wd2 / TORPEDO_SPEED) * 60.0) + 15)
	_check(torpedoes.is_empty(), "torpille contre un mur à %.1f m : explosée" % wd2)
	var flash_ok := false
	for mk in marks:
		if mk.has("grow"):
			var fp: Vector3 = mk["node"].global_position
			flash_ok = not wall(fp.x, fp.z)
	_check(flash_ok, "l'explosion se produit devant la paroi, pas dedans")

	print("SELFTEST — oxygène, sortie, infini")
	start_campaign(1)
	await _frames(5)
	monsters.clear()
	_test_kinds.clear()
	oxygen = 20.0
	await _frames(100)
	_check(_test_kinds.has("squeeze"), "oxygène bas → compression")
	oxygen = 0.01
	await _frames(3)
	_check(state == "dead" and death_cause == "oxygen", "oxygène à 0 → mort")
	start_campaign(0)
	await _frames(5)
	var o2 := oxygen
	teleport(beacons[0])
	await _frames(3)
	_check(beacons.is_empty() and oxygen > o2 + 15.0, "balise ramassée : +20 s d'O₂")
	teleport(exit_pos)
	await _frames(3)
	_check(state == "win", "sortie ouverte → épave terminée")
	_on_trigger_right()
	await _frames(3)
	_check(level_idx == 1 and state == "play", "gâchette → épave suivante")
	start_endless()
	await _frames(3)
	beacons.clear()
	teleport(exit_pos)
	await _frames(3)
	_advance()
	await _frames(3)
	_check(endless_depth == 1 and state == "play", "plongée infinie : profondeur suivante")
	oxygen = 0.01
	await _frames(3)
	_check(state == "dead" and int(cfg.get_value("scores", "endless_best", 0)) == 2, "record de profondeur enregistré")
	_advance()
	_check(state == "menu", "fin de plongée → menu")

	print("SELFTEST — torse, menu, calibration, lexique")
	start_campaign(0)
	await _frames(5)
	var b0 := body_yaw
	_rotate_origin(-20.0)
	await _frames(2)
	var small := absf(Vest.angle_diff(body_yaw, b0))
	_rotate_origin(-60.0)
	await _frames(2)
	_check(small < 3.0 and absf(Vest.angle_diff(body_yaw, b0)) > 40.0,
		"torse : tête à 20° ne tourne pas le gilet (%.1f°), à 80° il suit (%.1f°)" % [small, absf(Vest.angle_diff(body_yaw, b0))])
	open_menu()
	_check(menu_items[0] == "resume" and panel.visible, "menu en jeu : %s" % [menu_items])
	var g0 := vest.gain
	menu_select("gain", -1.0)
	_check(is_equal_approx(vest.gain, maxf(0.3, g0 - 0.1)), "intensité réglable : %d %%" % int(round(vest.gain * 100.0)))
	menu_select("turn")
	_check(turn_mode != "snap30", "rotation réglable : %s" % turn_mode)
	menu_select("resume")
	_check(state == "play" and not panel.visible, "reprendre")
	start_calib("menu")
	calib_answer(true)
	calib_answer(false)
	_check(not vest.mirror_front and vest.mirror_back and state == "lexique", "calibration → lexique")
	_test_kinds.clear()
	while state == "lexique":
		await _frames(1)
	var missing := []
	for e in LEX:
		if not _test_kinds.has(e[1]):
			missing.append(e[1])
	_check(missing.is_empty() and state == "menu", "lexique complet (%d signaux), retour menu %s" % [LEX.size(), missing])
	print("SELFTEST %s (%d échec(s))" % ["OK" if _test_fail == 0 else "ÉCHEC", _test_fail])
	get_tree().quit(1 if _test_fail > 0 else 0)
