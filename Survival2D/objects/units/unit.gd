extends "res://objects/item.gd"

const Buffs = preload("res://objects/units/buffs.gd")
const animation_map = {
	"idle": 0,
	"move": 1,
	"attack": 2,
	"hit": 3,
	"headbutt": 4,
	"knockout": 5,
	"kick": 6,
	"wait": 7,
}

onready var node_sprites = $Sprites
onready var animation = $Animation
onready var animtree = $AnimationTree
onready var sprite = $Sprites/Sprite
onready var skeleton = $Skeleton2D
onready var tween = $Tween
onready var mat = sprite.material

var state = ""
var delay = 0

var controller
var abilities
var actives = []
var passives
var fatigue = 0
var stamina
var cooldowns = {}
var buffs = Buffs.new(self)

func _ready():
	update_stats()
	for i in range(passives.size()):
		activate_passive(i)

func update_stats():
	abilities = []
	passives = []
	for i in dat.g("abilities", []):
		abilities.append(i)
	for i in dat.g("passives", []):
		passives.append(i)
		actives.append(-1)
	stamina = max(1, vars.g("agility", 1))

func activate_passive(idx):
	if idx < passives.size():
		var passive_data = G.data.skill_data.get(passives[idx])
		var cost = passive_data.get("cost", 0)
		var intel = vars.g("intelligence", 1)
		var slots = get_active_slots()
		if slots + cost <= intel:
			actives[idx] = cost
			return true
	return false

func get_active_slots():
	var slots = 0
	for i in actives:
		if i != -1:
			slots += i
	return slots

func ability(idx):
	if idx < abilities.size():
		var ability = abilities[idx]
		G.fx(self, ability)

func get_damage():
	return vars.g("strength", 1)

func set_delay(p):
	delay = max(delay, p)

func set_state(p, force=false):
	if force or delay == 0:
		state = p
		if state == "move":
			delay = max(1, dat.g("move speed", 1))
			set_move_delay_speed(delay)
			set_animation(state)
		elif state == "attack":
			roll_skill("onattack")
		else:
			set_animation(state)

func set_animation(p):
	var scale = delay
	animtree["parameters/state/current"] = animation_map[p]
	if scale > 0:
		animtree["parameters/timescale/scale"] = 1 / (scale*.25)
	else:
		animtree["parameters/timescale/scale"] = 1

func set_animation_direction(y):
	if y != 0:
		face(1)
	animtree["parameters/vertical/add_amount"] = y

func roll_skill(type):
	var roll = G.rng.randi_range(0, 99)
	var deck = []
	for i in range(passives.size()):
		if actives[i] != -1:
			deck.append(passives[i])
	while !deck.empty():
		var skill = G.rng.rnd_pop(deck)
		var data = G.data.skill_data.get(skill)
		if data != null and data.target == type:
			if data.chance > roll:
				G.influence.do(self, skill, data, 0)
				return skill
	delay = 4
	set_animation("wait")

func is_hit(acc):
	if acc > 0:
		acc = G.rng.randi_range(0, acc)
		var dodge = stamina - fatigue
		if acc > dodge:
			return true
		else:
			fatigue += acc
	return false

func hit(ptype, acc, dmg):
	if is_hit(acc):
		var toughness = max(1, vars.g("vitality", 1))
		dmg = G.rng.randi_range(0, dmg)
		fatigue += dmg
		if fatigue > stamina:
			var overwhelm = fatigue - stamina
			buffs.on_interrupt("interrupt")
			dmg = overwhelm / toughness
			delay = int(fatigue)
			if delay > 3:
				set_animation("knockout")
				flash("red", .5)
			else:
				set_animation("hit")
				flash("red", .1)
		damage(ptype, dmg)

func damage(ptype, dmg):
	if dmg > 0:
		G.make_particle("Blood", pos.to_pixel(), {"direction": Vector3(G.trng.randf_range(-1, 1), G.trng.randf_range(-1, 1), 0), "spread": 60})
		G.display_damage(pos.to_pixel(), int(dmg)+1, 1 - dmg/4.0)
		var vit = vars.g("vitality", 1)
		if dmg > vit:
			die()
		elif ptype == "bash":
			if dmg < G.rng.randi_range(1, vit):
				G.fx(self, "dazed")
			else:
				G.fx(self, "broken bones")
		elif ptype == "cut":
			if dmg < G.rng.randi_range(1, vit):
				G.fx(self, "open wound")
			else:
				G.fx(self, "internal bleeding")

func on_turn():
	if delay == 0:
		controller.on_turn()
	else:
		if delay > 0:
			delay -= 1
		if delay == 0:
			set_animation_direction(0)
			set_state("idle")
	if fatigue > 0:
		fatigue *= .9
		mat.set_shader_param("yellow", min(.3, fatigue / stamina * .3))
	else:
		mat.set_shader_param("yellow", 0)
	for i in cooldowns:
		if cooldowns[i] <= 0:
			cooldowns.erase(i)
		else:
			cooldowns[i] -= 1

func flash(color, dur):
	tween.interpolate_property(mat, "shader_param/" + color,
		1, 0, dur,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()

func face(p):
	if (p > 0) == (node_sprites.scale.x > 0):
		node_sprites.scale.x *= -1
		skeleton.scale.x *= -1

func face_toward(p):
	if p != null:
		if p.x > pos.x:
			face(1)
		elif p.x < pos.x:
			face(-1)

func die():
	G.factory.make_corpse(self, pos)
	remove()

func remove():
	.remove()
	buffs.remove()
	controller.remove()
	G.turn.remove(self)
