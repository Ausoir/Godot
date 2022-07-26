extends "res://world/generator.gd"

var size
var estates = []
var spawns = []
var complex

func generate(p):
	.create(50, 30)
	G.world.create_map(width, height)
	base = make_perlin(width, height, 6)
	output = make_base(width, height, 0)
	make_border(.1)
	make_border(.1, [], 1)
	if p == "fields":
		spawns = [
			[.8, ['grass', ['old tree', .08, '/', ['tree', .02, '/', ['young tree', .01, '/', ['shrub', .04]]]]]],
			[0, ['dirt', ['boulder', .01, '/', ['small boulder', .02]]]],
		]
		complex = ["shack", 0, 7]
	elif p == "woods":
		spawns = [
			[.75, ["rock wall"]],
			[.5, ['grass', ['old tree', .08, '/', ['tree', .02, '/', ['young tree', .01, '/', ['shrub', .04]]]]]],
			[.3, ['dirt', ['boulder', .01, '/', ['small boulder', .02]]]],
			[0, ['water']]
		]
		complex = ["shack", 0, 3]
	elif p == "caves":
		spawns = [
			[.5, ["rock wall"]],
			[0, ['dirt', ['boulder', .01, '/', ['small boulder', .02]]]],
		]
	for x in range(width):
		for y in range(height):
			var value = base[y][x]
			for i in spawns:
				if value > i[0]:
					output[y][x] = i[1]
	if complex != null:
		place_complex(complex)
	paint_map()

func place_complex(p):
	var padding = 4
	for _i in range(R.ir(p[1], p[2])):
		var fromx = R.ir(12 + padding, int(width*2/5) - padding)
		var fromy = R.ir(8 + padding, height-1-8 - padding)
		var estate = [fromx-padding, fromy-padding, fromx+padding, fromy+padding]
		make_vault(estate, p[0], R.ir(0, 3))
