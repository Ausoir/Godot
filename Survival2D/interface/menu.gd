extends Control

const ItemSlot = preload("res://interface/ItemSlot.tscn")
const SkillSlot = preload("res://interface/SkillSlot.tscn")

onready var tabs = $Tabs
onready var tab_equipment = $Tabs/INV/VSplit/Equipment
onready var tab_inventory = $Tabs/INV/VSplit/Inventory
onready var tab_cha_stats = $Tabs/CHA/VSplit/Stats
onready var tab_cha_skills = $Tabs/CHA/VSplit/Skills
onready var tab_map = $Tabs/MAP/Text
onready var tab_settings = $Tabs/OPT/Control
onready var n_drag = $Drag
onready var n_money = $Money
onready var container = $Container
onready var container_grid = $Container/Container
onready var n_time = $Time

var drag_item


func _on_mouse_move():
	if drag_item != null:
		n_drag.rect_position = G.ui.mouse_pos

func _background_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			if drag_item != null and drag_item.type == "item":
				drag_item.item.place(G.you.unit.pos)
				G.you.unit.on_item_remove(drag_item.item)
				set_drag_item(null)
		else:
			G.ui.clear()

func display(_arg):
	show()
	display_time()
	if _arg != -1:
		tabs.set_current_tab(_arg)
	_on_tab_change(tabs.current_tab)

func clear():
	hide()
	container.hide()
	set_drag_item(null)

func _on_tab_change(page):
	if page == 0:
		update_equipment()
		update_inventory()
	elif page == 1:
		update_status()
		update_skills()
	elif page == 2:
		update_map()
	elif page == 3:
		tab_settings.refresh()

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

func update_equipment():
	var n_eq = []
	var n_eq_label
	for child in tab_equipment.get_children():
		if child is RichTextLabel:
			child.unassign()
			n_eq.append(child)
		else:
			n_eq_label = child
	var unit = G.you.unit
	if unit.dat.g("type") != "other":
		var eq_weight = 0
		for child in n_eq:
			if child.part in unit.equipments:
				var eq = unit.equipments[child.part]
				child.assign(eq)
				eq_weight += eq.dat.g("weight", 0)
		n_eq_label.set_text("Equipment ["+ str(eq_weight) +"kg]: ")

func update_inventory():
	var n_inv_label
	for child in tab_inventory.get_children():
		if child is RichTextLabel:
			child.queue_free()
			tab_inventory.remove_child(child)
		else:
			n_inv_label = child
	var unit = G.you.unit
	if unit.dat.g("type") != "other":
		var inv_weight = 0
		var index = 0
		for inv_item in unit.inventory:
			var newslot = ItemSlot.instance()
			newslot.part = "inv"
			newslot.index = index
			index += 1
			if inv_item != null:
				newslot.assign(inv_item)
				inv_weight += inv_item.dat.g("weight", 0)
			tab_inventory.add_child(newslot)
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
	for child in tab_cha_skills.get_children():
		if child is RichTextLabel:
			child.queue_free()
			tab_cha_skills.remove_child(child)
		else:
			var slots = G.you.unit.dat.get_active_slots()
			var max_slots = G.you.unit.dat.g("intelligence", 1)
			child.set_text("Skills [" + str(slots) + "/" + str(max_slots) + "]: ")
	var unit_skills = G.you.unit.dat.g("skills", [])
	var item_skills = []
	if G.you.unit.dat.g("type") != "other":
		item_skills = G.you.unit.item_skills
		for i in range(item_skills.size()):
			var actives = unit_skills[item_skills[i]]
			var newslot = SkillSlot.instance()
			newslot.assign(actives, -1)
			newslot.set_is_item(true)
			tab_cha_skills.add_child(newslot)
	for i in range(unit_skills.size()):
		if !(i in item_skills):
			var actives = unit_skills[i]
			var newslot = SkillSlot.instance()
			newslot.assign(actives, i)
			tab_cha_skills.add_child(newslot)

func update_status():
	tab_cha_stats.get_node("Label").set_text(G.you.unit.item_name.capitalize())
	var textbox = tab_cha_stats.get_node("Control")
	var txt = textbox.get_stats_text(G.you.unit.dat.v)
	textbox.set_bbcode(txt)

func display_time():
	var hour = int(G.vars.time / 60) % 24
	var minute = int(G.vars.time) % 60
	if minute < 10:
		minute = "0" + str(minute)
	else:
		minute = str(minute)
	n_time.set_text(str(hour) + ":" + minute)

func update_map():
	var txt = "[color=#A64]Area[/color]: "+G.temp.area.capitalize()+"\n"
	txt += "[color=#A64]Difficulty[/color]: "+str(G.temp.rating)+"\n"
	txt += "[color=#A64]Objective[/color]: "+G.temp.objective.capitalize()
	if G.temp.get("complete", false) == true:
		txt += " (Complete)\n"
		txt += "Leave through the " + G.get_dir_to_cardinal_string(G.temp.enterside+2) + "side."
	tab_map.set_bbcode(txt)
