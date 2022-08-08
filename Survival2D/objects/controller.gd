extends Node


const Pathing = preload("res://objects/pathing.gd")
const Firm = ["attack", "ability", "command"]
var unit
var sight_range = 8
var target
var tasks = []
var pathing
var interruptible = false

func on_change(p):
	if p == "dat":
		pathing.cols = unit.dat.g("cols", pathing.cols)
		if "user" in unit.flags:
			pathing.can_open = true
			pathing.pathing_times = 5
		elif "float" in unit.flags:
			pathing.hinderance = 0
		pathing.smash_to = unit.dat.g("strength", 0)

func on_assign():
	unit.dirty_dat = true
	pathing = Pathing.new(unit.pos.world)
	target = null

func on_hit(_hitter):
	pass

func on_kill(_victim):
	pass

func unassign(_dead=false):
	if unit != null:
		unit.controller = null
		unit = null

func on_turn():
	if !tasks.empty():
		var task = tasks[0]
		interruptible = !(task in Firm)
		if perform(task):
			tasks.pop_front()
	else:
		interruptible = true

func perform(task):
	if task[0] == "path":
		if task.size() > 2 and validate_target(target):
			var exc = [unit.n_collider, target.n_collider]
			if unit.n_collider.cast_ray(task[2], exc, unit.col).empty():
				unit.slide(task[2].x, task[2].y)
				return false
		unit.slide(task[1].position.x, task[1].position.y)
		if unit.n_collider.get_slide_count() > 0:
			if !unit.n_collider.cast_ray(task[1].position, [unit.n_collider], unit.col).empty():
				if !task[1].is_col_adv(unit.col, pathing.can_open, pathing.smash_to):
					if interact_tile(task[1]):
						return false
					return perform(["smash", task[1]])
				else:
					return true
		return (task[1].position - unit.position).length_squared() < 64
	elif task[0] == "move":
		unit.slide(unit.position.x+task[1], unit.position.y+task[2])
	elif task[0] == "moveto":
		unit.slide(task[1].x, task[1].y)
		return (task[1] - unit.position).length_squared() < task[2]
	elif task[0] == "attack":
		if validate_target(task[1]):
			unit.slide(task[1].position.x, task[1].position.y)
			return false
	elif task[0] == "interact":
		unit.delay = 4
		unit.set_animation("wait", 4)
		if task[1].item_type == "tile":
			if unit.pos.distance_to(task[1]) <= 1:
				interact_tile(task[1])
		elif unit.pos.distance_to(task[1].pos) <= 1:
			interact(task[1])
	elif task[0] == "ability":
		unit.ability(task[1], task[2])
	elif task[0] == "smash":
		if unit.pos.distance_to(task[1]) <= 1:
			unit.face_toward(task[1].position)
			unit.delay = 8
			unit.set_animation("strike", 8)
			var dmg = unit.get_damage("bash", 100)
			task[1].smash(dmg)
	elif task[0] == "command":
		G.cmds(task[1], task[2], task[3])
	return true

func validate_target(p):
	if p == null:
		return false
	elif !is_instance_valid(p):
		if p == target:
			target = null
		return false
	return true

func path_to(pos, dist=0):
	pathing.result = []
	pathing.reach = dist
	pathing.cols = unit.col
	var unitpos_vec = unit.pos.to_vector()
	var pos_vec = pos.to_vector()
	if unitpos_vec == pos_vec:
		tasks = []
	else:
		var path = pathing.update(unitpos_vec, pos_vec)
		if path:
			tasks = []
			for p in path:
				tasks.append(["path", unit.pos.world.tiles[p.y][p.x], pos.position])

func interact_tile(_tile):
	if !_tile.items.empty():
		var items = _tile.get_items_by_type("item")
		if !items.empty():
			for item in items:
				if interact(item):
					return true

func interact(item):
	var onuse = item.dat.g("oninteract")
	if onuse != null:
		if pathing.can_open:
			if unit == G.you.unit:
				G.cmds(onuse, item, unit)
			elif item.dat.g("openable"):
				G.cmds(onuse, item, unit)
				return true
	return false

func remove():
	queue_free()
