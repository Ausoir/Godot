extends Node

const W = 32
const H = 32
const HW = 16
const HH = 16
const COL_SIGHT = 0
const COL_TERRAIN = 1
const COL_OBJECT = 2
const COL_MAGIC = 3
const CARDINALS = [[0,-1],[1,0],[0,1],[-1,0]]
const DIRS = [[0,-1],[1,-1],[1,0],[1,1],[0,1],[-1,1],[-1,0],[-1,-1]]
const STATS = ["vitality", "strength", "intelligence", "agility", "perception", "move speed"]
const UP = 0
const UPRIGHT = 1
const RIGHT = 2
const DOWNRIGHT = 3
const DOWN = 4
const DOWNLEFT = 5
const LEFT = 6
const UPLEFT = 7

const Properties = preload("res://classes/properties.gd")
const Gfx = preload("res://classes/gfx.gd")
var Damage_Label = load("res://objects/particles/Damage_Label.tscn")
var influence = preload("res://objects/units/influence.gd").new()
var data = preload("res://classes/json.gd").new()
var time = preload("res://classes/time.gd").new()
var turn = preload("res://classes/turn.gd").new()
var field = preload("res://world/field.gd").new()
var factory = preload("res://classes/factory.gd").new()
var world = preload("res://world/World.tscn").instance()
var ui = preload("res://interface/Interface.tscn").instance()
var command = load("res://classes/command.gd").new()
var events = []
var onloads = []
var vars = {}
var you


func _ready():
	get_tree().get_root().call_deferred("add_child", G.ui)

func process_onload():
	for i in onloads:
		cmd(i[1], i[0])
	onloads.clear()

func _process(delta):
	time.on_process(delta)
	if time.eighth_second:
		turn.process_frames += 1
	turn.on_process()
	if !events.empty():
		var ev = events.pop_back()
		ev.call_func()

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

func cmd(args, host=null):
	rpc("synced_cmd", args, host)
	return command.tgt

puppetsync func synced_cmd(args, host):
	command.assign(host)
	for arg in args:
		if !command.ignore:
			command.tgt = command.run(arg)
		else:
			command.ignore = false
	return command.tgt

func msg(msg):
	ui.message.add(msg)

func fx(host, effect):
	influence.do(host, effect)

func make_particle(arg, pos, args=null):
	var r = G.data.get_particle(arg)
	r.position = pos
	r.add()
	if args != null:
		r.run_details(args)
	return r

func display_damage(pos, dmg, color=Color.white, _scale=1):
	var r = Damage_Label.instance()
	r.rect_position = pos
	r.rect_position.y -= HH
	world.others.add_child(r)
	r.set_damage(str(dmg), color, _scale)

func travel(_map):
	gamestate.save_game(_map)
	G.vars.time += 1
	G.world.daytime = G.vars.time % 2 == 0
	gamestate.load_game()
