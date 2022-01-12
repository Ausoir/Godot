extends Node

var tileset = preload("res://assets/tileset.tres")
var generator = preload("res://world/generator_street.gd").new()

onready var tilemap = $Tilemap
onready var shademap = $Shademap
onready var items = $Items
onready var players = $Players
onready var others = $Others
onready var fog = $Fog

func generate():
	generator.generate()
	G.field.create_map(generator.width, generator.height)
	generator.paint_palette()
	G.field.apply_shades(Vector2(), G.field.size)
	for y in range(G.field.size.y):
		for x in range(G.field.size.x):
			set_dark(x, y)

func set_dark(x, y):
	if shademap.get_cell(x, y) != 0:
		shademap.set_cell(x, y, 0)
		G.field.tiles[y][x].set_visible(false)

func set_light(x, y):
	if shademap.get_cell(x, y) == 0:
		shademap.set_cell(x, y, G.field.tiles[y][x].shade)
		G.field.tiles[y][x].set_visible(true)

func check_collision(from, to, exclude):
	var space_state = $tilemap.get_world_2d().direct_space_state
	var result = space_state.intersect_ray(from, to, exclude, 1)
	return result
