extends Node


const Pathing = preload("res://objects/pathing.gd")
var unit
var sight_range = 8
var target
var tasks = []
var pathing

func on_dat():
	pathing.smash_to = unit.dat.g("strength", 0)
	if "mindless" in unit.flags:
		pathing.hinderance = 0
		pathing.pathing_times = 0
	elif "user" in unit.flags:
		pathing.can_open = true
		pathing.pathing_times = 3
		pathing.iterations = 24
	elif "float" in unit.flags:
		pathing.hinderance = 0
	elif "agile" in unit.flags:
		pathing.hinderance = .5
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
		unit.slide(task[1].to_pixel() - unit.position)
		return unit.pos == task[1]
	elif task[0] == "attack":
		if validate_target():
			unit.slide(task[1].position - unit.position)
			return false
	elif task[0] == "pave":
		if unit.pos.distance_to(task[1]) <= 1:
			if !interact(task[1]):
				perform(["smash", task[1]])
	elif task[0] == "interact":
		unit.delay = 4
		unit.set_animation("wait", 4)
		if unit.pos.distance_to(task[1].pos) <= 1:
			interact(task[1])
	elif task[0] == "ability":
		unit.ability(task[1], task[2])
	elif task[0] == "smash":
		if unit.pos.distance_to(task[1]) <= 1:
			for i in task[1].items:
				if i != unit:
					if i.item_type == "unit":
						target = i
						if validate_target():
							perform(["attack", i])
							return
			unit.face_toward(task[1])
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
				unit.set_state("wait")
				unit.delay = 4
				tasks.append(["enter", task[1], task[2], task[3]-1])
		else:
			unit.pos.remove_item(unit)
	return true

func validate_target():
	if target == null:
		return false
	elif !is_instance_valid(target):
		target = null
		return false
	return true

func path_to(pos, dist=0, destroy=false):
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
				tasks.append(["path", unit.pos.world.tiles[p.y][p.x]])
			if destroy and !tasks.empty():
				var latest_task = tasks[0]
				if latest_task[1].is_col(unit.col) and !latest_task[1].is_col_adv(unit.col, pathing.can_open, pathing.smash_to):
					tasks = [["pave", latest_task[1]]]
					return true

func interact(_tile):
	if !_tile.items.empty():
		var item = _tile.get_item_by_type("item")
		if item != null:
			var onuse = item.dat.g("onuse")
			if onuse != null:
				if pathing.can_open:
					G.cmd(onuse, item, unit)
					return true
			elif unit.dat.g("type") != "other":
				unit.store(item, true)
				item.pos.remove_item(item)
				return true
			else:
				item.remove()
				return true
	return false

func remove():
	queue_free()
