extends Node2D

var id = 0
var item_name = 'item'
var item_type
var col = '0000'
var dat
var vars
var pos
var prev_pos
var faction = 0
var move_delay = 0
var move_delay_speed = 1
var hp = Vector2()

func create(p):
	p.add_item(self)
	G.world.items.add_child(self)
	position = p.to_pixel()
	pos = p
	p.update_col()

func remove():
	pos.remove_item(self)
	G.world.items.remove_child(self)
	queue_free()

func face(_p):
	pass

func move(towards):
	var to = pos.get_adjacent(towards)
	if to != pos and !to.is_cols(col):
		relocate(to)
		return to

func relocate(to):
	if to.x > pos.x:
		face(1)
	elif to.x < pos.x:
		face(-1)
	pos.remove_item(self)
	move_delay = 1
	move_delay_speed = 3
	set_process(true)
	prev_pos = pos
	to.add_item(self)
	if to.sight_frame == G.you.vision.sight_frame -1:
		show()
	else:
		hide()

func swap(with):
	var t = pos
	relocate(with.pos)
	with.relocate(t)

func _process(delta):
	if move_delay <= 0:
		set_process(false)
	else:
		move_delay -= delta * move_delay_speed
		position = prev_pos.to_pixel().linear_interpolate(pos.to_pixel(), 1 - move_delay)
