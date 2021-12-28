extends "res://objects/units/controller.gd"

var state = "idle"
var foe
var reach = 1

func on_turn():
	.on_turn()
	if foe == null:
		perceive()
	if foe != null:
		think()

func perceive():
	var r
	var min_dist = 999
	for player in G.world.players.get_children():
		var t = unit.pos.get_beam_to(player.unit.pos, G.COL_SIGHT, unit.vars.g("perception", 9))
		if t != null and t == player.unit.pos:
			var dist = unit.pos.distance_to(player.unit.pos)
			if dist < min_dist:
				min_dist = dist
				r = player.unit
	foe = r

func think():
	path_to(foe.pos.to_vector(), reach)
