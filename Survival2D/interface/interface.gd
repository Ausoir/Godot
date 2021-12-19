extends CanvasLayer

const ItemSlot = preload("res://interface/ItemSlot.tscn")
onready var menu = $Control/Menu
onready var tint = $Control/Menu/Tint
onready var description = $Control/Description
onready var equipment = $Control/Menu/Tabs/Equipment/VBoxContainer
onready var inventory = $Control/Menu/Tabs/Equipment/VBoxContainer/Inventory
onready var status = $Control/Menu/Tabs/Status/VBoxContainer
onready var container = $Control/Menu/Container
onready var container_grid = $Control/Menu/Container/Container

var on = false
var drag_item
var drag_sprite


func _ready():
	var viewport_size = get_viewport().size
	$AnimationPlayer/Fade.set_size(viewport_size)
	$AnimationPlayer.play("FadeIn")

func _background_input(event):
	if event is InputEventMouseButton and !event.pressed:
		clear()

func _process(_delta):
	$FPS.set_text(str(Engine.get_frames_per_second())+' FPS')

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
	on_drag(null)
	container.hide()

func _input(event):
	if on:
		if event is InputEventMouseMotion:
			if drag_item != null:
				drag_sprite.position = get_viewport().get_mouse_position()

func on_drag(slot):
	if drag_item == null: #Take from
		if slot != null:
			drag_item = slot.item
			drag_sprite = slot.item_sprite.duplicate()
			drag_sprite.position = get_viewport().get_mouse_position()
			menu.add_child(drag_sprite)
			slot.unassign()
	else: #Place to
		if slot == null:
			G.you.unit.pos.add_item(drag_item)
		else:
			slot.assign(drag_item)
		drag_item = null
		drag_sprite.queue_free()
		menu.remove_child(drag_sprite)

func on_quick_drag(slot):
	if slot.tile != null:
		for child in inventory.get_children():
			if child.item == null:
				on_drag(slot)
				on_drag(child)
				return

func update_equipables(equipables):
	for slot in equipables:
		if slot != "wield":
			var node = equipment.get_node("Container/" + slot)
			var allow_type = equipables[slot]
			if allow_type == 2:
				node.make_full()
			elif allow_type == 1:
				node.make_light()
			else:
				node.make_disabled()

func update_inventory(equipments):
	var belt = "0000"
	for slot in equipments:
		if slot == "belt":
			belt = "0000"
		elif slot == "back":
			belt = "0000"
	var count = 1
	for i in belt:
		var node = equipment.get_node("Container/wpn" + str(count))
		if i == "1":
			node.make_light()
		elif i == "2":
			node.make_full()
		count += 1
	var newslot = ItemSlot.instance()
	newslot.make_light()
	inventory.add_child(newslot)

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
