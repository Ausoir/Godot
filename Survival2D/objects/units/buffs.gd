var host
var states = {}
var in_turn = false

class buff:
	var name
	var fx
	var duration
	var cancels

	func _init(p1,p2,p3):
		name = p1
		fx = p2
		duration = p3
		cancels = fx.get("cancel", null)

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

func extend(p, dur):
	if p in states:
		states[p].duration = dur

func expend(p):
	if p in states:
		states[p].duration = 0
		return states[p].fx
	return null

func remove():
	G.turn.remove(self)
	states.clear()

func clear():
	for i in states:
		states[i].duration = 0
		states[i].on_turn(host)
	states.clear()
	G.turn.remove(self)

func to_data():
	var r = []
	for i in states:
		r.append([i, states[i].duration])
	return r

func from_data(_data):
	for i in _data:
		var skill_data = G.data.skill_data.get(i[0])
		if skill_data != null:
			add(i[0], skill_data, i[1])
