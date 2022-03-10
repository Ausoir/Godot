extends "res://objects/controller.gd"

var state = ""
var reach = 1
var turn_delay = 0
var objectives = []

func on_hit(_hitter):
	if _hitter != null:
		target = _hitter

func on_turn():
	turn_delay += 1
	if turn_delay > 3:
		turn_delay = 0
		if target == null:
			perceive()
		elif !is_instance_valid(target):
			target = null
		hunt()
	.on_turn()

func set_state(_p):
	if state != _p:
		state = _p
		pathing.next_reset = 0

func perceive():
	var min_dist = unit.dat.g("perception", 4)
	var other_team
	if unit.faction == 1:
		other_team = 2
	else:
		other_team = 1
	var seen_units = search(other_team, min_dist)
	if !seen_units.empty():
		target = seen_units[0][0]

func search(faction, _dist):
	var list = G.world.team[faction]
	var r = []
	var dist2 = _dist*2
	var disthalf = int(_dist/2)
	for seen in list:
		if is_instance_valid(seen) and seen != unit:
			var dist = unit.pos.distance_to(seen.pos)
			if dist <= disthalf or (dist < dist2 and seen.pos.light >= 0):
				if seen.n_sprites.visible:
					if unit.n_collider.cast_col_ray(seen.position, [unit, seen], 1).empty():
						r.append([seen, dist])
	return r

func hunt():
	if target != null and is_instance_valid(target):
		set_state("hunt")
		path_to(target.pos, reach)
		if !perform_ability():
			tasks.append(["attack", target])
		return true
	else:
		target = null
		return false

func perform_ability():
	if R.ir(0, 3) == 0:
		var abilities = unit.dat.g("abilities", [])
		for i in abilities:
			var data = G.data.skill_data.get(i)
			if data != null:
				var dest = target.pos.to_pixel()
				return G.influence.do(unit, i, data, 0, dest)
