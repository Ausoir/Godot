extends Control

onready var title = $Control/Title
onready var content = $Control/Content

func display(header, desc):
	rect_size.y = 32
	title.set_text(header.capitalize())
	content.set_text(desc)
	rect_global_position = get_global_mouse_position()
	if rect_size.x + rect_position.x > G.ui.screen_size.x:
		rect_global_position.x -= rect_size.x
	if rect_size.y + rect_position.y > G.ui.screen_size.y:
		rect_global_position.y -= rect_size.y
	show()
