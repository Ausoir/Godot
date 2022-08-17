extends "res://world/generator.gd"

var biome_map
var biome
var _stack = []
var size
var estates = []

func generate():
	.create(4, 4)
	base = make_base(width, height, 1)

	_stack = [
		[1, 1, width-2, height-2]
	]
	_process()
	base = fatten(1, 1, 1)
	biome_map = make_perlin(width, height, 2)
	magnify(18)
	paint_map()

func paint_perlin(mx, my, sx, sy):
	for y in range(sy):
		for x in range(sx):
			var tx = mx + x
			var ty = my + y
			var value = biome[ty][tx]
			var spawnable = false
			if value > 0.75:
				output[ty][tx] = ['rock wall']
			elif value > 0.5:
				output[ty][tx] = ['grass', ['old tree', .1, '/', ['tree', .04, '/', ['young tree', .02]]]]
				spawnable = true
			elif value > 0.25:
				output[ty][tx] = ['dirt', ['boulder', .02, '/', ['small boulder', .03]]]
				spawnable = true
			else:
				output[ty][tx] = ['water']
			if tx == 0 or ty == 0 or tx == width*sx-1 or ty == height*sy-1:
				if spawnable:
					output[ty][tx] = [output[ty][tx][0]]
					spawn_points.append([tx, ty])

func magnify(mag):
	var minimap = base
	var default = G.data.palette_data.get(' ')
	var mwidth = width * mag
	var mheight = height * mag
	output = make_base(mwidth, mheight, default)
	biome = make_perlin(mwidth, mheight, 5, 2)
	for y in range(height):
		for x in range(width):
			var mx = x*mag
			var my = y*mag
			if biome_map[y][x] > .65:
				paint_perlin(mx, my, mag, mag)
			else:
				var val = minimap[y][x]
				var estate = [mx, my, mx+mag-1, my+mag-1]
				if val == 1 or (val == 2 and G.rng.r_percent(25)):
					var rots = []
					for i in range(4):
						var dir = G.CARDINALS[i]
						if get_tile(minimap, x+dir.x, y+dir.y, 1) != 1:
							rots.append(i)
					if rots.empty():
						make_vault(estate, "map_house", G.rng.ir(0, 3))
					else:
						var rot = G.rng.r_arr(rots)
						make_vault(estate, "map_house", rot)
				else:
					if get_tile(minimap, x+1, y, 1) == 1 and get_tile(minimap, x-1, y, 1) == 1:
						make_vault(estate, "map_road", 0)
					elif get_tile(minimap, x, y+1, 1) == 1 and get_tile(minimap, x, y-1, 1) == 1:
						make_vault(estate, "map_road", 1)
	width = mwidth
	height = mheight

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

	var rx = G.rng.r_arr(availX)
	var ry = G.rng.r_arr(availY)

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

	var solid = G.rng.r_arr(walls)
	for i in range(walls.size()):
		var w = walls[i]
		if (w == solid):
			continue
		elif !w.empty():
			var hole = G.rng.r_arr(w)
			base[hole[0]][hole[1]] = 2

	_stack.append([x1, y1, rx-1, ry-1]) #left top
	_stack.append([rx+1, y1, x2, ry-1]) #right top
	_stack.append([x1, ry+1, rx-1, y2]) #left bottom
	_stack.append([rx+1, ry+1, x2, y2]) #right bottom
