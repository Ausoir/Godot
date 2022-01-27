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
	magnify(21)
	paint_map()
	paint_spawn(0)

func magnify(mag):
	var minimap = base
	var default = G.data.palette_data.get('D')
	output = make_base(width*mag, height*mag, default)
	for y in range(height):
		for x in range(width):
			var val = minimap[y][x]
			var mx = x*mag
			var my = y*mag
			var estate = [mx, my, mx+mag-1, my+mag-1]
			if val == 1 or (val == 2 and G.rng.rnd_percent(25)):
				var rots = []
				for i in range(4):
					var dir = G.CARDINALS[i]
					if get_tile(minimap, x+dir[0], y+dir[1], 1) != 1:
						rots.append(i)
				if rots.empty():
					make_vault(estate, "map_houses", G.rng.randi_range(0, 3))
				else:
					var rot = G.rng.rnd_arr(rots)
					make_vault(estate, "map_houses", rot)
			else:
				if get_tile(minimap, x+1, y, 1) == 1 and get_tile(minimap, x-1, y, 1) == 1:
					make_vault(estate, "map_road", 0)
				elif get_tile(minimap, x, y+1, 1) == 1 and get_tile(minimap, x, y-1, 1) == 1:
					make_vault(estate, "map_road", 1)
	width *= mag
	height *= mag

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
