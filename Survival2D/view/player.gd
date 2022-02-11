extends "res://objects/units/controller.gd"

const Step = preload("res://view/Step.tscn")

onready var camera = $Camera
onready var cursor = $Cursor
onready var steps = $Steps

var p_id: int
var p_name: String
var auto_attack = true
var auto_attack_priority = 0
var aiming = -1
var last_pos
var view_dirty = false

var enabled = true
var allies = []


func on_assign():
	.on_assign()
	unit.faction = 1
	G.world.team[unit.faction].append(unit)
	last_pos = unit.pos
	var bodytype_list = G.data.get_json_data("bodytypes")
	var bodyparts = bodytype_list.get(unit.dat.g("type"))
	G.ui.update_equipables(bodyparts)
	G.ui.update_inventory()
	if camera.sight_frame > 0:
		camera.darken()
	camera.sight_range = unit.dat.g("perception", 18)
	camera.update(unit.pos, last_pos, unit.sight_col)
	pathing.can_open = false
	pathing.smash_to = 0
	pathing.iterations = 32
	pathing.pathing_times = 0

func _on_input(event: InputEvent):
	if enabled and !locked:
		if event is InputEventMouseButton:
			var mouse_pos = get_cursor_position(event.global_position)
			if event.pressed:
				if event.button_index == BUTTON_WHEEL_UP:
					if camera.zoom.x > .5:
						camera.zoom *= .8
				elif event.button_index == BUTTON_WHEEL_DOWN:
					if camera.zoom.x < 2:
						camera.zoom *= 1.2
				elif event.button_index == BUTTON_MIDDLE: #Teleport to cursor
					pass
				elif Input.is_action_just_pressed("move"):
					var mousetarget = G.pixel_to_pos(mouse_pos)
					target = G.field.get_tile(mousetarget.x, mousetarget.y)
					if target != null:
						move_to(target)
				elif Input.is_action_just_pressed("use"):
					tasks.clear()
					var mousetarget = G.pixel_to_pos(mouse_pos)
					var tile = G.field.get_tile(mousetarget.x, mousetarget.y)
					G.field.apply_autotile(mousetarget.x, mousetarget.y)
					if tile:
						auto_attack_priority = unit.pos.direction_to(tile)
						target = tile
						if aiming != -1:
							perform_ability(aiming)
							stop_aim()
						else:
							if !tile.items.empty():
								move_to(tile, 1)
								tasks.append(["interact", target])
							else:
								cursor.position = G.pos_to_pixel(mousetarget)
								cursor.show()
			elif Input.is_action_just_released("move"):
				cursor.hide()
			elif Input.is_action_just_released("use"):
				cursor.hide()
	elif event is InputEventMouseButton:
		if event.pressed and Input.is_action_just_pressed("use"):
			$menu.clear()
	elif event is InputEventKey:
		var t
		if Input.is_action_just_pressed("move_left"):
			t = unit.pos.get_adjacent(0)
		elif Input.is_action_just_pressed("move_up"):
			t = unit.pos.get_adjacent(1)
		elif Input.is_action_just_pressed("move_right"):
			t = unit.pos.get_adjacent(2)
		elif Input.is_action_just_pressed("move_down"):
			t = unit.pos.get_adjacent(3)
		if t != null:
			move_to(t)

func get_cursor_position(mouse):
	var screen_mouse = mouse * G.ui.screen_ratio
	screen_mouse -= G.ui.screen_size / 2
	return Vector2(screen_mouse.x*camera.zoom.x + camera.position.x,
					screen_mouse.y*camera.zoom.y + camera.position.y)

func on_turn():
	var cds = !unit.cooldowns.empty()
	.on_turn()
	remove_steps()
	show_steps()
	if last_pos != unit.pos or view_dirty:
		if last_pos != unit.pos and unit.pos.is_edge():
			tasks.append(["enter", "exit", 3])
		camera.update(last_pos, unit.pos, unit.sight_col)
		last_pos = unit.pos
	if cds:
		G.ui._update_cooldowns(unit.cooldowns)
	perform_auto_attack()
	G.ui.update_hud()

func _process(_delta):
	camera.position = unit.position

func perform_auto_attack():
	if auto_attack and unit.delay == 0 and tasks.empty():
		for dir in [auto_attack_priority] + range(8):
			var tile = unit.pos.get_adjacent(dir)
			for item in tile.items:
				if item.item_type == "unit" and item.faction != unit.faction:
					tasks.append(["attack", item])
					return true
	return false

func remove_steps():
	for child in steps.get_children():
		steps.remove_child(child)
		child.queue_free()

func show_steps():
	var last_step = unit.pos.to_vector()
	for task in tasks:
		if task[0] == "move":
			var step = Step.instance()
			step.position = G.pos_to_pixel(task[1])
			var new_step = task[1].to_vector()
			var p = (new_step - last_step).angle()
			step.rotate(p)
			steps.add_child(step)
			last_step = new_step

func aggro(npcs):
	var unit = $unit
	for i in npcs:
		i.find_player(unit)

func interact(tile):
	if G.ui.on:
		G.ui.clear()
	else:
		cursor.hide()
		if !tile.items.empty():
			var item = tile.get_priority_item([unit])
			if item != null:
				if item.item_type == "unit":
					if item.faction == unit.faction:
						if Input.is_action_pressed("shift"):
							auto_attack_priority = unit.pos.direction_to(tile)
							tasks.append(["attack", tile])
							if item.controller != null:
								item.controller.foe = unit
						else:
							var onuse = item.dat.g("onuse")
							if onuse != null:
								G.cmd(onuse, item)
					else:
						auto_attack_priority = unit.pos.direction_to(tile)
						tasks.append(["attack", tile])
				elif item.item_type == "item":
					if Input.is_action_pressed("shift"):
						tasks.append(["smash", target])
					else:
						var onuse = item.dat.g("onuse")
						if onuse != null:
							G.cmd(onuse, item)
						else:
							G.ui.search_inventory(tile)

func move_to(tile, reach=0):
	if tile.is_cols(unit.col):
		reach = 1
	var distance = unit.pos.distance_to(tile)
	if reach == 0 and distance == 1:
		if !tile.items.empty():
			var item = tile.get_priority_item([unit])
			if item != null and item.item_type == "unit" and item.faction == unit.faction:
				unit.swap(item)
				return
	if distance <= reach:
		return unit.pos
	cursor.position = G.pos_to_pixel(tile)
	cursor.show()
	path_to(tile, reach)
	remove_steps()
	show_steps()

func aim_ability(idx):
	Input.set_default_cursor_shape(Input.CURSOR_CROSS)
	aiming = idx

func stop_aim():
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	aiming = -1
	G.ui.update_hud()

func perform_ability(idx):
	tasks = [["ability", idx]]

func remove():
	if unit.get_health() <= 0:
		var player_unit = G.cmd([["make", "ghost", unit.pos]])
		player_unit.possess(self)

func on_leave():
	G.travel("base")

func save_data(remove_buffs=true):
	if remove_buffs:
		unit.buffs.clear()
	var ally_data = []
	for ally in allies:
		if ally != null and is_instance_valid(ally):
			ally_data.append(ally.item_name)
	var save_dict = {
		"type": "player",
		"id": p_id,
		"unit": unit.item_name,
		"unit_data": unit.dat.v,
		"unit_buff": unit.buffs.to_data(),
		"ally_data": ally_data
	}
	if unit.dat.g("type") == "man":
		save_dict = unit.update_save_data(save_dict)
	return save_dict

func load_data(_data):
	var player_pos = G.field.get_spawn_point()
	var player_unit = G.cmd([["make", _data.unit, player_pos]])
	player_unit.possess(self)
	player_unit.dat.load_data(_data.unit_data)
	if player_unit.dat.g("type") == "man":
		player_unit.load_item_data(_data)
	player_unit.buffs.from_data(_data.unit_buff)
	
	if G.world.map_name != "base":
		var adjs
		var adj = unit.pos
		for i in _data.ally_data:
			adjs = adj.get_available_adjacents("0100")
			adj = R.r_arr(adjs)
			if adj == null:
				adj = unit.pos
			var ally = G.cmd([["make", i, adj]])
			allies.append(ally)

func on_map_clear():
	for ally in allies:
		ally.remove()
	allies = []
