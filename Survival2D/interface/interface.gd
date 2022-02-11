extends CanvasLayer

const ItemSlot = preload("res://interface/ItemSlot.tscn")
const AbilitySlot = preload("res://interface/AbilitySlot.tscn")
const BuffSlot = preload("res://interface/BuffSlot.tscn")
const PassiveSlot = preload("res://interface/PassiveSlot.tscn")
const SkillSlot = preload("res://interface/SkillSlot.tscn")
onready var menu = $Control/Menu
onready var dialog = $Control/Dialog
onready var message = $Control/Message
onready var tint = $Control/Tint
onready var description = $Control/Description
onready var tabs = $Control/Menu/Tabs
onready var tab_equipment = $Control/Menu/Tabs/INV/VSplit/Equipment/Columns
onready var tab_inventory = $Control/Menu/Tabs/INV/VSplit/Inventory
onready var tab_status = $Control/Menu/Tabs/CHA/VBoxContainer
onready var tab_skill_label = $Control/Menu/Tabs/SKL/VBoxContainer/Label
onready var tab_skill_active = $Control/Menu/Tabs/SKL/VBoxContainer/Active
onready var tab_skill_inactive = $Control/Menu/Tabs/SKL/VBoxContainer/Inactive
onready var container = $Control/Menu/Container
onready var container_grid = $Control/Menu/Container/Container
onready var abilities = $Control/Abilities
onready var buffs = $Control/Status
var screen_size
var screen_ratio

var on = false
var drag_item


func _ready():
	screen_size = get_viewport().get_size_override()
	screen_ratio = screen_size / get_viewport().size
	$AnimationPlayer/Fade.set_size(screen_size)
	$AnimationPlayer.play("FadeIn")
	tint.get_stylebox("panel", "").set_bg_color(Color(0,0,0, .7))

func _process(_delta):
	$FPS.set_text(str(Engine.get_frames_per_second())+' FPS')
	if drag_item != null:
		drag_item.sprite.position = get_viewport().get_mouse_position()
	message._on_process()

func _background_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			if drag_item != null and drag_item.type == "item":
				drag_item.item.place(G.you.unit.pos)
				set_drag_item(null)
		else:
			clear()

func _unhandled_input(event):
	if event is InputEventKey:
		if Input.is_action_just_pressed("quit"):
			get_tree().quit()
		elif Input.is_action_just_pressed("restart"):
			G.world.generate()
			print("Player:restart: ", get_tree().change_scene("res://world/World.tscn"))
		elif Input.is_action_just_pressed("ui_fullscreen"):
			OS.window_fullscreen = !OS.window_fullscreen
		elif Input.is_action_just_pressed("auto_attack"):
			G.you.auto_attack = !G.you.auto_attack
			message.add("Auto attack: " + str(G.you.auto_attack))
		elif Input.is_action_just_pressed("item_1"):
			G.you.tasks = [["swap", 0]]
		elif Input.is_action_just_pressed("item_2"):
			G.you.tasks = [["swap", 1]]
		elif Input.is_action_just_pressed("item_3"):
			G.you.tasks = [["swap", 2]]
		elif Input.is_action_just_pressed("item_4"):
			G.you.tasks = [["swap", 3]]
		elif Input.is_action_just_pressed("quick_1"):
			if abilities.get_child_count() > 0:
				abilities.get_children()[0].activate()
		elif Input.is_action_just_pressed("quick_2"):
			if abilities.get_child_count() > 1:
				abilities.get_children()[1].activate()
		elif Input.is_action_just_pressed("quick_3"):
			if abilities.get_child_count() > 2:
				abilities.get_children()[2].activate()
		elif Input.is_action_just_pressed("quick_4"):
			if abilities.get_child_count() > 3:
				abilities.get_children()[3].activate()
		elif Input.is_action_just_pressed("menu"):
			if on:
				clear()
			else:
				G.cmd([["menu", "menu", -1]], G.you.unit)
		else:
			G.you._on_input(event)
	elif !on:
		G.you._on_input(event)

func display_dialog(_page, _host):
	on = true
	tint.set_size(screen_size)
	tint.show()
	dialog.display(_page, _host)
	dialog.rect_position = screen_size / 2 - dialog.rect_size / 2

func display(_arg):
	if !on:
		on = true
		tint.set_size(screen_size)
		tint.show()
		menu.show()
		if _arg != -1:
			tabs.set_current_tab(_arg)
		_on_tab_change(tabs.current_tab)

func clear():
	on = false
	menu.hide()
	tint.hide()
	description.hide()
	container.hide()
	dialog.hide()
	set_drag_item(null)

func set_drag_item(item):
	if item == null:
		if drag_item:
			drag_item.sprite.queue_free()
			menu.remove_child(drag_item.sprite)
			drag_item = null
	else:
		drag_item = item
		drag_item.sprite.position = get_viewport().get_mouse_position()
		menu.add_child(drag_item.sprite)

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

		var count = 1
		for belt_item in unit.belt:
			var slot = tab_equipment.get_node("belted/" + str(count))
			slot.make_mode(belt_item[0])
			if belt_item[1] != null:
				slot.assign(belt_item[1])
			count += 1
		for inv_item in unit.inventory:
			var newslot = ItemSlot.instance()
			if inv_item != null:
				newslot.assign(inv_item)
			newslot.part = "inv"
			tab_inventory.add_child(newslot)

func update_hud():
	for child in abilities.get_children():
		child.queue_free()
		abilities.remove_child(child)
	for i in buffs.get_children():
		i.queue_free()
		buffs.remove_child(i)
	var count = 0
	for i in G.you.unit.abilities:
		var newslot = AbilitySlot.instance()
		newslot.assign(i)
		newslot.set_index(count)
		abilities.add_child(newslot)
		if newslot.skill_type == "self":
			if G.you.unit.buffs.has(i):
				newslot.set_mode(3)
		if G.you.aiming == count:
			newslot.set_mode(1)
		else:
			newslot.set_mode(0)
		count += 1
	buffs.rect_position.x = screen_size.x - 48
	for i in G.you.unit.buffs.states:
		var buff = G.you.unit.buffs.states[i]
		var img = buff.fx.get("img")
		if img != null:
			var slot = BuffSlot.instance()
			slot.assign(i, img, buff.fx.get("desc"))
			buffs.add_child(slot)

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

func describe(type, header, subject):
	if !description.visible or !on:
		if header != null and subject != null:
			if type == "text":
				description.display(header, subject)
			elif type == "item":
				description.display_item(header, subject)
			elif type == "skill":
				description.display_skill(header, subject)

func _update_cooldowns(cds):
	for ability in abilities.get_children():
		if ability.skill in cds:
			ability._update_cooldown(cds[ability.skill])
			update_inventory()

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
	for i in range(G.you.unit.skills.size()):
		var skill = G.you.unit.skills[i]
		if skill != null:
			var slot
			if i >= G.you.unit.SKILL_SIZE:
				slot = tab_skill_active.get_child(i - G.you.unit.SKILL_SIZE)
			else:
				slot = tab_skill_inactive.get_child(i)
			slot.assign(skill)

func update_status():
	for child in tab_status.get_children():
		child.queue_free()
		tab_status.remove_child(child)
	for i in G.STATS:
		var label = Label.new()
		label.set_text(i.capitalize() + ": " + str(G.you.unit.dat.g(i, 0)))
		tab_status.add_child(label)
