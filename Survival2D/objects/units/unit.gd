extends "res://objects/item.gd"

onready var animation = $Animation
onready var animtree = $AnimationTree
onready var sprite = $Sprite
onready var skeleton = $Skeleton2D

var state = ""
var delay = 0

var controller
var equipment = {}


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

func face(p):
	if (p > 0) == (sprite.scale.x > 0):
		sprite.scale.x *= -1
		skeleton.scale.x *= -1

func die():
	if controller:
		controller.queue_free()
	G.turn.remove(self)
	queue_free()
