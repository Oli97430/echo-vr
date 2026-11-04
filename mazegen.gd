## Générateur d'épaves : labyrinthe à boucles + salles, balises dans les culs-de-sac.
## Même format que les niveaux écrits à la main (P, B, X, M, #, .).
class_name MazeGen

const DIRS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]


static func generate(seed_value: int, depth: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var cw := mini(7 + depth, 15)
	var ch := mini(5 + (depth >> 1), 10)
	var w := cw * 2 + 1
	var h := ch * 2 + 1
	var g := []
	for y in h:
		var row := []
		row.resize(w)
		row.fill("#")
		g.append(row)

	# labyrinthe parfait (backtracker)
	var stack: Array[Vector2i] = [Vector2i.ZERO]
	var seen := {Vector2i.ZERO: true}
	g[1][1] = "."
	while not stack.is_empty():
		var c: Vector2i = stack.back()
		var nbs := []
		for d in DIRS:
			var n: Vector2i = c + d
			if n.x >= 0 and n.y >= 0 and n.x < cw and n.y < ch and not seen.has(n):
				nbs.append(n)
		if nbs.is_empty():
			stack.pop_back()
			continue
		var n: Vector2i = nbs[rng.randi_range(0, nbs.size() - 1)]
		seen[n] = true
		g[n.y * 2 + 1][n.x * 2 + 1] = "."
		g[c.y + n.y + 1][c.x + n.x + 1] = "."
		stack.append(n)

	# boucles : sans elles, le monstre coince le joueur trop facilement
	for i in 4 + depth * 2:
		var x := rng.randi_range(1, w - 2)
		var y := rng.randi_range(1, h - 2)
		if (x % 2) != (y % 2):
			g[y][x] = "."

	# salles
	for i in mini(1 + (depth >> 1), 4):
		var rw := rng.randi_range(3, 5)
		var rh := rng.randi_range(3, 4)
		var rx := rng.randi_range(1, w - rw - 1)
		var ry := rng.randi_range(1, h - rh - 1)
		for yy in range(ry, ry + rh):
			for xx in range(rx, rx + rw):
				g[yy][xx] = "."

	# distances depuis le départ
	var start := Vector2i(1, 1)
	var dist := {start: 0}
	var q: Array[Vector2i] = [start]
	var far := start
	while not q.is_empty():
		var c: Vector2i = q.pop_front()
		if dist[c] > dist[far]:
			far = c
		for d in DIRS:
			var n: Vector2i = c + d
			if g[n.y][n.x] != "#" and not dist.has(n):
				dist[n] = dist[c] + 1
				q.append(n)
	g[start.y][start.x] = "P"
	g[far.y][far.x] = "X"

	# balises : culs-de-sac lointains d'abord
	var dead_ends := []
	var others := []
	for c in dist.keys():
		if c == start or c == far or dist[c] < 5:
			continue
		var open := 0
		for d in DIRS:
			if g[c.y + d.y][c.x + d.x] != "#":
				open += 1
		if open == 1:
			dead_ends.append(c)
		else:
			others.append(c)
	_shuffle(dead_ends, rng)
	_shuffle(others, rng)
	var pool := dead_ends + others
	var n_beacons := mini(2 + (depth >> 1), 5)
	var used := 0
	for c in pool:
		if used >= n_beacons:
			break
		g[c.y][c.x] = "B"
		used += 1

	# caisses de munitions
	for c in others.slice(0, mini(1 + depth / 3, 3)):
		if g[c.y][c.x] == ".":
			g[c.y][c.x] = "A"
	# trousses de soin, plus rares
	for c in others.slice(3, 3 + mini(1 + depth / 4, 2)):
		if g[c.y][c.x] == ".":
			g[c.y][c.x] = "H"
	others.reverse()

	# monstres : loin du départ, espacés entre eux ; types plus durs en profondeur
	var n_monsters := mini(1 + (depth >> 1), 4)
	var max_d: int = dist[far]
	var placed: Array[Vector2i] = []
	for c in others:
		if placed.size() >= n_monsters:
			break
		if g[c.y][c.x] != "." or dist[c] < maxi(8, max_d / 2):
			continue
		var ok := true
		for p in placed:
			if absi(p.x - c.x) + absi(p.y - c.y) < 6:
				ok = false
		if ok:
			var kind := "M"
			var roll := rng.randf()
			if depth >= 4 and roll < 0.25:
				kind = "C"  # colosse
			elif depth >= 2 and roll < 0.55:
				kind = "T"  # traqueur
			g[c.y][c.x] = kind
			placed.append(c)

	var rows := []
	for row in g:
		rows.append("".join(PackedStringArray(row)))
	return rows


static func _shuffle(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = a[i]
		a[i] = a[j]
		a[j] = t
