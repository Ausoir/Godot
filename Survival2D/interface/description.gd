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

func array_to_string(arr):
	var r = ""
	var prefix = ""
	for i in arr:
		r += prefix + i.capitalize()
		prefix = ", "
	return r

func display_item(header, item):
	var desc = ""
	if "part" in item:
		if item.part != "item":
			desc += "[color=#335]Armor ("+ str(item.part) +")[/color]\n"
		desc = "Weight: "+ str(item.get("weight", 0)) +"\n"
	else:
		var cut = item.get("cut", 0)
		if cut != 0:
			desc += "[color=#C66]Cut Damage: "+ str(cut) +"[/color]\n"
		var nutrition = item.get("nutrition", 0)
		if nutrition != 0:
			desc += "[color=#F94]Nutrition: "+ str(cut) +"[/color]\n"
		var skills = item.get("skills", [])
		if !skills.empty():
			desc += "[color=#56A]Skills: "+ array_to_string(skills) +"[/color]\n"
		var abilities = item.get("abilities", [])
		if !abilities.empty():
			desc += "[color=#84A]Abilities: "+ array_to_string(abilities) +"[/color]\n"
	var value = item.get("value", 0)
	if value != 0:
		desc += "[color=#FB0]Value: "+ str(value) +"[/color]\n"
	for i in G.STATS:
		var stat = item.get(i)
		if stat != null:
			desc += "[color=#CA6]"+ i.capitalize() +": " + str(stat) + "[/color]\n"
	var uses = item.get("uses", 0)
	if uses > 0:
		desc += "[color=#1B9]"+ str(uses) +" Uses[/color]\n"
	desc += item.get("desc", "")
	display(header, desc)

func display_skill(header, skill):
	var desc = "[color=#FB3]"+ str(skill.get("chance", 100)) +"% Chance[/color]\n"
	if "block" in skill:
		desc += "[color=#CC3]"+ str(skill.block) +" Block[/color]\n"
	desc += "[color=#1B9]"+ str(skill.get("delay", 0)) +" Turns[/color]\n"
	if "desc_dmg" in skill:
		desc += "[color=red]"+ skill.desc_dmg +"[/color]\n"
	desc += skill.desc
	display(header, desc)
