extends Node2D

const Note = preload("res://objects/Note.tscn")
const ColBox = preload("res://objects/CollisionBox.tscn")
const Healthbar = preload("res://interface/Health.tscn")
var n_healthbar
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
var flash_state = [0, 0, 0, 0]

func get_display_name():
	if display_name == null:
		return item_name
	return display_name

func place(p):
	on_change("dat")
	position = p.position
	pos = p
	if pos.visible:
		if col & 1 == 0 and pos.is_col(1):
			G.you.view_dirty = true
		elif col & 1 > 0 and !pos.is_col(1):
			G.you.view_dirty = true
	p.add_item(self)

func remove():
	if host != null and is_instance_valid(host):
		host.on_item_remove(self)
	if n_healthbar != null:
		n_healthbar.queue_free()
	G.world.turn.remove(self)
	if pos != null: #not an equipment
		pos.remove_item(self)
		if pos.visible:
			if col & 1 == 0 and pos.is_col(1):
				G.you.view_dirty = true
			elif col & 1 > 0 and !pos.is_col(1):
				G.you.view_dirty = true
	queue_free()

func die():
	var ondie = dat.g("ondie")
	if ondie != null:
		G.cmds(ondie, self)
	remove()

func take(owner):
	if pos != null:
		pos.remove_item(self)
	host = owner
	pos = owner.pos

func get_defense(_p):
	return dat.g("armor", 0)

func hit(_type, dmg, _hitter):
	if dmg > 0:
		if _type != "true":
			var block = get_defense(_type)
			if block >= dmg:
				G.make_particle("Hit", pos.position)
				return
			else:
				dmg -= block
			if dmg > 1:
				if _type == "cut":
					G.make_particle("Cut", pos.position)
				elif _type == "bash":
					G.make_particle("Hit", pos.position)
		G.sfx.play_hit(_type, dat.g("mat","other"), position)
		dat.add("damage", dmg, 0)
		show_healthbar()
		G.display_damage(round(dmg), pos.position, Color.red)
		flash(0, dmg * .2)
		on_health_change()
	elif dmg < 0:
		dat.add("damage", dmg, 0, dat.g("vitality"))
		show_healthbar()
		G.display_damage(round(dmg), pos.position, Color.green)
		flash(1, dmg * -.2)

func on_health_change():
	if get_health() <= 0:
		die()

func show_healthbar():
	var vit = dat.g("vitality", 0)
	if vit > 0:
		if n_healthbar == null:
			n_healthbar = Healthbar.instance()
			add_child(n_healthbar)
		n_healthbar.set_mhp(vit)
		n_healthbar.set_hp(vit - dat.g("damage", 0))

func get_health():
	var vit = dat.g("vitality", -1)
	if vit == -1:
		return 1
	elif vit == 0:
		return 0
	var hurt = dat.g("damage", 0)
	return 1 - (hurt / vit)

func autotilize():
	var autotile = dat.g("autotile", 0)
	if autotile != 0:
		var dirs = []
		for i in range(4):
			var adj = pos.get_adjacent(i * 2)
			var items = adj.get_items_by_name(item_name)
			if !items.empty():
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

func on_change(p):
	if p == "dat":
		layer = dat.g("layer", 0)
		var oldcol = col
		col = dat.g("col", 0)
		if col != oldcol:
			update_col(col)
		flags = dat.g("flags", [])
		var color = dat.g("modulate")
		if color != null:
			set_modulate(Color(color))
		if dat.g("onmake") != null:
			if !G.world.turn.has(self):
				G.world.turn.add(self)
				turns = -1
		elif dat.g("onturn") != null:
			if !G.world.turn.has(self):
				G.world.turn.add(self)
		else:
			if G.world.turn.has(self):
				G.world.turn.remove(self)

func update_col(p):
	if n_collider != null:
		n_collider.collision_layer = p
	elif p > 0:
		n_collider = ColBox.instance()
		add_child(n_collider)
		n_collider.collision_layer = p

func on_turn():
	if turns == -1:
		if dat.g("onmake") != null:
			dat.run(self, "onmake")
			if dat.g("onturn") == null:
				G.world.turn.remove(self)
				return
			else:
				turns = 0
	turns += 1
	if turns > dat.g("turn", 0):
		dat.run(self, "onturn")
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

func _process(delta):
	if flash_state[0] > 0:
		var percent = flash_state[0] / flash_state[1]
		if flash_state[2] > 0:
			modulate.r = 1
			modulate.g = 1-flash_state[2]*percent
			modulate.b = modulate.g
		elif flash_state[3] > 0:
			modulate.r = 1-flash_state[3]*percent
			modulate.g = 1
			modulate.b = modulate.r
		flash_state[0] -= delta
	else:
		set_process(false)

func flash(c, dur):
	dur = max(.1, dur)
	flash_state = [dur, dur, 0, 0]
	flash_state[2 + c] = 1
	set_process(true)
