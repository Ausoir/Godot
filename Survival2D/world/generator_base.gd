extends "res://world/generator.gd"

var _stack = []
var size
var estates = []
var fixed_buildings = []

func generate():
	.create(120, 60)
	G.field.create_map(width, height)
	base = make_perlin(width, height, 6)
	output = make_base(width, height, 0)
	for x in range(width):
		for y in range(height):
			var value = base[y][x]
			if value > 0.75:
				output[y][x] = ['rock wall']
			elif value > 0.5:
				output[y][x] = ['grass', ['tree', 12]]
			elif value > 0.3:
				output[y][x] = ['dirt', ['boulder', 2, '/', ['small boulder', 3]]]
			else:
				output[y][x] = ['water']
	place_buildings()
	paint_map()
	paint_spawn(0)

func place_buildings():
	for _i in range(20):
		var fromx = R.ir(10, width-39)
		var fromy = R.ir(10, height-19)
		var estate = [fromx, fromy, fromx+8, fromy+8]
		make_vault(estate, "map_shack", R.ir(0, 3))
	var fromx = R.ir(20, width-54)
	var fromy = R.ir(20, height-34)
	var estate = [fromx, fromy, fromx+13, fromy+13]
	make_vault(estate, "map_chiefshack", R.ir(0, 3))
