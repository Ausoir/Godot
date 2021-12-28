extends CanvasLayer

const ItemSlot = preload("res://interface/ItemSlot.tscn")
const SkillSlot = preload("res://interface/SkillSlot.tscn")
onready var menu = $Control/Menu
onready var tint = $Control/Menu/Tint
onready var description = $Control/Description
onready var equipment = $Control/Menu/Tabs/Equipment/VBoxContainer/Equipment
onready var inventory = $Control/Menu/Tabs/Equipment/VBoxContainer/Inventory
onready var status = $Control/Menu/Tabs/Status/VBoxContainer
onready var container = $Control/Menu/Container
onready var container_grid = $Control/Menu/Container/Container
onready var skills = $Control/Skills

var on = false
var drag_item
var drag_sprite


func _ready():
	var viewport_size = get_viewport().size
	$AnimationPlayer/Fade.set_size(viewport_size)
	$AnimationPlayer.play("FadeIn")

func _process(_delta):
	$FPS.set_text(str(Engine.get_frames_per_second())+' FPS')

func _input(event):
	if event is InputEventMouseMotion:
		if drag_item != null:
			drag_sprite.position = get_viewport().get_mouse_position()

func _background_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			if drag_item != null:
				G.you.unit.pos.add_item(drag_item)
				set_drag_item(null, null)
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
		elif Input.is_action_just_pressed("item_1"):
			G.you.tasks.append(["swap", 0])
		elif Input.is_action_just_pressed("item_2"):
			G.you.tasks.append(["swap", 1])
		elif Input.is_action_just_pressed("item_3"):
			G.you.tasks.append(["swap", 2])
		elif Input.is_action_just_pressed("item_4"):
			G.you.tasks.append(["swap", 3])
		elif Input.is_action_just_pressed("quick_1"):
			skills.get_children()[0].activate()
		elif Input.is_action_just_pressed("quick_2"):
			skills.get_children()[1].activate()
		elif Input.is_action_just_pressed("quick_3"):
			skills.get_children()[2].activate()
		elif Input.is_action_just_pressed("quick_4"):
			skills.get_children()[3].activate()
		elif Input.is_action_just_pressed("menu"):
			if on:
				clear()
			else:
				G.cmd([["menu", ""]], G.you.unit)
	elif !on:
		G.you._on_input(event)

func display(_arg):
	if !on:
		on = true
		var screen_size = get_viewport().size
		tint.set_size(screen_size)
		tint.get_stylebox("panel", "").set_bg_color(Color(0,0,0, .7))
		menu.show()
		G.you.unit.update()
		update_inventory()

func clear():
	on = false
	menu.hide()
	description.hide()
	container.hide()
	set_drag_item(null, null)

func set_drag_item(item, item_sprite):
	if item == null:
		if drag_item:
			drag_item = null
			drag_sprite.queue_free()
			menu.remove_child(drag_sprite)
	else:
		drag_item = item
		drag_sprite = item_sprite.duplicate()
		drag_sprite.position = get_viewport().get_mouse_position()
		menu.add_child(drag_sprite)

func get_vacant_inventory():
	for child in inventory.get_children():
		if child.item == null:
			return child

func update_equipables(equipables):
	for slot in equipables:
		if slot != "wield":
			var node = equipment.get_node(slot)
			var allow_type = equipables[slot]
			node.make_mode(allow_type)

func update_inventory():
	var unit = G.you.unit
	if unit.dat.g("bodyparts") != null:
		for child in inventory.get_children():
			child.queue_free()
			inventory.remove_child(child)
		for child in skills.get_children():
			child.queue_free()
			skills.remove_child(child)
		for child in equipment.get_children():
			child.unassign()

		for eq_part in unit.equipments:
			var slot = equipment.get_node(eq_part)
			var eq_item = unit.equipments[eq_part]
			slot.assign(eq_item)

		var count = 0
		for belt_item in unit.belt:
			var slot = equipment.get_node("belt" + str(count))
			slot.make_mode(belt_item[0])
			if belt_item[1] != null:
				slot.assign(belt_item[1])
			count += 1

		for inv_item in unit.inventory:
			var newslot = ItemSlot.instance()
			newslot.make_mode(inv_item[0])
			if inv_item[1] != null:
				newslot.assign(inv_item[1])
			newslot.part = "inv"
			inventory.add_child(newslot)
		count = 0
		for i in G.you.unit.actives:
			var newslot = SkillSlot.instance()
			newslot.assign(i)
			newslot.set_index(count)
			skills.add_child(newslot)
			count += 1

func search_inventory(tile):
	display(null)
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

func describe(item):
	if !description.visible or !on:
		if item:
			display(null)
			description.display(item)

func _update_cooldowns(cds):
	for skill in skills.get_children():
		if skill.skill in cds:
			skill._update_cooldown(cds[skill.skill])
