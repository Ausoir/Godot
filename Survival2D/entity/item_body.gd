extends StaticBody2D

var item_type = "item"

func cast_ray(to, exc, mask=1):
	var space_state = get_world_2d().direct_space_state
	var result = space_state.intersect_ray(global_position, to, exc, mask)
	return result
