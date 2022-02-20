extends Control

const ItemSlot = preload("res://interface/ItemSlot.tscn")
const SkillSlot = preload("res://interface/SkillSlot.tscn")

onready var tabs = $Tabs
onready var tab_equipment = $Tabs/INV/VSplit/Equipment/Columns
onready var tab_inventory = $Tabs/INV/VSplit/Inventory
onready var tab_status = $Tabs/CHA/VBoxContainer
onready var tab_skill_label = $Tabs/SKL/VBoxContainer/Label
onready var tab_skill_active = $Tabs/SKL/VBoxContainer/Active
onready var tab_skill_inactive = $Tabs/SKL/VBoxContainer/Inactive
onready var container = $Container
onready var container_grid = $Container/Container

var drag_item


func _process(_delta):
	if drag_item != null:
		drag_item.sprite.position = get_viewport().get_mouse_position()

func _background_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			if drag_item != null and drag_item.type == "item":
				drag_item.item.place(G.you.unit.pos)
				set_drag_item(null)
		else:
			clear()

func display(_arg):
	show()
	if _arg != -1:
		tabs.set_current_tab(_arg)
	_on_tab_change(tabs.current_tab)

func clear():
	hide()
	container.hide()
	set_drag_item(null)

func set_drag_item(item):
	if item == null:
		if drag_item:
			drag_item.sprite.queue_free()
			remove_child(drag_item.sprite)
			drag_item = null
	else:
		drag_item = item
		drag_item.sprite.position = get_viewport().get_mouse_position()
		add_child(drag_item.sprite)

func get_vacant_inventory():
	for child in tab_inventory.get_children():
		if child.item == null:
			return child

func update_equipables(equipables):
	for columns in tab_equipment.get_children():
		for child in columns.get_children():
			child.make_mode(0)

	for slot in equipables:
		for columns in tab_equipment.get_children():
			for child in columns.get_children():
				if child.name == slot:
					var allow_type = equipables[slot]
					child.make_mode(allow_type)

func update_inventory():
	var unit = G.you.unit
	if unit.dat.g("type") != "other":
		for child in tab_inventory.get_children():
			child.queue_free()
			tab_inventory.remove_child(child)
		for columns in tab_equipment.get_children():
			for child in columns.get_children():
				child.unassign()

		for columns in tab_equipment.get_children():
			for child in columns.get_children():
				if child.name in unit.equipments:
					child.assign(unit.equipments[child.name])

		for inv_item in unit.inventory:
			var newslot = ItemSlot.instance()
			if inv_item != null:
				newslot.assign(inv_item)
			newslot.part = "inv"
			tab_inventory.add_child(newslot)

func search_inventory(tile):
	display(0)
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

func _on_tab_change(page):
	if page == 0:
		update_inventory()
	elif page == 1:
		update_status()
	elif page == 2:
		update_skills()

func update_skills():
	for child in tab_skill_inactive.get_children():
		child.assign(null)
	for child in tab_skill_active.get_children():
		child.assign(null)
	var slots = G.you.unit.get_active_slots()
	var max_slots = G.you.unit.dat.g("agility", 1)
	tab_skill_label.set_text("Slots: " + str(slots) + "/" + str(max_slots))
	var unit_skills = G.you.unit.dat.g("skills", [])
	for i in range(unit_skills.size()):
		var skill = unit_skills[i]
		var slot = tab_skill_inactive.get_child(i)
		slot.assign(skill)
	var unit_actives = G.you.unit.dat.g("actives", [])
	for i in range(unit_actives.size()):
		var actives = unit_actives[i]
		var slot = tab_skill_active.get_child(i)
		slot.assign(actives)

func update_status():
	var header = tab_status.get_node("Panel/Label")
	header.text = "Scavenger Lv.1"
	var stat_list = tab_status.get_node("Control")
	for child in stat_list.get_children():
		child.queue_free()
		stat_list.remove_child(child)
	for i in G.STATS:
		var label = Label.new()
		label.set_text(i.capitalize() + ": " + str(G.you.unit.dat.g(i, 0)))
		stat_list.add_child(label)
