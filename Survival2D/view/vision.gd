extends Node

const octant_flip = [[1, 0, 0, 1], [0, 1, 1, 0], [0, -1, 1, 0], [-1, 0, 0, 1], \
	[-1, 0, 0, -1], [0, -1, -1, 0], [0, 1, -1, 0], [1, 0, 0, -1]]
var view_range = 16
var sight_range = 22
var col_sight = G.COL_SIGHT
 
func update(last_pos, pos):
	for y in range(-sight_range, sight_range+1):
		for x in range(-sight_range, sight_range+1):
			var tile = G.field.get_tile(last_pos.x+x, last_pos.y+y)
			if tile:
				G.world.set_dark(last_pos.x+x, last_pos.y+y)
	G.world.set_light(pos.x, pos.y)
	for i in range(8):
		shadow_cast(pos, 1, 1.0, 0.0, octant_flip[i], 0)

func shadow_cast(camera, row, start, end, flips, depth):
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
					G.world.set_light(map_x, map_y)
					if blocked:
						if tile.is_col(col_sight):
							new_start = end_slope
							continue
						else:
							blocked = false
							start = new_start
					elif tile.is_col(col_sight) and cell < sight_range:
						blocked = true
						shadow_cast(camera, cell + 1, start, start_slope, flips, depth + 1)
						new_start = end_slope
		if blocked:
			break
