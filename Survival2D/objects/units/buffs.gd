var host
var states = {}
var in_turn = false

class buff:
	var name
	var fx
	var duration
	var cancels

	func _init(p1,p2,p3,p4):
		name = p1
		fx = p2
		duration = p3
		cancels = p4

	func on_turn(host):
		if duration == 0:
			if "onend" in fx:
				G.influence.do(host, name, fx, 2)
			return true
		elif duration > 0:
			duration -= 1
		if "onturn" in fx:
			G.influence.do(host, name, fx, 1)
		return false

func _init(phost):
	host = phost

func add(p, effect, duration, cancels):
	if p in states:
		states[p].duration = duration
	else:
		states[p] = buff.new(p, effect, duration, cancels)
		if !G.turn.has(self):
			G.turn.add(self)

func has(p):
	return p in states

func cancel(p):
	if states.erase(p):
		if states.empty():
			G.turn.remove(self)
		return true
	else:
		push_error("Could not remove buff " + str(p))

func on_turn():
	for i in states.keys():
		if states[i].on_turn(host):
			cancel(i)

func on_interrupt(p):
	for i in states.keys():
		var state = states[i]
		if state.cancels != null:
			for cancel in state.cancels:
				if cancel == p:
					cancel(i)

func end(p):
	if p in states:
		states[p].duration = 0

func remove():
	G.turn.remove(self)
	states.clear()
