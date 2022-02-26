extends Node

export var active: bool


func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == BUTTON_LEFT:
				if G.ui.menu.drag_item != null and G.ui.menu.drag_item.type == "skill":
					place_to(G.ui.menu.drag_item)

func place_to(item):
	if active:
		if !item.active:
			G.you.unit.dat.activate_skill(item.index)
	else:
		if item.active:
			G.you.unit.dat.deactivate_skill(item.index)
	G.ui.menu.set_drag_item(null)
	G.ui.menu.update_skills()
