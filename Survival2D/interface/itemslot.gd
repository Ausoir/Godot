extends Panel

const SLOT_DISABLED = 0
const SLOT_LIGHT = 1
const SLOT_FULL = 2

var stylebox = get_stylebox("panel", "")
var item
var allow_type = SLOT_DISABLED
var sprite

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
	sprite = Sprite.new()
	sprite.texture = item.texture
	sprite.region_enabled = true
	sprite.region_rect = item.region_rect
	sprite.position = rect_position + rect_size / 2
	add_child(sprite)
