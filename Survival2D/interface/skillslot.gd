extends RichTextLabel

var index = 0
var is_item = false
var skill
var skill_data

func set_is_item(p):
	is_item = p
	if p:
		modulate = Color.darkgoldenrod
	else:
		modulate = Color.white

func assign(p, idx):
	skill = p.name
	skill_data = p
	index = idx
	set_bbcode("[" + str(skill_data.get("cost", 0)) + "] " + skill.capitalize())
	set_is_item(false)

func unassign():
	if skill != null:
		var r = {"drag":skill.capitalize(),"type":"skill", "item":skill, "index":index}
		queue_free()
		get_parent().remove_child(self)
		return r

func _on_mouse_entered():
	if skill != null:
		G.ui.describe("skill", skill, skill_data)

func _on_mouse_exited():
	G.ui.description.hide()

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.is_pressed() and !is_item:
			if get_global_rect().has_point(G.ui.mouse_pos):
				if G.ui.menu.drag_item != null and G.ui.menu.drag_item.type == "skill":
					place_to(G.ui.menu.drag_item)
				else:
					take_from()
		G.ui.description.hide()

func take_from():
	if skill != null:
		var r = unassign()
		if r:
			G.ui.menu.set_drag_item(r)

func place_to(item):
	swap_skills(item.index, index)
	G.ui.menu.set_drag_item(null)
	G.ui.menu.update_skills()

func swap_skills(idx1, idx2):
	var skills = G.you.unit.skills
	if idx2 >= skills.size():
		var prim = skills[idx1]
		skills.remove(idx1)
		skills.append(prim)
	else:
		var prim = skills[idx1]
		skills[idx1] = skills[idx2]
		skills[idx2] = prim
