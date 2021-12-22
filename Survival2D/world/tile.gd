var x
var y
var terrain
var items = []
var visible = true
var col: String
var light: int = 0
var shade: int = -1
var height: int
var sight_frame = 0

func _init(px, py):
	x = px
	y = py

func to_pixel():
	return Vector2(x * G.W + G.HW, y * G.H + G.HH)

func to_vector():
	return Vector2(x, y)

func set_visible(p):
	if visible != p:
		if p:
			for item in items:
				item.show()
		else:
			for item in items:
				item.hide()
		visible = p

func set_terrain(val):
	var data = G.data.terrain_data.get(val)
	if data:
		terrain = val
		var img = val
		if "rnd" in data:
			img = val + str(G.rng.randi_range(1, data.rnd))
		var tile_image = G.world.tileset.find_tile_by_name(img)
		G.world.tilemap.set_cell(x, y, tile_image)
		col = data.col
		height = data.height
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
	if height < 1:
		var shades = "00000"
		var checks = [[-1,0],[-1,-1],[0,-1],[1,-1],[1,0]]
		for i in range(5):
			var tile = G.field.get_tile(x+checks[i][0], y+checks[i][1])
			if tile:
				if tile.height > height:
					shades[i] = "1"
				apply_shade_from_dir(shades)

func apply_shade_from_dir(shades):
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
	elif shades[1] == "1" and shades[2] == "0" and shades[3] == "1":
		shade = 14
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
	if tx == 0 and ty == 0:
		return -1
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
	return max(abs(x - tile.x), abs(y - tile.y))

func get_object():
	for i in items:
		if i.item_type == "object":
			return i
