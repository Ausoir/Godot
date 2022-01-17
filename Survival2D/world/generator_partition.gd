extends "res://world/generator.gd"

var _stack = []
var size

func generate():
	.create(60, 60)
	base = make_base(width, height, FLOOR_TILE)

	_stack = [
		[1, 1, width-2, height-2]
	]
	_process()

	return base

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

	var rx = G.rng.rnd_arr(availX)
	var ry = G.rng.rnd_arr(availY)

	base[rx][ry] = WALL_TILE

	var walls = []

	var left = []
	walls.append(left)
	for i in range(x1, rx):
		base[i][ry] = WALL_TILE
		if (i % 2):
			left.append([i, ry])

	var right = []
	walls.append(right) #Right
	for i in range(rx+1, x2+1):
		base[i][ry] = WALL_TILE
		if (i % 2):
			right.append([i, ry])

	var top = []
	walls.append(top) #Top
	for j in range(y1, ry):
		base[rx][j] = WALL_TILE
		if (j % 2):
			top.append([rx, j])

	var bottom = []
	walls.append(bottom)
	for j in range(ry+1, y2+1):
		base[rx][j] = WALL_TILE
		if (j % 2):
			bottom.append([rx, j])

	var solid = G.rng.rnd_arr(walls)
	for i in range(walls.size()):
		var w = walls[i]
		if (w == solid):
			continue
		elif !w.empty():
			var hole = G.rng.rnd_arr(w)
			base[hole[0]][hole[1]] = 'D'

	_stack.append([x1, y1, rx-1, ry-1]) #left top
	_stack.append([rx+1, y1, x2, ry-1]) #right top
	_stack.append([x1, ry+1, rx-1, y2]) #left bottom
	_stack.append([rx+1, ry+1, x2, y2]) #right bottom
