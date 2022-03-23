extends Node


const Pathing = preload("res://objects/pathing.gd")
var unit
var sight_range = 8
var target
var tasks = []
var pathing

func update_dat(p):
	if p == "":
		pathing.smash_to = unit.dat.g("strength", 0)
		if "user" in unit.flags:
			pathing.can_open = true
			pathing.pathing_times = 5
		elif "float" in unit.flags:
			pathing.hinderance = 0
		elif "agile" in unit.flags:
			pathing.hinderance = .5
	elif p == "col":
		pathing.cols = unit.dat.g("cols", pathing.cols)

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
		if perform(task):
			tasks.pop_front()

func perform(task):
	if task[0] == "path":
		if task.size() > 2 and validate_target(target):
			var exc = [unit.n_collider, target.n_collider]
			if unit.n_collider.cast_col_ray(task[2], exc, unit.col).empty():
				unit.slide(task[2] - unit.position)
				return false
		var diff = task[1].to_pixel() - unit.position
		unit.slide(diff)
		if unit.n_collider.get_slide_count() > 0:
			if !task[1].is_col_adv(unit.col, pathing.can_open, pathing.smash_to):
				if interact(task[1]):
					return false
				return perform(["smash", task[1]])
		return diff.length_squared() < 16
	elif task[0] == "attack":
		if validate_target(task[1]):
			unit.slide(task[1].position - unit.position)
			return false
	elif task[0] == "interact":
		unit.delay = 4
		unit.set_animation("wait", 4)
		if unit.pos.distance_to(task[1].pos) <= 1:
			interact(task[1])
	elif task[0] == "ability":
		unit.ability(task[1], task[2])
	elif task[0] == "smash":
		if unit.pos.distance_to(task[1]) <= 1:
			unit.face_toward(task[1].to_pixel())
			unit.delay = 5
			unit.set_animation("attack", 5)
			var dmg = unit.get_damage("bash", 100)
			task[1].smash(dmg)
	elif task[0] == "enter":
		if self == G.you:
			if task[3] < 1:
				if task[1] in unit.pos.world.connections:
					G.you.unit.reposition(task[2].to_pixel())
					G.travel(unit.pos.world.connections[task[1]])
			else:
				var adjs = unit.pos.get_available_adjacents(1)
				for tile in adjs:
					for i in tile.items:
						if i.item_type == "unit" and i.faction != unit.faction:
							return
				G.msg("Moving map..." + str(task[3]))
				unit.set_animation("wait")
				unit.delay = 4
				tasks.append(["enter", task[1], task[2], task[3]-1])
		else:
			unit.pos.remove_item(unit)
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
				tasks.append(["path", unit.pos.world.tiles[p.y][p.x], pos.to_pixel()])

func interact(_tile):
	if !_tile.items.empty():
		var item = _tile.get_item_by_type("item")
		if item != null:
			var onuse = item.dat.g("onuse")
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
