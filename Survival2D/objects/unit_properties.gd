extends "res://classes/properties.gd"

func _init(p).(p):
	pass

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
