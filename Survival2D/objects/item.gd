extends Node2D

const ColBox = preload("res://objects/CollisionBox.tscn")
var n_collider
var id = 0
var item_type
var item_name = 'item'
var display_name
var col: int = 0
var dat
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
	var ls = []
	if col & 1 > 0 and pos.visible:
		G.you.view_dirty = pos
		ls = G.you.n_camera.get_affected_lights(pos)
		for i in ls:
			var t = i.light
			i.radiate(-i.light, false)
			i.light = t
	p.add_item(self)
	for i in ls:
		var t = i.light
		i.radiate(i.light, false)
		i.light -= t

func remove():
	G.turn.remove(self)
	var ls = []
	if pos != null: #not an equipment
		if col & 1 > 0 and pos.visible:
			G.you.view_dirty = pos
			ls = G.you.n_camera.get_affected_lights(pos)
			for i in ls:
				var t = i.light
				i.radiate(-i.light, false)
				i.light = t
		pos.remove_item(self)
		for i in ls:
			var t = i.light
			i.radiate(i.light, false)
			i.light -= t
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
	if to.sight_frame >= G.you.n_camera.sight_frame - 1:
		show()
	else:
		hide()

func move_world(wld):
	var x = pos.x
	var y = pos.y
	pos.world.items.remove_child(self)
	pos.remove_item(self)
	prev_pos = pos
	wld.items.add_child(self)
	wld.tiles[y][x].add_item(self)

func on_dat():
	flags = dat.g("flags", [])
	light = dat.g("light", 0)
	var oldcol = col
	col = dat.g("col", 0)
	if col != oldcol:
		update_col(col)
	var onuse = dat.g("onuse")
	if onuse != null and n_collider == null:
		update_col(16) #make collider for clickability

func update_col(p):
	if n_collider != null:
		n_collider.collision_layer = p
	elif p > 0:
		n_collider = ColBox.instance()
		add_child(n_collider)
		n_collider.parent = self
		n_collider.collision_layer = p

func on_turn():
	turns += 1
	if turns > dat.g("turn", 0):
		var onturn = dat.g("onturn")
		if onturn != null:
			G.cmd(onturn, self)
		turns = 0
