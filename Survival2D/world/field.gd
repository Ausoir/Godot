extends Node

var size
var terrain
var sound
var light
var tiles
var spawn_points

func create_map(sx, sy):
	var Tile = preload("res://world/tile.gd")
	size = Vector2(sx, sy)
	var r = []
	for _y in range(sy+1):
		var row = []
		for _x in range(sx+1):
			row.append(Tile.new())
		r.append(row)
	tiles = r

func set_terrain(x, y, val):
	tiles[y][x].set_terrain(val)
	var tile_image = G.world.tileset.find_tile_by_name(val)
	G.world.tilemap.set_cell(x, y, tile_image)

func add_item(x, y, val):
	tiles[y][x].items.append(val)

func get_spawn_point():
	for y in range(size.y):
		for x in range(size.x):
			if tiles[y][x].get_item('@') != null:
				return Vector2(x, y)

func get_routes(pos):
	var r = []
	for i in [[pos.x-1, pos.y], [pos.x+1, pos.y], [pos.x, pos.y-1], [pos.x, pos.y+1]]:
		if tiles[i[1]][i[0]].passable():
			r.append([i[0], i[1], 0])
	return r

func set_sound(pos, radius):
	for x in range(-radius, radius):
		for y in range(-radius, radius):
			var tx = pos.x + x
			var ty = pos.y + y
			if tx >= 0 and tx < len(sound[0]):
				if ty >= 0 and ty < len(sound):
					G.field.sound[pos.y + y][pos.x + x] = 1
