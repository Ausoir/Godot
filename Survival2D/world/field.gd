extends Node

const Tile = preload("res://world/tile.gd")
var size
var terrain
var sound
var light
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
			if adj.height == pos.height:
				dirs.append(i)
		var v = G.get_autotile_coord(dirs)
		var tileid = G.world.tilemap.get_cell(x, y)
		G.world.tilemap.set_cell(x, y, tileid, false, false, false, v)
	elif pos.autotile == 2:
		G.world.tilemap.update_bitmask_area(Vector2(x, y))
	for item in pos.items:
		item.autotilize()

func set_terrain(x, y, val):
	tiles[y][x].set_terrain(val)

func add_item(x, y, val):
	tiles[y][x].items.append(val)

func is_inbound(x, y):
	return x >= 0 and x < G.field.size.x and y >= 0 and y < G.field.size.y

func get_spawn_point():
	if spawn_points.empty():
		return tiles[0][0]
	return G.rng.rnd_arr(spawn_points)

func get_routes(pos, cols):
	var r = []
	var count = 0
	for i in G.DIRS:
		var ty = pos.y + i[1]
		var tx = pos.x + i[0]
		if G.field.is_inbound(tx, ty) and !tiles[ty][tx].is_cols(cols):
			r.append(count)
		count += 1
	return r

func set_sound(pos, radius):
	for x in range(-radius, radius):
		for y in range(-radius, radius):
			var tx = pos.x + x
			var ty = pos.y + y
			if tx >= 0 and tx < len(sound[0]):
				if ty >= 0 and ty < len(sound):
					G.field.sound[pos.y + y][pos.x + x] = 1
