var vaults = preload("res://world/vaults.gd").new()
var FLOOR_TILE = '.'
var WALL_TILE = '#'
var width
var height
var base
var terrain
var rng

func create(x, y):
	width = x
	height = y
	rng = G.rng

func paint_palette():
	for x in range(width):
		for y in range(height):
			var value = base[y][x]
			var palet = G.data.palette_data.get(value)
			if palet != null:
				G.field.set_terrain(x, y, palet[0])
				for i in range(1, palet.size()):
					place_object(palet[i], x, y)
			else:
#				G.field.set_terrain(x, y, 'glass')
				print("Palette value not found for: "+str(value))
			if G.rng.rnd_percent(1):
				G.field.spawn_points.append(G.field.tiles[y][x])

func place_object(dat, x, y):
	if G.rng.rnd_percent(dat[1]):
		G.factory.make_item(dat[0], G.field.tiles[y][x])
		if dat.size() > 2:
			place_object(dat[2], x, y)

func make_base(sx, sy, val):
	var r = []
	for _y in range(sy):
		var row = []
		for _x in range(sx):
			row.append(val)
		r.append(row)
	return r

func make_random(sx, sy):
	var r = []
	for _y in range(sy):
		var row = []
		for _x in range(sx):
			row.append(G.rng.randf())
		r.append(row)
	return r


func make_smooth(map, level):
	var w = len(map[0])
	var h = len(map)
	var r = []
	var period = 2 << level
	var frequency = 1.0 / period
	for y in range(h):
		var sample1 = int(y / period) * period
		var sample2 = int((sample1 + period) % h)
		var horizontal_blend = (y - sample1) * frequency
		var row = []
		for x in range(w):
			var sample3 = int(x / period) * period
			var sample4 = int((sample3 + period) % w)
			var vertical_blend = (x - sample3) * frequency
			var top = interpolate(map[sample1][sample3], map[sample2][sample3], horizontal_blend)
			var bot = interpolate(map[sample1][sample4], map[sample2][sample4], horizontal_blend)
			row.append(interpolate(top, bot, vertical_blend))
		r.append(row)
	return r
		
func interpolate(arg1, arg2, alpha):
	return arg1 * (1 - alpha) + alpha * arg2

func make_perlin(sx, sy):
	var r = make_random(sx, sy)
	var map = make_base(sx, sy, 0)
	var levels = 5
	var max_value = 0
	for i in range(1, levels):
		max_value += float(1)/i
	for level in range(1, levels):
		var graph = make_smooth(r, level)
		for y in range(sy):
			for x in range(sx):
				map[y][x] += graph[y][x] * 1/level
	for y in range(sy):
		for x in range(sx):
			map[y][x] /= max_value
	return map

func smooth_edges(val):
	var w = len(base[0])
	var h = len(base)
	for y in range(h):
		for i in range(val):
			base[y][i] *= float(i)/val
			base[y][w-i-1] *= float(i)/val
	for x in range(w):
		for i in range(val):
			base[i][x] *= float(i)/val
			base[h-i-1][x] *= float(i)/val
	return base

func smooth_base(_map, iterations, threshold):
	for _i in range(iterations):
		var tiles = make_base(width, height, FLOOR_TILE)
		for y in range(height):
			for x in range(width):
				var r2 = 0
				for dy in range(-2, 3):
					for dx in range(-2, 3):
						if (abs(dx) + abs(dy) >= 3):
							continue
						if (is_inbound(x + dx, y + dy) and _map[y+dy][x+dx] == FLOOR_TILE):
							r2 += 1
				if (r2 >= threshold):
					tiles[y][x] = FLOOR_TILE
				else:
					tiles[y][x] = WALL_TILE
		_map = tiles


func radialize():
	var w = len(base[0])
	var h = len(base)
	var center_x = int(w * .5)
	var center_y = int(h * .5)
	for i in range(h):
		for j in range(w):
			var val_y = pow(float(i - center_y) / center_y, 2)
			var val_x = pow(float(j - center_x) / center_x, 2)
			var val = min(1, (1-sqrt(val_x+val_y)) * 12)
			base[i][j] = val * base[i][j]
	return base

func invert():
	var w = len(base[0])
	var h = len(base)
	for i in range(h):
		for j in range(w):
			base[i][j] = 1 - base[i][j]
	return base

func fill(from, to, val):
	for y in range(from.y, to.y+1):
		for x in range(from.x, to.x+1):
			base[y][x] = val

func make_border(val, exc=[]):
	var list = []
	for i in range(height):
		list.append([i, 0])
		list.append([i, width-1])
	for i in range(width):
		list.append([0, i])
		list.append([height-1, i])
	for i in list:
		if not base[i[0]][i[1]] in exc:
			base[i[0]][i[1]] = val
	return base

func check_adjacent(x, y, tile):
	if base[y][x] == tile or\
		(y+1 < len(base) and base[y+1][x] == tile) or\
		(y-1 >= 0 and base[y-1][x] == tile) or\
		(x+1 < len(base[0]) and base[y][x+1] == tile) or\
		(x-1 >= 0 and base[y][x-1] == tile):
			return true
	return false

func boundary_dist(x, y):
	var xdist = min(x, len(base[0])-1-x)
	var ydist = min(y, len(base)-1-y)
	return min(xdist, ydist)

func oddify(p):
	return int(p / 2) * 2 + 1

func is_inbound(x, y):
	return x >= 0 and x < width and y >= 0 and y < height

func magnify(mag):
	var r = []
	for y in range(height):
		var row = []
		for x in range(width):
			for _i in range(mag):
				row.append(base[y][x])
		for _i in range(mag):
			r.append(row)
	width = len(r[0])
	height = len(r)
	return r
