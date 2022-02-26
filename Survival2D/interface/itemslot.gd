extends RichTextLabel

const SLOT_DISABLED = 0
const SLOT_LIGHT = 1
const SLOT_FULL = 2

var part = "none"
var allow_type = SLOT_FULL
var tile
var item

func make_mode(ppart, p):
	var txt = ""
	part = ppart
	allow_type = p
	if p == 2:
		txt = get_part_text() + "---"
	elif p == 1:
		txt = get_part_text() + "-"
	else:
		txt = get_part_text() + "XXX"
	set_bbcode(txt)

func check_weight(_item):
	if G.you.unit.can_carry(item.dat.g("weight", 0)):
		return true
	else:
		G.msg("Too heavy!")
		return false

func get_part_text():
	return "[color=#874]" + part.capitalize() + "[/color]: "

func assign(p):
	var txt = ""
	var r
	if item != null:
		r = item
	item = p
	if part == "none":
		txt = item.item_name.capitalize()
	elif part == "inv":
		txt = item.item_name.capitalize()
	else:
		txt = get_part_text() + item.item_name.capitalize()
	set_bbcode(txt)
	return r

func unassign():
	if item:
		var r = {"drag":item.item_name.capitalize(),"type":"item", "item":item}
		if tile:
			tile.remove_item(item)
		item = null
		make_mode(part, allow_type)
		return r

func _on_mouse_entered():
	if item != null:
		G.ui.describe("item", item.get_display_name(), item.dat.v)

func _on_mouse_exited():
	G.ui.description.hide()

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == BUTTON_LEFT:
				if G.ui.menu.drag_item != null and G.ui.menu.drag_item.type == "item":
					place_to(G.ui.menu.drag_item)
				else:
					take_from()
			elif event.button_index == BUTTON_RIGHT:
				on_quick_action()
			G.you.unit.update()
			G.ui.menu.update_inventory()
		G.ui.description.hide()

func on_quick_action():
	if item != null:
		if tile == null:
			if part == "inv" and G.you.unit.auto_equip(item):
				take_from()
				G.ui.menu.set_drag_item(null)
			elif part != "none" and G.you.unit.store(item):
				take_from()
				G.ui.menu.set_drag_item(null)
		else:
			if check_weight(item) and G.you.unit.store(item):
				unassign()

func take_from():
	if item != null and check_weight(item):
		var taken = part == "none"
		taken = taken or (part == "inv" and G.you.unit.unstore(item))
		taken = taken or G.you.unit.unequip(part) != null
		if taken:
			var r = unassign()
			if r:
				G.ui.menu.set_drag_item(r)

func place_to(pitem):
	var swap = false
	if item != null:
		G.ui.menu.set_drag_item(null)
		take_from()
		swap = true
	if tile != null:
		pitem.item.place(tile)
		assign(pitem.item)
	elif part == "none":
		assign(pitem.item)
	elif part == "inv":
		if !G.you.unit.store(pitem.item):
			return false
	else:
		if !G.you.unit.equip(part, pitem.item):
			return false
	if !swap:
		G.ui.menu.set_drag_item(null)
	return true
