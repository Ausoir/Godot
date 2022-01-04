var host
var states = {}
var cancels = []

class buff:
	var name
	var fx
	var duration

	func _init(p1,p2,p3):
		name = p1
		fx = p2
		duration = p3

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

func add(p, effect, duration):
	if p in states:
		states[p].duration = duration
	else:
		states[p] = buff.new(p, effect, duration)
		G.turn.add(self)

func has(p):
	return p in states

func on_turn():
	for i in states.keys():
		if states[i].on_turn(host):
			states.erase(i)
			if states.empty():
				G.turn.remove(self)

func on_interrupt(p):
	for buff in cancels:
		if buff[0] == p:
			states.erase(buff[1])

func end(p):
	states[p].duration = 0

func remove():
	G.turn.remove(self)
	states.clear()
