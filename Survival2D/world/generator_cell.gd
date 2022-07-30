extends "res://world/generator.gd"

func generate_ruins():
	.create(57, 57)
	G.world.create_map(width, height)
	output = make_base(width, height, null)
	for x in range(8):
		for y in range(8):
			var fromx = x * 7
			var fromy = y * 7
			var estate = [fromx, fromy, fromx+6, fromy+6]
			make_vault(estate, "map_cell", R.ir(0, 3))
	paint_map()
