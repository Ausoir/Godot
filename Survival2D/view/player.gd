extends "res://objects/units/controller.gd"

const Step = preload("res://view/Step.tscn")

onready var n_camera = $Camera
onready var n_cursor = $Cursor
onready var n_steps = $Steps

var p_id: int
var p_name: String
var auto_attack = true
var auto_attack_priority = 0
var aiming = -1
var last_pos
var view_dirty = false
var allies = []

func _ready():
	n_camera.set_process(false)

func on_dat():
	.on_dat()
	n_camera.sight_range = unit.dat.g("perception", 8)
	n_camera.sight2 = n_camera.sight_range * 2
	if n_camera.sight_frame > 0:
		n_camera.darken()
	n_camera.update(unit.pos, last_pos, unit.sight_col)

func on_assign():
	.on_assign()
	unit.faction = 1
	G.world.team[unit.faction].append(unit)
	last_pos = unit.pos
	var bodytype_list = G.data.get_json_data("bodytypes")
	var bodyparts = bodytype_list.get(unit.dat.g("type"))
	G.ui.update_equipables(bodyparts)
	G.ui.update_inventory()
	pathing.can_open = false
	pathing.smash_to = 0
	pathing.iterations = 32
	pathing.pathing_times = 0

func _on_input(event: InputEvent):
	if event is InputEventMouseButton:
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
				target = G.field.get_tile(mousetarget.x, mousetarget.y)
				if target != null:
					move_to(target)
			elif Input.is_action_just_pressed("use"):
				tasks.clear()
				var mousetarget = G.pixel_to_pos(mouse_pos)
				var tile = G.field.get_tile(mousetarget.x, mousetarget.y)
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
							n_cursor.position = G.pos_to_pixel(mousetarget)
							n_cursor.show()
		elif Input.is_action_just_released("move"):
			n_cursor.hide()
		elif Input.is_action_just_released("use"):
			n_cursor.hide()

func get_cursor_position(mouse):
	var screen_mouse = mouse * G.ui.screen_ratio
	screen_mouse -= G.ui.screen_size / 2
	return Vector2(screen_mouse.x*n_camera.zoom.x + n_camera.position.x,
					screen_mouse.y*n_camera.zoom.y + n_camera.position.y)

func on_turn():
	var cds = !unit.cooldowns.empty()
	.on_turn()
	remove_steps()
	show_steps()
	if last_pos != unit.pos or view_dirty:
		if last_pos != unit.pos and unit.pos.is_edge():
			tasks.append(["enter", "exit", 3])
		n_camera.update(last_pos, unit.pos, unit.sight_col)
		last_pos = unit.pos
		view_dirty = false
	if cds:
		G.ui._update_cooldowns(unit.cooldowns)
	perform_auto_attack()
	G.ui.update_hud()

func _process(_delta):
	n_camera.position = unit.position
	if unit.delay == 0:
		if Input.is_action_pressed("attack"):
			var tile = unit.pos.get_adjacent(auto_attack_priority)
			tasks.append(["smash", tile])
		elif Input.is_action_pressed("move_up"):
			if Input.is_action_pressed("move_left"):
				key_move(7)
			elif Input.is_action_pressed("move_right"):
				key_move(1)
			else:
				key_move(0)
		elif Input.is_action_pressed("move_down"):
			if Input.is_action_pressed("move_left"):
				key_move(5)
			elif Input.is_action_pressed("move_right"):
				key_move(3)
			else:
				key_move(4)
		elif Input.is_action_pressed("move_right"):
			key_move(2)
		elif Input.is_action_pressed("move_left"):
			key_move(6)

func key_move(dir):
	if !G.ui.on:
		auto_attack_priority = dir
		var t = unit.pos.get_adjacent(auto_attack_priority)
		if Input.is_action_pressed("shift"):
			interact(t)
		else:
			move_to(t, 0, false)

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
	for child in n_steps.get_children():
		n_steps.remove_child(child)
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
			n_steps.add_child(step)
			last_step = new_step

func aggro(npcs):
	var unit = $unit
	for i in npcs:
		i.find_player(unit)

func interact(tile):
	if !G.ui.on:
		n_cursor.hide()
		if !tile.items.empty():
			var item = tile.get_priority_item([unit])
			if item != null:
				var onuse = item.dat.g("onuse")
				if onuse != null:
					G.cmd(onuse, item)
				elif item.item_type == "item":
					G.ui.search_inventory(tile)
				elif item.item_type == "unit":
					if item.faction == unit.faction:
						if Input.is_action_pressed("shift"):
							auto_attack_priority = unit.pos.direction_to(tile)
							tasks.append(["attack", tile])
							if item.controller != null:
								item.controller.foe = unit
						elif unit.delay == 0 and item.delay == 0:
							unit.delay = 4
							item.delay = 4
							unit.set_animation("walk")
							item.set_animation("walk")
							unit.swap(item)
					else:
						auto_attack_priority = unit.pos.direction_to(tile)
						tasks.append(["attack", tile])

func move_to(tile, reach=0, _path=true):
	var distance = unit.pos.distance_to(tile)
	if reach == 0 and distance == 1 and tile.is_cols(unit.col):
		tasks = [["interact", tile]]
	else:
		if _path:
			if distance <= reach:
				return unit.pos
			n_cursor.position = G.pos_to_pixel(tile)
			n_cursor.show()
			path_to(tile, reach)
			remove_steps()
			show_steps()
		else:
			path_to(tile, reach)

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
	var buff_data = unit.buffs.to_data()
	if remove_buffs:
		unit.buffs.clear()
	var ally_data = []
	for ally in allies:
		if ally != null and is_instance_valid(ally):
			ally_data.append(ally.item_name)
	var save_dict = {
		"id": p_id,
		"unit": unit.item_name,
		"unit_data": unit.dat.v,
		"unit_buff": buff_data,
		"ally_data": ally_data,
	}
	if G.world.map_name == "base":
		save_dict["position"] = unit.pos.to_array()
	if unit.dat.g("type") != "other":
		save_dict = unit.update_save_data(save_dict)
	return save_dict

func load_data(_data):
	var player_pos = _data.get("position")
	if player_pos == null:
		player_pos = G.field.get_spawn_point()
	else:
		player_pos = G.field.tiles[player_pos[1]][player_pos[0]]
	var player_unit = G.cmd([["make", _data.unit, player_pos]])
	player_unit.possess(self)
	player_unit.dat.load_data(_data.unit_data)
	if player_unit.dat.g("type") != "other":
		player_unit.load_item_data(_data)
		player_unit.set_seed()
	player_unit.buffs.from_data(_data.unit_buff)
	var adjs
	var adj = unit.pos
	for i in _data.ally_data:
		adjs = adj.get_available_adjacents("0011")
		adj = R.r_arr(adjs)
		if adj == null:
			adj = unit.pos
		var ally = G.cmd([["make", i, adj]])
		allies.append(ally)

func on_map_clear():
	for ally in allies:
		ally.remove()
	allies = []
