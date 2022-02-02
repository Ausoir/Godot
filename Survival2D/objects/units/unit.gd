extends "res://objects/item.gd"

const Ai = preload("res://objects/units/ai.gd")
const Buffs = preload("res://objects/units/buffs.gd")
const animation_map = {
	"idle": 0,
	"walk": 1,
	"attack": 2,
	"hit": 3,
	"headbutt": 4,
	"knockout": 5,
	"kick": 6,
	"wait": 7,
}
const SKILL_SIZE = 12

onready var node_sprites = $Sprites
onready var animation = $Animation
onready var sprite = $Sprites/Sprite
onready var skeleton = $Skeleton2D
onready var tween = $Tween
onready var mat = sprite.material

var state = ""
var delay = 0
var flags

var controller
var abilities
var skills
var deck = []
var damage_taken = 0
var energy = 0
var cooldowns = {}
var buffs = Buffs.new(self)
var last_skill = "wait"
var sight_col = "1000"

func _ready():
	update_stats()
	var count = 0
	for i in range(SKILL_SIZE):
		if move_skill(i, SKILL_SIZE + count):
			count += 1
	for i in dat.g("buffs", []):
		G.fx(self, i)
	energy = vars.g("agility", 0)

func possess(ctlr = null):
	if ctlr == null:
		ctlr = Ai.new()
	else:
		ctlr.unassign()
	if controller != null:
		controller.remove()
		controller = null
	controller = ctlr
	ctlr.unit = self
	ctlr.target = pos
	ctlr.on_assign()

func update_stats():
	abilities = []
	skills = []
	for i in dat.g("abilities", []):
		abilities.append(i)
	for i in dat.g("skills", []):
		skills.append(i)
	for _i in range(skills.size(), SKILL_SIZE * 2):
		skills.append(null)
	update_flags()

func update_flags():
	if controller != null:
		if "mindless" in flags:
			controller.pathing.hinderance = 0
		elif "float" in flags:
			controller.pathing.hinderance = 0
		elif "agile" in flags:
			controller.pathing.hinderance = .5

func add_skill(p):
	for i in range(SKILL_SIZE):
		if skills[i] == null:
			skills[i] = p
			return true
	return false

func move_skill(idx1, idx2):
	if skills[idx1] == null:
		return false
	else:
		if idx1 < SKILL_SIZE and idx2 >= SKILL_SIZE:
			var cost2 = 0
			var passive_data2
			if skills[idx2] != null:
				passive_data2 = G.data.skill_data.get(skills[idx2])
				cost2 = passive_data2.get("cost", 0)
			var passive_data = G.data.skill_data.get(skills[idx1])
			var cost = passive_data.get("cost", 0)
			var intel = vars.g("intelligence", 1)
			var slots = get_active_slots()
			if slots + cost - cost2 > intel:
				return false
			if passive_data.target == "constant":
				G.influence.do(self, skills[idx1], passive_data, 0)
		elif idx1 >= SKILL_SIZE and idx2 < SKILL_SIZE:
			var passive_data = G.data.skill_data.get(skills[idx1])
			if passive_data != null and passive_data.target == "constant":
				G.influence.do(self, skills[idx1], passive_data, 2)
		var swap = skills[idx2]
		skills[idx2] = skills[idx1]
		skills[idx1] = swap
		return true

func has_active(p):
	for i in range(skills.size()):
		if skills[i] == p:
			return i >= SKILL_SIZE
	return false

func get_active_slots():
	var slots = 0
	for i in range(SKILL_SIZE-1, skills.size()):
		if skills[i] != null:
			var data = G.data.skill_data.get(skills[i])
			if data != null:
				slots += data.get("cost", 0)
	return slots

func ability(idx):
	if idx < abilities.size():
		var ability = abilities[idx]
		G.fx(self, ability)

func get_damage(ptype, p):
	if ptype == "true":
		return p
	elif ptype == "bash":
		return round(G.rng.randf() * vars.g("strength", 1) * p * .01)
	elif ptype == "cut":
		return round(G.rng.randf() * p)

func set_delay(p):
	delay = max(delay, p)

func set_state(p, force=false):
	if force or delay == 0:
		state = p
		if state == "move":
			var dir = pos.direction_to(controller.target)
			if move(dir) != null:
				var ms = vars.g("move speed", 1)
				if "agile" in flags:
					ms += int(pos.slow / 2)
				elif !("float" in flags):
					ms += pos.slow
				delay = max(1, ms)
				set_move_delay_speed(delay)
				set_animation("walk")
			else:
				delay = 1
		elif state == "attack":
			var used = "wait"
			var dist = pos.distance_to(controller.target)
			if dist == 1:
				used = roll_skill("onattack")
			elif dist == 2:
				set_state("move")
				if pos.distance_to(controller.target) == 1:
					used = roll_skill("oncharge")
			if used != "wait" and used != "repeat":
				last_skill = used
		else:
			set_animation(state)

func set_animation(p):
	var scale = delay
	if scale > 0:
		animation.play(p, -1, 1/(scale*.15))
		if p == "knockout":
			if "getup" in flags:
				delay = int(delay / 2)
	else:
		animation.play(p)

func set_animation_direction(y):
	if y != 0:
		face(1)
#	animtree["parameters/vertical/add_amount"] = y

func roll_skill(type):
	var roll = G.rng.randi_range(0, 99)
	var skill
	var data
	if deck.empty():
		skill = "wait"
		data = G.data.skill_data.get("wait")
		G.influence.do(self, skill, data, 0)
		return skill
	else:
		skill = deck.pop_front()
		data = G.data.skill_data.get(skill)
		if data != null and data.target == type:
			var energy_cost = data.get("energy", 0)
			if energy_cost <= energy and data.chance > roll:
				energy -= energy_cost
				G.influence.do(self, skill, data, 0)
				return skill
		return roll_skill(type)

func get_health():
	var vit = vars.g("vitality", 1) * 2
	return 1 - (damage_taken / vit)

func hit(_type, dmg):
	damage_taken += dmg
	if dmg > 0:
		roll_skill("onhit")
		if _type != "true":
			if buffs.expend("dodge"):
				G.msg("Dodge!")
				damage_taken -= dmg
				return
		set_animation("hit")
		delay = 2
		buffs.on_interrupt("interrupt")
		G.make_particle("Blood", pos.to_pixel(), {"direction": Vector3(G.trng.randf_range(-1, 1), G.trng.randf_range(-1, 1), 0), "spread": 60})
		var damage_percent = get_health()
		G.display_damage(pos.to_pixel(), round(dmg), [1,1 - damage_percent,0])
		if damage_percent <= 0:
			die()
		else:
			flash("red", damage_percent + .1)
			if damage_percent < .25:
				if !buffs.has("major injury"):
					G.fx(self, "major injury")
			elif damage_percent < .5:
				if !buffs.has("moderate injury"):
					G.fx(self, "moderate injury")
			elif damage_percent < .8:
				if !buffs.has("minor injury"):
					G.fx(self, "minor injury")
	elif dmg < 0:
		flash("green", dmg * -.2)
		G.display_damage(pos.to_pixel(), round(dmg), [0,1,0])

func on_turn():
	if delay == 0:
		controller.on_turn()
	else:
		if delay > 0:
			delay -= 1
		if delay == 0:
			set_animation_direction(0)
			set_state("idle")
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
	if (p > 0) != (node_sprites.scale.x > 0):
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
	if controller != null:
		controller.remove()
	.remove()
	buffs.remove()
	G.turn.remove(self)

func is_visible():
	return node_sprites.visible
