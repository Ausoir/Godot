extends CanvasLayer

const ItemSlot = preload("res://interface/ItemSlot.tscn")
onready var menu = $Menu
onready var tint = $Menu/Tint
onready var equipment = $Menu/Tabs/Equipment/VBoxContainer
onready var status = $Menu/Tabs/Status/VBoxContainer
onready var container = $Menu/Container
onready var container_grid = $Menu/Container/Container

var on = false


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
	if on:
		clear()
	container.hide()
	on = true
	var screen_size = get_viewport().size
	tint.set_size(screen_size)
	tint.get_stylebox("panel", "").set_bg_color(Color(0,0,0, .7))
	menu.show()

func clear():
	on = false
	menu.hide()
	for child in container_grid.get_children():
		container_grid.remove_child(child)
		child.queue_free()

func update_inventory(equipables):
	for slot in equipables:
		if slot == "wield":
			var node = equipment.get_node("Container/wpn1/wpn")
		else:
			var node = equipment.get_node("Container/" + slot)
			var allow_type = equipables[slot]
			if allow_type == 3:
				node.make_full()
			elif allow_type == 2:
				node.make_light()
			else:
				node.make_disabled()

func search_inventory(tile):
	display(null)
	container.show()
	container.set_tab_title(0, tile.terrain.capitalize())
	for item in tile.items:
		var slot = ItemSlot.instance()
		slot.make_full()
		slot.assign(item)
		container_grid.add_child(slot)
