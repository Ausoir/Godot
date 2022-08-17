extends KinematicBody2D

var item_type = "unit"
var parent
var vel = Vector2()
var last_col
var last_touch
var stop = true
var moved_dist

func _physics_process(_delta):
	moved_dist = move_and_slide(vel)
	last_col = get_last_slide_collision()
	if last_col != null:
		last_touch = last_col.collider.position
		var itype = last_col.collider.get("item_type")
		if itype != null:
			last_col = last_col.collider.get_parent()
			if parent.delay == 0:
				parent.controller.on_touch(last_col)
		else:
			last_col = null
	else:
		last_touch = null
	parent.position = global_position
	position.x = 0
	position.y = 0
	if stop:
		vel *= .9

func stop_move():
	stop = true
	if parent.n_animation.current_animation == "walk":
		parent.n_animation.play("idle", -1)

func check_overlap():
	if last_col != null:
		var tpos = last_col.global_position
		var diff = tpos - global_position
		if diff.length_squared() < 64:
			position += Vector2(32, 32) * diff.normalized()

func cast_ray(to, exc, mask=1):
	var space_state = get_world_2d().direct_space_state
	var result = space_state.intersect_ray(global_position, to, exc, mask)
	return result
