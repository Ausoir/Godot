extends "res://world/generator.gd"

var _stack = []
var size
var estates = []

func generate():
	.create(7, 7)
	base = make_base(width, height, 1)

	_stack = [
		[1, 1, width-2, height-2]
	]
	_process()
	base = fatten(1, 1, 1)
	make_border(0)
	magnify(7)
	return base

func magnify(mag):
	var r = make_base(width*mag, height*mag, '.')
	for y in range(height):
		for x in range(width):
			var val = base[y][x]
			var mx = x*mag
			var my = y*mag
			var estate = [mx, my, mx+mag-1, my+mag-1]
			if val == 1:
				var rots = []
				for i in range(4):
					var dir = G.CARDINALS[i]
					if base[y+dir[1]][x+dir[0]] == 0:
						rots.append(i)
				var rot = G.rng.rnd_arr(rots)
				make_terrain(r, estate, "map_houses", rot)
			else:
				make_road(r, estate)
	width *= mag
	height *= mag
	base = r

func make_road(map, room):
	for y in range(room[1], room[3]+1):
		for x in range(room[0], room[2]+1):
			map[y][x] = 'D'

func make_terrain(map, room, vault_type, rots):
	vaults.load_vault(vault_type)
	return vaults.make_vault(map, room, rots)

func fatten(block, roadh, roadv):
	var r = []
	for y in range(height):
		var row = []
		for x in range(width):
			if x % 2 == 1:
				for _i in range(block):
					row.append(base[y][x])
			for _i in range(roadh):
				row.append(base[y][x])
		if y % 2 == 1:
			for _i in range(block):
				r.append(row)
		for _i in range(roadv):
			r.append(row)
	width = len(r[0])
	height = len(r)
	return r

func _process():
	while !_stack.empty():
		var room = _stack.pop_front()
		partition(room[0], room[1], room[2], room[3], 1)

func partition(x1, y1, x2, y2, until):
	var availX = []
	var availY = []
	for i in range(x1, x2+1):
		var vbound = y1 > 0 and y2 < height-1
		if vbound and !(i % 2):
			availX.append(i)
	for j in range(y1, y2+1):
		var hbound = x1 > 0 and x2 < width-1
		if hbound and !(j % 2):
			availY.append(j)

	if availX.size() < until or availY.size() < until:
		return

	var rx = G.rng.rnd_arr(availX)
	var ry = G.rng.rnd_arr(availY)

	base[rx][ry] = 0
	estates.append([rx, ry])

	var walls = []

	var left = []
	walls.append(left)
	for i in range(x1, rx):
		base[i][ry] = 0
		if (i % 2):
			left.append([i, ry])

	var right = []
	walls.append(right) #Right
	for i in range(rx+1, x2+1):
		base[i][ry] = 0
		if (i % 2):
			right.append([i, ry])

	var top = []
	walls.append(top) #Top
	for j in range(y1, ry):
		base[rx][j] = 0
		if (j % 2):
			top.append([rx, j])

	var bottom = []
	walls.append(bottom)
	for j in range(ry+1, y2+1):
		base[rx][j] = 0
		if (j % 2):
			bottom.append([rx, j])

	var solid = G.rng.rnd_arr(walls)
	for i in range(walls.size()):
		var w = walls[i]
		if (w == solid):
			continue
		elif !w.empty():
			var hole = G.rng.rnd_arr(w)
			base[hole[0]][hole[1]] = 2

	_stack.append([x1, y1, rx-1, ry-1]) #left top
	_stack.append([rx+1, y1, x2, ry-1]) #right top
	_stack.append([x1, ry+1, rx-1, y2]) #left bottom
	_stack.append([rx+1, ry+1, x2, y2]) #right bottom
