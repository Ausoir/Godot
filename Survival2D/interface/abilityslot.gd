extends Panel

const MODE_NORMAL = 0
const MODE_SELECTED = 1
const MODE_COOLDOWN = 2
const MODE_ACTIVE = 3

var mode = MODE_NORMAL
var skill_index: int
var stylebox = get_stylebox("panel", "")
var skill
var skill_type

func set_index(p):
	skill_index = p
	$Label.text = str(p + 1)

func set_mode(p):
	if p == 3:
		$Overlay.show()
		stylebox.region_rect.position.x = 1088
	elif p == 2:
		$Overlay.hide()
		stylebox.region_rect.position.x = 1024
	elif p == 1:
		$Overlay.hide()
		stylebox.region_rect.position.x = 1056
	else:
		stylebox.region_rect.position.x = 1088
	mode = p

func assign(p):
	skill = p
	var skill_data = G.data.skill_data.get(p)
	if skill_data == null:
		return false
	skill_type = skill_data.type
	var img_pos = G.data.get_tile_image_pos(skill_data.img)
	get_node("Sprite").region_rect.position = img_pos

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == BUTTON_LEFT:
				activate()

func activate():
	if mode == MODE_NORMAL:
		if skill_type == "projectile" or skill_type == "smite":
			set_mode(MODE_SELECTED)
			G.you.aim_ability(skill_index)
		elif skill_type == "buff":
			G.you.perform_ability(skill_index)
	elif mode == MODE_ACTIVE:
		G.you.perform_ability(skill_index)

func _update_cooldown(cd):
	if cd > 0:
		set_mode(MODE_COOLDOWN)
		set_modulate(Color.webgray)
	else:
		set_mode(MODE_NORMAL)
		set_modulate(Color.white)
