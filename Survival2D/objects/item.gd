extends Node2D

var id = 0
var item_name = 'item'
var item_type
var col = '0000'
var dat
var vars
var pos
var prev_pos
var turns = 0
var faction = 0
var move_delay = 0
var move_delay_speed = 3
var light: int
var hp = Vector2()

func place(p):
	p.add_item(self)
	position = p.to_pixel()
	pos = p

func remove():
	G.turn.remove(self)
	pos.remove_item(self)
	queue_free()

func die():
	var ondie = dat.g("ondie")
	if ondie != null:
		G.cmd(ondie, self)
	remove()

func move(towards):
	var to = pos.get_adjacent(towards)
	if to != pos and !to.is_cols(col):
		relocate(to)
		return to

func autotilize():
	var autotile = dat.g("autotile", 0)
	if autotile != 0:
		var dirs = []
		for i in range(4):
			var adj = pos.get_adjacent(i * 2)
			var item = adj.get_item_by_name(item_name)
			if item != null:
				dirs.append(i)
		var v = G.get_autotile_coord(dirs)
		self.region_rect.position = v * 32

func relocate(to):
	pos.remove_item(self)
	move_delay = 1
	set_process(true)
	prev_pos = pos
	to.add_item(self)
	if to.sight_frame >= G.you.camera.sight_frame - 1:
		show()
	else:
		hide()

func set_move_delay_speed(p):
	var delay2msec = p * .5 #(1.0/8) * G.turn.taker.size()
	move_delay_speed = 1 + 1.5 / delay2msec

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

func on_turn():
	turns += 1
	if turns > dat.g("turn", 0):
		var onturn = dat.g("onturn")
		if onturn != null:
			G.cmd(onturn, self)
		turns = 0
