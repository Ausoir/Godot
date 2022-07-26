extends "res://world/generator.gd"

var _stack = []
var size

func generate_lab():
	generate_maze(24, 24)
	place_output()
	place_buildings()
	paint_map()
	paint_spawn(R.ir(0, 3))
	return base

func generate_maze(sx, sy):
	.create(sx, sy)
	base = make_base(width, height, 0)
	_stack = [
		[1, 1, width-2, height-2]
	]
	_process()
	return base

func place_buildings():
	for _i in range(20):
		var fromx = R.ir(8, width-17)
		var fromy = R.ir(8, height-17)
		var estate = [fromx, fromy, fromx+7, fromy+7]
		make_vault(estate, "map_maze", R.ir(0, 3))

func paint_spawn(dir):
	var floor_tile = 'tile'
	if dir == 0:
		var x = R.ir(1, width-2)
		G.world.set_terrain(x, 0, floor_tile)
		G.world.set_terrain(x, 1, floor_tile)
		G.world.spawn_points.append(G.world.tiles[0][x])
	elif dir == 1:
		var y = R.ir(1, height-2)
		G.world.set_terrain(width-1, y, floor_tile)
		G.world.set_terrain(width-2, y, floor_tile)
		G.world.spawn_points.append(G.world.tiles[y][width-1])
	elif dir == 2:
		var x = R.ir(1, width-2)
		G.world.set_terrain(x, height-1, floor_tile)
		G.world.set_terrain(x, height-2, floor_tile)
		G.world.spawn_points.append(G.world.tiles[height-1][x])
	elif dir == 3:
		var y = R.ir(1, height-2)
		G.world.set_terrain(0, y, floor_tile)
		G.world.set_terrain(1, y, floor_tile)
		G.world.spawn_points.append(G.world.tiles[y][0])

func place_output():
	output = make_base(width, height, 0)
	for y in range(height):
		for x in range(width):
			var val = base[y][x]
			if val == FLOOR_TILE:
				output[y][x] = ['tile']
			elif val == WALL_TILE:
				output[y][x] = ['concrete']
			else:
				output[y][x] = ['tile', ['door', 100]]

func _process():
	while !_stack.empty():
		var room = _stack.pop_front()
		partition(room[0], room[1], room[2], room[3])

func partition(x1, y1, x2, y2):
	var availX = []
	var availY = []
	for i in range(x1, x2+1):
		var vbound = y1 > 0 and y2 < height
		if vbound and !(i % 2):
			availX.append(i)
	for j in range(y1, y2+1):
		var hbound = x1 > 0 and x2 < width
		if hbound and !(j % 2):
			availY.append(j)

	if availX.size() < 1 or availY.size() < 1:
		return

	var rx = R.r_arr(availX)
	var ry = R.r_arr(availY)

	base[ry][rx] = WALL_TILE

	var walls = []

	var left = []
	walls.append(left)
	for i in range(x1, rx):
		base[ry][i] = WALL_TILE
		if (i % 2):
			left.append([i, ry])

	var right = []
	walls.append(right)
	for i in range(rx, x2):
		base[ry][i] = WALL_TILE
		if (i % 2):
			right.append([i, ry])

	var top = []
	walls.append(top)
	for j in range(y1, ry):
		base[j][rx] = WALL_TILE
		if (j % 2):
			top.append([rx, j])

	var bottom = []
	walls.append(bottom)
	for j in range(ry, y2):
		base[j][rx] = WALL_TILE
		if (j % 2):
			bottom.append([rx, j])

	var solid = R.r_arr(walls)
	for i in range(walls.size()):
		var w = walls[i]
		if (w == solid):
			continue
		elif !w.empty():
			var hole = R.r_arr(w)
			base[hole[1]][hole[0]] = 2

	_stack.append([x1, y1, rx-1, ry-1]) #left top
	_stack.append([rx+1, y1, x2, ry-1]) #right top
	_stack.append([x1, ry+1, rx-1, y2]) #left bottom
	_stack.append([rx+1, ry+1, x2, y2]) #right bottom
