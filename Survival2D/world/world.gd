extends Node

const Tile = preload("res://world/tile.gd")
const Turn = preload("res://classes/turn.gd")
var tileset = preload("res://assets/tileset.tres")
var turn = Turn.new()
var size
var terrain
var sound
var tiles
var spawn_points = []

onready var tilemap = $Tilemap
onready var shademap = $Shademap
onready var items = $Items
onready var players = $Players
onready var others = $Others
onready var canvas = $Canvas
var connections = {"exit":"city"}
var lights = []
var daytime = true
var map_name: String
var team = [[], [], []]

func clear():
	turn.clear()
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
	var generator
	map_name = _type
	G.worlds[map_name] = self
	daytime = int(G.vars.time) % 2 == 0
	if map_name == "city":
		generator = load("res://world/generator_city.gd").new()
		connections["down"] = "sewer"
		connections["up"] = "2nd"
		generator.generate()
	elif map_name == "sewer":
		daytime = false
		generator = load("res://world/generator_vault.gd").new()
		connections["up"] = "city"
		generator.generate("map_city_sewers")
	elif map_name == "2nd":
		generator = load("res://world/generator_vault.gd").new()
		connections["down"] = "city"
		generator.generate("map_city_2nd")
	apply_shades(Vector2(), size)
	tilemap.update_bitmask_region(Vector2(), size)
	for y in range(size.y):
		for x in range(size.x):
			apply_autotile(x, y)
			shademap.set_cell(x, y, 2)
			var tile = tiles[y][x]
			tile.visible = true
			tile.set_visible(false)
	G.process_onload()

func place_mobs(type, num):
	for _i in range(num):
		var adj
		var limit = 8
		while adj == null and limit > 0:
			limit -= 1
			var x = R.ir(0, size.x-1)
			var y = R.ir(0, size.y-1)
			adj = tiles[y][x]
			if adj.is_col(12):
				var adjs = tiles[y][x].get_available_adjacents(12)
				adj = R.r_arr(adjs)
		if adj != null:
			G.factory.make_group(type, adj)

func set_dark(tile):
	if tile.set_visible(false):
#		pass
		shademap.set_cell(tile.x, tile.y, 2)

func set_light(tile):
	tile.set_visible(true)
	shademap.set_cell(tile.x, tile.y, -1)

func set_sight(tile):
	tile.set_visible(true)
	shademap.set_cell(tile.x, tile.y, 1)

func create_map(sx, sy):
	size = Vector2(sx, sy)
	var r = []
	for y in range(sy):
		var row = []
		for x in range(sx):
			row.append(Tile.new(self, x, y))
		r.append(row)
	tiles = r

func get_tile(x, y):
	if is_inbound(x, y):
		return tiles[y][x]

func from_vec(v):
	var x = int(v.x / 32)
	var y = int(v.y / 32)
	return tiles[y][x]

func apply_shades(start, end):
	for y in range(start.y, end.y):
		for x in range(start.x, end.x):
			tiles[y][x].apply_shade()

func apply_autotile(x, y):
	var pos = tiles[y][x]
	if pos.autotile == 1:
		var dirs = []
		for i in range(4):
			var adj = pos.get_adjacent(i * 2)
			if adj.height == pos.height:
				dirs.append(i)
		var v = G.get_autotile_coord(dirs)
		var tileid = tilemap.get_cell(x, y)
		tilemap.set_cell(x, y, tileid, false, false, false, v)
	for item in pos.items:
		item.autotilize()

func set_terrain(x, y, val):
	tiles[y][x].set_terrain(val)

func add_item(x, y, val):
	tiles[y][x].items.append(val)

func is_inbound(x, y):
	return x >= 0 and x < size.x and y >= 0 and y < size.y

func fit_bound(x, y):
	return tiles[clamp(y, 0, size.y-1)][clamp(x, 0, size.x-1)]

func get_spawn_point():
	if !spawn_points.empty():
		return R.r_arr(spawn_points)

func get_routes(pos, cols, opens=false, strength=0):
	var r = []
	for i in G.CARDINALS:
		var ty = pos.y + i[1]
		var tx = pos.x + i[0]
		if is_inbound(tx, ty) and !tiles[ty][tx].is_col_adv(cols, opens, strength):
			r.append(i)
	return r

func set_sound(pos, radius):
	for x in range(-radius, radius):
		for y in range(-radius, radius):
			var tx = pos.x + x
			var ty = pos.y + y
			if tx >= 0 and tx < len(sound[0]):
				if ty >= 0 and ty < len(sound):
					sound[pos.y + y][pos.x + x] = 1
