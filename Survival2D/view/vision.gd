extends Node

const octant_flip = [[1, 0, 0, 1], [0, 1, 1, 0], [0, -1, 1, 0], [-1, 0, 0, 1], \
	[-1, 0, 0, -1], [0, -1, -1, 0], [0, 1, -1, 0], [1, 0, 0, -1]]

var processing_frame = 0
var view_range = 16
var sight_range = 18
var col_sight = G.COL_SIGHT
var sight_frame = 0
var param_last_pos
var param_pos

func g_event():
	if processing_frame == 1:
		param_pos.sight_frame = sight_frame
		for i in range(8):
			cast_sight(param_pos, 1, 1.0, 0.0, octant_flip[i], 0)
		processing_frame = 2
		G.events.append(funcref(self, "g_event"))
	elif processing_frame == 2:
		for y in range(-sight_range, sight_range+1):
			for x in range(-sight_range, sight_range+1):
				var tile = G.field.get_tile(param_last_pos.x+x, param_last_pos.y+y)
				if tile:
					if tile.sight_frame == sight_frame:
						G.world.set_light(param_last_pos.x+x, param_last_pos.y+y)
					elif tile.sight_frame == sight_frame - 1:
						G.world.set_dark(param_last_pos.x+x, param_last_pos.y+y)
		sight_frame += 1
		processing_frame = 0

func update(last_pos, pos):
	param_last_pos = last_pos
	param_pos = pos
	processing_frame = 1
	G.events.append(funcref(self, "g_event"))

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
				var map_x = camera.x + tile_x
				var map_y = camera.y + tile_y
				var tile = G.field.get_tile(map_x, map_y)
				if tile:
#					if abs(tile_x) <= view_range.x and abs(tile_y) <= view_range.y:
					tile.sight_frame = sight_frame
					if blocked:
						if tile.is_col(col_sight):
							new_start = end_slope
						else:
							blocked = false
							start = new_start
					else:
						if tile.is_col(col_sight) and cell < sight_range:
							blocked = true
							cast_sight(camera, cell + 1, start, start_slope, flips, depth + 1)
							new_start = end_slope
		if blocked:
			break
