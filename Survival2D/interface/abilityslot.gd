extends Panel

const MODE_NORMAL = 0
const MODE_SELECTED = 1
const MODE_COOLDOWN = 2
const MODE_ACTIVE = 3

onready var overlay = $Overlay
var mode = MODE_NORMAL
var skill_index: int
var stylebox = get_stylebox("panel", "")
var skill
var skill_data
var skill_type
var skill_description

func set_index(p):
	skill_index = p
	$Label.text = str(p + 1)

func set_mode(p):
	if p == 3:
		overlay.hide()
		stylebox.texture = G.data.get_image("gui/skillslot_use")
	elif p == 2:
		overlay.hide()
		stylebox.texture = G.data.get_image("gui/skillslot_disabled")
	elif p == 1:
		overlay.show()
		stylebox.texture = G.data.get_image("gui/skillslot")
	else:
		overlay.hide()
		stylebox.texture = G.data.get_image("gui/skillslot")
	mode = p

func assign(p, type):
	skill = p
	if type == "skill":
		skill_data = G.data.skill_data.get(p)
		if skill_data == null:
			return false
		skill_type = skill_data.get("target")
		skill_description = skill_data.get("desc")
		$Sprite.texture = G.data.get_image(skill_data.img)
	elif type == "item":
		skill_data = G.data.item_data.get(p)
		skill_type = "item"
		skill_description = skill.dat.g("desc")
		$Sprite.texture = skill.texture
	elif type == "object":
		skill_data = G.data.item_data.get(p)
		skill_type = "object"
		skill_description = skill.dat.g("desc")
		if skill.item_type == "unit":
			$Sprite.texture = skill.n_sprite.texture
		else:
			$Sprite.texture = skill.texture
			$Sprite.set_region(true)
			$Sprite.set_region_rect(Rect2(0, 0, 32, 32))

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			activate()

func activate():
	if mode == MODE_NORMAL:
		G.ui.unselect_skills()
		if skill_type == "self":
			G.you.tasks = [["ability", skill_index, G.you.unit.position]]
		elif skill_type == "item":
			if skill.dat.g("aimable") != null:
				set_mode(MODE_SELECTED)
				G.you.aim_ability(-2)
				G.you.on_point = [skill.dat.g("onuse"), skill]
			else:
				G.you.tasks = [["command", skill.dat.g("onuse"), skill, G.you.unit.position]]
		elif skill_type == "object":
			G.you.tasks.append(["interact", skill])
		else:
			set_mode(MODE_SELECTED)
			G.you.aim_ability(skill_index)
	elif mode == MODE_SELECTED:
		if skill_type != "self":
			set_mode(MODE_NORMAL)
			G.you.stop_aim()
	elif mode == MODE_ACTIVE:
		G.you.tasks = [["ability", skill_index, G.you.unit.position]]
	G.ui.description.hide()

func _update_cooldown(cd):
	if cd > 0:
		set_mode(MODE_COOLDOWN)
		set_modulate(Color.webgray)
	else:
		set_mode(MODE_NORMAL)
		set_modulate(Color.white)

func _on_mouse_entered():
	if skill_type == "item":
		if skill != null and is_instance_valid(skill):
			G.ui.describe("item", skill.get_display_name(), skill.dat.v)
	else:
		G.ui.describe("ability", skill, skill_data)

func _on_mouse_exited():
	G.ui.description.hide()
