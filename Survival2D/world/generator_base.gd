extends "res://world/generator.gd"

var _stack = []
var size
var estates = []

func generate():
	.create(80, 80)
	G.field.create_map(width, height)
	base = make_perlin(width, height)
	output = make_base(width, height, 0)
	for x in range(width):
		for y in range(height):
			var value = base[y][x]
			if value > 0.7:
				output[y][x] = ['rock wall']
			elif value > 0.5:
				output[y][x] = ['grass']
			elif value > 0.4:
				output[y][x] = ['dirt']
			else:
				output[y][x] = ['water']
	place_buildings()
	paint_map()
	paint_spawn(0)

func place_buildings():
	var centers = []
	for _i in range(20):
		var fromx = G.rng.randi_range(20, width-29)
		var fromy = G.rng.randi_range(20, height-29)
		var estate = [fromx, fromy, fromx+8, fromy+8]
		make_vault(estate, "map_shack", G.rng.randi_range(0, 3))
		centers.append([fromx + 4, fromy + 4])
