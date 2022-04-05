var host
var states = {}
var in_turn = false
var disrupt_hit = false

class buff:
	var parent
	var name
	var fx
	var duration
	var dest
	var cancelable
	var turns
	var turn = 0

	func _init(pparent,p1,p2,p3,p4):
		parent = pparent
		name = p1
		fx = p2
		duration = p3
		dest = p4
		cancelable = fx.get("cancelable", false)
		turns = fx.get("turns", 0)

	func on_turn(host):
		if duration == 0:
			if "onend" in fx:
				G.influence.do(name, host, dest, 2, fx)
			parent.cancel(name)
		elif duration > 0:
			duration -= 1
		turn += 1
		if "onturn" in fx:
			if turn > turns:
				turn = 0
				G.influence.do(name, host, dest, 1, fx)

func _init(phost):
	host = phost

func add(p, effect, duration, dest=null):
	if p in states:
		states[p].duration = duration
	else:
		states[p] = buff.new(self, p, effect, duration, dest)
		if !G.world.turn.has(self):
			G.world.turn.add(self)

func has(p):
	return p in states

func cancel(p):
	states.erase(p)
	if states.empty():
		G.world.turn.remove(self)

func on_turn():
	var keys = states.keys()
	for i in keys:
		var state = states[i]
		if disrupt_hit and state.cancelable:
			cancel(i)
			continue
		state.on_turn(host)
	disrupt_hit = false

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
	states.clear()
	G.world.turn.remove(self)

func clear():
	for i in states:
		states[i].duration = 0
		states[i].on_turn(host)
	states.clear()
	G.world.turn.remove(self)

func to_data():
	var r = []
	for i in states:
		r.append([i, states[i].duration])
	return r

func from_data(_data):
	for i in _data:
		var skill_data = G.data.skill_data.get(i[0])
		if skill_data != null:
			if "onstart" in skill_data:
				G.influence.do(i[0], host, null, 0, skill_data)
			else:
				add(i[0], skill_data, i[1])
