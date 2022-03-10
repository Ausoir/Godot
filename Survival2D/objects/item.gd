extends Node2D

const ColBox = preload("res://objects/CollisionBox.tscn")
var n_collider
var id = 0
var item_type
var item_name = 'item'
var display_name
var col: int = 0
var dat
var layer: int
var pos
var prev_pos
var turns = 0
var faction = 0
var flags
var light: int
var hp = Vector2()

func get_display_name():
	if display_name == null:
		return item_name
	return display_name

func place(p):
	position = p.to_pixel()
	pos = p
	if col & 1 > 0 and pos.visible: #Recalc light
		G.you.view_dirty = true
		var ls = pos.world.get_affected_lights(pos)
		for i in ls:
			var t = i.light
			i.radiate(-i.light, false)
			i.light = t
		p.add_item(self)
		for i in ls:
			var t = i.light
			i.light -= t
			i.radiate(t, false)
	else:
		p.add_item(self)

func remove():
	G.world.turn.remove(self)
	if pos != null: #not an equipment
		if col & 1 > 0 and pos.visible:
			G.you.view_dirty = true
			var ls = pos.world.get_affected_lights(pos)
			for i in ls:
				var t = i.light
				i.radiate(-i.light, false)
				i.light = t
			pos.remove_item(self)
			for i in ls:
				var t = i.light
				i.light -= t
				i.radiate(i.light, false)
		else:
			pos.remove_item(self)
	queue_free()

func die():
	var ondie = dat.g("ondie")
	if ondie != null:
		G.cmd(ondie, self)
	remove()

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
	position = to.to_pixel()
	prev_pos = pos
	to.add_item(self)
	on_relocate()

func on_relocate():
	if pos.sight_frame >= G.you.n_camera.sight_frame - 1:
		show()
	else:
		hide()

func move_world(wld):
	var x = pos.x
	var y = pos.y
	pos.remove_item(self)
	prev_pos = pos
	wld.tiles[y][x].add_item(self)

func on_dat():
	flags = dat.g("flags", [])
	light = dat.g("light", 0)
	layer = dat.g("layer", 0)
	var oldcol = col
	col = dat.g("col", 0)
	if col != oldcol:
		update_col(col)

func update_col(p):
	if n_collider != null:
		n_collider.collision_layer = p
	elif p > 0:
		n_collider = ColBox.instance()
		add_child(n_collider)
		n_collider.collision_layer = p

func on_turn():
	turns += 1
	if turns > dat.g("turn", 0):
		var onturn = dat.g("onturn")
		if onturn != null:
			G.cmd(onturn, self)
		turns = 0
