extends "res://objects/controller.gd"

var reach = 1
var turn_delay = 0

func on_hit(_hitter):
	if _hitter != null and _hitter.dat.g("faction", -1) != unit.dat.g("faction", -1):
		target = _hitter

func on_turn():
	turn_delay += 1
	if turn_delay > 3:
		turn_delay = 0
		if target == null:
			perceive()
		if !hunt():
			think()
	.on_turn()

func think():
	if tasks.empty():
		var goal = unit.dat.g("goal", "")
		if goal == "wander":
			path_to(unit.pos.get_rand_offset(12, 12), 0)
		elif goal == "kill":
			target = G.you.unit
		elif goal == "sabotage":
			var sabo = G.temp.machines
			if !sabo.empty():
				var machine = R.r_arr(sabo)
				if machine == null or !is_instance_valid(machine):
					G.temp.machines.erase(machine)
				else:
					var to = machine.pos
					path_to(to, 0)

func perceive():
	var min_dist = unit.dat.g("perception", 4)
	var other_team
	if unit.dat.g("faction", -1) == 1:
		other_team = 2
	else:
		other_team = 1
	var seen_units = search(other_team, min_dist)
	if !seen_units.empty():
		target = seen_units[0][0]

func search(faction, _dist):
	var list = G.world.team[faction]
	var r = []
	for seen in list:
		if is_instance_valid(seen) and seen != unit:
			var dist = unit.pos.distance_to(seen.pos)
			if dist <= _dist:
				if seen.n_sprites.visible:
					if unit.pos.get_beam_to(seen.pos, 1)[1] == seen.pos:
						r.append([seen, dist])
	return r

func hunt():
	if target != null and is_instance_valid(target):
		path_to(target.pos, reach)
		if !perform_ability():
			tasks.append(["attack", target])
		return true
	else:
		target = null
		return false

func perform_ability():
	if R.b():
		var exc = [unit.n_collider, target.n_collider]
		if unit.n_collider.cast_col_ray(target.position, exc, unit.col).empty():
			var ability_idx = R.ir(0, unit.dat.g("abilities", []).size())
			tasks = [["ability", ability_idx, target.position]]
