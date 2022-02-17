extends "res://world/generator.gd"

var _stack = []
var size
var estates = []
var fixed_buildings = []

func generate():
	.create(90, 60)
	G.field.create_map(width, height)
	base = make_perlin(width, height, 6)
	output = make_base(width, height, 0)
	for x in range(width):
		for y in range(height):
			var value = base[y][x]
			if value > 0.75:
				output[y][x] = ['rock wall']
			elif value > 0.5:
				output[y][x] = ['grass', ['old tree', 12, '/', ['tree', 4, '/', ['young tree', 2]]]]
			elif value > 0.3:
				output[y][x] = ['dirt', ['boulder', 2, '/', ['small boulder', 3]]]
			else:
				output[y][x] = ['water']
	place_complex()
	place_buildings()
	paint_map()
	paint_spawn(0)

func get_boundary(marginx, marginy, sx, sy):
	var fromx = R.ir(marginx + sx, width-1-marginx - sx)
	var fromy = R.ir(marginy + sy, height-1-marginy - sy)
	return [fromx-sx, fromy-sy, fromx+sx, fromy+sy]

func place_complex():
	for _i in range(28):
		var estate = get_boundary(24, 12, 4, 4)
		make_vault(estate, "base/shack", R.ir(0, 3))

func is_estate_vacant(px, py):
	for i in estates:
		if i[0] == px and i[1] == py:
			return false
	return true

func place_building(_building):
	var cellsx = (width-25)/8
	var cellsy = (height-25)/8
	for cx in range(cellsx):
		for cy in range(cellsy):
			if is_estate_vacant(cx, cy):
				estates.append([cx, cy])
				var x1 = cx*10 + 12
				var y1 = cy*10 + 12
				var estate = [x1-4, y1-4, x1+4, y1+4]
				make_vault(estate, "base/" + _building, R.ir(0, 3))
				return true
	return false

func place_buildings():
	for i in G.vars.base:
		if !place_building(i):
			push_error("Unable to place building "+i)
