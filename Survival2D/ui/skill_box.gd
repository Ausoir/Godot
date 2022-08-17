extends Node

export var active: bool


func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			if G.ui.menu.drag_item != null and G.ui.menu.drag_item.type == "skill":
				place_to(G.ui.menu.drag_item)

func place_to(item):
	var t = G.you.unit.dat
	t.swap_skills("skills", item.index, t.g("skills",[]).size())
	G.ui.menu.set_drag_item(null)
	G.ui.menu.update_skills()
