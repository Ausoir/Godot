extends "res://world/generator.gd"


func generate():
	var field = G.field
	field.create_map(G.rng.randi_range(60, 80), G.rng.randi_range(60, 80))
	base = make_perlin(field.size.x, field.size.y)
	for x in range(field.size.x):
		for y in range(field.size.y):
			var value = base[y][x]
			if value > 0.7:
				field.set_terrain(x, y, 'rock')
			elif value > 0.55:
				field.set_terrain(x, y, 'field')
			elif value > 0.4:
				field.set_terrain(x, y, 'dirt')
			elif value > 0.398:
				field.set_terrain(x, y, 'field')
				field.spawn_points.append(G.field.tiles[y][x])
			elif value > 0.394:
				field.set_terrain(x, y, 'field')
				G.factory.make_item('rock', field.tiles[y][x])
			elif value > 0.39:
				field.set_terrain(x, y, 'field')
				G.factory.make_item('branch', field.tiles[y][x])
			else:
				field.set_terrain(x, y, 'water')
	for _i in range(4):
		var x = G.rng.randi_range(0, field.size.x-1)
		var y = G.rng.randi_range(0, field.size.y-1)
		G.factory.make_mob('kenku peasants', field.tiles[y][x])

	G.world.tilemap.update_bitmask_region()
