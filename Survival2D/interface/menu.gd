extends Control

const ItemSlot = preload("res://interface/ItemSlot.tscn")
const SkillSlot = preload("res://interface/SkillSlot.tscn")

onready var tabs = $Tabs
onready var tab_equipment = $Tabs/INV/VSplit/Equipment
onready var tab_inventory = $Tabs/INV/VSplit/Inventory
onready var tab_status = $Tabs/CHA/VBoxContainer
onready var tab_skill_active = $Tabs/SKL/VSplit/Actives
onready var tab_skill_inactive = $Tabs/SKL/VSplit/Reserves
onready var n_drag = $Drag
onready var container = $Container
onready var container_grid = $Container/Container

var drag_item


func _on_mouse_move():
	if drag_item != null:
		n_drag.rect_position = G.ui.mouse_pos

func _background_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			if drag_item != null and drag_item.type == "item":
				drag_item.item.place(G.you.unit.pos)
				set_drag_item(null)
		else:
			G.ui.clear()

func display(_arg):
	show()
	if _arg != -1:
		tabs.set_current_tab(_arg)
	_on_tab_change(tabs.current_tab)

func clear():
	hide()
	container.hide()
	set_drag_item(null)

func _on_tab_change(page):
	if page == 0:
		update_inventory()
	elif page == 1:
		update_status()
	elif page == 2:
		update_skills()

func set_drag_item(item):
	if item == null:
		if drag_item:
			n_drag.hide()
			drag_item = null
	else:
		drag_item = item
		n_drag.set_text(item.drag)
		n_drag.show()
		_on_mouse_move()

func update_equipables(equipables):
	for child in tab_equipment.get_children():
		if child is RichTextLabel:
			child.queue_free()
			tab_equipment.remove_child(child)
	for slot in equipables:
		var newslot = ItemSlot.instance()
		var allow_type = equipables[slot]
		newslot.make_mode(slot, allow_type)
		tab_equipment.add_child(newslot)

func update_inventory():
	var n_eq = []
	var n_eq_label
	var n_inv_label
	for child in tab_equipment.get_children():
		if child is RichTextLabel:
			child.unassign()
			n_eq.append(child)
		else:
			n_eq_label = child
	for child in tab_inventory.get_children():
		if child is RichTextLabel:
			child.queue_free()
			tab_inventory.remove_child(child)
		else:
			n_inv_label = child
	var unit = G.you.unit
	if unit.dat.g("type") != "other":
		var eq_weight = 0
		var inv_weight = 0
		for child in n_eq:
			if child.part in unit.equipments:
				var eq = unit.equipments[child.part]
				child.assign(eq)
				eq_weight += eq.dat.g("weight", 0)
		for inv_item in unit.inventory:
			var newslot = ItemSlot.instance()
			newslot.part = "inv"
			if inv_item != null:
				newslot.assign(inv_item)
				inv_weight += inv_item.dat.g("weight", 0)
			tab_inventory.add_child(newslot)
		n_eq_label.set_text("Equipment ["+ str(eq_weight) +"kg]: ")
		n_inv_label.set_text("Inventory ["+ str(inv_weight) +"kg]: ")

func search_inventory(tile):
	G.ui.display(0)
	container.show()
	container.set_tab_title(0, tile.terrain.capitalize())
	for child in container_grid.get_children():
		container_grid.remove_child(child)
		child.queue_free()
	for item in tile.items:
		if item.item_type == "item":
			var slot = ItemSlot.instance()
			slot.assign(item)
			slot.tile = tile
			container_grid.add_child(slot)

func update_skills():
	for child in tab_skill_active.get_children():
		if child is RichTextLabel:
			child.queue_free()
			tab_skill_active.remove_child(child)
		else:
			var slots = G.you.unit.dat.get_active_slots()
			var max_slots = G.you.unit.dat.g("agility", 1)
			child.set_text("Actives [" + str(slots) + "/" + str(max_slots) + "]: ")
	for child in tab_skill_inactive.get_children():
		if child is RichTextLabel:
			child.queue_free()
			tab_skill_inactive.remove_child(child)
	var unit_skills = G.you.unit.dat.g("skills", [])
	var unit_actives = G.you.unit.dat.g("actives", [])
	for i in range(unit_actives.size()):
		var actives = unit_actives[i]
		var newslot = SkillSlot.instance()
		newslot.assign(actives, i)
		newslot.active = true
		tab_skill_active.add_child(newslot)
	for i in range(unit_skills.size()):
		var actives = unit_skills[i]
		var newslot = SkillSlot.instance()
		newslot.assign(actives, i)
		tab_skill_inactive.add_child(newslot)
	if G.you.unit.dat.g("type") != "other":
		for i in range(G.you.unit.item_skills.size()):
			var actives = G.you.unit.item_skills[i]
			var newslot = SkillSlot.instance()
			newslot.assign(actives, -1)
			newslot.set_is_item(true)
			tab_skill_active.add_child(newslot)

func update_status():
	var header = tab_status.get_node("Label")
	header.text = "Scavenger Lv.1"
	var textbox = tab_status.get_node("RichTextLabel")
	var txt = ""
	for i in G.STATS:
		txt += "[color=#A64]"+i.capitalize()+"[/color]: "+str(G.you.unit.dat.g(i, 0)) + "\n"
	textbox.set_bbcode(txt)
