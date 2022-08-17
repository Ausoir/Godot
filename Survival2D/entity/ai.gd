extends "res://entity/controller.gd"

var reach = 1
var turn_delay = 0
var behavior_name
var behavior
var other

func on_assign():
	.on_assign()
	var goal = unit.dat.g("goal", "hunt")
	if goal == "follow":
		behavior_name = "follow"
	else:
		behavior_name = "hunt"
	behavior = funcref(self, behavior_name)

func on_hit(_hitter):
	if _hitter != null:
		target = _hitter

func on_turn():
	turn_delay += 1
	if turn_delay > 3:
		turn_delay = 0
		if !behavior.call_func():
			think()
	.on_turn()

func think():
	if tasks.empty():
		var goal = unit.dat.g("goal", "hunt")
		if goal == "wander":
			path_to(unit.pos.get_rand_offset(12, 12), 0)
		elif goal == "kill":
			target = G.you.unit
		elif goal == "follow":
			if other == null:
				other = G.world.get_item_by_seed(unit.dat.g("follow", -1))
		elif goal == "sabotage":
			var sabo = G.temp.get("sabotage")
			if sabo != null and !sabo.empty():
				var machine = G.rng.r_arr(sabo)
				if machine == null or !is_instance_valid(machine):
					G.temp.sabotage.erase(machine)
				else:
					var to = machine.pos
					path_to(to, 0)

func perceive():
	var min_dist = unit.dat.g("perception", 1)
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
		if !perform_ability():
			path_to(target.pos)
			tasks.append(["moveto", target.position, 0])
		return true
	else:
		target = null
		perceive()
	return false

func follow():
	if !hunt() and other != null:
		path_to(other.pos, 1)

func perform_ability():
	if unit.position.distance_squared_to(target.position) <= unit.dat.g("perception", 8)*G.V:
		var ssize = unit.skills.size()
		if G.rng.ir(1, 8+ssize) <= ssize:
			var exc = [unit.n_collider, target.n_collider]
			if unit.n_collider.cast_ray(target.position, exc, 4).empty():
				var ability_idx = G.rng.ir(0, ssize-1)
				tasks = [["ability", ability_idx, target.position]]
				return true
