extends Control

onready var title = $Control/Title
onready var content = $Control/Content

func display(item):
	title.set_text(item.item_name.capitalize())
	content.set_text(item.dat.g("desc"))
	rect_global_position = get_global_mouse_position()
	show()
