extends CanvasLayer

const ItemSlot = preload("res://interface/ItemSlot.tscn")
const SkillSlot = preload("res://interface/SkillSlot.tscn")
onready var menu = $Control/Menu
onready var tint = $Control/Menu/Tint
onready var description = $Control/Description
onready var equipment = $Control/Menu/Tabs/Equipment/VBoxContainer
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

func _background_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			if drag_item != null:
				G.you.unit.pos.add_item(drag_item)
				set_drag_item(null, null)
		else:
			clear()

func _input(event):
	if on:
		if event is InputEventMouseMotion:
			if drag_item != null:
				drag_sprite.position = get_viewport().get_mouse_position()

func display(_arg):
	if !on:
		on = true
		var screen_size = get_viewport().size
		tint.set_size(screen_size)
		tint.get_stylebox("panel", "").set_bg_color(Color(0,0,0, .7))
		menu.show()

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
			var node = equipment.get_node("Equipment/" + slot)
			var allow_type = equipables[slot]
			if allow_type == 2:
				node.make_full()
			elif allow_type == 1:
				node.make_light()
			else:
				node.make_disabled()

func update_inventory():
	var unit = G.you.unit
	if unit.dat.g("parts") != null:
		var removals = inventory.get_children() + skills.get_children()
		for child in removals:
			child.queue_free()
			inventory.remove_child(child)

		for eq_part in unit.equipments:
			var slot = equipment.get_node("Equipment/" + eq_part)
			var eq_item = unit.equipments[eq_part]
			slot.assign(eq_item)

		var count = 0
		for belt_item in unit.belt:
			var slot = equipment.get_node("Equipment/belt" + str(count))
			if belt_item is int:
				if belt_item == 0:
					slot.make_disabled()
				elif belt_item == 1:
					slot.make_light()
				elif belt_item == 2:
					slot.make_full()
			else:
				slot.make_full()
				slot.assign(belt_item)
			count += 1

		for inv_item in unit.inventory:
			var newslot = ItemSlot.instance()
			if inv_item is int:
				if inv_item == 0:
					newslot.make_disabled()
				elif inv_item == 1:
					newslot.make_light()
				elif inv_item == 2:
					newslot.make_full()
			else:
				newslot.make_full()
				newslot.assign(inv_item)
			newslot.part = "inv"
			inventory.add_child(newslot)
		for i in G.you.unit.actives:
			var newslot = SkillSlot.instance()
			newslot.assign(i)
			skills.add_child(newslot)

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
			slot.make_full()
			slot.assign(item)
			slot.tile = tile
			container_grid.add_child(slot)

func describe(item):
	if !description.visible or !on:
		if item:
			display(null)
			description.display(item)
