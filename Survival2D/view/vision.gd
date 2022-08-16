extends Node

const QUADRANT_FLIP = [[1, 0, 1, 0],[0, 1, 1, 0],[1, 0, 0, 1],[0, 1, 0, 1]]
const QUADRANT_ALL = [1, 1, 1, 1]

var processing_frame: int
var sight_range = -1
var sight_range_y = -1
var sight_ratio = .75
var sight_frame = 0
var sight_bits = 1
var last_pos = G.void_tile
var pos = G.void_tile

func _process(_delta):
	if processing_frame == -1:
		pos.sight_frame = sight_frame
		for i in range(8):
			cast_sight(pos, 1, 1.0, 0.0, G.OCTANT_FLIP[i], 0)
		processing_frame += 1
	elif processing_frame == 4:
		var diffx = abs(last_pos.x - pos.x)
		var diffy = abs(last_pos.y - pos.y)
		if diffx > 1 or diffy > 1:
			process_vision(pos, QUADRANT_ALL)
		stop_process()
	elif processing_frame >= 0:
		process_vision(last_pos, QUADRANT_FLIP[processing_frame])
		processing_frame += 1

func darken():
	for y in range(-sight_range_y, sight_range_y+1):
		for x in range(-sight_range, sight_range+1):
			var xx = pos.x+x
			var yy = pos.y+y
			var tile = G.world.get_tile(xx, yy)
			if tile:
				G.world.set_dark(tile)

func update_z():
	for y in range(max(0, pos.y-sight_range_y), min(G.world.size.y-1, pos.y+sight_range_y+1)):
		for x in range(max(0, pos.x-sight_range), min(G.world.size.x-1, pos.x+sight_range+1)):
			var tile = G.world.tiles[y][x]
			if tile.visible:
				for item in tile.items:
					item.update_z()

func process_vision(center, quad):
	for y in range(-sight_range_y * quad[0], sight_range_y * quad[1] + 1):
		for x in range(-sight_range * quad[2], sight_range * quad[3] + 1):
			var xx = center.x+x
			var yy = center.y+y
			var tile = G.world.get_tile(xx, yy)
			if tile:
				if tile.sight_frame == sight_frame:
					G.world.set_light(tile)
				elif tile.sight_frame == sight_frame - 1:
					G.world.set_dark(tile)

func stop_process():
	sight_frame += 1
	processing_frame = -2

func set_sight(p, p_col=1):
	var new_sight_range = min(12, p)
	var new_sight_range_y = int(new_sight_range * sight_ratio)
	var new_sight_bits = p_col
	if new_sight_range != sight_range or new_sight_bits != sight_bits:
		darken()
		sight_range = new_sight_range
		sight_range_y = new_sight_range_y
		sight_bits = new_sight_bits
		return true

func update(p_last_pos, p_pos):
	if processing_frame != -2:
		for _i in range(processing_frame - 3):
			_process(0)
	last_pos = p_last_pos
	pos = p_pos
	processing_frame = -1

func cast_sight(camera, row, start, end, flips, depth):
	if start < end:
		return
	var new_start
	for cell in range(row, sight_range + 1):
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
				if abs(tile_y) < sight_range_y:
					var map_x = camera.x + tile_x
					var map_y = camera.y + tile_y
					var tile = G.world.get_tile(map_x, map_y)
					if tile:
						tile.sight_frame = sight_frame
						if blocked:
							if tile.is_col(sight_bits):
								new_start = end_slope
							else:
								blocked = false
								start = new_start
						else:
							if tile.is_col(sight_bits) and cell < sight_range:
								blocked = true
								cast_sight(camera, cell + 1, start, start_slope, flips, depth + 1)
								new_start = end_slope
		if blocked:
			break

func is_in_range(p_pos):
	return abs(p_pos.y-pos.y) <= sight_range_y and abs(p_pos.x-pos.x) <= sight_range
