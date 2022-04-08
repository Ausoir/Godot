extends "res://world/generator.gd"

var mob_spawns = []

func generate():
	.create(85, 40)
	G.world.create_map(width, height)
	base = make_perlin(width, height, 6)
	output = make_base(width, height, 0)
	for x in range(width):
		for y in range(height):
			if y == height-1:
				output[y][x] = ['water']
			elif x == width-1:
				if y % 9 == 0:
					output[y][x] = ['dirt', ["late spawner", 100]]
				else:
					output[y][x] = ['dirt']
			else:
				var value = base[y][x]
				if value > 0.7:
					output[y][x] = ['rock wall']
				elif value > 0.5:
					output[y][x] = ['grass', ['old tree', 8, '/', ['tree', 2, '/', ['young tree', 1, '/', ['shrub', 4]]]]]
				elif value > 0.3:
					output[y][x] = ['dirt', ['small boulder', 1, '/', ['boulder', 1]]]
				else:
					output[y][x] = ['water']
	place_complex()
	make_vault([0, 0, 54, 39], "map_city", -1)
	for x in range(width):
		for y in range(height):
			if output[y][x][0] == 'asphalt':
				spawn_points.append([x, y])
	paint_map()
	paint_spawn(1)
	for i in mob_spawns:
		var adj = G.world.tiles[i[1]][i[0]]
		if !adj.is_col(14):
			G.factory.make_group("g_urban", adj)

func place_complex():
	for _i in range(12):
		var fromx = R.ir(62, width-5)
		var fromy = R.ir(5, height-5)
		var estate = [fromx-4, fromy-4, fromx+4, fromy+4]
		make_vault(estate, "shack", R.ir(0, 3))
		mob_spawns.append([fromx, fromy])
