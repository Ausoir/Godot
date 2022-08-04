extends "res://objects/item.gd"

const Ai = preload("res://objects/ai.gd")
const Buffs = preload("res://objects/buffs.gd")

onready var n_sprites = $Sprites
onready var n_animation = $Animation
onready var n_sprite = $Sprites/Sprite
onready var n_skeleton = $Skeleton2D

var delay = 0

var is_dead = false
var controller
var cooldowns = {}
var buffs = Buffs.new(self)
var current_action = ""
var has_on_turn = false

func _ready():
	n_collider = get_node("Body")
	n_collider.parent = self
	for i in dat.g("buffs", []):
		G.influence.do(i, self)
	if !dat.g("controlled", false):
		possess()

func set_seed():
	pass

func on_change(p):
	if p == "dat":
		layer = dat.g("layer", 0)
		var oldcol = col
		col = dat.g("col", 12)
		if col != oldcol:
			update_col(col)
		for team in G.world.team:
			if self in team:
				team.erase(self)
		var faction = dat.g("faction", -1)
		if faction != -1:
			if !(self in G.world.team[faction]):
				G.world.team[faction].append(self)
		flags = dat.g("flags", [])
		if dat.g("onturn") != null:
			has_on_turn = true
		else:
			has_on_turn = false
	if controller != null:
		controller.on_change(p)

func update_col(p):
	var body = get_node("Body")
	body.collision_mask = p
	if p & 12 > 0:
		body.collision_layer = p | 2
	else:
		body.collision_layer = p

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
	ctlr.on_assign()

func can_carry(_w):
	return false

func ability(idx, at):
	var abilities = dat.g("abilities", [])
	if idx < abilities.size():
		face_toward(at)
		var ability = abilities[idx]
		return G.influence.do(ability, self, at)

func get_damage(ptype, p):
	if ptype == "true":
		return p
	elif ptype == "bash":
		return round(R.f() * dat.g("strength", 1) * p * .01)
	elif ptype == "cut":
		return round(R.f() * p)

func reposition(p):
	position = p
	on_slide()

func place(p):
	.place(p)
	n_collider.check_overlap()

func slide(tox, toy):
	var ms = dat.g("move speed", 0)
	if ms > 0:
		if !("float" in flags):
			ms = max(.2, ms * pos.slow)
		n_animation.play("walk", -1, ms / 20)
		var deg = atan2(toy-position.y, tox-position.x)
		var vx = cos(deg)
		var vy = sin(deg)
		if vx > .1:
			face(1)
		elif vx < -.1:
			face(-1)
		n_collider.vel.x += vx * ms
		n_collider.vel.y += vy * ms
	return on_slide()

func on_slide():
	var newpos = pos.world.from_vec(position)
	if newpos != pos:
		pos.remove_item(self)
		newpos.add_item(self)
		on_relocate()
		newpos.play_step_sound()
		if !newpos.visible and G.you.n_camera.is_in_range(newpos):
			G.make_particle("Sound", newpos.position, null, true)
	if delay == 0:
		var col = n_collider.get_collider(dat.g("faction", -1))
		if col != null:
			controller.target = col
			face_toward(col.position)
			roll_skill("onattack")
			return col

func set_animation(p, spd=0):
	current_action = p
	if spd > 0:
		n_animation.play(p, -1, 1/(spd*.15))
	else:
		n_animation.play(p)

func roll_skill(type, mode=0):
	var data
	for skill in dat.g("skills", []) + ["wait"]:
		data = G.data.skill_data.get(skill)
		if data != null and data.target == type:
			if R.r_percent(data.chance):
				G.influence.do(skill, self, controller.target, mode, data)
				return [skill, data]
	return null

func on_kill(killed):
	if "cannibal" in flags:
		hit("true", -2, self)
	controller.on_kill(killed)

func hit(_type, dmg, _hitter):
	if dmg > 0:
		if _hitter != null and controller != null:
			controller.on_hit(_hitter)
		if _type != "true":
			var block = get_defense(_type)
			var used = roll_skill("onhit", 3)
			if used != null:
				block += used[1].get("block", 0)
			if block >= dmg:
				G.display_damage("MISS", pos.position, Color.darkgray)
				return
			else:
				dmg -= block
			if dmg > 0:
				if _type == "cut":
					G.sfx.play_hit(_type, dat.g("mat","flesh"), position)
					G.make_particle("Cut", pos.position)
				elif _type == "bash":
					G.sfx.play_hit(_type, dat.g("mat","flesh"), position)
					G.make_particle("Hit", pos.position)
				elif _type == "steal":
					G.sfx.play_hit(_type, dat.g("mat","flesh"), position)
					G.make_particle("Hit", pos.position)
					if _hitter != null:
						G.cmd(["*dmg",_hitter,-dmg])
			else:
				G.make_particle("Glance", pos.position)
		dat.add("damage", dmg, 0)
		buffs.disrupt_hit = true
		show_healthbar()
		G.make_particle("Blood", pos.position, {"direction": Vector3(R.fr(-1, 1), R.fr(-1, 1), 0), "spread": 60})
		G.display_damage(round(dmg), pos.position, Color.red)
		flash(0, dmg * .2)
		on_health_change()
		if is_dead:
			if _hitter != null:
				_hitter.on_kill(self)
	elif dmg < 0:
		dat.add("damage", dmg, 0, dat.g("vitality"))
		show_healthbar()
		flash(1, dmg * -.2)
		G.display_damage(round(dmg), pos.position, Color.green)

func on_health_change():
	var health_percent = get_health()
	if health_percent <= 0:
		is_dead = true
	elif health_percent <= .5:
		if !buffs.has("injury"):
			G.influence.do("injury", self)

func on_turn():
	if is_dead:
		die()
	else:
		if dirty_dat:
			on_change("dat")
			dirty_dat = false
		if delay == 0:
			if controller != null:
				controller.on_turn()
		else:
			if delay > 0:
				delay -= 1
			if delay == 0:
				set_animation("idle")
		for i in cooldowns:
			if cooldowns[i] <= 0:
				cooldowns.erase(i)
			else:
				cooldowns[i] -= 1
		if has_on_turn:
			.on_turn()

func face(p):
	if (p > 0) != (n_sprites.scale.x > 0):
		n_sprites.scale.x *= -1
		n_skeleton.scale.x *= -1

func face_toward(p):
	if p != null:
		if p.x > position.x:
			face(1)
		elif p.x < position.x:
			face(-1)

func die():
	if self in pos.world.team:
		var faction = dat.g("faction", -1)
		if faction != -1:
			pos.world.team[faction].erase(self)
	G.factory.make_corpse(self, pos)
	remove()

func remove():
	if n_collider != null:
		n_collider.queue_free()
	if controller != null:
		controller.remove()
	$Shadow.queue_free()
	for child in get_children():
		child.queue_free()
	.remove()
	buffs.remove()

func move_world(wld):
	var faction = dat.g("faction", -1)
	if faction != -1:
		pos.world.team[faction].erase(self)
	.move_world(wld)
	if faction != -1:
		G.world.team[faction].append(self)
	controller.tasks.clear()
	if !G.world.turn.has(self):
		G.world.turn.add(self)
	if !buffs.states.empty():
		if !G.world.turn.has(buffs):
			G.world.turn.add(buffs)
