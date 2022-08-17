var item_type = "tile"
var x
var y
var position
var world
var terrain
var items = []
var visible = true
var dat
var col: int
var autotile = 0
var height: int
var slow = 1
var shade = -1
var sight_frame = -1

func _init(wld, px, py):
	world = wld
	x = px
	y = py
	position = Vector2(x * G.W + G.HW, y * G.H + G.HH)

func to_vector():
	return Vector2(x, y)

func to_array():
	return [x, y]

func to_string():
	return str(x) + "," + str(y)

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
		slow = data.get("slow", 1)
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
	if item.layer < 0:
		items.insert(0, item)
	else:
		items.append(item)
	item.update_z()
	item.pos = self
	update_tile()
	if !visible:
		item.hide()

func remove_item(item):
	if item.get_parent() == world.items:
		world.items.remove_child(item)
	items.erase(item)
	update_tile()

func smash(_dmg, _type="true"):
	for item in items:
		if item.hit(_type, R.ir(0, _dmg), null):
			return true

func update_tile():
	var t = height
	col = dat.col
	height = dat.height
	slow = dat.get("slow", 1)
	for item in items:
		slow = max(0.2, slow - item.dat.g("slow", 0))
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
	if items.empty() or (!opens and strength <= 0):
		return is_col(cols)
	var tcol = dat.col
	for item in items:
		if opens and item.dat.g("openable"):
			continue
		var item_hp = item.dat.g("armor", 999)
		if item_hp > strength:
			tcol = item.col | tcol
	return tcol & cols > 0

func get_items_by_name(val):
	var r = []
	for item in items:
		if item.item_name == val:
			r.append(item)
	return r

func get_items_by_type(val, exc=null):
	var r = []
	for item in items:
		if item.item_type == val and item != exc:
			r.append(item)
	return r

func get_adjacent(dir, val=1):
	if dir == -1:
		return self
	var t = G.DIRS[dir]
	var ry = y + t.y*val
	var rx = x + t.x*val
	if world.is_inbound(rx, ry):
		return world.tiles[ry][rx]
	return self

func get_area(p):
	var r = []
	var xmin = max(0, x-p)
	var xmax = min(world.size.x-1, x+p+1)
	var ymin = max(0, y-p)
	var ymax = min(world.size.y-1, y+p+1)
	for iy in range(ymin, ymax):
		for ix in range(xmin, xmax):
			r.append(world.tiles[iy][ix])
	return r

func distance_to(tile):
	return max(abs(x - tile.x), abs(y - tile.y))

func get_available_adjacents(cols):
	var r = []
	for i in range(8):
		var adj = get_adjacent(i)
		if !adj.is_col(cols):
			r.append(adj)
	return r

func get_edge():
	if y == 0:
		return 0
	elif y == 2:
		return 2
	elif x == 0:
		return 3
	elif x == world.size.x-1:
		return 1
	return -1

func get_rand_offset(_x, _y):
	var rx = R.ir(-_x, _x)
	var ry = R.ir(-_y, _y)
	return world.fit_bound(x + rx, y + ry)

func get_beam_to(dest, col_mask, distance=-1):
	var diffx = dest.x - x
	var diffy = dest.y - y
	var step = max(abs(diffx), abs(diffy))
	var current = self
	var prev = self
	while current != dest and distance != 0:
		distance -= 1
		var tx = round(current.x + (diffx/step))
		var ty = round(current.y + (diffy/step))
		if world.is_inbound(tx, ty):
			current = world.tiles[ty][tx]
			if current.is_col(col_mask):
				break
		else:
			break
		prev = current
	return [prev, current]

func play_step_sound():
	G.sfx.play("step", position)
