extends KinematicBody2D

var parent
var vel = Vector2()
var last_col

func _physics_process(_delta):
	move_and_slide(vel)
	parent.position = global_position
	position.x = 0
	position.y = 0
	vel *= .9

func get_collider(faction):
	for i in get_slide_count():
		var collision = get_slide_collision(i)
		if collision.collider is KinematicBody2D:
			var item = collision.collider.get_parent()
			if item.faction != faction:
				return item

func check_ray(to, exc, mask=1):
	var space_state = get_world_2d().direct_space_state
	var result = space_state.intersect_ray(global_position, to, exc, mask)
	return result.empty()

func cast_ray(to, exc, mask=1):
	var space_state = get_world_2d().direct_space_state
	var result = space_state.intersect_ray(global_position, to, exc, mask)
	if !result.empty():
		return result.position
	return to

func cast_col_ray(to, exc, mask=1):
	var space_state = get_world_2d().direct_space_state
	var result = space_state.intersect_ray(global_position, to, exc, mask)
	return result

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton \
	and Input.is_action_just_pressed("use"):
		G.you.on_item_click(parent)
