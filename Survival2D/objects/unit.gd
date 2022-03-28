extends "res://objects/item.gd"

const Ai = preload("res://objects/ai.gd")
const Buffs = preload("res://objects/buffs.gd")
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
const SPEED = 8

onready var n_sprites = $Sprites
onready var n_animation = $Animation
onready var n_sprite = $Sprites/Sprite
onready var n_skeleton = $Skeleton2D
onready var n_mat = n_sprite.material
var n_healthbar

var delay = 0

var is_dead = false
var controller
var cooldowns = {}
var buffs = Buffs.new(self)
var current_action = ""
var flash_state = [0, 0, 0, 0]

func _ready():
	n_collider = get_node("Body")
	n_collider.parent = self
	for i in dat.g("buffs", []):
		G.influence.do(i, self)
	if !dat.g("controlled", false):
		possess()

func set_seed():
	pass

func update_dat():
	layer = dat.g("layer", 0)
	var oldcol = col
	col = dat.g("col", 0)
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
	if controller != null:
		controller.update_dat()

func update_col(p):
	get_node("Body").collision_layer = p

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
		return G.influence.do(ability, self, at, 0, null)

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

func slide(diff):
	var ms = dat.g("move speed", 0)
	if ms > 0:
		if !("float" in flags):
			ms = max(.2, ms * pos.slow)
		n_animation.play("walk", -1, ms / 4)
		var diff_normalized = diff.normalized()
		if diff_normalized.x > 0:
			face(1)
		elif diff_normalized.x < 0:
			face(-1)
		ms *= SPEED
		n_collider.vel = Vector2(diff_normalized.x * ms, diff_normalized.y * ms)
	return on_slide()

func on_slide():
	var newpos = pos.world.from_vec(position)
	if newpos != pos:
		pos.remove_item(self)
		newpos.add_item(self)
		on_relocate()
		if !newpos.visible and newpos.sight_frame <= G.you.n_camera.sight_frame - 1:
			G.make_particle("Sound", newpos.position)
	if delay == 0:
		var col = n_collider.get_collider(dat.g("faction", -1))
		if col != null:
			controller.target = col
			face_toward(col.position)
			roll_skill("onattack")
			return col

func set_animation(p, spd=0):
	if p == "knockout":
		if "getup" in flags:
			delay = 0
			return
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

func get_health():
	var vit = dat.g("vitality", 1) * 2
	if vit <= 0:
		return 0
	var hurt = dat.g("damage", 0)
	return 1 - (hurt / vit)

func on_kill(killed):
	if "cannibal" in flags:
		hit("true", -2, self)
	controller.on_kill(killed)

func hit(_type, dmg, _hitter):
	if dmg > 0:
		if _hitter != null and controller != null:
			controller.on_hit(_hitter)
		if pos.light < 0 and R.b():
			G.display_damage(pos.position, "MISS", Color.darkgray)
			return
		if _type != "true":
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
		set_animation("hit", 2)
		buffs.on_interrupt("interrupt")
		show_healthbar()
		G.make_particle("Blood", pos.position, {"direction": Vector3(R.fr(-1, 1), R.fr(-1, 1), 0), "spread": 60})
		var health_percent = get_health()
		G.display_damage(pos.position, round(dmg), Color(1,health_percent,0))
		flash(0, (1 - health_percent)*.3 + .1)
		if health_percent <= 0:
			is_dead = true
			if _hitter != null:
				_hitter.on_kill(self)
		elif health_percent <= .5:
			if !buffs.has("injury"):
				G.influence.do("injury", self)
	elif dmg < 0:
		dat.add("damage", dmg, 0, dat.g("vitality"))
		show_healthbar()
		flash(1, dmg * -.2)
		G.display_damage(pos.position, round(dmg), Color.green)

func on_turn():
	if is_dead:
		die()
	else:
		if dirty_dat:
			update_dat()
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

func _process(delta):
	if flash_state[0] > 0:
		var percent = flash_state[0] / flash_state[1]
		if flash_state[2] > 0:
			n_mat.set_shader_param("red", flash_state[2]*percent)
		elif flash_state[3] > 0:
			n_mat.set_shader_param("green", flash_state[3]*percent)
		flash_state[0] -= delta

func flash(c, dur):
	dur = max(.1, dur)
	flash_state = [dur, dur, 0, 0]
	flash_state[2 + c] = 1

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
	if n_healthbar != null:
		n_healthbar.queue_free()
	if controller != null:
		controller.remove()
	$Shadow.queue_free()
	for child in get_children():
		child.queue_free()
	.remove()
	buffs.remove()
	G.world.turn.remove(self)

func show_healthbar():
	if n_healthbar == null:
		n_healthbar = Healthbar.instance()
		add_child(n_healthbar)
	var vit = dat.g("vitality", 1) * 2
	n_healthbar.set_mhp(vit)
	n_healthbar.set_hp(vit - dat.g("damage", 0))

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
