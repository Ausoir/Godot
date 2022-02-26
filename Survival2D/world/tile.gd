const COL_BITS = [1,2,4,8]

var item_type = "tile"
var x
var y
var world
var terrain
var items = []
var visible = false #Dont set to true, items will calculate lighting on creation
var dat
var col: int
var autotile = 0
var height: int
var orig_light: int
var light: int
var light_source = []
var slow = 0
var shade = -1
var sight_frame = 0

func _init(wld, px, py):
	world = wld
	x = px
	y = py

func to_pixel():
	return Vector2(x * G.W + G.HW, y * G.H + G.HH)

func to_vector():
	return Vector2(x, y)

func to_array():
	return [x, y]

func set_visible(p):
	if visible != p:
		if p:
			for item in items:
				item.show()
		else:
			for item in items:
				item.hide()
		visible = p
		return true
	return false

func set_terrain(val):
	var data = G.data.terrain_data.get(val)
	if data != null:
		terrain = val
		if "autotile" in data:
			autotile = data.autotile
		if data.get("ceiling") != null or !world.daytime:
			orig_light = -1
		else:
			orig_light = 0
		light = orig_light
		slow = data.get("slow", 0)
		var tile_image = world.tileset.find_tile_by_name(val)
		world.tilemap.set_cell(x, y, tile_image)
		dat = data
		dat.col = int(dat.col)
		col = dat.col
		height = data.height
	else:
		push_error("Could not find terrain data " + val)

func add_item(item):
	if item.get_parent() == null:
		world.items.add_child(item)
	items.append(item)
	item.set_z_index(y * 2 - 4000)
	item.pos = self
	update_tile()
	if item.light != 0:
		radiate(item.light)

func remove_item(item):
	if item.get_parent() == world.items:
		world.items.remove_child(item)
	items.erase(item)
	update_tile()
	if item.light != 0:
		radiate(-item.light)

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
		col = col | item.col
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
			var tile = world.get_tile(x+checks[i][0], y+checks[i][1])
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

func is_col(bit):
	return col & bit > 0

func is_col_adv(cols, opens, strength):
	if !opens and strength == 0:
		return is_col(cols)
	var tcol = dat.col
	for item in items:
		if opens and item.dat.g("openable"):
			continue
		var item_hp = item.dat.g("durability")
		if item_hp != null and item_hp <= strength:
			continue
		tcol = item.col | tcol
	return tcol & cols > 0

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

func get_adjacent(dir, val=1):
	if dir == -1:
		return self
	var t = G.DIRS[dir]
	var ry = y + t[1]*val
	var rx = x + t[0]*val
	if world.is_inbound(rx, ry):
		return world.tiles[ry][rx]
	return self

func distance_to(tile):
	return max(abs(x - tile.x), abs(y - tile.y))

func get_items_by_type(p):
	var r = []
	for i in items:
		if i.item_type == p:
			r.append(i)
	return r

func get_available_adjacents(cols):
	var r = []
	for i in range(8):
		var adj = get_adjacent(i)
		if !adj.is_col(cols):
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
	return x == 0 or x == world.size.x-1 or y == 0 or y == world.size.y-1

func get_rand_offset(_x, _y):
	var rx = R.ir(-_x, _x)
	var ry = R.ir(-_y, _y)
	return world.fit_bound(x + rx, y + ry)

func radiate(_light, new=true):
	light += _light
	if new:
		if light > 0:
			world.lights.append(self)
		else:
			world.lights.erase(self)
	for i in range(8):
		cast_sight(self, 1, 1.0, 0.0, G.OCTANT_FLIP[i], abs(_light), _light)

func cast_sight(camera, row, start, end, flips, sight2, intensity):
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
				var tile = world.get_tile(map_x, map_y)
				if tile:
					tile.light += intensity
					if blocked:
						if tile.is_col(1):
							new_start = end_slope
						else:
							blocked = false
							start = new_start
					else:
						if tile.is_col(1) and cell < sight2:
							blocked = true
							cast_sight(camera, cell + 1, start, start_slope, flips, sight2, intensity)
							new_start = end_slope
		if blocked:
			break
