extends Node

var tileset = preload("res://assets/tileset.tres")

onready var tilemap = $Tilemap
onready var shademap = $Shademap
onready var items = $Items
onready var players = $Players
onready var others = $Others
var daytime = true
var map_name: String
var team = [[], [], []]

func clear():
	G.turn.clear()
	team = [[], [], []]
	G.data.json_cache.clear()
	tilemap.clear()
	shademap.clear()
	for player in players.get_children():
		player.on_map_clear()
	for item in items.get_children():
		item.remove()
	for item in others.get_children():
		item.queue_free()
		items.remove_child(item)

func create(_type):
	clear()
	var generator
	map_name = _type
	if map_name == "base":
		generator = load("res://world/generator_base.gd").new()
		generator.generate()
	elif map_name == "urban":
		generator = load("res://world/generator_street.gd").new()
		generator.generate()
		place_mobs("g_urban", 36)
	elif map_name == "dungeon":
		generator = load("res://world/generator_dungeon.gd").new()
		generator.generate()
		place_mobs("g_urban", 44)
	elif map_name == "lab":
		generator = load("res://world/generator_maze.gd").new()
		generator.generate()
		place_mobs("g_urban", 36)
	G.field.apply_shades(Vector2(), G.field.size)
	for y in range(G.field.size.y):
		for x in range(G.field.size.x):
			G.field.apply_autotile(x, y)
			set_dark(x, y)
	G.process_onload()

func place_mobs(type, num):
	for _i in range(num):
		var adj
		var limit = 8
		while adj == null and limit > 0:
			limit -= 1
			var x = R.ir(0, G.field.size.x-1)
			var y = R.ir(0, G.field.size.y-1)
			adj = G.field.tiles[y][x]
			if adj.is_col(1):
				var adjs = G.field.tiles[y][x].get_available_adjacents("0100")
				adj = R.r_arr(adjs)
		if adj != null:
			G.factory.make_group(type, adj)

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
