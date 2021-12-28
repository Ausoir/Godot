extends Panel

const SLOT_DISABLED = 0
const SLOT_LIGHT = 1
const SLOT_FULL = 2

var stylebox = get_stylebox("panel", "")
var tile
var item
var allow_type = SLOT_FULL
var item_sprite
var dragged_sprite
export var part: String = "none"

func make_mode(p):
	if p == 2:
		stylebox.region_rect.position.x = 928
		allow_type = SLOT_FULL
	elif p == 1:
		stylebox.region_rect.position.x = 960
		allow_type = SLOT_LIGHT
	else:
		stylebox.region_rect.position.x = 992
		allow_type = SLOT_DISABLED

func is_item_valid(p):
	var valid_part = p.dat.g("part", "any") == part
	if part == "any":
		valid_part = true
	var valid_size = p.dat.g("size", 2) <= allow_type
	return valid_part and valid_size

func assign(p):
	var r
	if item != null:
		r = item
	item = p
	item_sprite = Sprite.new()
	item_sprite.texture = item.texture
	item_sprite.region_enabled = true
	item_sprite.region_rect = item.region_rect
	item_sprite.position = rect_size / 2
	add_child(item_sprite)
	if tile != null:
		tile.add_item(item)
	return r

func unassign():
	if item:
		var t = [item, item_sprite]
		if tile:
			tile.remove_item(item)
		item_sprite.queue_free()
		remove_child(item_sprite)
		item = null
		return t

func _on_mouse_entered():
	G.ui.describe(item)

func _on_mouse_exited():
	G.ui.description.hide()

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == BUTTON_LEFT:
				if G.ui.drag_item != null:
					place_to(G.ui.drag_item)
				else:
					take_from()
			elif event.button_index == BUTTON_RIGHT:
				on_quick_action()
			G.you.unit.update()
			G.ui.update_inventory()

func on_quick_action():
	if item != null:
		if tile == null:
			var t = item
			take_from()
			for child in G.ui.equipment.get_children():
				if child.place_to(t):
					return
		else:
			if G.you.unit.store(item):
				unassign()

func take_from():
	if item != null:
		var taken = part == "none"
		taken = taken or (part == "inv" and G.you.unit.unstore(item))
		taken = taken or (part[0] == "#" and G.you.unit.unsheathe(int(part[1])))
		taken = taken or G.you.unit.unequip(part) != null
		if taken:
			var r = unassign()
			if r:
				G.ui.set_drag_item(r[0], r[1])

func place_to(pitem):
	var swap = false
	if item != null:
		G.ui.set_drag_item(null, null)
		take_from()
		swap = true
	if part == "none":
		assign(pitem)
	elif part == "inv":
		if !G.you.unit.store(pitem):
			return false
	elif part[0] == "#":
		if !G.you.unit.sheathe(int(part[1]), pitem):
			return false
	else:
		if !G.you.unit.equip(part, pitem):
			return false
	if !swap:
		G.ui.set_drag_item(null, null)
	return true
