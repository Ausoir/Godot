extends Node2D


var id = 0
var item_name = 'item'
var item_type
var col_mask = 0b0001
var dat
var pos
var prev_pos
var move_delay = 0
var move_delay_speed = 1

func face(_p):
	pass

func move(towards):
	var to = pos.get_adjacent(towards)
	if to != pos:
		relocate(to)
		return to

func relocate(to):
	if pos:
		if to.x > pos.x:
			face(1)
		elif to.x < pos.x:
			face(-1)
		pos.items.erase(self)
		move_delay = 1
		move_delay_speed = 3
		set_process(true)
	to.items.append(self)
	prev_pos = pos
	pos = to

func _process(delta):
	if move_delay <= 0:
		set_process(false)
	else:
		move_delay -= delta * move_delay_speed
		position = prev_pos.to_pixel().linear_interpolate(pos.to_pixel(), 1 - move_delay)
