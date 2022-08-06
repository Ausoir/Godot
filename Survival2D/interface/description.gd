extends Control

onready var title = $Control/Title
onready var content = $Control/Content

func on_display(header, desc):
	rect_size.y = 32
	title.set_text(header.capitalize())
	content.set_bbcode(desc)
	show()
	rect_global_position.x = G.ui.screen_size.x - rect_size.x - 80
	rect_global_position.y = 0

func array_to_string(arr):
	var r = ""
	var prefix = ""
	for i in arr:
		r += prefix + i.capitalize()
		prefix = ", "
	return r

func display(type, header, subject):
	if type == "text":
		on_display(header, subject)
	elif type == "item":
		display_item(header, subject)
	elif type == "skill":
		display_skill(header, subject)
	elif type == "ability":
		display_ability(header, subject)

func display_item(header, item):
	var desc = ""
	var value = item.get("value", 0)
	if value != 0:
		desc += "[color=#FB0]$"+ str(value) +"[/color]\n"
	var weight = item.get("weight", -1)
	if weight != -1:
		desc += "[color=#888]Weight: "+ str(weight) +"[/color]\n"
	if "part" in item:
		if item.part != "item":
			desc += "[color=#229]Armor ("+ str(item.part) +")[/color]\n"
			var space = item.get("space", 0)
			if space != 0:
				desc += "[color=#86A]Storage: "+ str(space) +" items[/color]\n"
	else:
		var bash = item.get("bash", 0)
		if bash != 0:
			desc += "[color=#C84]Bash Damage: "+ str(bash) +"[/color]\n"
		var cut = item.get("cut", 0)
		if cut != 0:
			desc += "[color=#C48]Cut Damage: "+ str(cut) +"[/color]\n"
		var skills = item.get("skills", [])
		if !skills.empty():
			var skill_types = [[],[],[]]
			for skill in skills:
				var data = G.data.skill_data.get(skill)
				var trigger = data.get("trigger", 0)
				skill_types[trigger].append(skill)
			if !skill_types[0].empty():
				desc += "[color=#56A]Skills: "+ array_to_string(skill_types[0]) +"[/color]\n"
			if !skill_types[1].empty():
				desc += "[color=#84A]Abilities: "+ array_to_string(skill_types[1]) +"[/color]\n"
			if !skill_types[2].empty():
				desc += "[color=#996]Specials: "+ array_to_string(skill_types[2]) +"[/color]\n"
	for i in G.data.vars.stats:
		var s = G.data.vars.stats[i].name
		var stat = item.get(s)
		if stat != null:
			desc += "[color=#CA6]"+ s.capitalize() +": " + str(stat) + "[/color]\n"
	var uses = item.get("uses", 0)
	if uses > 0:
		desc += "[color=#1B9]"+ str(uses) +" Uses[/color]\n"
	desc += item.get("desc", "")
	on_display(header, desc)

func display_skill(header, skill):
	var desc = "[color=#FB3]"+ str(skill.get("chance", 1)*100) +"% Chance[/color]\n"
	if "block" in skill:
		desc += "[color=#CC3]"+ str(skill.block) +" Block[/color]\n"
	desc += "[color=#1B9]"+ str(skill.get("delay", 0)) +" Turns[/color]\n"
	if "desc_dmg" in skill:
		desc += "[color=red]"+ skill.desc_dmg +"[/color]\n"
	desc += skill.get("desc", "")
	on_display(header, desc)

func display_ability(header, skill):
	var desc = "[color=#1B9]"+ str(skill.get("delay", 0)) +" Turns[/color]\n"
	var dur = skill.get("duration", -1)
	if dur != -1:
		desc += "[color=#84A]"+ str(dur) +" Duration[/color]\n"
	var cd = skill.get("cooldown", -1)
	if cd != -1:
		desc += "[color=#56A]"+ str(cd) +" Cooldown[/color]\n"
	var desc2 = skill.get("desc2")
	if desc2 != null:
		desc += "[color=#888]"+ desc2 +"[/color]\n"
	desc += skill.get("desc", "")
	on_display(header, desc)
