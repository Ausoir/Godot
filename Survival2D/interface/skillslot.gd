extends Panel

const SLOT_DISABLED = 0
const SLOT_LIGHT = 1
const SLOT_FULL = 2

var stylebox = get_stylebox("panel", "")
var skill

func assign(p):
	skill = G.data.skill_data.get(p)
	var img_pos = G.data.image_map.get(skill.img)
	get_node("Sprite").region_rect.position = Vector2(img_pos.x, img_pos.y)

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == BUTTON_LEFT:
				G.ui.on_drag(self)
