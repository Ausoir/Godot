extends "res://objects/units/controller.gd"

var screen_size = Vector2()
var mouse_pos = Vector2()

var enabled = true


func _input(event: InputEvent):
	var unit = $unit
	if event is InputEventMouseMotion:
		mouse_pos = event.global_position
	elif enabled and !unit.locked:
		if event is InputEventMouseButton:
			screen_size = get_viewport().size / 2
			mouse_pos = event.global_position
			var pos = Vector2(mouse_pos.x + unit.position.x - screen_size.x,
								mouse_pos.y + unit.position.y - screen_size.y)
			if event.pressed:
				if event.button_index == BUTTON_WHEEL_UP:
					$camera.zoom *= .9
					$sight.scale *= .9
				elif event.button_index == BUTTON_WHEEL_DOWN:
					$camera.zoom *= 1.1
					$sight.scale *= 1.1
				elif event.button_index == BUTTON_MIDDLE: #Teleport to cursor
					screen_size = get_viewport().size / 2
					unit.position = Vector2(mouse_pos.x + unit.position.x - screen_size.x,
											mouse_pos.y + unit.position.y - screen_size.y)
				elif Input.is_action_just_pressed("move"):
					unit.set_task(["move", -1, pos])
				elif Input.is_action_just_pressed("use"):
					if unit.weapon != null:
						unit.set_task(unit.weapon.get_action())
					else:
						$menu.display("craft", unit)
			elif Input.is_action_just_released("move"):
				if (mouse_pos - screen_size).length() < 32:
					unit.set_task(["drop", 5])
				else:
					unit.task[1] = 0
	elif event is InputEventMouseButton:
		if event.pressed and Input.is_action_just_pressed("use"):
			$menu.clear()


func _physics_process(_delta):
	var unit = $unit
	get_node("camera").position = unit.position
	get_node("sight").position = unit.position
	# cancel action
	if enabled and !unit.locked:
		var pos = Vector2(mouse_pos.x + unit.position.x - screen_size.x,
							mouse_pos.y + unit.position.y - screen_size.y)
		if Input.is_action_pressed("move"):
			unit.set_task(["move", -1, pos])
		elif Input.is_action_pressed("use") and unit.task[0] == "attack":
			unit.task[2] = pos


func aggro(npcs):
	var unit = $unit
	for i in npcs:
		i.find_player(unit)
