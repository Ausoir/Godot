extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var rng = RandomNumberGenerator.new()
# Called when the node enters the scene tree for the first time.
func _ready():
	rng.randomize()
	var tilemap = $Tilemap
	var objmap = $Objectmap
	var tile_set = load("res://tileset.tres")
	var obj_set = load("res://objectset.tres")
	var dirt = tile_set.find_tile_by_name("dirt")
	var grass = tile_set.find_tile_by_name("grass")
	var water = tile_set.find_tile_by_name("water")
	var bush = tile_set.find_tile_by_name("bush")
	var branch = obj_set.find_tile_by_name("rock")

	var sx = 50
	var sy = 50
	var map = make_perlin(sx, sy)
	for x in range(sx):
		for y in range(sy):
			if map[x][y] > 0.7:
				tilemap.set_cell(x, y, bush)
			elif map[x][y] > 0.5:
				tilemap.set_cell(x, y, grass)
			elif map[x][y] > 0.2:
				tilemap.set_cell(x, y, dirt)
			else:
				tilemap.set_cell(x, y, water)

	for x in range(sx):
		tilemap.set_cell(x, 0, bush)
		tilemap.set_cell(x, sx, bush)
	for y in range(sy):
		tilemap.set_cell(0, y, water)
		tilemap.set_cell(sy, y, water)

	tilemap.update_bitmask_region(Vector2(0, 0), Vector2(sx, sy))

	tilemap.update_dirty_quadrants()
	
	var unit = load("res://objects/ai.tscn").instance()
	unit.get_node("unit").position = Vector2(320, 320)
	$NPCs.add_child(unit)
	
	var object = load("res://objects/table.tscn").instance()
	object.position = Vector2(544, 288)
	$Objects.add_child(object)


func make_base(sx, sy):
	var base = []
	for x in range(sx):
		var row = []
		for y in range(sx):
			row.append(rng.randf())
		base.append(row)
	return base
	
func make_smooth(base, level):
	var w = len(base[0])
	var h = len(base)
	var map = []
	var period = 1 << level
	var frequency = 1.0 / period
	for x in range(w):
		var sample1 = int(x / period) * period
		var sample2 = int((sample1 + period) % h)
		var horizontal_blend = (x - sample1) * frequency
		var row = []
		for y in range(h):
			var sample3 = int(y / period) * period
			var sample4 = int((sample3 + period) % w)
			var vertical_blend = (y - sample3) * frequency
			var top = interpolate(base[sample1][sample3], base[sample2][sample3], horizontal_blend)
			var bot = interpolate(base[sample1][sample4], base[sample2][sample4], horizontal_blend)
			row.append(interpolate(top, bot, vertical_blend))
		map.append(row)
	return map
		
func interpolate(arg1, arg2, alpha):
	return arg1 * (1 - alpha) + alpha * arg2

func make_perlin(sx, sy):
	var base = make_base(sx, sy)
	var map = []
	for level in range(1, 3):
		var graph = make_smooth(base, level)
		for x in range(sx):
			var row = []
			for y in range(sy):
				row.append(graph[x][y] * 1/level)
			map.append(row)
	return map

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
