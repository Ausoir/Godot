extends "res://objects/controller.gd"

const Step = preload("res://view/Step.tscn")

onready var n_camera = $Camera
onready var n_cursor = $Cursor
onready var n_steps = $Steps

var last_pos
var p_id: int
var p_name: String
var auto_attack = true
var aiming = -1
var view_dirty = false
var on_point

func update_dat():
	.update_dat()
	n_camera.darken()
	n_camera.set_sight(unit.dat.gi("perception", 4), unit.dat.gi("sight", 1))
	n_camera.update(unit.pos, last_pos)
	var bodytype_list = G.data.get_json_data("bodytypes")
	var bodyparts = bodytype_list.get(unit.dat.g("type"))
	G.ui.menu.update_equipables(bodyparts)
	G.ui.menu.update_inventory()
	pathing.can_open = false
	pathing.smash_to = 0
	pathing.iterations = 32
	pathing.pathing_times = 0

func on_assign():
	.on_assign()
	last_pos = unit.pos
	n_camera.update(last_pos, unit.pos)

func on_kill(_victim):
	var money = R.ir(0, _victim.dat.g("value", 0))
	if money > 0:
		G.vars.money += money
		G.display_damage(unit.position, "+$"+str(money), Color.gold, 1, 250)
		for i in _victim.dat.g("actives", []):
			if R.b() and !(i in G.vars.learnable):
				G.vars.learnable.append(i)

func _on_input(event: InputEvent):
	if event is InputEventMouseMotion:
		var mouse_pos = get_cursor_position(event.global_position)
		n_cursor.position = G.pos_to_pixel(G.pixel_to_pos(mouse_pos))
	elif event is InputEventMouseButton:
		var mouse_pos = get_cursor_position(event.global_position)
		if event.pressed:
			if event.button_index == BUTTON_WHEEL_UP:
				if n_camera.zoom.x > .5:
					n_camera.zoom *= .8
			elif event.button_index == BUTTON_WHEEL_DOWN:
				if n_camera.zoom.x < 2:
					n_camera.zoom *= 1.2
			elif event.button_index == BUTTON_MIDDLE: #Teleport to cursor
				pass
			elif Input.is_action_just_pressed("move"):
				var mousetarget = G.pixel_to_pos(mouse_pos)
				var t = G.world.get_tile(mousetarget.x, mousetarget.y)
				if t != null:
					move_to(t)
			elif Input.is_action_just_pressed("use"):
				tasks.clear()
				var mousetarget = G.pixel_to_pos(mouse_pos)
				var tile = G.world.get_tile(mousetarget.x, mousetarget.y)
				if tile:
					if aiming != -1:
						if aiming == -2 and on_point != null:
							tasks = [["command", on_point[0], on_point[1], tile]]
							on_point = null
						else:
							tasks = [["ability", aiming, mouse_pos]]
						stop_aim()
					elif !tile.items.empty():
						var item = tile.get_item_by_type("item")
						if item != null:
							tasks = [["interact", item]]

func get_cursor_position(mouse):
	var screen_mouse = mouse * G.ui.screen_ratio
	screen_mouse -= G.ui.screen_size / 2
	return Vector2(screen_mouse.x*n_camera.zoom.x + n_camera.position.x,
					screen_mouse.y*n_camera.zoom.y + n_camera.position.y)

func on_turn():
	if auto_attack and tasks.empty():
		var colld = unit.n_collider.get_collider(unit.dat.g("faction", -1))
		if colld != null:
			if tasks.empty():
				tasks = [["attack", colld]]
	var cds = !unit.cooldowns.empty()
	.on_turn()
	remove_steps()
	show_steps()
	if view_dirty or last_pos != unit.pos:
		n_camera.update(last_pos, unit.pos)
		view_dirty = false
		last_pos = unit.pos
	if cds:
		G.ui._update_cooldowns(unit.cooldowns)
	G.ui.update_hud()

func make_money(p):
	G.vars.money += p
	G.ui.n_money.display(p)

func _physics_process(_delta):
	n_camera.position = unit.n_collider.global_position
	if unit.delay == 0:
		var dir = -1
		if Input.is_action_pressed("move_up"):
			if Input.is_action_pressed("move_left"):
				dir = 7
			elif Input.is_action_pressed("move_right"):
				dir = 1
			else:
				dir = 0
		elif Input.is_action_pressed("move_down"):
			if Input.is_action_pressed("move_left"):
				dir = 5
			elif Input.is_action_pressed("move_right"):
				dir = 3
			else:
				dir = 4
		elif Input.is_action_pressed("move_right"):
			dir = 2
		elif Input.is_action_pressed("move_left"):
			dir = 6
		if dir != -1:
			tasks.clear()
			var v = G.DIRS[dir]
			unit.slide(Vector2(v[0], v[1]))
		elif unit.n_collider.vel != Vector2.ZERO and tasks.empty():
			unit.set_animation("idle")

func on_item_click(item): #runs after _unhandled_input
	if tasks.empty():
		tasks.append(["interact", item])
	elif tasks.size() == 1 and tasks[0][0] == "interact":
		tasks[0][1] = item

func remove_steps():
	for child in n_steps.get_children():
		n_steps.remove_child(child)
		child.queue_free()

func show_steps():
	var last_step = unit.pos.to_vector()
	for task in tasks:
		if task[0] == "path":
			var step = Step.instance()
			step.position = G.pos_to_pixel(task[1])
			var new_step = task[1].to_vector()
			var p = (new_step - last_step).angle()
			step.rotate(p)
			n_steps.add_child(step)
			last_step = new_step

func on_hit(_hitter):
	if _hitter != null and target == null:
		target = _hitter

func interact(item):
	if !G.ui.on:
		var onuse = item.dat.g("onuse")
		if onuse != null:
			G.cmds(onuse, item, unit)
		elif item.item_type == "item":
			G.ui.menu.search_inventory(item.pos)
		elif item.item_type == "unit":
			if item.dat.g("faction", -1) != unit.dat.g("faction", -1):
				tasks.append(["attack", item])
			elif item.controller != null:
				item.controller.path_to(item.pos.get_rand_offset(2, 2), 0)

func move_to(tile, reach=0, _path=true):
	var distance = unit.pos.distance_to(tile)
	if _path:
		if distance <= reach:
			return unit.pos
		path_to(tile, reach)
		remove_steps()
		show_steps()
	else:
		path_to(tile, reach)

func aim_ability(idx):
	n_cursor.show()
	Input.set_default_cursor_shape(Input.CURSOR_CROSS)
	aiming = idx

func stop_aim():
	n_cursor.hide()
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	aiming = -1
	G.ui.update_hud()

func remove():
	if unit.get_health() <= 0:
		G.cmds([["menu","dialog","Game Over"]])
		var player_unit = G.cmds([["make", "ghost", unit.pos]])
		player_unit.possess(self)

func save_data(remove_buffs=true):
	var buff_data = unit.buffs.to_data()
	if remove_buffs:
		unit.buffs.clear()
	var save_dict = {
		"id": p_id,
		"unit": unit.item_name,
		"unit_data": unit.dat.v,
		"unit_buff": buff_data,
		"position": unit.pos.to_array()
	}
	if unit.dat.g("type") != "other":
		save_dict = unit.update_save_data(save_dict)
	return save_dict

func load_data(_data):
	var player_pos = G.world.get_spawn_point()
	if "position" in _data:
		player_pos = G.world.tiles[_data.position[1]][_data.position[0]]
	var player_unit = G.cmds([["make", _data.unit, player_pos]])
	player_unit.possess(self)
	player_unit.dat.load_data(_data.unit_data)
	if player_unit.dat.g("type") != "other":
		player_unit.load_item_data(_data)
		player_unit.set_seed()
	player_unit.buffs.from_data(_data.unit_buff)
	make_money(0)
