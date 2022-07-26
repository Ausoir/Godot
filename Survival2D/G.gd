extends Node

const W = 32
const H = 32
const HW = 16
const HH = 16
const OCTANT_FLIP = [[1, 0, 0, 1], [0, 1, 1, 0], [0, -1, 1, 0], [-1, 0, 0, 1], \
	[-1, 0, 0, -1], [0, -1, -1, 0], [0, 1, -1, 0], [1, 0, 0, -1]]
const CARDINALS = [[0,-1],[1,0],[0,1],[-1,0]]
const DIRS = [[0,-1],[1,-1],[1,0],[1,1],[0,1],[-1,1],[-1,0],[-1,-1]]
const UP = 0
const UPRIGHT = 1
const RIGHT = 2
const DOWNRIGHT = 3
const DOWN = 4
const DOWNLEFT = 5
const LEFT = 6
const UPLEFT = 7

const Damage_Label = preload("res://fx/particles/Damage_Label.tscn")
const Gfx = preload("res://fx/Gfx.tscn")
var sfx
var influence
var data
var time
var factory
var world
var ui
var custom
var command
var events = []
var vars = {}
var temp = {}
var you


func _ready():
	sfx = preload("res://fx/Sfx.tscn").instance()
	influence = preload("res://classes/influence.gd").new()
	data = preload("res://classes/json.gd").new()
	time = preload("res://classes/time.gd").new()
	factory = preload("res://classes/factory.gd").new()
	world = preload("res://world/World.tscn").instance()
	ui = preload("res://interface/Interface.tscn").instance()
	you = preload("res://view/Player.tscn").instance()
	custom = preload("res://classes/custom.gd").new()
	command = load("res://classes/command.gd").new()
	get_tree().get_root().call_deferred("add_child", ui)
	set_process(false)

func _process(delta):
	time.on_process(delta)
	if time.eighth_second:
		world.turn.process_frames += 1
		if time.second:
			custom.on_time()
	world.turn.on_process()
	for i in range(events.size()):
		var ev = events[i]
		ev[0] -= delta
		if ev[0] <= 0:
			if ev[1] == null:
				cmds(ev[2])
			else:
				ev[1].call_funcv(ev[2])
			events.remove(i)
			i -= 1

func pixel_to_pos(pos):
	return Vector2(pos.x / G.W, pos.y / G.H).floor()

func pos_to_pixel(pos):
	return Vector2(pos.x*G.W+G.HW, pos.y*G.H+G.HH)

func vector_to_dir(x, y):
	var count = 0
	for i in DIRS:
		if i[0] == x and i[1] == y:
			return count
		count += 1
	return -1

func get_autotile_coord(dirs):
	var v
	if dirs.empty():
		v = Vector2()
	else:
		if dirs == [0]:
			v = Vector2(0, 3)
		elif dirs == [1]:
			v = Vector2(1, 0)
		elif dirs == [2]:
			v = Vector2(0, 1)
		elif dirs == [3]:
			v = Vector2(3, 0)
		elif dirs == [0, 1]:
			v = Vector2(1, 3)
		elif dirs == [0, 2]:
			v = Vector2(0, 2)
		elif dirs == [0, 3]:
			v = Vector2(3, 3)
		elif dirs == [1, 2]:
			v = Vector2(1, 1)
		elif dirs == [1, 3]:
			v = Vector2(2, 0)
		elif dirs == [2, 3]:
			v = Vector2(3, 1)
		elif dirs == [0, 1, 2]:
			v = Vector2(1, 2)
		elif dirs == [0, 1, 3]:
			v = Vector2(2, 3)
		elif dirs == [0, 2, 3]:
			v = Vector2(3, 2)
		elif dirs == [1, 2, 3]:
			v = Vector2(2, 1)
		elif dirs == [0, 1, 2, 3]:
			v = Vector2(2, 2)
		else:
			v = Vector2()
	return v

func get_direction_between(from, to):
	var tx = from.x - to.x
	var ty = from.y - to.y
	if tx == 0 and ty == 0:
		return -1
	var dir
	var angle = atan2(ty, tx) + PI
	var octant = int(angle / .3927)
	if octant == 15 or octant == 0:
		dir = G.LEFT
	elif octant == 1 or octant == 2:
		dir = G.UPLEFT
	elif octant == 3 or octant == 4:
		dir = G.UP
	elif octant == 5 or octant == 6:
		dir = G.UPRIGHT
	elif octant == 7 or octant == 8:
		dir = G.RIGHT
	elif octant == 9 or octant == 10:
		dir = G.DOWNRIGHT
	elif octant == 11 or octant == 12:
		dir = G.DOWN
	elif octant == 13 or octant == 14:
		dir = G.DOWNLEFT
	return dir

func is_vec_in_range(pos):
	var dist = pos - you.n_camera.position
	var length = max(abs(dist.x), abs(dist.y))
	return length/H < you.n_camera.sight_range

func is_vec_visible(p):
	var pos = pixel_to_pos(p)
	var tile = world.get_tile(pos.x, pos.y)
	return tile != null and tile.visible

func make_particle(arg, pos, args=null, force=false):
	if (force and is_vec_in_range(pos)) or is_vec_visible(pos):
		var r = G.data.get_particle(arg)
		r.position = pos
		r.add()
		if args != null:
			r.run_details(args)
		return r

func display_damage(val, pos, color=Color.white, _scale=1, _speed=800, lifetime=200):
	if is_vec_visible(pos):
		var r = Damage_Label.instance()
		r.lifetime = lifetime
		r.rect_position = pos
		r.rect_position.y -= G.HH
		G.world.others.add_child(r)
		r.set_damage(str(val), color, _scale, _speed)

func cmds(args, host=null, ptgt=null):
	if ptgt != null:
		command.tgt = ptgt
	for arg in args:
		if command.stop:
			if command.onstop != null:
				G.msg(command.onstop)
			command.stop = false
			command.onstop = null
			return command.tgt
		elif command.ignore:
			command.ignore = false
		else:
			cmd(arg, host)
	command.onstop = null
	return command.tgt

func cmd(arg, host=null):
	command.tgt = command.run(arg, host)

func script(p, param):
	custom.run(p, param)

func msg(msg):
	ui.message.add(msg)

func travel(_map):
	get_tree().set_pause(true)
	var root = get_tree().get_root()
	if G.world.get_parent() != null:
		root.remove_child(G.world)
		G.world.others.remove_child(G.sfx)
	var newworld = load('res://world/World.tscn').instance()
	root.add_child(newworld)
	G.world = newworld
	G.world.create(_map)
	G.world.others.add_child(G.sfx)
	if G.you.get_parent() != null:
		G.you.get_parent().remove_child(G.you)
	G.world.players.add_child(G.you)
	if G.you.unit != null:
		G.you.unit.move_world(G.world)
	get_tree().set_pause(false)
