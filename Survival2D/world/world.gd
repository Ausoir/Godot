extends Node

const Turn = preload("res://classes/turn.gd")
var tileset = preload("res://assets/tileset.tres")
var turn = Turn.new()
var size
var terrain
var sound
var tiles
var spawn_points = []
var timeout = 0

onready var tilemap = $Tilemap
onready var shademap = $Shademap
onready var items = $Items
onready var players = $Players
onready var others = $Others
onready var canvas = $Canvas
var connections = {"exit":"city"}
var map_name: String
var team = [[], [], []]
var onloads = []

func create(_type):
	var generator
	map_name = _type
	if map_name == "caverns":
		generator = load("res://world/generator_wild.gd").new()
		generator.generate("caves")
	elif map_name == "woods":
		generator = load("res://world/generator_wild.gd").new()
		generator.generate("woods")
	elif map_name == "fields":
		generator = load("res://world/generator_wild.gd").new()
		generator.generate("fields")
	elif map_name == "town":
		generator = load("res://world/generator_street.gd").new()
		generator.generate()
	elif map_name == "ruins":
		generator = load("res://world/generator_cell.gd").new()
		generator.generate_ruins()
	elif map_name == "lab":
		generator = load("res://world/generator_maze.gd").new()
		generator.generate_lab()
	apply_shades(Vector2(), size)
	tilemap.update_bitmask_region(Vector2(), size)
	for y in range(size.y):
		for x in range(size.x):
			apply_autotile(x, y)
			shademap.set_cell(x, y, 2)
			var tile = tiles[y][x]
			tile.set_visible(false)
	process_onload()
	$Borders.position = Vector2(size.x * G.HW, size.y * G.HH)
	$Borders/Left.position = Vector2(size.x * -G.HW - G.W, 0)
	$Borders/Right.position = Vector2(size.x * G.HW + G.W, 0)
	$Borders/Top.position = Vector2(0, size.y * -G.HH - G.H)
	$Borders/Bottom.position = Vector2(0, size.y * G.HH + G.H)

func get_item_by_seed(p):
	if p == -1:
		return G.you.unit
	elif p > 0:
		for i in team:
			for unit in i:
				if unit.dat.g("seed", 0) == p:
					return unit

func get_items_by_name(p):
	var r = []
	for y in range(size.y):
		for x in range(size.x):
			for item in tiles[y][x].items:
				if item.item_name == p and is_instance_valid(item):
					r.append(item)
	return r

func process_onload():
	for i in onloads:
		G.cmds(i[1], i[0])
	onloads.clear()

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
		shademap.set_cell(tile.x, tile.y, 1)
		for i in tile.items:
			if i.item_type == "unit":
				G.you.on_enemy_sighted(i, false)

func set_light(tile):
	if !tile.visible:
		tile.set_visible(true)
		if shademap.get_cell(tile.x, tile.y) == 2:
			if G.temp.discover != null:
				G.cmds(G.temp.discover, G.you.unit, tile)
		for i in tile.items:
			if i.item_type == "unit":
				G.you.on_enemy_sighted(i, true)
		shademap.set_cell(tile.x, tile.y, -1)

func create_map(sx, sy):
	size = Vector2(sx, sy)
	var r = []
	for y in range(sy):
		var row = []
		for x in range(sx):
			row.append(G.Tile.new(self, x, y))
		r.append(row)
	tiles = r

func get_tile(x, y):
	if is_inbound(x, y):
		return tiles[y][x]

func from_vec(v):
	var x = int(v.x / G.W)
	var y = int(v.y / G.H)
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
		var ty = pos.y + i.y
		var tx = pos.x + i.x
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

func paint_spawn(dir):
	if dir == 0:
		for x in range(1, size.x-1):
			if !tiles[0][x].is_col(4) and !tiles[1][x].is_col(4):
				spawn_points.append(tiles[0][x])
	elif dir == 1:
		for y in range(1, size.y-1):
			if !tiles[y][size.x-1].is_col(4) and !tiles[y][size.x-2].is_col(4):
				spawn_points.append(tiles[y][size.x-1])
	elif dir == 2:
		for x in range(1, size.x-1):
			if !tiles[size.y-1][x].is_col(4) and !tiles[size.y-2][x].is_col(4):
				spawn_points.append(tiles[size.y-1][x])
	elif dir == 3:
		for y in range(1, size.y-1):
			if !tiles[y][0].is_col(4) and !tiles[y][1].is_col(4):
				spawn_points.append(tiles[y][0])
	for _i in range(100):
		var tile = tiles[R.ir(0, size.y-1)][R.ir(0, size.x-1)]
		if !tile.is_col(4):
			spawn_points.append(tile)
			break
	if spawn_points.empty():
		if timeout > 2:
			print("Could not place spawn point for map: "+map_name)
			return null
		timeout += 1
		create(map_name)
		return paint_spawn(dir)
	return spawn_points
