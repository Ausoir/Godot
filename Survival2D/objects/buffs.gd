var host
var states = {}
var in_turn = false
var disrupt_hit = false

class buff:
	var parent
	var skill
	var fx
	var duration
	var dest
	var cancelable
	var turns
	var turn = 0

	func _init(pparent,p1,p2,p3):
		parent = pparent
		skill = p1
		duration = p2
		dest = p3
		cancelable = p1.get("cancelable", false)
		turns = p1.get("turns", 0)

	func on_turn(host):
		if duration == 0:
			parent.cancel(skill.name)
			return
		elif duration > 0:
			duration -= 1
		turn += 1
		if "onturn" in skill:
			if turn > turns:
				turn = 0
				G.influence.do(skill, host, dest, 1)

func _init(phost):
	host = phost

func add(skill, duration, dest=null):
	if skill.name in states:
		states[skill.name].duration = duration
	else:
		states[skill.name] = buff.new(self, skill, duration, dest)
		if !G.world.turn.has(self):
			G.world.turn.add(self)

func has(p):
	return p in states

func cancel(p):
	var state = states.get(p)
	if state != null:
		if "onend" in state.skill:
			G.influence.do(state.skill, host, state.dest, 2)
		states.erase(p)
		if states.empty():
			G.world.turn.remove(self)

func on_turn():
	var keys = states.keys()
	for i in keys:
		var state = states[i]
#		if disrupt_hit and state.cancelable:
#			cancel(i)
#		else:
		state.on_turn(host)
	disrupt_hit = false

func end(p):
	if p.name in states:
		states[p.name].duration = 0

func extend(p, dur):
	if p.name in states:
		states[p.name].duration = dur

func remove():
	states.clear()
	G.world.turn.remove(self)

func clear():
	for i in states:
		states[i].duration = 0
		states[i].on_turn(host)
	states.clear()
	G.world.turn.remove(self)
