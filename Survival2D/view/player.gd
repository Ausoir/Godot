extends "res://objects/units/controller.gd"

const Step = preload("res://view/Step.tscn")
const Vision = preload("res://view/vision.gd")

var vision = Vision.new()
onready var camera = $Camera
onready var sight = $Sight
onready var cursor = $Cursor
onready var steps = $Steps

var aiming = -1
var screen_size = Vector2(1, 1)
var last_pos

var enabled = true


func _ready():
	pathing.iterations = 28
	last_pos = unit.pos
	vision.update(unit.pos, last_pos)

func assign(p):
	.assign(p)
	p.faction = 1
	if unit.dat.g("bodyparts") != null:
		G.ui.update_equipables(unit.dat.g("bodyparts"))
		G.ui.update_inventory()
	if get_parent() == null:
		G.world.players.add_child(self)
	vision.sight_range = unit.vars.g("perception", 18)

func unassign():
	.unassign()
	if get_parent() == G.world.players:
		G.world.players.remove_child(self)

func _on_input(event: InputEvent):
	if enabled and !locked:
		if event is InputEventMouseButton:
			screen_size = get_viewport().size / 2
			var mouse_pos = get_cursor_position(event.global_position)
			if event.pressed:
				if event.button_index == BUTTON_WHEEL_UP:
					if camera.zoom.x > .5:
						camera.zoom *= .8
						sight.scale *= .8
				elif event.button_index == BUTTON_WHEEL_DOWN:
					if camera.zoom.x < 2:
						camera.zoom *= 1.2
						sight.scale *= 1.2
				elif event.button_index == BUTTON_MIDDLE: #Teleport to cursor
					pass
				elif Input.is_action_just_pressed("move"):
					var mousetarget = G.pixel_to_pos(mouse_pos)
					var destination = move_to(mousetarget)
					if destination.distance_to(mousetarget) > 0:
						tasks.append(["interact", destination.direction_to(mousetarget)])
					else:
						tasks.append(["interact", -1])
				elif Input.is_action_just_pressed("use"):
					var mousetarget = G.pixel_to_pos(mouse_pos)
					var tile = G.field.get_tile(mousetarget.x, mousetarget.y)
					if tile:
						if aiming != -1:
							target = tile
							stop_aim()
							tasks.append(["ability", aiming])
						else:
							if !tile.items.empty():
								var destination = move_to(mousetarget, 1)
								tasks.append(["interact", destination.direction_to(mousetarget)])
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

func _process(_delta):
	if unit:
		camera.position = unit.position
		sight.position = unit.position

func get_cursor_position(mouse):
	var zoom = min(screen_size.x / 512, screen_size.y / 300) / camera.zoom.x
	return Vector2((mouse.x - screen_size.x)/zoom + camera.position.x,
					(mouse.y - screen_size.y)/zoom + camera.position.y)

func on_turn():
	var cds = !unit.cooldowns.empty()
	.on_turn()
	remove_steps()
	show_steps()
	if last_pos != unit.pos:
		vision.update(last_pos, unit.pos)
		last_pos = unit.pos
		if G.ui.on:
			G.ui.clear()
	if cds:
		G.ui._update_cooldowns(unit.cooldowns)

func on_update_equipment():
	G.ui.update_inventory()

func remove_steps():
	for child in steps.get_children():
		steps.remove_child(child)
		child.queue_free()

func show_steps():
	var last_step = unit.pos
	for task in tasks:
		if task[0] == "move":
			var new_pos = last_step.get_adjacent(task[1])
			var step = Step.instance()
			step.position = G.pos_to_pixel(new_pos.to_vector())
			var p = (new_pos.to_vector() - last_step.to_vector()).angle()
			step.rotate(p)
			steps.add_child(step)
			last_step = new_pos
	return last_step

func aggro(npcs):
	var unit = $unit
	for i in npcs:
		i.find_player(unit)

func interact_tile(tile):
	if G.ui.on:
		G.ui.clear()
	else:
		cursor.hide()
		if !tile.items.empty():
			var item = tile.get_priority_item([unit])
			if item != null:
				if item.item_type == "unit":
					if item.faction == unit.faction:
						unit.swap(item)
					else:
						tasks.append(["attack", unit.pos.direction_to(tile)])
				elif item.item_type == "object":
					pass
				elif item.item_type == "item":
					G.ui.search_inventory(tile)

func move_to(mousetarget, dist=0):
	if unit.pos.distance_to(mousetarget) <= dist:
		return unit.pos
	cursor.position = G.pos_to_pixel(mousetarget)
	cursor.show()
	path_to(mousetarget, dist)
	remove_steps()
	return show_steps()

func aim_ability(idx):
	Input.set_default_cursor_shape(Input.CURSOR_CROSS)
	aiming = idx

func stop_aim():
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	aiming = -1
	unit.dirty = true

func perform_ability(idx):
	tasks.append(["ability", idx])
