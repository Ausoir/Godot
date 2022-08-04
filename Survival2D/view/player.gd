extends "res://objects/controller.gd"

const Step = preload("res://view/Step.tscn")

onready var control = preload("res://objects/controller.gd")
onready var n_camera = $Camera
onready var n_cursor = $Cursor
onready var n_steps = $Steps

var last_pos
var aiming = -1
var view_dirty = false
var interactables = []
var unhandled_input = false
var on_point
var events = {}
var last_drag_dist = 0

func on_change(p):
	.on_change(p)
	if p == "dat":
		if n_camera.set_sight(unit.dat.gi("perception", 4), unit.dat.gi("sight", 1)):
			n_camera.update(unit.pos, last_pos)
		var bodytype_list = G.data.get_json_data("bodytypes")
		var bodyparts = bodytype_list.get(unit.dat.g("type"))
		G.ui.menu.update_equipables(bodyparts)
		G.ui.menu.update_equipment()
		G.ui.menu.update_inventory()
		pathing.can_open = false
		pathing.smash_to = -1
		pathing.iterations = 32
		pathing.pathing_times = 0
	G.ui.update_hud()

func on_assign():
	.on_assign()
	last_pos = unit.pos
	n_camera.update(last_pos, unit.pos)
	G.ui.update_hud()

func on_kill(_victim):
	var money = R.ir(0, _victim.dat.g("value", 0))
	if money > 0:
		G.vars.money += money
		G.display_damage("+$"+str(money), unit.position, Color.gold, 1, 250)

func get_mouse():
	var screen_mouse = G.ui.mouse_pos
	screen_mouse -= G.ui.screen_size / 2
	return Vector2(screen_mouse.x*n_camera.zoom.x + n_camera.position.x,
				screen_mouse.y*n_camera.zoom.y + n_camera.position.y)

func _on_input(event: InputEvent):
	if event is InputEventScreenDrag:
		if unhandled_input:
			events[event.index] = event
			if events.size() == 2:
				var drag_distance = events[0].position.distance_to(events[1].position)
				if abs(drag_distance - last_drag_dist) > 10:
					var new_zoom = .95
					if drag_distance < last_drag_dist:
						new_zoom = 1.05
					new_zoom = clamp(n_camera.zoom.x * new_zoom, .5, 2)
					n_camera.zoom = Vector2.ONE * new_zoom
					last_drag_dist = drag_distance
			elif aiming != -1:
				n_cursor.position = get_mouse()
	elif event is InputEventMouseButton:
		if event.is_pressed() and !G.ui.on:
			unhandled_input = true
			if event.button_index == BUTTON_WHEEL_UP:
				if n_camera.zoom.x > .5:
					n_camera.zoom *= .8
			elif event.button_index == BUTTON_WHEEL_DOWN:
				if n_camera.zoom.x < 2:
					n_camera.zoom *= 1.2
			elif aiming == -1:
				var screen_mouse = G.ui.mouse_pos
				screen_mouse -= G.ui.screen_size / 2
				if screen_mouse.length_squared() < G.W * G.H:
					G.cmds([["menu", "menu", -1]], unit)
			else:
				n_cursor.show()
				n_cursor.position = get_mouse()
		else:
			events.clear()
			if interruptible and unhandled_input:
				if aiming != -1:
					var mtile = G.pixel_to_pos(get_mouse())
					var tile = G.world.fit_bound(mtile.x, mtile.y)
					if aiming == -2 and on_point != null:
						tasks = [["command", on_point[0], on_point[1], tile]]
						on_point = null
					else:
						tasks = [["ability", aiming, tile.position]]
					stop_aim()
				else:
					var mtile = G.pixel_to_pos(get_mouse())
					var tile = G.world.get_tile(mtile.x, mtile.y)
					if tile != null and !tile.items.empty():
						if tile.distance_to(unit.pos) <= 1 and tile != unit.pos:
							if n_camera.zoom.x <= .5:
								tasks = [["smash", tile]]
							else:
								tasks = [["interact", tile]]
						elif tile.visible:
							move_and_interact(tile)
					elif !tasks.empty() and tasks[0][0] == "moveto":
						tasks.clear()
			unhandled_input = false

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
		if interruptible and aiming == -1:
			if unhandled_input and Input.is_action_pressed("use"):
				tasks = [["moveto", get_mouse(), 64]]
			elif dir != -1:
				var to = G.DIRS[dir]
				tasks = [["move", to[0] * 10, to[1] * 10]]

func on_turn():
	if tasks.empty():
		var colld = unit.n_collider.get_collider(unit.dat.g("faction", -1))
		if colld != null:
			tasks = [["attack", colld]]
	var cds = !unit.cooldowns.empty()
	.on_turn()
	remove_steps()
	show_steps()
	if view_dirty or last_pos != unit.pos:
		n_camera.update(last_pos, unit.pos)
		view_dirty = false
		last_pos = unit.pos
		check_edge()
	check_nearby_interactibles()
	if cds:
		G.ui._update_cooldowns(unit.cooldowns)

func check_edge():
	var edge = unit.pos.get_edge()
	if edge != -1:
		var farside = false
		var complete = G.temp.get("complete")
		if "enterside" in G.temp:
			if G.temp.enterside == G.get_dir_to_cardinal_string(edge):
				if G.time.seconds > 3:
					tasks.append(["exit", 3, false])
					return
			elif G.temp.enterside == G.get_dir_to_cardinal_string(edge+2):
				farside = true
		else:
			farside = true
		if farside and complete:
			tasks.append(["exit", 3, complete])

func check_nearby_interactibles():
	if unit.dat.g("type") != "other":
		var vicinity = unit.pos.get_area(1)
		var ninteractables = []
		var items = []
		var npcs = []
		for tile in vicinity:
			items += tile.get_items_by_type("item")
			npcs += tile.get_items_by_type("unit", unit)
		for item in items:
			if item != null and (item.dat.g("oninteract") != null or unit.can_carry(item.dat.g("weight",-1))):
				ninteractables.append(item)
		for npc in npcs:
			if npc != null and npc.dat.g("oninteract") != null:
				ninteractables.append(npc)
		if interactables != ninteractables:
			interactables = ninteractables
			G.ui.update_hud()

func make_money(p):
	G.vars.money = G.vars.money+p
	G.ui.menu.n_money.display(p)

func on_hit(_hitter):
	if _hitter != null and target == null:
		target = _hitter

func interact(item):
	if !G.ui.on:
		var oninteract = item.dat.g("oninteract")
		if oninteract != null:
			G.cmds(oninteract, item, unit)
		elif item.item_type == "item":
			G.ui.menu.search_inventory(item.pos)
		elif item.item_type == "unit":
			if item.dat.g("faction", -1) != unit.dat.g("faction", -1):
				tasks.append(["attack", item])
			elif item.controller != null:
				item.controller.path_to(item.pos.get_rand_offset(2, 2), 0)

func move_and_interact(tile):
	path_to(tile, 1)
	remove_steps()
	show_steps()
	tasks.append(["interact", tile])

func aim_ability(idx):
	Input.set_default_cursor_shape(Input.CURSOR_CROSS)
	aiming = idx

func stop_aim():
	n_cursor.hide()
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	aiming = -1
	G.ui.update_hud()

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

func remove():
	if unit.get_health() <= 0:
		G.vars["dead"] = 1
		G.cmds([["menu","dialog","Death"]])
		var player_unit = G.cmds([["make", "ghost", unit.pos]])
		player_unit.possess(self)

func save_data(remove_buffs=true):
	var buff_data = unit.buffs.to_data()
	if remove_buffs:
		unit.buffs.clear()
	var save_dict = {
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
	var player_unit = G.cmds([["make", _data.unit, player_pos]])
	player_unit.possess(self)
	player_unit.dat.load_data(_data.unit_data)
	if player_unit.dat.g("type") != "other":
		player_unit.load_item_data(_data)
		player_unit.set_seed()
	player_unit.buffs.from_data(_data.unit_buff)
	make_money(0)
	G.ui.update_hud()
