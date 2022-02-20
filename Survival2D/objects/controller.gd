extends Node


const Pathing = preload("res://objects/pathing.gd")
var unit
var sight_range = 8
var target
var tasks = []
var delay = 0
var pathing = Pathing.new()

func on_dat():
	pathing.smash_to = unit.dat.g("strength", 0)
	if "mindless" in unit.flags:
		pathing.hinderance = 0
	elif "user" in unit.flags:
		pathing.can_open = true
		pathing.pathing_times = 5
	elif "float" in unit.flags:
		pathing.hinderance = 0
	elif "agile" in unit.flags:
		pathing.hinderance = .5

func on_assign():
	unit.dirty_dat = true

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
		var task = tasks.pop_front()
		perform(task)

func perform(task):
	if task[0] == "move":
		target = task[1]
		unit.face_toward(target)
		unit.set_state("move")
	elif task[0] == "ability":
		unit.face_toward(target)
		unit.ability(task[1])
	elif task[0] == "attack":
		target = task[1]
		if validate_target():
			if target.item_type == "unit":
				target = target.pos
			unit.face_toward(target)
			unit.set_state("attack")
	elif task[0] == "pave":
		if unit.pos.distance_to(task[1]) <= 1:
			if !interact(task[1]):
				perform(["smash", task[1]])
	elif task[0] == "interact":
		if unit.pos.distance_to(task[1]) <= 1:
			interact(task[1])
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
			unit.set_animation("attack")
			var dmg = unit.get_damage("bash", 100)
			unit.delay = 5
			task[1].smash(dmg)
	elif task[0] == "enter":
		if task[1] == "exit":
			if self == G.you:
				if task[2] < 1:
					G.you.on_leave()
				else:
					var adjs = unit.pos.get_available_adjacents("1000")
					for tile in adjs:
						for i in tile.items:
							if i.item_type == "unit" and i.faction != unit.faction:
								return
					G.msg("Exiting map..." + str(task[2]))
					unit.set_state("wait")
					unit.delay = 8
					if unit.pos.is_edge():
						var focused = unit.buffs.has("focus")
						if !focused and task[2] == 3:
							tasks.append(["enter", "exit", task[2]-1])
							G.influence.do(unit, "focus")
							unit.buffs.extend("focus", 12)
						elif focused:
							tasks.append(["enter", "exit", task[2]-1])
							unit.buffs.extend("focus", 12)
			else:
				unit.pos.remove_item(unit)

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
				tasks.append(["move", G.field.tiles[p.y][p.x]])
			if destroy and !tasks.empty():
				var latest_task = tasks[0]
				if latest_task[1].is_cols(unit.col) and !latest_task[1].is_cols_adv(unit.col, pathing.can_open, pathing.smash_to):
					tasks = [["pave", latest_task[1]]]
					return true

func interact(_tile):
	if !_tile.items.empty():
		var item = _tile.get_priority_item([unit])
		if item != null:
			if item.item_type == "item":
				var onuse = item.dat.g("onuse")
				if onuse != null:
					if pathing.can_open:
						G.cmd(onuse, item)
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
