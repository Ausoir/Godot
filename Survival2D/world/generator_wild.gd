extends "res://world/generator.gd"

var size
var estates = []
var spawns = []
var complex

func generate(p):
	.create(R.ir(30, 60), R.ir(30, 60))
	G.world.create_map(width, height)
	base = make_perlin(width, height, 5)
	output = make_base(width, height, 0)
	if p == "fields":
		spawns = [
			[0, ['dirt', ['boulder', .01, '/', ['small boulder', .02]]]],
			[.4, ['grass', ['shrub', .02]]],
			[.6, ['grass', ['old tree', .05, '/', ['tree', .01, '/', ['young tree', .01, '/', ['shrub', .04]]]]]],
			[.8, ['water']],
		]
		complex = ["shack", 0, 5]
	elif p == "woods":
		spawns = [
			[0, ['dirt', ['boulder', .01, '/', ['small boulder', .02]]]],
			[.5, ['grass', ['old tree', .06, '/', ['tree', .1, '/', ['young tree', .03, '/', ['shrub', .2]]]]]],
			[.7, ["rock wall"]],
			[.8, ['water']],
		]
		complex = ["shack", 0, 3]
	elif p == "caves":
		spawns = [
			[0, ["water"]],
			[.2, ['dirt', ['boulder', .01, '/', ['small boulder', .02]]]],
			[.65, ["rock wall"]],
		]
		make_border(WALL_TILE)
		post_process_cmd = [["make","stairdown","$R"], ["make","stairup","$R"]]
	for x in range(width):
		for y in range(height):
			var v = base[y][x]
			for i in spawns:
				if v > i[0]:
					output[y][x] = i[1]
	for _i in range(16):
		base[0][R.ir(0, width-1)] = spawns[0][1]
		base[height-1][R.ir(0, width-1)] = spawns[0][1]
		base[R.ir(0, height-1)][0] = spawns[0][1]
		base[R.ir(0, height-1)][width-1] = spawns[0][1]
	if complex != null:
		for _i in range(R.ir(complex[1], complex[2])):
			place_building(complex[0])
	paint_map()

func place_complex(p):
	var padding = 4
	for _i in range(R.ir(p[1], p[2])):
		var fromx = R.ir(12 + padding, int(width*2/5) - padding)
		var fromy = R.ir(8 + padding, height-1-8 - padding)
		var estate = [fromx-padding, fromy-padding, fromx+padding, fromy+padding]
		make_vault(estate, p[0], R.ir(0, 3))

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
				make_vault(estate, _building, R.ir(0, 3))
				return true
	return false
