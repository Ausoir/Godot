extends "res://world/generator.gd"

var _stack = []
var size
var estates = []
var fixed_buildings = []

func generate():
	.create(80, 50)
	G.field.create_map(width, height)
	base = make_perlin(width, height, 6)
	output = make_base(width, height, 0)
	make_border(.1)
	make_border(.1, [], 1)
	for y in range(height):
		base[y][width-1] = .5
		base[y][width-2] = .5
	for x in range(width):
		for y in range(height):
			var value = base[y][x]
			if value > 0.75:
				output[y][x] = ['rock wall']
			elif value > 0.5:
				output[y][x] = ['grass', ['old tree', 8, '/', ['tree', 2, '/', ['young tree', 1, '/', ['shrub', 4]]]]]
			elif value > 0.3:
				output[y][x] = ['dirt', ['boulder', 1, '/', ['small boulder', 2]]]
			else:
				output[y][x] = ['water']
	make_vault([0, 0, 54, 39], "map_base", -1)
	place_complex()
	place_buildings()
	for x in range(width):
		for y in range(height):
			if output[y][x][0] == 'wood floor':
				spawn_points.append([x, y])
	paint_map()
	paint_spawn(1)

func place_complex():
	for _i in range(G.vars.base.size() + 1):
		var fromx = R.ir(12 + 4, int(width*2/5) - 5)
		var fromy = R.ir(8 + 4, height-1-8 - 4)
		var estate = [fromx-4, fromy-4, fromx+4, fromy+4]
		make_vault(estate, "base/shack", R.ir(0, 3))

func is_estate_vacant(px, py):
	for i in estates:
		if i[0] == px and i[1] == py:
			return false
	return true

func place_building(_building):
	var cellsx = (width-16)/8
	var cellsy = (height-16)/8
	for cx in range(cellsx):
		for cy in range(cellsy):
			if is_estate_vacant(cx, cy):
				var midgap
				if cy < cellsy/2:
					midgap = -4
				else:
					midgap = 4
				estates.append([cx, cy])
				var x1 = cx*8 + 8
				var y1 = cy*8 + 8+midgap
				var estate = [x1-4, y1-4, x1+4, y1+4]
				make_vault(estate, "base/" + _building, R.ir(0, 3))
				return true
	return false

func place_buildings():
	for i in G.vars.base:
		if !place_building(i):
			push_error("Unable to place building "+i)
