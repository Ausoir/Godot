extends "res://objects/item.gd"

const Ai = preload("res://objects/units/ai.gd")
const Buffs = preload("res://objects/units/buffs.gd")
const Healthbar = preload("res://interface/Health.tscn")
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

onready var n_sprites = $Sprites
onready var n_animation = $Animation
onready var n_sprite = $Sprites/Sprite
onready var n_skeleton = $Skeleton2D
onready var n_tween = $Tween
onready var n_mat = n_sprite.material
var n_healthbar

var delay = 0

var is_dead = false
var controller
var deck = []
var cooldowns = {}
var buffs = Buffs.new(self)
var current_action = ""
var last_skill = "wait"
var sight_col = "1000"
var dirty_dat = false

func _ready():
	for i in dat.g("buffs", []):
		G.fx(self, i)

func set_seed():
	pass

func on_dat():
	.on_dat()
	if controller != null:
		controller.on_dat()

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

func fill_skills():
	var skillsize = dat.g("skills", []).size()
	for _i in range(skillsize):
		if !activate_skill(0):
			return

func swap_skills(type, idx1, idx2):
	var skills = dat.g(type, [])
	if idx2 >= skills.size():
		var prim = skills[idx1]
		skills.remove(idx1)
		skills.append(prim)
	else:
		var prim = skills[idx1]
		skills[idx1] = skills[idx2]
		skills[idx2] = prim
	dat.a(type, skills)

func activate_skill(idx):
	var agility = dat.g("agility", 1)
	var skills = dat.g("skills", [])
	var skill = skills[idx]
	var skill_data = G.data.skill_data.get(skill)
	if get_active_slots()+skill_data.get("cost", 0) <= agility:
		skills.remove(idx)
		var actives = dat.g("actives", [])
		actives.append(skill)
		dat.a("actives", actives)
		dat.a("skills", skills)
		return true

func deactivate_skill(idx):
	var actives = dat.g("actives", [])
	var skills = dat.g("skills", [])
	var active = actives[idx]
	actives.remove(idx)
	skills.append(active)
	dat.a("actives", actives)
	dat.a("skills", skills)

func get_active_slots():
	var slots = 0
	var actives = dat.g("actives", [])
	for i in range(actives.size()):
		var data = G.data.skill_data.get(actives[i])
		if data != null:
			slots += data.get("cost", 0)
	return slots

func ability(idx):
	var abilities = dat.g("abilities", [])
	if idx < abilities.size():
		var ability = abilities[idx]
		G.fx(self, ability)

func get_damage(ptype, p):
	if ptype == "true":
		return p
	elif ptype == "bash":
		return round(R.f() * dat.g("strength", 1) * p * .01)
	elif ptype == "cut":
		return round(R.f() * p)

func set_delay(p):
	delay = max(delay, p)

func set_state(state, force=false):
	if force or delay == 0:
		if state == "move":
			var dir = pos.direction_to(controller.target)
			if move(dir) != null:
				var ms = dat.g("move speed", 1)
				if "agile" in flags:
					ms += max(0, controller.target.slow - 4)
				elif !("float" in flags):
					ms += controller.target.slow
				delay = max(1, ms)
				set_move_delay_speed(delay)
				set_animation("walk")
				if !pos.visible and pos.sight_frame <= G.you.n_camera.sight_frame - 1:
					G.make_particle("Sound", pos.to_pixel())
			else:
				delay = 1
		elif state == "attack":
			var used
			var dist = pos.distance_to(controller.target)
			if dist == 1:
				used = draw_skill("onattack")
			elif dist == 2:
				set_state("move")
				if pos.distance_to(controller.target) == 1:
					used = roll_skill("oncharge")
			if used == null:
				last_skill = null
			elif used[1].get("repeatable", true):
				last_skill = used[0]
		else:
			set_animation(state)

func set_animation(p):
	current_action = p
	if delay > 0:
		if p == "knockout":
			if "getup" in flags:
				return
		n_animation.play(p, -1, 1/(delay*.15))
	else:
		n_animation.play(p)

func set_animation_direction(y):
	if y != 0:
		face(1)

func draw_skill(type, mode=0):
	var roll = R.ir(0, 99)
	var skill
	var data
	if deck.empty():
		skill = "wait"
		data = G.data.skill_data.get("wait")
		G.influence.do(self, skill, data, 0)
		return [skill, data]
	else:
		skill = deck.pop_front()
		data = G.data.skill_data.get(skill)
		if data != null and data.target == type:
			if data.chance > roll:
				G.influence.do(self, skill, data, mode)
				return [skill, data]
		return draw_skill(type)

func roll_skill(type, mode=0):
	var data
	for skill in dat.g("actives", []):
		data = G.data.skill_data.get(skill)
		if data != null and data.target == type:
			if R.r_percent(data.chance):
				G.influence.do(self, skill, data, mode)
				return [skill, data]
	return null

func get_health():
	var vit = dat.g("vitality", 1) * 2
	if vit <= 0:
		return 0
	var hurt = dat.g("damage", 0)
	return 1 - (hurt / vit)

func hit(_type, dmg, _hitter):
	if dmg > 0:
		if _hitter != null and controller != null:
			controller.on_hit(_hitter)
		if pos.light < 0 and R.b():
			G.display_damage(pos.to_pixel(), "MISS", Color.darkgray)
			return
		var used = roll_skill("onhit", 3)
		if used != null:
			var block = used[1].get("block", 0)
			if block >= dmg:
				return
			else:
				dmg -= block
		if current_action == "knockout":
			dmg *= 2
		dat.add("damage", dmg, 0)
		delay = 2
		set_animation("hit")
		buffs.on_interrupt("interrupt")
		show_healthbar()
		G.make_particle("Blood", pos.to_pixel(), {"direction": Vector3(R.fr(-1, 1), R.fr(-1, 1), 0), "spread": 60})
		var health_percent = get_health()
		G.display_damage(pos.to_pixel(), round(dmg), Color(1,health_percent,0))
		flash("red", health_percent + .1)
		if health_percent <= 0:
			is_dead = true
		elif health_percent <= .5:
			if !buffs.has("injury"):
				G.fx(self, "injury")
	elif dmg < 0:
		dat.add("damage", dmg, 0, dat.g("vitality"))
		show_healthbar()
		flash("green", dmg * -.2)
		G.display_damage(pos.to_pixel(), round(dmg), Color.green)

func on_turn():
	if is_dead:
		die()
	else:
		if dirty_dat:
			dirty_dat = false
			on_dat()
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
	n_tween.interpolate_property(n_mat, "shader_param/" + color,
		1, 0, dur,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	n_tween.start()

func face(p):
	if (p > 0) != (n_sprites.scale.x > 0):
		n_sprites.scale.x *= -1
		n_skeleton.scale.x *= -1

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
	if n_healthbar != null:
		n_healthbar.queue_free()
		remove_child(n_healthbar)
	if controller != null:
		controller.remove()
	$Shadow.queue_free()
	for child in get_children():
		child.queue_free()
	.remove()
	buffs.remove()
	G.turn.remove(self)

func is_visible():
	return n_sprites.visible

func show_healthbar():
	if n_healthbar == null:
		n_healthbar = Healthbar.instance()
		add_child(n_healthbar)
	var vit = dat.g("vitality", 1) * 2
	n_healthbar.set_mhp(vit)
	n_healthbar.set_hp(vit - dat.g("damage", 0))
