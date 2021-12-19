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

func make_disabled():
	stylebox.region_rect.position.x = 992
	allow_type = SLOT_DISABLED

func make_light():
	stylebox.region_rect.position.x = 960
	allow_type = SLOT_LIGHT

func make_full():
	stylebox.region_rect.position.x = 928
	allow_type = SLOT_FULL

func assign(p):
	item = p
	item_sprite = Sprite.new()
	item_sprite.texture = item.texture
	item_sprite.region_enabled = true
	item_sprite.region_rect = item.region_rect
	item_sprite.position = rect_position + rect_size / 2
	add_child(item_sprite)
	if tile:
		tile.add_item(item)

func unassign():
	if tile:
		tile.remove_item(item)
	item_sprite.queue_free()
	remove_child(item_sprite)
	item = null

func _on_mouse_entered():
	G.ui.describe(item)

func _on_mouse_exited():
	G.ui.description.hide()

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == BUTTON_LEFT:
				G.ui.on_drag(self)
			elif event.button_index == BUTTON_RIGHT:
				G.ui.on_quick_drag(self)
