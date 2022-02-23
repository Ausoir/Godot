extends Node

const QUADRANT_FLIP = [[1, 0, 1, 0],[0, 1, 1, 0],[1, 0, 0, 1],[0, 1, 0, 1]]
const QUADRANT_ALL = [1, 1, 1, 1]

var processing_frame = -1
var view_range = 16
var sight_range = 7
var sight2 = 14
var sight_frame = 0
var param_last_pos
var param_pos

func _ready():
	set_process(false)

func _process(_delta):
	if processing_frame == -1:
		param_pos.sight_frame = sight_frame
		for i in range(8):
			cast_sight(param_pos, 1, 1.0, 0.0, G.OCTANT_FLIP[i], 0)
		processing_frame += 1
	elif processing_frame >= 0:
		process_vision(param_pos, QUADRANT_FLIP[processing_frame])
		processing_frame += 1
		if processing_frame == 4:
			var diffx = abs(param_last_pos.x - param_pos.x)
			var diffy = abs(param_last_pos.y - param_pos.y)
			if diffx > 1 or diffy > 1:
				process_vision(param_pos, QUADRANT_ALL)
			stop_process()

func process_vision(center, quad):
	for y in range(-sight2 * quad[0], sight2 * quad[1] + 1):
		for x in range(-sight2 * quad[2], sight2 * quad[3] + 1):
			var xx = center.x+x
			var yy = center.y+y
			var tile = G.field.get_tile(xx, yy)
			if tile:
				if tile.sight_frame == sight_frame:
					if tile.light >= 0:
						G.world.set_light(tile)
					elif (x > -sight_range and x < sight_range and y > -sight_range and y < sight_range):
						G.world.set_sight(tile)
					else:
						G.world.set_dark(tile)
				elif tile.sight_frame == sight_frame - 1:
					G.world.set_dark(tile)

func stop_process():
	sight_frame += 1
	processing_frame = -1

func get_affected_lights(pos):
	var r = []
	for i in G.world.lights:
		if pos.distance_to(i) <= i.light:
			r.append(i)
	return r

func set_sight(p):
	sight_range = int(p / 2)
	sight2 = p * 2

func update(last_pos, pos):
	param_last_pos = last_pos
	param_pos = pos

func cast_sight(camera, row, start, end, flips, depth):
	if start < end:
		return
	var new_start
	for cell in range(row, sight2 + 1):
		var dx = -cell - 1
		var dy = -cell
		var blocked = false
		while dx <= 0:
			dx += 1
			var start_slope = (dx - 0.5) / (dy + 0.5)
			var end_slope = (dx + 0.5) / (dy - 0.5)
			if start < end_slope:
				continue
			elif end > start_slope:
				break
			else:
				var tile_x = dx * flips[0] + dy * flips[1]
				var tile_y = dx * flips[2] + dy * flips[3]
				var map_x = camera.x + tile_x
				var map_y = camera.y + tile_y
				var tile = G.field.get_tile(map_x, map_y)
				if tile:
					if tile.light >= 0 or (abs(tile_x) <= sight_range and abs(tile_y) <= sight_range):
						tile.sight_frame = sight_frame
					if blocked:
						if tile.is_col(0):
							new_start = end_slope
						else:
							blocked = false
							start = new_start
					else:
						if tile.is_col(0) and cell < sight2:
							blocked = true
							cast_sight(camera, cell + 1, start, start_slope, flips, depth + 1)
							new_start = end_slope
		if blocked:
			break
