extends "res://world/generator.gd"


func generate():
	.create(60, 60)
	base = make_perlin(width, height)
	for x in range(width):
		for y in range(height):
			var value = base[y][x]
			if value > 0.7:
				G.field.set_terrain(x, y, 'concrete')
			elif value > 0.65:
				G.field.set_terrain(x, y, 'concrete')
			elif value > 0.55:
				G.field.set_terrain(x, y, 'grass')
			elif value > 0.4:
				G.field.set_terrain(x, y, 'grass')
			elif value > 0.398:
				G.field.set_terrain(x, y, 'grass')
				G.field.spawn_points.append(G.G.field.tiles[y][x])
			elif value > 0.394:
				G.field.set_terrain(x, y, 'grass')
				G.factory.make_item('rock', G.field.tiles[y][x])
			elif value > 0.39:
				G.field.set_terrain(x, y, 'grass')
				G.factory.make_item('branch', G.field.tiles[y][x])
			else:
				G.field.set_terrain(x, y, 'waterr')
	for _i in range(5):
		var x = rng.randi_range(0, width-1)
		var y = rng.randi_range(0, height-1)
		G.factory.make_mob('kenku peasants', G.field.tiles[y][x])

	G.world.tilemap.update_bitmask_region()
