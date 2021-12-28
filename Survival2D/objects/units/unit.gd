extends "res://objects/item.gd"

onready var animation = $Animation
onready var animtree = $AnimationTree
onready var sprite = $Sprite
onready var weapon_sprite = $Sprite/Weapon
onready var skeleton = $Skeleton2D

var state = ""
var delay = 0

var dirty = false
var controller
var actives
var passives
var cooldowns = {}

func _ready():
	update()

func update():
	actives = []
	passives = []
	for i in dat.g("actives", []):
		actives.append(i)
	for i in dat.g("passives", []):
		passives.append(i)

func ability(idx, target):
	if idx < actives.size():
		var active = actives[idx]
		G.cmd([["cast", active, target]], self)

func set_state(p, force=false):
	state = p
	if force or delay <= 0:
		if state == "idle":
			animtree["parameters/state/current"] = 0
		elif state == "move":
			animtree["parameters/state/current"] = 1
			delay = dat.g("move speed", 2)
			animtree["parameters/walkspeed/scale"] = 1.5

func _on_turn():
	if delay == 0:
		if controller:
			controller.on_turn()
	else:
		if delay > 0:
			delay -= 1
		else:
			delay += 1
		if delay == 0:
			set_state("idle")
	for i in cooldowns:
		if cooldowns[i] <= 0:
			cooldowns.erase(i)
		else:
			cooldowns[i] -= 1
	if dirty:
		update()
		dirty = false

func face(p):
	if (p > 0) == (sprite.scale.x > 0):
		sprite.scale.x *= -1
		skeleton.scale.x *= -1

func die():
	if controller:
		controller.queue_free()
	G.turn.remove(self)
	queue_free()
