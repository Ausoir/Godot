extends Node

var size
var terrain
var sound
var light
var tiles
var spawn_points = []

func create_map(sx, sy):
	var Tile = preload("res://world/tile.gd")
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
	for x in range(start.x, end.x):
		for y in range(start.y, end.y):
			tiles[y][x].apply_shade()

func set_terrain(x, y, val):
	tiles[y][x].set_terrain(val)

func add_item(x, y, val):
	tiles[y][x].items.append(val)

func is_inbound(x, y):
	return x >= 0 and x < G.field.size.x and y >= 0 and y < G.field.size.y

func get_spawn_point():
	return G.rng.rnd_arr(spawn_points)

func get_routes(pos, col):
	var r = []
	var count = 0
	for i in G.CARDINALS:
		var ty = pos.y + i[1]
		var tx = pos.x + i[0]
		if G.field.is_inbound(tx, ty) and !tiles[ty][tx].is_col(col):
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
