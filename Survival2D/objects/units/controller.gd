extends Node


const Pathing = preload("res://objects/units/pathing.gd")
var unit
var tasks = []
var delay = 0
var locked = false
var pathing = Pathing.new()

func assign(p):
	unassign()
	unit = p
	unit.controller = self

func unassign():
	if unit:
		unit.controller = null

func on_turn():
	if !tasks.empty():
		var task = tasks.pop_front()
		if task[0] == "move":
			unit.relocate(G.get_tile(task[1]))
			unit.set_state("move")

func path_to(pos):
	pathing.result = []
	if unit.pos.to_vector() == pos:
		tasks = []
	else:
		var path = pathing.update(unit.pos.to_vector(), pos)
		if path:
			tasks = []
			for p in path:
				tasks.append(["move", p])
