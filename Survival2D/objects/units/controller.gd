extends Node


const Pathing = preload("res://objects/units/pathing.gd")
var unit
var sight_range = 8
var target
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
			unit.move(task[1])
			unit.set_state("move")
		elif task[0] == "interact":
			interact(task[1])
		elif task[0] == "ability":
			unit.ability(task[1])
		elif task[0] == "attack":
			unit.ability(task[1])
		elif task[0] == "swap":
			unit.select_weapon(task[1])
			unit.dirty = true

func path_to(pos, dist=0):
	pathing.result = []
	pathing.reach = dist
	var unitpos = unit.pos.to_vector()
	if unitpos == pos:
		tasks = []
	else:
		var path = pathing.update(unit.pos.to_vector(), pos)
		if path:
			tasks = []
			var lastpos = unitpos
			for p in path:
				var vec = p - lastpos
				var dir = G.vector_to_dir(vec.x, vec.y)
				if dir != null:
					tasks.append(["move", dir])
					lastpos = p

func interact(dir):
	var tile = unit.pos.get_adjacent(dir)
	if tile.distance_to(unit.pos) <= 1:
		interact_tile(tile)

func interact_tile(_tile):
	pass
