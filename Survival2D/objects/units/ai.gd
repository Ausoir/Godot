extends "res://objects/units/controller.gd"

var state = ""
var foe
var lead
var reach = 1
var turn_delay = 0
var think_delay = 0
var objectives
var timeout = 0

func on_turn():
	turn_delay += 1
	if turn_delay > 3:
		turn_delay = 0
		if foe == null:
			perceive()
		elif !is_instance_valid(foe):
			foe = null
		if !hunt():
			if !follow():
				think()
	.on_turn()

func set_state(_p):
	if state != _p:
		state = _p
		pathing.next_reset = 0

func think():
	think_delay += 1
	if think_delay > 3:
		think_delay = 0
		var social = unit.dat.g("social")
		if social == "lead":
			if unit.faction == 1:
				if objectives == null:
					var goal = unit.dat.g("goal", "loot")
					set_objectives(goal)
				else:
					if do_objective():
						objectives.pop_front()
						timeout = 0
					else:
						timeout += 1
						if timeout > 9:
							set_objectives("end")
			elif unit.faction == 2:
				path_to(unit.pos.get_rand_offset(16, 16), 1, true)
		elif social == "follow":
			var min_dist = unit.dat.g("perception", 8)
			var seen_allies = search(unit.faction, min_dist)
			for seen_ally in seen_allies:
				if seen_ally[0].dat.g("social", "") == "lead":
					lead = seen_ally[0]
					timeout = 0
					return
			timeout += 1
			if timeout > 9:
				set_objectives("end")

func perceive():
	var min_dist = unit.dat.g("perception", 8)
	var other_team
	if unit.faction == 1:
		other_team = 2
	else:
		other_team = 1
	var seen_units = search(other_team, min_dist)
	if !seen_units.empty():
		foe = seen_units[0][0]

func search(faction, _dist):
	var list = G.world.team[faction]
	var r = []
	for seen in list:
		if is_instance_valid(seen) and seen != unit:
			var dist = unit.pos.distance_to(seen.pos)
			if dist < _dist:
				var t = unit.pos.get_beam_to(seen.pos, unit.sight_col, _dist)
				if t != null and t == seen.pos:
					if seen.is_visible():
						r.append([seen, dist])
	return r

func hunt():
	if foe != null and is_instance_valid(foe):
		set_state("hunt")
		path_to(foe.pos, reach, true)
		tasks.append(["attack", foe])
		return true
	else:
		foe = null
		return false

func follow():
	if lead != null and is_instance_valid(lead):
		set_state("follow")
		path_to(lead.pos, 1)
		return true
	else:
		lead = null
		return false

func set_objectives(_goal):
	if _goal == "loot" and unit.dat.g("type") == "man":
		for _i in range(unit.inventory.size()):
			var item_count = G.world.items.get_child_count()-1
			if item_count < 1:
				return
			else:
				var item = G.world.items.get_child(R.ir(0, item_count))
				objectives = []
				objectives.append(["move", item.pos])
				objectives.append(["interact", item.pos])
	elif _goal == "end":
		var pos
		var dir = 0
		var dist_s = G.field.size.y - unit.pos.y
		var dist_e = G.field.size.x - unit.pos.x
		if dist_e < unit.pos.y:
			dir += 1
			if dist_s < dist_e:
				dir += 1
				if unit.pos.x < dist_s:
					dir += 1
		if dir == 0:
			pos = G.field.tiles[0][unit.pos.x]
		elif dir == 1:
			pos = G.field.tiles[unit.pos.y][G.field.size.x-1]
		elif dir == 2:
			pos = G.field.tiles[G.field.size.y-1][unit.pos.x]
		elif dir == 3:
			pos = G.field.tiles[unit.pos.y][0]
		objectives = [["moveon", pos], ["exit"]]

func do_objective():
	if !objectives.empty():
		var goal = objectives[0]
		set_state(goal[0])
		if goal[0] == "move":
			if unit.pos.distance_to(goal[1]) == 1:
				return true
			else:
				path_to(goal[1], 1, true)
		elif goal[0] == "moveon":
			if unit.pos.distance_to(goal[1]) == 0:
				return true
			else:
				path_to(goal[1], 0, true)
		elif goal[0] == "interact":
			tasks.append(["interact", goal[1]])
			return true
		elif goal[0] == "exit":
			tasks.append(["enter", "exit", 0])
			G.msg(unit.item_name + " has left the map.")
	return false
