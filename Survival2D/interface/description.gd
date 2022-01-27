extends Control

onready var title = $Control/Title
onready var content = $Control/Content

func display(header, desc):
	rect_size.y = 32
	title.set_text(header.capitalize())
	content.set_bbcode(desc)
	show()
	rect_global_position = get_global_mouse_position()
	rect_global_position.x = min(rect_global_position.x, G.ui.screen_size.x - rect_size.x)
	rect_global_position.y = min(rect_global_position.y, G.ui.screen_size.y - rect_size.y)

func display_item(header, item):
	display(header, item.dat.g("desc"))

func display_skill(header, skill):
	var desc = "[color=#FB3]"+ str(skill.get("chance", 100)) +"% Chance[/color]\n"
	if "energy" in skill:
		desc += "[color=#CC3]"+ str(skill.energy) +" Energy[/color]\n"
	desc += "[color=#1B9]"+ str(skill.get("delay", 0)) +" Turns[/color]\n"
	if "desc_dmg" in skill:
		desc += "[color=red]"+ skill.desc_dmg +"[/color]\n"
	desc += skill.desc
	display(header, desc)
