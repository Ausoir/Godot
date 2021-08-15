class_name Pathing


var world
var target
var chase = 11
var open
var closed = []
var closest
var result
var next_reset = 0
var heuristic_threshold = 0
var out_of_reach = false


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
		h = (pos - destination).length()


func _init(pworld):
	world = pworld
	result = []


func check_loop(loop, pos):
	for i in loop:
		if i.pos == pos:
			return i


func iterate(node):
	var index = 0
	for k in range(open.size()):
		var v = open[k]
		if v.f < node.f:
			index = k
			node = v
	open.remove(index)
	closed.append(node)
	var achieved = (node.pos - target).length()
	if achieved <= 1:
		return node
	if achieved < (closest.pos - target).length():
		closest = node
	var options = world.get_routes(node.pos)
	for i in options:
		var pos = Vector2(i[0], i[1])
		if check_loop(closed, pos):
			continue
		var conflict = check_loop(open, pos)
		if conflict:
			if node.g + 1 <= conflict.g:
				conflict.parent = node
				conflict.g = node.g + 1 + i[2]
				conflict.set_h(target)
				conflict.f = conflict.h + conflict.g
			continue
		var new = pathnode.new(node, pos)
		new.g = node.g + 1 + i[2]
		new.set_h(target)
		new.f = new.h + new.g
		#if new.h < heuristic_threshold:
		open.append(new)
	return null


func reset(hostpos):
	heuristic_threshold = (hostpos - target).length() * 2 + 4
	open = [pathnode.new(null, hostpos)]
	closed = []
	closest = open[0]


func debug_trace():
	for draw in open:
		#print("debug trace: ", draw.pos * 64)
		world.make_particle("smoke", draw.pos * 64 + Vector2(32, 32))


func to_tile_coord(vec):
	return (vec / 64).floor()


func update(hostposv, targetv):	
	target = to_tile_coord(targetv)
	var hostpos = to_tile_coord(hostposv)
	if not result and (hostpos - target).length() > 1:
		var done = null
		if next_reset == 0:
			reset(hostpos)
			next_reset = 1
		else:
			next_reset += 1
		for _i in range(15):
			if open:
				done = iterate(open[0])
				if done != null:
					break
			else:
				break
		debug_trace()
		if not done and next_reset > chase:
			out_of_reach = true
			done = closest
		if done:
			next_reset = 0
			result = [done.pos]
			while done.parent:
				done = done.parent
				if done.pos == hostpos:
					break
				result.insert(0, done.pos)
		return result
