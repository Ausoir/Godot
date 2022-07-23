extends CanvasLayer

const AbilitySlot = preload("res://interface/AbilitySlot.tscn")
const BuffSlot = preload("res://interface/BuffSlot.tscn")
onready var menu = $Control/Menu
onready var n_money = $Money
onready var dialog = $Control/Dialog
onready var message = $Control/Message
onready var tint = $Control/Tint
onready var description = $Control/Description
onready var abilities = $Control/Abilities
onready var buffs = $Control/Status
var screen_size
var mouse_pos = Vector2()
var on = false

func _ready():
	screen_size = get_viewport().get_size_override()
	n_money.rect_position.x = screen_size.x - 80
	fadein()
	tint.get_stylebox("panel", "").set_bg_color(Color(0,0,0, .7))

func fadein():
	$AnimationPlayer/Fade.set_size(screen_size)
	$AnimationPlayer.play("FadeIn")

func _process(_delta):
	$FPS.set_text(str(Engine.get_frames_per_second())+' FPS')
	message._on_process()

func _input(event):
	if event is InputEventMouseMotion:
		mouse_pos = get_viewport().get_mouse_position()
		menu._on_mouse_move()

func _unhandled_input(event):
	if event is InputEventKey:
		if Input.is_action_just_pressed("quit"):
			get_tree().notification(MainLoop.NOTIFICATION_WM_QUIT_REQUEST)
		elif Input.is_action_just_pressed("restart"):
			G.script("start menu", null)
		elif Input.is_action_just_pressed("ui_fullscreen"):
			OS.window_fullscreen = !OS.window_fullscreen
		elif Input.is_action_just_pressed("quick_1"):
			if abilities.get_child_count() > 0:
				abilities.get_children()[0].activate()
		elif Input.is_action_just_pressed("menu"):
			if on:
				clear()
			else:
				G.cmds([["menu", "menu", -1]], G.you.unit)
		else:
			G.you._on_input(event)
	elif !on:
		G.you._on_input(event)

func display_dialog(_page, _host):
	tint.set_size(screen_size)
	tint.show()
	dialog.display(_page, _host)
	dialog.rect_position = screen_size / 2 - dialog.rect_size / 2
	on = true

func display(_arg):
	if !on:
		on = true
		G.you.unhandled_input = false
		tint.set_size(screen_size)
		tint.show()
		menu.display(_arg)

func clear():
	on = false
	menu.clear()
	tint.hide()
	description.hide()
	dialog.hide()

func unselect_skills():
	for child in abilities.get_children():
		if !(child is RichTextLabel):
			if child.mode == 1:
				child.set_mode(0)

func update_hud():
	for child in abilities.get_children():
		child.queue_free()
		abilities.remove_child(child)
	for i in buffs.get_children():
		i.queue_free()
		buffs.remove_child(i)
	var count = 0
	var ab = G.you.unit.dat.g("abilities", [])
	if G.you.unit.dat.g("type") == "man":
		ab += G.you.unit.get_usable_items()
	for i in G.you.interactables:
		if i != null and is_instance_valid(i):
			ab.append(i)
	for i in ab:
		var newslot = AbilitySlot.instance()
		newslot.assign(i)
		newslot.set_index(count)
		abilities.add_child(newslot)
		if newslot.skill_type == "self" and G.you.unit.buffs.has(i):
			newslot.set_mode(3)
		elif G.you.aiming == count:
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

func describe(type, header, subject):
	if !description.visible:
		if header != null and subject != null:
			description.display(type, header, subject)

func _update_cooldowns(cds):
	for ability in abilities.get_children():
		if ability.skill in cds:
			ability._update_cooldown(cds[ability.skill])
			menu.update_inventory()
