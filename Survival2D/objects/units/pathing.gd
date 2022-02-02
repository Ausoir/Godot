var cols = "0100"
var target
var iterations = 12
var open
var closed = []
var closest
var result
var next_reset = 0
var reach = 0
var hinderance = 1


class pathnode:
	var parent
	var pos
	var g = 0
	var h = 0
	var f = 0

	func _init(pparent, pnode):
		parent = pparent
		pos = pnode
		
	func set_h(destination):
		h = (pos - destination).length_squared()

func _init():
	result = []

func check_loop(loop, pos):
	for i in loop:
		if i.pos == pos:
			return i

func distance_to(pos, dest):
	return max(abs(pos.x - dest.x), abs(pos.y - dest.y))

func iterate(node):
	var index = 0
	for k in range(open.size()):
		var v = open[k]
		if v.f < node.f:
			index = k
			node = v
	open.remove(index)
	closed.append(node)
	var routes = G.field.get_routes(node.pos, cols)
	for route in routes:
		var dir_pos = G.DIRS[route]
		var pos = Vector2(node.pos.x + dir_pos[0], node.pos.y + dir_pos[1])
		var achieved = distance_to(pos, target)
		if achieved <= reach:
			var reached = pathnode.new(node, pos)
			open.append(reached)
			return reached
		if achieved < distance_to(closest.pos, target):
			closest = node
		var cost = G.field.tiles[pos.y][pos.x].slow * hinderance
		if check_loop(closed, pos):
			continue
		var conflict = check_loop(open, pos)
		if conflict:
			if node.g + 1 <= conflict.g:
				conflict.parent = node
				conflict.g = node.g + 1 + cost
				conflict.set_h(target)
				conflict.f = conflict.h + conflict.g
			continue
		var new = pathnode.new(node, pos)
		new.g = node.g + 1 + cost
		new.set_h(target)
		new.f = new.h + new.g
		open.append(new)
	return null


func reset(hostpos):
	open = [pathnode.new(null, hostpos)]
	closed = []
	closest = open[0]


func debug_trace():
	for draw in open:
		#print("debug trace: ", draw.pos * G.W)
		G.world.make_particle("smoke", Vector2(draw.pos.x * G.W + G.HW, draw.pos.y * G.H + G.HH))


func update(hostpos, p):
	target = p
	if not result and distance_to(hostpos, target) > reach:
		var done = null
		if next_reset == 0:
			reset(hostpos)
			next_reset = 1
		else:
			next_reset += 1
		for _i in range(iterations):
			if open:
				done = iterate(open[0])
				if done != null:
					break
			else:
				break
		#debug_trace()
		if not done:
			done = closest
		if done:
			next_reset = 0
			result = [done.pos]
			while done.parent:
				#G.world.make_particle("smoke", to_tile_pos(done.pos))
				done = done.parent
				if done.pos == hostpos:
					break
				result.insert(0, done.pos)
		return result
