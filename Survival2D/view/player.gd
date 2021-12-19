extends "res://objects/units/controller.gd"

const Step = preload("res://view/Step.tscn")
const Vision = preload("res://view/vision.gd")

var vision = Vision.new()
onready var camera = $Camera
onready var sight = $Sight
onready var cursor = $Cursor
onready var steps = $Steps

var screen_size = Vector2(1, 1)
var mouse_pos = Vector2()
var last_pos

var enabled = true


func _ready():
	pathing.iterations = 28
	last_pos = G.field.tiles[0][0]

func assign(p):
	.assign(p)
	G.ui.update_equipables(unit.dat.g("equip"))
	G.ui.update_inventory(unit.equipment)
	if get_parent() == null:
		G.world.players.add_child(self)

func unassign():
	.unassign()
	if get_parent() == G.world.players:
		G.world.players.remove_child(self)

func _input(event: InputEvent):
	if G.ui.on:
		if Input.is_action_just_pressed("menu"):
			G.ui.clear()
	else:
		if event is InputEventMouseMotion:
			mouse_pos = get_cursor_position(event.global_position)
		elif event is InputEventKey:
			if Input.is_action_just_pressed("quit"):
				get_tree().quit()
			elif Input.is_action_just_pressed("restart"):
				restart()
			elif Input.is_action_just_pressed("ui_fullscreen"):
				OS.window_fullscreen = !OS.window_fullscreen
			elif Input.is_action_just_pressed("menu"):
				G.cmd([["menu", ""]], unit)
		elif enabled and !locked:
			if event is InputEventMouseButton:
				screen_size = get_viewport().size / 2
				mouse_pos = get_cursor_position(event.global_position)
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
						screen_size = get_viewport().size / 2
						unit.position = Vector2(mouse_pos.x + unit.position.x - screen_size.x,
												mouse_pos.y + unit.position.y - screen_size.y)
					elif Input.is_action_just_pressed("move"):
						var mousetarget = G.pixel_to_pos(mouse_pos)
						move_to(mousetarget)
					elif Input.is_action_just_pressed("use"):
						var mousetarget = G.pixel_to_pos(mouse_pos)
						var tile = G.field.get_tile(mousetarget.x, mousetarget.y)
						if tile:
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

func restart():
	unit.die()
	print("Player:restart: ", get_tree().change_scene("res://lobby.tscn"))

func _process(_delta):
	if unit:
		camera.position = unit.position
		sight.position = unit.position
	# cancel action
#	if enabled and !locked:
#		var pos = get_cursor_position()
#		if Input.is_action_pressed("use") and unit.task[0] == "attack":
#			unit.task[2] = pos

func get_cursor_position(mouse):
	var zoom = min(screen_size.x / 512, screen_size.y / 300) / camera.zoom.x
	return Vector2((mouse.x - screen_size.x)/zoom + camera.position.x,
					(mouse.y - screen_size.y)/zoom + camera.position.y)

func on_turn():
	.on_turn()
	remove_steps()
	show_steps()
	if last_pos != unit.pos:
		vision.update(last_pos, unit.pos)
		last_pos = unit.pos
		G.ui.clear()

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
		G.ui.search_inventory(tile)

func move_to(mousetarget, dist=0):
	cursor.position = G.pos_to_pixel(mousetarget)
	cursor.show()
	path_to(mousetarget, dist)
	remove_steps()
	return show_steps()
