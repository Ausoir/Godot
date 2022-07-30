extends "res://world/generator.gd"

var mob_spawns = []

func generate(vault_name, x, y):
	.create(x, y)
	G.world.create_map(width, height)
	output = make_base(width, height, null)
	make_vault([0, 0, x-1, y-1], vault_name, -1)
	paint_map()
