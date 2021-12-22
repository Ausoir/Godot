extends Panel

const SLOT_DISABLED = 0
const SLOT_LIGHT = 1
const SLOT_FULL = 2

var stylebox = get_stylebox("panel", "")
var tile
var item
var allow_type = SLOT_DISABLED
var item_sprite
var dragged_sprite
export var part: String = "none"

func make_disabled():
	stylebox.region_rect.position.x = 992
	allow_type = SLOT_DISABLED

func make_light():
	stylebox.region_rect.position.x = 960
	allow_type = SLOT_LIGHT

func make_full():
	stylebox.region_rect.position.x = 928
	allow_type = SLOT_FULL

func is_item_valid(p):
	var valid_part = p.dat.g("part", "any") == part
	if part == "any":
		valid_part = true
	var valid_size = p.dat.g("size", 2) <= allow_type
	return valid_part and valid_size

func assign(p):
	item = p
	item_sprite = Sprite.new()
	item_sprite.texture = item.texture
	item_sprite.region_enabled = true
	item_sprite.region_rect = item.region_rect
	item_sprite.position = rect_size / 2
	add_child(item_sprite)
	if tile != null:
		tile.add_item(item)

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
				on_quick_drag()

func on_quick_drag():
	if tile != null and item != null:
		if G.you.unit.store(item):
			unassign()
			G.ui.update_inventory()

func take_from():
	if item != null:
		var taken = part == "none"
		taken = taken or (part == "inv" and G.you.unit.unstore(item))
		taken = taken or (part[0] == "#" and G.you.unit.unsheathe(int(part[1])))
		taken = taken or G.you.unit.unequip(part)
		if taken:
			var r = unassign()
			if r:
				G.ui.set_drag_item(r[0], r[1])

func place_to(pitem):
	if part == "none":
		assign(pitem)
	elif part == "inv":
		if !G.you.unit.store(pitem):
			return
	elif part[0] == "#":
		if !G.you.unit.sheathe(int(part[1]), pitem):
			return
	else:
		if !G.you.unit.equip(part, pitem):
			return
	G.ui.set_drag_item(null, null)
