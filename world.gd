extends Node2D

var item = preload("res://objects/item.tscn")
var object = preload("res://objects/object.tscn")
var ai = preload("res://objects/ai.tscn")
var tile_set = preload("res://data/tileset.tres")
var dirt = tile_set.find_tile_by_name("dirt")
var field = tile_set.find_tile_by_name("field")

var rng = RandomNumberGenerator.new()
var map_size = Vector2(0, 0)

# Called when the node enters the scene tree for the first time.
func _ready():
	rng.randomize()
	var tilemap = $tilemap
	var water = tile_set.find_tile_by_name("water")
	var bush = tile_set.find_tile_by_name("bush")

	map_size = Vector2(rng.randi_range(40, 80), rng.randi_range(40, 80))
	var map = make_perlin(map_size.x, map_size.y)
	var map_type = rng.randi_range(1, 3)
	map_type = 2
	if map_type == 1:
		map = radialize(map)
	elif map_type == 2:
		map = divide(map, rng.randi_range(1, 3))
	var reverse_tile = rng.randi_range(1, 2)

	for x in range(map_size.x):
		for y in range(map_size.y):
			var value = map[y][x]
			if reverse_tile == 2:
				value = 1 - value
			if value > 0.7:
				tilemap.set_cell(x, y, bush, false, false)
				tilemap.set_collision_layer_bit(1, false)
			elif value > 0.69:
				tilemap.set_cell(x, y, field)
				make_object("stone", get_tile_pos(x, y))
			elif value > 0.5:
				tilemap.set_cell(x, y, field)
			elif value > 0.4:
				tilemap.set_cell(x, y, dirt)
			elif value > 0.3:
				tilemap.set_cell(x, y, field)
			elif value > 0.29:
				tilemap.set_cell(x, y, field)
				make_item("wood", get_tile_pos(x, y))
			else:
				tilemap.set_cell(x, y, water)

	var border = bush
	if reverse_tile == 2:
		border = water
	for x in range(map_size.x):
		tilemap.set_cell(x, 0, border)
		tilemap.set_cell(x, 1, border)
		tilemap.set_cell(x, map_size.y - 1, border)
		tilemap.set_cell(x, map_size.y, border)
	for y in range(map_size.y):
		tilemap.set_cell(0, y, border)
		tilemap.set_cell(1, y, border)
		tilemap.set_cell(map_size.x, y, border)
		tilemap.set_cell(map_size.x + 1, y, border)

	tilemap.update_bitmask_region(Vector2(0, 0), Vector2(map_size.x, map_size.y))

	tilemap.update_dirty_quadrants()
	#make_unit("", pos * 64 + Vector2(32, 32))


func get_tile_pos(x, y):
	return Vector2(x * 64 + 32, y * 64 + 32)


func get_routes(pos):
	var r = []
	var tilemap = $tilemap
	for i in [[pos.x-1, pos.y], [pos.x+1, pos.y], [pos.x, pos.y-1], [pos.x, pos.y+1]]:
		if tilemap.get_cell(i[0], i[1]) in [dirt, field]:
			r.append([i[0], i[1], 0])
	return r


func make_particle(arg, pos):
	var r = load("res://objects/particles/" + arg + ".tscn").instance()
	r.position = pos
	$Particles.add_child(r)
	return r


func make_object(sprite, pos):
	var r = object.instance()
	r.make(sprite, pos)
	$Objects.add_child(r)
	return r


func make_item(sprite, pos):
	var newitem = item.instance()
	newitem.make(sprite, pos)
	$Objects.add_child(newitem)
	return newitem


func make_unit(_arg, pos):
	var unit = ai.instance()
	unit.get_node("unit").position = pos
	$NPCs.add_child(unit)


func get_spawn_point():
	var viable = false
	var pos
	while not viable:
		pos = Vector2(rng.randi_range(1, map_size.x-1), rng.randi_range(1, map_size.y-1))
		viable = $tilemap.get_cell(pos.x, pos.y) == tile_set.find_tile_by_name("dirt")
	return pos * 64 + Vector2(32, 32)


func make_base(sx, sy):
	var base = []
	for _y in range(sy):
		var row = []
		for _x in range(sx):
			row.append(0)
		base.append(row)
	return base


func make_random(sx, sy):
	var base = []
	for _y in range(sy):
		var row = []
		for _x in range(sx):
			row.append(rng.randf())
		base.append(row)
	return base


func make_smooth(base, level):
	var w = len(base[0])
	var h = len(base)
	var map = []
	var period = 2 << level
	var frequency = 1.0 / period
	for y in range(h):
		var sample1 = int(y / period) * period
		var sample2 = int((sample1 + period) % h)
		var horizontal_blend = (y - sample1) * frequency
		var row = []
		for x in range(w):
			var sample3 = int(x / period) * period
			var sample4 = int((sample3 + period) % w)
			var vertical_blend = (x - sample3) * frequency
			var top = interpolate(base[sample1][sample3], base[sample2][sample3], horizontal_blend)
			var bot = interpolate(base[sample1][sample4], base[sample2][sample4], horizontal_blend)
			row.append(interpolate(top, bot, vertical_blend))
		map.append(row)
	return map
		
func interpolate(arg1, arg2, alpha):
	return arg1 * (1 - alpha) + alpha * arg2

func make_perlin(sx, sy):
	var base = make_random(sx, sy)
	var map = make_base(sx, sy)
	for level in range(1, 4):
		var graph = make_smooth(base, level)
		for y in range(sy):
			for x in range(sx):
				map[y][x] += graph[y][x] * 1/level
	return map

func radialize(base):
	var width = len(base[0])
	var height = len(base)
	var center_x = int(width / 2)
	var center_y = int(height / 2)
	for i in range(height):
		for j in range(width):
			var val = pow(float(i - center_y) / center_y, 2)
			val += pow(float(j - center_x) / center_x, 2)
			val = sqrt(val)
			base[i][j] *= val
	return base

func divide(base, type):
	var width = len(base[0])
	var height = len(base)
	var center_x = int(width / 2)
	var center_y = int(height / 2)
	for i in range(height):
		for j in range(width):
			var val = 1
			if type == 1:
				val = float(i - center_y) / center_y
			elif type == 2:
				val = float(j - center_x) / center_x
			elif type == 3:
				val = float(i - center_y) / center_y
				val = val + float(j - center_x) / center_x
				val = val / 2
			val = (abs(val) + 1.2) / 2
			base[i][j] *= val
	return base
