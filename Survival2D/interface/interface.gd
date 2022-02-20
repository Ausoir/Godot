extends CanvasLayer

const AbilitySlot = preload("res://interface/AbilitySlot.tscn")
const BuffSlot = preload("res://interface/BuffSlot.tscn")
onready var menu = $Control/Menu
onready var dialog = $Control/Dialog
onready var message = $Control/Message
onready var tint = $Control/Tint
onready var description = $Control/Description
onready var abilities = $Control/Abilities
onready var buffs = $Control/Status
var screen_size
var screen_ratio
var on = false

func _ready():
	screen_size = get_viewport().get_size_override()
	screen_ratio = screen_size / get_viewport().size
	$AnimationPlayer/Fade.set_size(screen_size)
	$AnimationPlayer.play("FadeIn")
	tint.get_stylebox("panel", "").set_bg_color(Color(0,0,0, .7))

func _process(_delta):
	$FPS.set_text(str(Engine.get_frames_per_second())+' FPS')
	message._on_process()

func _unhandled_input(event):
	if event is InputEventKey:
		if Input.is_action_just_pressed("quit"):
			get_tree().notification(MainLoop.NOTIFICATION_WM_QUIT_REQUEST)
		elif Input.is_action_just_pressed("restart"):
			G.world.generate()
			print("Player:restart: ", get_tree().change_scene("res://world/World.tscn"))
		elif Input.is_action_just_pressed("ui_fullscreen"):
			OS.window_fullscreen = !OS.window_fullscreen
		elif Input.is_action_just_pressed("auto_attack"):
			G.you.auto_attack = !G.you.auto_attack
			message.add("Auto attack: " + str(G.you.auto_attack))
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
		elif Input.is_action_just_pressed("quick_5"):
			if abilities.get_child_count() > 4:
				abilities.get_children()[4].activate()
		elif Input.is_action_just_pressed("quick_6"):
			if abilities.get_child_count() > 5:
				abilities.get_children()[5].activate()
		elif Input.is_action_just_pressed("quick_7"):
			if abilities.get_child_count() > 6:
				abilities.get_children()[6].activate()
		elif Input.is_action_just_pressed("quick_8"):
			if abilities.get_child_count() > 7:
				abilities.get_children()[7].activate()
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
		menu.display(_arg)

func clear():
	on = false
	menu.clear()
	tint.hide()
	description.hide()
	dialog.hide()

func update_hud():
	for child in abilities.get_children():
		child.queue_free()
		abilities.remove_child(child)
	for i in buffs.get_children():
		i.queue_free()
		buffs.remove_child(i)
	var count = 0
	for i in G.you.unit.dat.g("abilities", []):
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
			menu.update_inventory()
