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
var skill_type
var skill_description

func _ready():
	stylebox.texture = G.data.tileset
	stylebox.region_rect.position.y = 1600
	stylebox.region_rect.size = Vector2(32, 32)

func set_index(p):
	skill_index = p
	$Label.text = str(p + 1)

func set_mode(p):
	if p == 3:
		overlay.show()
		stylebox.region_rect.position.x = 1088
	elif p == 2:
		overlay.hide()
		stylebox.region_rect.position.x = 1024
	elif p == 1:
		overlay.hide()
		stylebox.region_rect.position.x = 1056
	else:
		stylebox.region_rect.position.x = 1088
	mode = p

func assign(p):
	skill = p
	var skill_data = G.data.skill_data.get(p)
	if skill_data == null:
		return false
	skill_description = skill_data.get("desc")
	skill_type = skill_data.target
	$Sprite.texture = G.data.get_image(skill_data.img)

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == BUTTON_LEFT:
				activate()

func activate():
	if mode == MODE_NORMAL:
		if skill_type == "self":
			G.you.perform_ability(skill_index)
		else:
			set_mode(MODE_SELECTED)
			G.you.aim_ability(skill_index)
	elif mode == MODE_ACTIVE:
		G.you.perform_ability(skill_index)

func _update_cooldown(cd):
	if cd > 0:
		set_mode(MODE_COOLDOWN)
		set_modulate(Color.webgray)
	else:
		set_mode(MODE_NORMAL)
		set_modulate(Color.white)

func _on_mouse_entered():
	G.ui.describe(skill, skill_description)

func _on_mouse_exited():
	G.ui.description.hide()
