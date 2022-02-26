extends RichTextLabel

var index = 0
var active = false
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
	skill = p
	skill_data = G.data.skill_data.get(p)
	index = idx
	set_bbcode("[" + str(skill_data.get("cost", 0)) + "] " + skill.capitalize())
	set_is_item(false)

func unassign():
	if skill != null:
		var r = {"drag":skill.capitalize(),"type":"skill", "item":skill, "index":index, "active":active}
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
		if event.pressed and !is_item:
			if event.button_index == BUTTON_LEFT:
				if G.ui.menu.drag_item != null and G.ui.menu.drag_item.type == "skill":
					place_to(G.ui.menu.drag_item)
				else:
					take_from()
			elif event.button_index == BUTTON_RIGHT:
				on_quick_action()
		G.ui.description.hide()

func on_quick_action():
	if skill != null:
		var t = skill
		take_from()
		for child in G.ui.menu.tab_skill_inactive.get_children():
			if child.index == -1:
				child.place_to(t)
				return

func take_from():
	if skill != null:
		var r = unassign()
		if r:
			G.ui.menu.set_drag_item(r)

func place_to(item):
	if active == item.active:
		if active:
			G.you.unit.dat.swap_skills("actives", item.index, index)
		else:
			G.you.unit.dat.swap_skills("skills", item.index, index)
	elif active:
		G.you.unit.dat.deactivate_skill(index)
		G.you.unit.dat.activate_skill(item.index)
	else:
		G.you.unit.dat.deactivate_skill(item.index)
		G.you.unit.dat.activate_skill(index)
	G.ui.menu.set_drag_item(null)
	G.ui.menu.update_skills()
