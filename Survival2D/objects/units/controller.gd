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
			var vec = task[1] - unit.pos.to_vector()
			var dir = G.vector_to_dir(vec.x, vec.y)
			unit.move(dir)
			unit.set_state("move")
			var x = G.CARDINALS[dir][0]
			if x > 0:
				unit.face(1)
			elif x < 0:
				unit.face(-1)
		elif task[0] == "interact":
			interact(task[1])
		elif task[0] == "ability":
			unit.face_toward(target)
			unit.ability(task[1])
		elif task[0] == "attack":
			target = task[1]
			unit.face_toward(target)
			if unit.pos.distance_to(target) <= 1:
				unit.set_state("attack")
		elif task[0] == "swap":
			unit.select_weapon(task[1])

func path_to(pos, dist=0):
	pathing.result = []
	pathing.reach = dist
	var unitpos_vec = unit.pos.to_vector()
	var pos_vec = pos.to_vector()
	if unitpos_vec == pos_vec:
		tasks = []
	else:
		var path = pathing.update(unitpos_vec, pos_vec)
		if path:
			tasks = []
			for p in path:
				tasks.append(["move", p])

func interact(tile):
	if unit.pos.distance_to(tile) <= 1:
		interact_tile(tile)

func interact_tile(_tile):
	pass

func remove():
	queue_free()
