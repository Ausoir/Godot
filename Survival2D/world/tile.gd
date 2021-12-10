const W = 64
const H = 64
const HW = 32
const HH = 32
var x
var y
var terrain
var items = []
var passable

func _init(px, py):
	x = px
	y = py

func to_pixel():
	return Vector2(x * W + HW, y * H + HH)

func to_vector():
	return Vector2(x, y)

func set_terrain(val):
	terrain = val
	passable = val

func is_passable():
	return true

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
	var tx = 0
	var ty = 0
	if dir == G.RIGHT:
		tx = 1
	elif dir == G.DOWNRIGHT:
		tx = 1
		ty = 1
	elif dir == G.DOWN:
		ty = 1
	elif dir == G.DOWNLEFT:
		tx = -1
		ty = 1
	elif dir == G.LEFT:
		tx = -1
	elif dir == G.UPLEFT:
		tx = -1
		ty = -1
	elif dir == G.UP:
		ty = -1
	elif dir == G.UPRIGHT:
		tx = 1
		ty = -1
	var ry = y + ty*val
	var rx = x + tx*val
	if G.field.is_inbound(rx, ry):
		return G.field.tiles[ry][rx]
	return self
