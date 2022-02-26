extends Node

var parent

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton \
	and Input.is_action_just_pressed("use"):
		G.you.on_item_click(parent)
