extends Panel

export var index = 0
export var active = false
var stylebox = get_stylebox("panel", "")
var is_item = false
var skill
var skill_data
var dragged_sprite

func set_is_item(p):
	is_item = p
	if p:
		$Sprite.modulate = Color.darkgoldenrod
	else:
		$Sprite.modulate = Color.white

func assign(p):
	skill = p
	if skill != null:
		skill_data = G.data.skill_data.get(skill)
		if skill_data == null:
			return false
		var item_sprite = get_node("Sprite")
		item_sprite.texture = G.data.get_image(skill_data.get("img"))
		item_sprite.show()
		$Label.set_text(str(skill_data.get("cost", 0)))
	else:
		get_node("Sprite").hide()
		$Label.set_text("")
	set_is_item(false)

func unassign():
	if skill != null:
		var item_sprite = get_node("Sprite")
		var r = {"drag":skill,"type":"skill", "item":skill, "index":index, "active":active}
		skill = null
		item_sprite.hide()
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
			G.you.unit.swap_skills("actives", item.index, index)
		else:
			G.you.unit.swap_skills("skills", item.index, index)
	elif active:
		G.you.unit.activate_skill(item.index)
	else:
		G.you.unit.deactivate_skill(item.index)
	G.ui.menu.set_drag_item(null)
	G.ui.menu.update_skills()
