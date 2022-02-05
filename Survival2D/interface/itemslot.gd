extends Panel

const SLOT_DISABLED = 0
const SLOT_LIGHT = 1
const SLOT_FULL = 2

export var part: String = "none"
var stylebox = get_stylebox("panel", "")
var tile
var item
var allow_type = SLOT_FULL
var dragged_sprite

func _ready():
	stylebox = stylebox.duplicate() #Make unique
	add_stylebox_override("panel", stylebox)

func make_mode(p):
	if p == 2:
		stylebox.texture = G.data.get_image("gui/slot_full")
		allow_type = SLOT_FULL
	elif p == 1:
		stylebox.texture = G.data.get_image("gui/slot_limited")
		allow_type = SLOT_LIGHT
	else:
		stylebox.texture = G.data.get_image("gui/slot_disabled")
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
	var slot_sprite = get_node("Sprite")
	var item_sprite = item.dat.g("sprite")
	if item_sprite != null:
		slot_sprite.texture = G.data.get_image(item_sprite)
	else:
		slot_sprite.texture = p.texture
		if p is Sprite:
			slot_sprite.region_enabled = p.region_enabled
			slot_sprite.region_rect = p.region_rect
	slot_sprite.show()
	if has_node("Overlay"):
		$Overlay.hide()
	return r

func unassign():
	if item:
		var item_sprite = get_node("Sprite")
		var r = {"type":"item", "item":item, "sprite":item_sprite.duplicate()}
		if tile:
			tile.remove_item(item)
		item = null
		item_sprite.hide()
		if has_node("Overlay"):
			$Overlay.show()
		return r

func _on_mouse_entered():
	if item != null:
		G.ui.describe("item", item.item_name, item.dat.v)

func _on_mouse_exited():
	G.ui.description.hide()

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == BUTTON_LEFT:
				if G.ui.drag_item != null and G.ui.drag_item.type == "item":
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
			if part == "inv" and G.you.unit.auto_equip(item):
				take_from()
				G.ui.set_drag_item(null)
			elif part != "none" and G.you.unit.store(item):
				take_from()
				G.ui.set_drag_item(null)
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
				G.ui.set_drag_item(r)

func place_to(pitem):
	var swap = false
	if item != null:
		G.ui.set_drag_item(null)
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
	elif part[0] == "#":
		if !G.you.unit.sheathe(int(part[1]), pitem.item):
			return false
	else:
		if !G.you.unit.equip(part, pitem.item):
			return false
	if !swap:
		G.ui.set_drag_item(null)
	return true
