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
	make_mobs("urban")
	G.field.apply_shades(Vector2(), G.field.size)
	for y in range(G.field.size.y):
		for x in range(G.field.size.x):
			G.field.apply_autotile(x, y)
			set_dark(x, y)

func make_mobs(type):
	for _i in range(40):
		var x = G.rng.randi_range(0, G.field.size.x-1)
		var y = G.rng.randi_range(0, G.field.size.y-1)
		G.factory.make_group(type, G.field.tiles[y][x])

func set_dark(x, y):
	if shademap.get_cell(x, y) != 0:
		shademap.set_cell(x, y, 0)
		G.field.tiles[y][x].set_visible(false)

func set_light(x, y):
	if shademap.get_cell(x, y) == 0:
		shademap.set_cell(x, y, G.field.tiles[y][x].shade)
		G.field.tiles[y][x].set_visible(true)
