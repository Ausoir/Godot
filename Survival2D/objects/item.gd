extends Node2D

const Note = preload("res://objects/Note.tscn")
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
var flags
var dirty_dat = true
var hp = Vector2()
var host

func _ready():
	update_dat()

func get_display_name():
	if display_name == null:
		return item_name
	return display_name

func place(p):
	position = p.position
	pos = p
	if col & 1 == 0 and pos.visible and pos.is_col(1):
		G.you.view_dirty = true
	p.add_item(self)

func remove():
	if host != null:
		host.on_item_remove(self)
	G.world.turn.remove(self)
	if pos != null: #not an equipment
		pos.remove_item(self)
		if col & 1 > 0 and pos.visible and !pos.is_col(1):
			G.you.view_dirty = true
	queue_free()

func die():
	var ondie = dat.g("ondie")
	if ondie != null:
		G.cmds(ondie, self)
	remove()

func hit(_type, dmg, _hitter):
	if dmg > dat.g("armor", 99):
		G.make_particle("Hit", pos.position)
		G.display_damage(pos.position, round(dmg))
		die()
		return true

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
	position = to.position
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

func update_dat():
	layer = dat.g("layer", 0)
	var oldcol = col
	col = dat.g("col", 0)
	if col != oldcol:
		update_col(col)
	flags = dat.g("flags", [])

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
			G.cmds(onturn, self)
		turns = 0

func textify(p):
	if has_node("Viewport"):
		$Viewport/Label.set_text(p.to_upper())
	else:
		var note = Note.instance()
		add_child(note)
		var t = self
		t.set_texture(note.get_texture())
		$Viewport/Label.set_text(p.to_upper())
		t.set_centered(true)
