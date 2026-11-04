## Couche haptique X40 : tampon de 40 moteurs envoyé au bHaptics Player.
## Repère : angle en degrés relatif au regard, 0 = devant, +90 = droite,
## 180 = derrière. Lignes : 0 = épaules, 4 = ventre.
class_name Vest
extends Node

## Deux sorties : PC = websocket du bHaptics Player Windows ;
## Quest autonome = plugin Android BhapticsGodot (bHaptics Player pour Quest).
const URL := "ws://127.0.0.1:15881/v2/feedbacks?app_id=com.olivier.echovr&app_name=EchoVR"
# Identifiants du bHaptics Developer Portal (playMotors n'utilise aucun événement du portail).
const APP_ID := "com.olivier.echovr"
const API_KEY := ""
const COLS := 4
const ROWS := 5
const FRONT_ANGLES := [-67.5, -22.5, 22.5, 67.5]     # colonne porteur 0 = gauche
const BACK_ANGLES := [-112.5, -157.5, 157.5, 112.5]  # colonne porteur 0 = gauche
const SPREAD := 50.0

var enabled := true
var peak := 0.0
# Réglés par la calibration en jeu (gauche/droite inversés sur une face).
var mirror_front := false
var mirror_back := false
var gain := 1.0
var front := PackedFloat32Array()
var back := PackedFloat32Array()
var _ws := WebSocketPeer.new()
var _last_try := -10.0
var _android: Object = null
var _android_ok := false
var _android_check := -10.0
var _was_empty := false


func _ready() -> void:
	front.resize(20)
	back.resize(20)
	if enabled and Engine.has_singleton("BhapticsGodot"):
		_android = Engine.get_singleton("BhapticsGodot")
		if not _android.init(APP_ID, API_KEY):
			push_warning("bHaptics Player pour Quest introuvable : installe-le puis relance le jeu")


func backend() -> String:
	return "Quest" if _android != null else "PC"


func _process(_delta: float) -> void:
	if not enabled:
		return
	if _android != null:
		var t := Time.get_ticks_msec() / 1000.0
		if t - _android_check > 1.0:
			_android_check = t
			_android_ok = _android.is_vest_connected()
		return
	_ws.poll()
	var st := _ws.get_ready_state()
	if st == WebSocketPeer.STATE_OPEN:
		while _ws.get_available_packet_count() > 0:
			_ws.get_packet()  # statuts du Player, ignorés
	elif st == WebSocketPeer.STATE_CLOSED:
		var t := Time.get_ticks_msec() / 1000.0
		if t - _last_try > 3.0:
			_last_try = t
			_ws = WebSocketPeer.new()
			_ws.connect_to_url(URL)


func is_connected_to_player() -> bool:
	if _android != null:
		return _android_ok
	return enabled and _ws.get_ready_state() == WebSocketPeer.STATE_OPEN


static func angle_diff(a: float, b: float) -> float:
	return fposmod(a - b + 180.0, 360.0) - 180.0


func dot(is_front: bool, col: int, row: int, inten: float) -> void:
	var mirror := mirror_front if is_front else mirror_back
	var c := COLS - 1 - col if mirror else col
	var i := row * COLS + c
	var v := minf(1.0, inten)
	if is_front:
		front[i] = maxf(front[i], v)
	else:
		back[i] = maxf(back[i], v)


## Projette un point haptique à un angle autour du torse.
func point(angle: float, inten: float, rows: Array = [0, 1, 2, 3, 4], spread: float = SPREAD) -> void:
	for side in 2:
		var angles: Array = FRONT_ANGLES if side == 0 else BACK_ANGLES
		for c in COLS:
			var w := 1.0 - absf(angle_diff(angle, angles[c])) / spread
			if w <= 0.0:
				continue
			for r in rows:
				dot(side == 0, c, r, inten * w)


func fill(inten: float) -> void:
	for side in 2:
		for c in COLS:
			for r in ROWS:
				dot(side == 0, c, r, inten)


## Envoie le tampon (multiplié par le gain) puis le vide. ~20 fois par seconde.
func flush(duration_ms: int = 90) -> void:
	# une image vide suffit pour arrêter les moteurs : inutile de la répéter 20 fois par seconde
	var empty := true
	for i in 20:
		if front[i] * gain > 0.02 or back[i] * gain > 0.02:
			empty = false
			break
	if empty and _was_empty:
		front.fill(0.0)
		back.fill(0.0)
		return
	_was_empty = empty
	var submit := []
	for side in 2:
		var buf := front if side == 0 else back
		var dots := []
		for i in 20:
			var v := minf(1.0, buf[i] * gain)
			peak = maxf(peak, v)
			if v > 0.02:
				dots.append({"Index": i, "Intensity": int(v * 100.0)})
		submit.append({
			"Type": "frame", "Key": "echo_f" if side == 0 else "echo_b",
			"Frame": {"Position": "VestFront" if side == 0 else "VestBack",
				"PathPoints": [], "DotPoints": dots, "DurationMillis": duration_ms},
		})
	if _android != null:
		_flush_android(duration_ms)
	elif is_connected_to_player():
		_ws.send_text(JSON.stringify({"Register": [], "Submit": submit}))
	front.fill(0.0)
	back.fill(0.0)


## Le SDK Android voit le gilet en 32 moteurs (4×4 devant puis 4×4 dos) :
## on ramène nos 5 lignes à 4, la ligne du milieu se partage entre ses voisines.
func _flush_android(duration_ms: int) -> void:
	var motors := PackedInt32Array()
	motors.resize(32)
	for side in 2:
		var buf := front if side == 0 else back
		for c in COLS:
			var r: Array = []
			for row in ROWS:
				r.append(minf(1.0, buf[row * COLS + c] * gain))
			var rows4 := [r[0], maxf(r[1], r[2] * 0.6), maxf(r[3], r[2] * 0.6), r[4]]
			for k in 4:
				motors[side * 16 + k * COLS + c] = int(rows4[k] * 100.0)
	_android.play_motors(0, duration_ms, motors)
