extends "res://objects/units/controller.gd"

const Step = preload("res://objects/units/Step.tscn")

onready var camera = $Camera
onready var sight = $Sight
onready var cursor = $Cursor
onready var steps = $Steps

var screen_size = Vector2(1, 1)
var mouse_pos = Vector2()

var enabled = true


func _input(event: InputEvent):
	if event is InputEventMouseMotion:
		mouse_pos = event.global_position
	elif enabled and !locked:
		if event is InputEventMouseButton:
			screen_size = get_viewport().size / 2
			mouse_pos = event.global_position
			var pos = get_cursor_position()
			if event.pressed:
				if event.button_index == BUTTON_WHEEL_UP:
					camera.zoom *= .9
					sight.scale *= .9
				elif event.button_index == BUTTON_WHEEL_DOWN:
					camera.zoom *= 1.1
					sight.scale *= 1.1
				elif event.button_index == BUTTON_MIDDLE: #Teleport to cursor
					screen_size = get_viewport().size / 2
					unit.position = Vector2(mouse_pos.x + unit.position.x - screen_size.x,
											mouse_pos.y + unit.position.y - screen_size.y)
				elif Input.is_action_just_pressed("move"):
					var mousetarget = G.pixel_to_pos(pos)
					cursor.position = G.pos_to_pixel(mousetarget)
					cursor.show()
					path_to(mousetarget)
					remove_steps()
					show_steps()
				elif Input.is_action_just_pressed("use"):
					$menu.display("craft", unit)
			elif Input.is_action_just_released("move"):
				cursor.hide()
	elif event is InputEventMouseButton:
		if event.pressed and Input.is_action_just_pressed("use"):
			$menu.clear()

func _process(_delta):
	if unit:
		camera.position = unit.position
		sight.position = unit.position
	# cancel action
	if enabled and !locked:
		var pos = get_cursor_position()
		if Input.is_action_pressed("use") and unit.task[0] == "attack":
			unit.task[2] = pos

func get_cursor_position():
	var zoom = min(screen_size.x / 512, screen_size.y / 300)
	return Vector2((mouse_pos.x - screen_size.x)/zoom + camera.position.x,
					(mouse_pos.y - screen_size.y)/zoom + camera.position.y)

func on_turn():
	.on_turn()
	remove_steps()
	show_steps()

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
			var p = (task[1] - last_step).angle()
			step.rotate(p)
			last_step = task[1]
			steps.add_child(step)

func aggro(npcs):
	var unit = $unit
	for i in npcs:
		i.find_player(unit)
