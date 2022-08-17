extends Node

var frame
var s
var seconds
var second
var half_second
var quarter_second
var quarter_seconds

func _process(delta):
	increment_seconds(delta)
	if quarter_second:
		G.world.turn.process_frames += 1
		if second:
			G.custom.on_time()
	G.world.turn.on_process()
	var events = G.events
	var count = events.size() - 1
	while count >= 0:
		var ev = events[count]
		ev[0] -= delta
		if ev[0] <= 0:
			if ev[1] == null:
				G.cmds(ev[2])
			else:
				ev[1].call_funcv(ev[2])
			events.remove(count)
		count -= 1

func reset():
	second = false
	half_second = false
	quarter_second = false
	s = 0
	frame = 0
	seconds = 0
	quarter_seconds = 0

func increment_seconds(delta):
	frame += delta
	second = false
	half_second = false
	quarter_second = false
	if frame >= .2:
		s += 1
		frame = frame - .25
		quarter_seconds = quarter_seconds + 1
		quarter_second = true
		if quarter_seconds == 2:
			half_second = true
		elif quarter_seconds == 4:
			half_second = true
			second = true
			seconds += 1
			quarter_seconds = 0
