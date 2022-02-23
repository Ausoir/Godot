extends "res://world/generator.gd"

var _stack = []
var size
var estates = []
var fixed_buildings = []
var mob_spawns = []

func generate():
	.create(56, 75)
	G.field.create_map(width, height)
	base = make_perlin(width, height, 6)
	output = make_base(width, height, 0)
	make_border(.1)
	make_border(.1, [], 1)
	for x in range(width):
		base[height-1][x] = .5
		base[height-2][x] = .5
	for x in range(width):
		for y in range(height):
			var value = base[y][x]
			if value > 0.75:
				output[y][x] = ['rock wall']
			elif value > 0.5:
				output[y][x] = ['grass', ['old tree', 8, '/', ['tree', 2, '/', ['young tree', 1, '/', ['shrub', 4]]]]]
			elif value > 0.3:
				output[y][x] = ['dirt', ['small boulder', 1, '/', ['boulder', 1]]]
			else:
				output[y][x] = ['water']
	place_complex()
	make_vault([0, 0, 55, 40], "map_city", -1)
	for x in range(width):
		for y in range(height):
			if output[y][x][0] == 'asphalt':
				spawn_points.append([x, y])
	paint_map()
	paint_spawn(1)
	for i in mob_spawns:
		var adj = G.field.tiles[i[1]][i[0]]
		if !adj.is_cols("0011"):
			G.factory.make_group("g_urban", adj)

func place_complex():
	for _i in range(7):
		var fromx = R.ir(8, width-9)
		var fromy = R.ir(45, height-5)
		var estate = [fromx-4, fromy-4, fromx+4, fromy+4]
		make_vault(estate, "base/shack", R.ir(0, 3))
		mob_spawns.append([fromx, fromy])

func is_estate_vacant(px, py):
	for i in estates:
		if i[0] == px and i[1] == py:
			return false
	return true
