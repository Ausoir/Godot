extends "res://world/generator.gd"


func generate():
	var field = G.field
	field.create_map(G.rng.randi_range(60, 80), G.rng.randi_range(60, 80))
	base = make_perlin(field.size.x, field.size.y)
	var spawn_set = false
	for x in range(field.size.x):
		for y in range(field.size.y):
			var value = base[y][x]
			if value > 0.6:
				field.set_terrain(x, y, 'rock')
			elif value > 0.3:
				field.set_terrain(x, y, 'field')
			elif value > 0.29:
				if !spawn_set:
					field.spawn_points.append(G.field.tiles[y][x])
					spawn_set = true
				field.set_terrain(x, y, 'field')
				G.factory.make_item('rock', field.tiles[y][x])
			else:
				field.set_terrain(x, y, 'water')
	field.terrain = terrain
	print(G.field.terrain)

	G.world.tilemap.update_bitmask_region(Vector2(0, 0), Vector2(field.size.x, field.size.y))
	G.world.tilemap.update_dirty_quadrants()
