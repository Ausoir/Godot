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
	for y in range(sy+1):
		var row = []
		for x in range(sx+1):
			row.append(Tile.new(x, y))
		r.append(row)
	tiles = r

func set_terrain(x, y, val):
	tiles[y][x].set_terrain(val)
	var tile_image = G.world.tileset.find_tile_by_name(val)
	G.world.tilemap.set_cell(x, y, tile_image)

func add_item(x, y, val):
	tiles[y][x].items.append(val)

func get_spawn_point():
	return G.rng.rand_arr(spawn_points)

func is_inbound(x, y):
	return x > 0 and x < G.field.size.x and y > 0 and y < G.field.size.y

func get_routes(pos):
	var r = []
	for i in G.CARDINALS:
		var ty = pos.y + i[1]
		var tx = pos.x + i[0]
		if G.field.is_inbound(tx, ty) and tiles[ty][tx].is_passable():
			r.append([tx, ty, 0])
	return r

func set_sound(pos, radius):
	for x in range(-radius, radius):
		for y in range(-radius, radius):
			var tx = pos.x + x
			var ty = pos.y + y
			if tx >= 0 and tx < len(sound[0]):
				if ty >= 0 and ty < len(sound):
					G.field.sound[pos.y + y][pos.x + x] = 1
