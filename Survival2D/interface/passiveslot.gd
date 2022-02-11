extends Button

const MODE_NORMAL = 0
const MODE_SELECTED = 1
const MODE_COOLDOWN = 2
const MODE_ACTIVE = 3

onready var label = $Label
var index
var passive
var passive_data
var slot_label

func assign(p, idx, pslot_label):
	index = idx
	passive = p
	passive_data = G.data.skill_data.get(p)
	if passive_data == null:
		return false
	slot_label = pslot_label
	set_text(p)

func _on_mouse_entered():
	G.ui.describe(passive, passive_data.get("desc"))

func _on_mouse_exited():
	G.ui.description.hide()

func _on_toggle(button_pressed):
	if button_pressed:
		if !G.you.unit.activate_passive(index):
			pressed = false
	else:
		G.you.unit.actives[index] = -1
	var slots = G.you.unit.get_active_slots()
	var intel = G.you.unit.vars.g("agility", 1)
	slot_label.set_text("Slots: " + str(slots) + "/" + str(intel))
