extends "res://classes/properties.gd"

func _init(p).(p):
	pass

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

func get_active_slots():
	var slots = 0
	var actives = g("skills", [])
	for i in range(actives.size()):
		var data = G.data.skill_data.get(actives[i])
		if data != null:
			slots += data.get("cost", 0)
	return slots

func can_learn(p):
	return g("intelligence", 1) >= get_active_slots() + p
