extends Node

const Tile = preload("res://world/tile.gd")
const ORDERED_DIRS = [[0,-1],[1,0],[0,1],[-1,0],[1,1],[-1,1],[-1,-1],[1,-1]]
var size
var terrain
var sound
var tiles
var spawn_points = []

func create_map(sx, sy):
	size = Vector2(sx, sy)
	var r = []
	for y in range(sy):
		var row = []
		for x in range(sx):
			row.append(Tile.new(x, y))
		r.append(row)
	tiles = r

func get_tile(x, y):
	if is_inbound(x, y):
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
			if adj.height == pos.height or adj == pos:
				dirs.append(i)
		var v = G.get_autotile_coord(dirs)
		var tileid = G.world.tilemap.get_cell(x, y)
		G.world.tilemap.set_cell(x, y, tileid, false, false, false, v)
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
	if spawn_points.empty():
		return tiles[0][0]
	return R.r_arr(spawn_points)

func get_routes(pos, cols, opens=false, strength=0):
	var r = []
	for i in ORDERED_DIRS:
		var ty = pos.y + i[1]
		var tx = pos.x + i[0]
		if is_inbound(tx, ty) and !tiles[ty][tx].is_cols_adv(cols, opens, strength):
			r.append(i)
	return r

func set_sound(pos, radius):
	for x in range(-radius, radius):
		for y in range(-radius, radius):
			var tx = pos.x + x
			var ty = pos.y + y
			if tx >= 0 and tx < len(sound[0]):
				if ty >= 0 and ty < len(sound):
					G.field.sound[pos.y + y][pos.x + x] = 1
