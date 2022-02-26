extends "res://classes/properties.gd"

func _init(p).(p):
	pass

func fill_skills():
	var skillsize = g("skills", []).size()
	for _i in range(skillsize):
		if !activate_skill(0):
			return

func swap_skills(type, idx1, idx2):
	var skills = g(type, [])
	if idx2 >= skills.size():
		var prim = skills[idx1]
		skills.remove(idx1)
		skills.append(prim)
	else:
		var prim = skills[idx1]
		skills[idx1] = skills[idx2]
		skills[idx2] = prim
	a(type, skills)

func activate_skill(idx):
	var agility = g("agility", 1)
	var skills = g("skills", [])
	var skill = skills[idx]
	var skill_data = G.data.skill_data.get(skill)
	if get_active_slots()+skill_data.get("cost", 0) <= agility:
		skills.remove(idx)
		var actives = g("actives", [])
		actives.append(skill)
		a("actives", actives)
		a("skills", skills)
		return true

func deactivate_skill(idx):
	var actives = g("actives", [])
	var skills = g("skills", [])
	var active = actives[idx]
	actives.remove(idx)
	skills.append(active)
	a("actives", actives)
	a("skills", skills)

func get_active_slots():
	var slots = 0
	var actives = g("actives", [])
	for i in range(actives.size()):
		var data = G.data.skill_data.get(actives[i])
		if data != null:
			slots += data.get("cost", 0)
	return slots
