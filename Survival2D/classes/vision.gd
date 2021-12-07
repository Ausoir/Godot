extends Node

const octant_flip = [[1, 0, 0, 1], [0, 1, 1, 0], [0, -1, 1, 0], [-1, 0, 0, 1], \
	[-1, 0, 0, -1], [0, -1, -1, 0], [0, 1, -1, 0], [1, 0, 0, -1]]


func update_fog():
	self.sight_frame += 1
	center = Global.world.location.get_tile(Camera.target.pos.x, Camera.target.pos.y)
	for i in range(8):
		self.shadow_cast(Camera.target.pos, 1, 1.0, 0.0, self.octant_flip[i], 0)
	center.sight_frame = self.sight_frame

func shadow_cast(camera, row, start, end, flips, depth):
	if start < end:
		return
	for cell in range(row, self.sight_range + 1):
		var dx = -cell - 1
		var dy = -cell
		blocked = false
		while dx <= 0:
			dx += 1
			var start_slope = (dx - 0.5) / (dy + 0.5)
			var end_slope = (dx + 0.5) / (dy - 0.5)
			if start < end_slope:
				continue
			elif end > start_slope:
				break
			else:
				tile_x = dx * flips[0] + dy * flips[1]
				tile_y = dx * flips[2] + dy * flips[3]
				map_x = camera.x + tile_x
				map_y = camera.y + tile_y
				tile = Global.world.location.get_tile(map_x, map_y)
				if tile:
					if abs(dx) < self.sight_range + 1 and abs(dy) < self.sight_range + 1:
						in_view_range = abs(tile_x) <= self.view_range and abs(tile_y) <= self.view_range_y
						if in_view_range or (tile.light and abs(tile_x) <= self.sight_range
												and abs(tile_y) <= self.sight_range_y):
							tile.sight_frame = self.sight_frame
					if blocked:
						if tile.is_land(Global.player.character.sight):
							self.new_start = end_slope
							continue
						else:
							blocked = False
							start = self.new_start
					elif tile.is_land(Global.player.character.sight) and cell < self.sight_range:
						blocked = True
						self.shadow_cast(camera, cell + 1, start, start_slope, flips, depth + 1)
						self.new_start = end_slope
		if blocked:
			break
