var item_type = "tile"
var x
var y
var terrain
var items = []
var visible = true
var dat
var col: String
var autotile = 0
var height: int
var light: int
var slow = 0
var shade = -1
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
	if data != null:
		terrain = val
		if "autotile" in data:
			autotile = data.autotile
		if data.get("ceiling") != null or !G.world.daytime:
			light = -1
		else:
			light = 0
		slow = data.get("slow", 0)
		var tile_image = G.world.tileset.find_tile_by_name(val)
		G.world.tilemap.set_cell(x, y, tile_image)
		dat = data
		col = data.col
		height = data.height
	else:
		push_error("Could not find terrain data " + val)

func add_item(item):
	if item.get_parent() == null:
		G.world.items.add_child(item)
	items.append(item)
	item.set_z_index(y * 2 - 4000)
	item.pos = self
	update_tile()
	if item.light != 0:
		radiate(item.light)

func remove_item(item):
	if item.get_parent() == G.world.items:
		G.world.items.remove_child(item)
	items.erase(item)
	update_tile()
	if item.light != 0:
		radiate(-item.light)

func radiate(_light):
	if _light > 1:
		for i in range(4):
			var adj = get_adjacent(i * 2)
			if !adj.is_col(0):
				adj.radiate(_light - 1)
	elif _light < -1:
		for i in range(4):
			var adj = get_adjacent(i * 2)
			if !adj.is_col(0):
				adj.radiate(_light + 1)
	light += _light
	if visible:
		G.world.update_light(x, y)

func smash(_dmg):
	G.make_particle("Hit", to_pixel())
	G.display_damage(to_pixel(), round(_dmg))
	for item in items:
		var durability = item.dat.g("durability", 999)
		if durability < _dmg:
			item.die()

func update_tile():
	var t = height
	col = dat.col
	height = dat.height
	slow = dat.get("slow", 0)
	for item in items:
		slow += item.dat.g("slow", 0)
		for i in range(4):
			if item.col[i] == "1":
				col[i] = "1"
		var item_height = item.dat.g("height")
		if item_height != null:
			height = int(max(height, item_height))
	if height != t:
		apply_shade()
		for i in range(8):
			get_adjacent(i).apply_shade()

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
	else:
		shade = -1

func apply_shade_from_dir(shades):
	if shades[0] == "1" and shades[2] == "1" and shades[4] == "1":
		shade = 21
	elif shades[0] == "1" and shades[2] == "1":
		shade = 16
	elif shades[2] == "1" and shades[4] == "1":
		shade = 17
	elif shades[0] == "1" and shades[4] == "1":
		shade = 18
	elif shades[0] == "1" and shades[3] == "1":
		shade = 19
	elif shades[4] == "1" and shades[1] == "1":
		shade = 20
	elif shades[1] == "1" and shades[2] == "0" and shades[3] == "1":
		shade = 24
	elif shades[0] == "1":
		if shades[1] == "0":
			shade = 22
		else:
			shade = 11
	elif shades[2] == "1":
		shade = 13
	elif shades[4] == "1":
		if shades[3] == "0":
			shade = 23
		else:
			shade = 15
	elif shades[1] == "1":
		shade = 12
	elif shades[3] == "1":
		shade = 14
	else:
		shade = -1
		return

func update_shade():
	G.world.shademap.set_cell(x, y, -1)

func is_col(bit):
	return col[bit] == "1"

func is_cols(cols):
	for i in range(4):
		if cols[i] == "1" and col[i] == "1":
			return true
	return false

func is_cols_adv(cols, opens, strength):
	if !opens and strength == 0:
		return is_cols(cols)
	var tcol = dat.col
	for item in items:
		if opens and item.dat.g("openable"):
			continue
		var item_hp = item.dat.g("durability")
		if item_hp != null and item_hp <= strength:
			continue
		for i in range(4):
			if item.col[i] == "1":
				tcol[i] = "1"
	for i in range(4):
		if tcol[i] == "1" and cols[i] == "1":
			return true
	return false

func get_item_by_name(val):
	for item in items:
		if item.item_name == val:
			return item
	return null

func get_item_by_type(val):
	for item in items:
		if item.item_type == val:
			return item
	return null

func direction_to(target, mult = 1):
	var tx = target.x - x * mult
	var ty = target.y - y * mult
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
	if dir == -1:
		return self
	var t = G.DIRS[dir]
	var ry = y + t[1]*val
	var rx = x + t[0]*val
	if G.field.is_inbound(rx, ry):
		return G.field.tiles[ry][rx]
	return self

func distance_to(tile):
	return max(abs(x - tile.x), abs(y - tile.y))

func get_items_by_type(p):
	var r = []
	for i in items:
		if i.item_type == p:
			r.append(i)
	return r

func get_beam_to(destination, col_masks, distance):
#	var degree = atan2(destination.y - y, destination.x - x)
	var current = to_vector()
	var current_tile = self
	var dist = Vector2(destination.x - current.x, destination.y - current.y)
	var diff = dist.normalized()
	while current_tile != destination and distance_to(current) < distance:
		current.x += diff.x
		current.y += diff.y
		current_tile = G.field.get_tile(round(current.x), round(current.y))
		if current_tile.is_cols(col_masks):
			break
	return current_tile

func get_available_adjacents(cols):
	var r = []
	for i in range(8):
		var adj = get_adjacent(i)
		if !adj.is_cols(cols):
			r.append(adj)
	return r

func get_priority_item(exc):
	var low
	for item in items:
		if !(item in exc):
			if item.item_type == "unit":
				return item
			elif item.item_type == "item":
				low = item
	return low

func is_edge():
	return x == 0 or x == G.field.size.x-1 or y == 0 or y == G.field.size.y-1

func get_rand_offset(_x, _y):
	var rx = R.ir(-_x, _x)
	var ry = R.ir(-_y, _y)
	return G.field.fit_bound(x + rx, y + ry)
