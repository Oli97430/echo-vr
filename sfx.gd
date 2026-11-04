## Sons mécaniques synthétisés (relais, servo, bourdonnements graves).
class_name Sfx

const SR := 22050


static func _wav(s: PackedFloat32Array, vol: float) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(s.size() * 2)
	for i in s.size():
		data.encode_s16(i * 2, int(clampf(s[i], -1.0, 1.0) * 32767.0 * vol))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = SR
	w.stereo = false
	w.data = data
	return w


static func _buf(dur: float) -> PackedFloat32Array:
	var s := PackedFloat32Array()
	s.resize(int(SR * dur))
	return s


static func build() -> Dictionary:
	var out := {}
	var s := _buf(0.35)
	for i in s.size():
		var t := float(i) / SR
		s[i] = sin(TAU * (70.0 - 30.0 * t / 0.35) * t) * exp(-t * 12.0) \
			+ randf_range(-1.0, 1.0) * exp(-t * 600.0) * 0.6
	out["ping"] = _wav(s, 0.6)

	s = _buf(0.04)
	for i in s.size():
		s[i] = randf_range(-1.0, 1.0) * exp(-float(i) / SR * 250.0)
	out["relay"] = _wav(s, 0.35)

	s = _buf(0.6)
	for i in s.size():
		var t := float(i) / SR
		s[i] = sin(TAU * 48.0 * t) * (0.6 + 0.4 * sin(TAU * 7.0 * t)) * sin(PI * t / 0.6)
	out["growl"] = _wav(s, 0.7)

	s = _buf(0.3)
	var phase := 0.0
	for i in s.size():
		var t := float(i) / SR
		phase += TAU * (300.0 + 400.0 * t / 0.3) / SR
		s[i] = signf(sin(phase)) * 0.25 * sin(PI * t / 0.3)
	out["servo"] = _wav(s, 0.4)

	s = _buf(1.2)
	for i in s.size():
		var t := float(i) / SR
		s[i] = (sin(TAU * 40.0 * t) + 0.5 * sin(TAU * 61.0 * t)) * exp(-t * 2.0) * 0.7
	out["drone"] = _wav(s, 0.6)

	s = _buf(0.12)  # tes pas : petit choc sourd sur la tôle
	for i in s.size():
		var t := float(i) / SR
		s[i] = (sin(TAU * 95.0 * t) * 0.7 + randf_range(-1.0, 1.0) * 0.3) * exp(-t * 45.0)
	out["step"] = _wav(s, 0.25)

	s = _buf(0.35)  # pas du monstre : impact grave
	for i in s.size():
		var t := float(i) / SR
		s[i] = (sin(TAU * (38.0 - 10.0 * t) * t) + randf_range(-1.0, 1.0) * 0.25 * exp(-t * 60.0)) * exp(-t * 11.0)
	out["mstep"] = _wav(s, 0.8)

	s = _buf(0.3)  # battement de cœur (lub-dub)
	for i in s.size():
		var t := float(i) / SR
		s[i] = sin(TAU * 55.0 * t) * (exp(-t * 30.0) + 0.6 * exp(-absf(t - 0.17) * 30.0) * float(t > 0.17))
	out["heart"] = _wav(s, 0.5)

	s = _buf(0.45)  # faisceau : balayage montant
	phase = 0.0
	for i in s.size():
		var t := float(i) / SR
		phase += TAU * (180.0 + 900.0 * t / 0.45) / SR
		s[i] = sin(phase) * sin(PI * t / 0.45) * 0.6
	out["beam"] = _wav(s, 0.35)

	s = _buf(0.3)  # leurre : impulsion plus aiguë
	for i in s.size():
		var t := float(i) / SR
		s[i] = sin(TAU * 150.0 * t) * exp(-t * 14.0) + randf_range(-1.0, 1.0) * exp(-t * 500.0) * 0.4
	out["decoy"] = _wav(s, 0.55)

	s = _buf(0.5)  # alarme oxygène : deux relais + bourdon
	for i in s.size():
		var t := float(i) / SR
		var buzz := signf(sin(TAU * 110.0 * t)) * 0.18 * float(t > 0.05 and t < 0.4)
		var clicks := randf_range(-1.0, 1.0) * (exp(-t * 300.0) + exp(-absf(t - 0.4) * 300.0))
		s[i] = buzz + clicks * 0.5
	out["alarm"] = _wav(s, 0.45)

	s = _buf(0.35)  # fusil-harpon : détente pneumatique + sifflement métallique
	for i in s.size():
		var t := float(i) / SR
		s[i] = randf_range(-1.0, 1.0) * exp(-t * 40.0) * 0.8 + sin(TAU * (900.0 - 1500.0 * t) * t) * exp(-t * 9.0) * 0.3
	out["harpoon"] = _wav(s, 0.6)

	s = _buf(1.0)  # découpeur plasma : bourdonnement en boucle
	for i in s.size():
		var t := float(i) / SR
		s[i] = signf(sin(TAU * 120.0 * t)) * 0.25 + sin(TAU * 240.0 * t) * 0.2 + randf_range(-1.0, 1.0) * 0.12
	var pl := _wav(s, 0.35)
	pl.loop_mode = AudioStreamWAV.LOOP_FORWARD
	pl.loop_end = s.size()
	out["plasma"] = pl

	s = _buf(1.4)  # grenade sonique : souffle grave
	for i in s.size():
		var t := float(i) / SR
		s[i] = (sin(TAU * (60.0 - 25.0 * t) * t) + randf_range(-1.0, 1.0) * exp(-t * 6.0) * 0.7) * exp(-t * 3.0)
	out["blast"] = _wav(s, 0.9)

	s = _buf(0.9)  # monstre abattu : râle qui s'effondre
	for i in s.size():
		var t := float(i) / SR
		s[i] = sin(TAU * (70.0 - 40.0 * t) * t) * (0.5 + 0.5 * sin(TAU * 11.0 * t)) * exp(-t * 3.5)
	out["collapse"] = _wav(s, 0.8)

	s = _buf(0.25)  # monstre touché : cri bref
	for i in s.size():
		var t := float(i) / SR
		s[i] = sin(TAU * (180.0 + 120.0 * sin(TAU * 25.0 * t)) * t) * sin(PI * t / 0.25)
	out["hit"] = _wav(s, 0.55)

	s = _buf(0.15)  # couteau électrique : claquement d'arc
	for i in s.size():
		var t := float(i) / SR
		s[i] = randf_range(-1.0, 1.0) * exp(-t * 30.0) * (0.5 + 0.5 * signf(sin(TAU * 60.0 * t)))
	out["zap"] = _wav(s, 0.5)

	# ambiance de coque : bourdon grave modulé + craquements, en boucle
	s = _buf(8.0)
	var creak_at := [1.3, 3.9, 6.2]
	for i in s.size():
		var t := float(i) / SR
		var v := (sin(TAU * 33.0 * t) * 0.5 + sin(TAU * 49.5 * t) * 0.25) * (0.6 + 0.4 * sin(TAU * t / 8.0))
		for c in creak_at:
			var dt: float = t - c
			if dt > 0.0 and dt < 0.5:
				v += sin(TAU * (240.0 + 60.0 * sin(TAU * 9.0 * dt)) * dt) * exp(-dt * 7.0) * 0.25
		s[i] = v
	var amb := _wav(s, 0.35)
	amb.loop_mode = AudioStreamWAV.LOOP_FORWARD
	amb.loop_end = s.size()
	out["ambient"] = amb
	return out
