extends Node

var screen_size = Vector2()
var mouse_pos = Vector2()

func _input(event):
	if event is InputEventMouseButton:
		var unit = get_node("unit")
		if event.pressed:
			mouse_pos = event.global_position
			screen_size = get_viewport().size / 2
			unit.set_goal(Vector2(mouse_pos.x + unit.position.x - screen_size.x,
								mouse_pos.y + unit.position.y - screen_size.y))
		else:
			unit.set_goal(unit.position)
	elif event is InputEventMouseMotion:
		mouse_pos = event.global_position

func _physics_process(_delta):
	var unit = get_node("unit")
	get_node("Camera2D").position = unit.position
	if Input.is_action_pressed("move"):
		unit.set_goal(Vector2(mouse_pos.x + unit.position.x - screen_size.x,
							mouse_pos.y + unit.position.y - screen_size.y))
