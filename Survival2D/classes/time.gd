extends Node

var frame = 0
var frames = 0
var seconds = 0
var second
var half_second
var quarter_second
var eighth_second

func reset():
	second = false
	half_second = false
	quarter_second = false
	eighth_second = false
	frame = 0
	seconds = 0

func on_process(delta):
	frame += delta
	second = false
	half_second = false
	quarter_second = false
	eighth_second = false
	if frame >= .125:
		frame = frame - .125
		frames = frames + 1
		eighth_second = true
		if frames % 2 == 0:
			quarter_second = true
		if frames % 4 == 0:
			half_second = true
		if frames == 8:
			second = true
			seconds += 1
			frames = 0
