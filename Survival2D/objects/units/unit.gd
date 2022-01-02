extends "res://objects/item.gd"

const Buffs = preload("res://objects/units/buffs.gd")

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
var spd_attack = 1
var spd_move = 1
var defense = 0
var cooldowns = {}
var buffs = Buffs.new(self)

func _ready():
	update()

func update():
	actives = []
	passives = []
	for i in dat.g("actives", []):
		actives.append(i)
	for i in dat.g("passives", []):
		passives.append(i)
	var r_spd_atk = dat.g("attack speed", 1)
	var r_spd_move = dat.g("move speed", 1)
	spd_attack = r_spd_atk + vars.g("attack speed", 0)
	spd_move = r_spd_move + vars.g("move speed", 0)

func ability(idx):
	if idx < actives.size():
		var active = actives[idx]
		G.fx(self, active)

func set_state(p, force=false):
	state = p
	if force or delay <= 0:
		if state == "idle":
			animtree["parameters/state/current"] = 0
		elif state == "move":
			animtree["parameters/state/current"] = 1
			delay = max(1, spd_move)
			set_move_delay_speed(delay)
			animtree["parameters/walkspeed/scale"] = 1 / (delay*.25)
		elif state == "attack":
			animtree["parameters/state/current"] = 2
			delay = spd_attack

func on_turn():
	if delay == 0:
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
	controller.queue_free()
	G.turn.remove(self)
	queue_free()
