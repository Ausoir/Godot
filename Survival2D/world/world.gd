extends Node

var tileset = preload("res://assets/tileset.tres")

var sunlight = 0
onready var tilemap = $Tilemap
onready var shademap = $Shademap
onready var items = $Items
onready var players = $Players
onready var others = $Others

func create(_type):
	var generator
	if _type == "base":
		generator = load("res://world/generator_base.gd").new()
		generator.generate()
	elif _type == "urban":
		generator = load("res://world/generator_street.gd").new()
		generator.generate()
		make_mobs("urban", 24)
	G.field.apply_shades(Vector2(), G.field.size)
	for y in range(G.field.size.y):
		for x in range(G.field.size.x):
			G.field.apply_autotile(x, y)
			set_dark(x, y)

func change(_map):
	G.data.json_cache.clear()
	tilemap.clear()
	shademap.clear()
	var units = []
	for player in players.get_children():
		if player.unit != null:
			items.remove_child(player.unit)
			units.append(player.unit)
	for item in items.get_children():
		item.remove()
	for item in others.get_children():
		item.queue_free()
		items.remove_child(item)
	create(_map)
	for unit in units:
		items.add_child(unit)

func make_mobs(type, num):
	for _i in range(num):
		var x = G.rng.randi_range(0, G.field.size.x-1)
		var y = G.rng.randi_range(0, G.field.size.y-1)
		G.factory.make_group(type, G.field.tiles[y][x])

func set_dark(x, y):
	if shademap.get_cell(x, y) != 0:
		shademap.set_cell(x, y, 0)
		G.field.tiles[y][x].set_visible(false)

func set_light(x, y):
	if shademap.get_cell(x, y) == 0:
		var light = G.field.tiles[y][x].light
		if light >= 0:
			shademap.set_cell(x, y, G.field.tiles[y][x].shade)
		else:
			shademap.set_cell(x, y, 1)
		G.field.tiles[y][x].set_visible(true)

func update_light(x, y):
	var light = G.field.tiles[y][x].light
	if light >= 0:
		shademap.set_cell(x, y, G.field.tiles[y][x].shade)
	else:
		shademap.set_cell(x, y, 1)
