extends "res://objects/units/controller.gd"

var state = "idle"
var foe
var reach = 1

func on_turn():
	.on_turn()
	if foe == null:
		perceive()
	if foe != null:
		if !is_instance_valid(foe):
			foe = null
		else:
			think()

func perceive():
	var r
	var min_dist = unit.vars.g("perception", 8)
	for player in G.world.players.get_children():
		var dist = unit.pos.distance_to(player.unit.pos)
		if dist < min_dist and unit.faction != player.unit.faction:
			var t = unit.pos.get_beam_to(player.unit.pos, "1000", unit.vars.g("perception", 9))
			if t != null and t == player.unit.pos:
				if player.unit.is_visible():
					min_dist = dist
					r = player.unit
	foe = r

func think():
	path_to(foe.pos, reach)
	target = foe.pos
	tasks.append(["attack", foe.pos])
