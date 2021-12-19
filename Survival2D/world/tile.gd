var x
var y
var terrain
var items = []
var col: String
var light: int = 1
var shade: int = -1
var dark_shade = 0

func _init(px, py):
	x = px
	y = py

func to_pixel():
	return Vector2(x * G.W + G.HW, y * G.H + G.HH)

func to_vector():
	return Vector2(x, y)

func set_visible(p):
	if p:
		for item in items:
			item.show()
	else:
		for item in items:
			item.hide()

func set_terrain(val):
	var data = G.factory.data.terrain_data.get(val)
	if data:
		terrain = val
		var tile_image = G.world.tileset.find_tile_by_name(data.img)
		G.world.tilemap.set_cell(x, y, tile_image)
		col = data.col
	else:
		push_error("Could not find terrain data " + val)

func add_item(item):
	items.append(item)
	G.world.items.add_child(item)
	item.position = to_pixel()
	item.pos = self

func remove_item(item):
	if item in items:
		items.erase(item)
		G.world.items.remove_child(item)

func apply_shade():
	if col == "0000":
		var shades = "00000"
		var checks = [[-1,0],[-1,-1],[0,-1],[1,-1],[1,0]]
		for i in range(5):
			var tile = G.field.get_tile(x+checks[i][0], y+checks[i][1])
			if tile and tile.is_col(G.COL_SIGHT):
				shades[i] = "1"
		if shades[0] == "1" and shades[2] == "1" and shades[4] == "1":
			shade = 11
		elif shades[0] == "1" and shades[2] == "1":
			shade = 6
		elif shades[2] == "1" and shades[4] == "1":
			shade = 7
		elif shades[0] == "1" and shades[4] == "1":
			shade = 8
		elif shades[0] == "1" and shades[3] == "1":
			shade = 9
		elif shades[4] == "1" and shades[1] == "1":
			shade = 10
		elif shades[0] == "1":
			if shades[1] == "0":
				shade = 12
			else:
				shade = 1
		elif shades[2] == "1":
			shade = 3
		elif shades[4] == "1":
			if shades[1] == "0":
				shade = 13
			else:
				shade = 5
		elif shades[1] == "1":
			shade = 2
		elif shades[3] == "1":
			shade = 4
		else:
			shade = -1
			return
		shade += dark_shade

func update_shade():
	G.world.shademap.set_cell(x, y, -1)

func is_col(bit):
	return col[bit] == "1"

func get_item_by_name(val):
	for item in items:
		if item.item_name == val:
			return item
	return null

func direction_to(target):
	var tx = target.x - x
	var ty = target.y - y
	var dir
	var angle = atan2(ty, tx) + PI
	var octant = int(angle / .3927)
	if octant == 15 or octant == 0:
		dir = G.LEFT
	elif octant == 1 or octant == 2:
		dir = G.UPLEFT
	elif octant == 3 or octant == 4:
		dir = G.UP
	elif octant == 5 or octant == 6:
		dir = G.UPRIGHT
	elif octant == 7 or octant == 8:
		dir = G.RIGHT
	elif octant == 9 or octant == 10:
		dir = G.DOWNRIGHT
	elif octant == 11 or octant == 12:
		dir = G.DOWN
	elif octant == 13 or octant == 14:
		dir = G.DOWNLEFT
	return dir

func get_adjacent(dir, val=1):
	var t = G.CARDINALS[dir]
	var ry = y + t[1]*val
	var rx = x + t[0]*val
	if G.field.is_inbound(rx, ry):
		return G.field.tiles[ry][rx]
	return self

func distance_to(tile):
	return min(abs(x - tile.x), abs(y - tile.y))

func get_object():
	for i in items:
		if i.item_type == "object":
			return i
