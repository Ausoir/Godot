extends "res://world/generator.gd"


func generate():
	var field = G.field
	field.create_map(G.rng.randi_range(40, 80), G.rng.randi_range(40, 80))
	base = make_perlin(field.size.x, field.size.y)
	for x in range(field.size.x):
		for y in range(field.size.y):
			var value = base[y][x]
			if value > 0.8:
				field.set_terrain(x, y, 'metal')
			elif value > 0.6:
				field.set_terrain(x, y, 'rock')
			elif value > 0.3:
				field.set_terrain(x, y, 'field')
			else:
				field.set_terrain(x, y, 'water')
	field.spawn_points.append(G.field.tiles[2][2])
	field.terrain = terrain
	print(G.field.terrain)

	G.world.tilemap.update_bitmask_region(Vector2(0, 0), Vector2(field.size.x, field.size.y))
	G.world.tilemap.update_dirty_quadrants()
