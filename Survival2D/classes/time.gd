extends Node

var frame = 0
var s = 0
var seconds = 0
var second
var half_second
var quarter_second
var quarter_seconds

func reset():
	second = false
	half_second = false
	quarter_second = false
	s = 0
	frame = 0
	seconds = 0
	quarter_seconds = 0

func on_process(delta):
	frame += delta
	second = false
	half_second = false
	quarter_second = false
	if frame >= .25:
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
