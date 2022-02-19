extends Node

const octant_flip = [[1, 0, 0, 1], [0, 1, 1, 0], [0, -1, 1, 0], [-1, 0, 0, 1], \
	[-1, 0, 0, -1], [0, -1, -1, 0], [0, 1, -1, 0], [1, 0, 0, -1]]

var processing_frame = 0
var view_range = 16
var sight_range = 7
var sight2 = 14
var col_sight = G.COL_SIGHT
var sight_frame = 0
var param_last_pos
var param_pos

func _process(_delta):
	if processing_frame == 1:
		param_pos.sight_frame = sight_frame
		sight2 = sight_range * 2
		for i in range(8):
			cast_sight(param_pos, 1, 1.0, 0.0, octant_flip[i], 0)
		processing_frame = 2
	elif processing_frame == 2:
		for y in range(-sight2, sight2+1):
			for x in range(-sight2, sight2+1):
				var xx = param_last_pos.x+x
				var yy = param_last_pos.y+y
				var tile = G.field.get_tile(xx, yy)
				if tile:
					if tile.sight_frame == sight_frame:
						if tile.light >= 0 or (x > -sight_range and x < sight_range and y > -sight_range and y < sight_range):
							G.world.set_light(xx, yy)
					elif tile.sight_frame == sight_frame - 1:
						G.world.set_dark(xx, yy)
		var diffx = abs(param_last_pos.x - param_pos.x)
		var diffy = abs(param_last_pos.y - param_pos.y)
		if diffx > 1 or diffy > 1:
			processing_frame = 3
		else:
			stop_process()
	elif processing_frame == 3:
		for y in range(-sight2, sight2+1):
			for x in range(-sight2, sight2+1):
				var xx = param_pos.x+x
				var yy = param_pos.y+y
				var tile = G.field.get_tile(xx, yy)
				if tile:
					if tile.sight_frame == sight_frame:
						if tile.light >= 0 or (x > -sight_range and x < sight_range and y > -sight_range and y < sight_range):
							G.world.set_light(xx, yy)
					elif tile.sight_frame == sight_frame - 1:
						G.world.set_dark(xx, yy)
		stop_process()

func stop_process():
	sight_frame += 1
	processing_frame = 0
	set_process(false)

func darken():
	for y in range(-sight2, sight2+1):
		for x in range(-sight2, sight2+1):
			var tile = G.field.get_tile(param_pos.x+x, param_pos.y+y)
			if tile:
				G.world.set_dark(param_pos.x+x, param_pos.y+y)

func update(last_pos, pos, sight_col):
	param_last_pos = last_pos
	param_pos = pos
	set_process(true)
	processing_frame = 1
	col_sight = sight_col

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
#					if abs(tile_x) <= view_range.x and abs(tile_y) <= view_range.y:
					tile.sight_frame = sight_frame
					if blocked:
						if tile.is_cols(col_sight):
							new_start = end_slope
						else:
							blocked = false
							start = new_start
					else:
						if tile.is_cols(col_sight) and cell < sight2:
							blocked = true
							cast_sight(camera, cell + 1, start, start_slope, flips, depth + 1)
							new_start = end_slope
		if blocked:
			break
