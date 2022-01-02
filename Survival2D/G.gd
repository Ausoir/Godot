extends Node

const W = 32
const H = 32
const HW = 16
const HH = 16
const COL_SIGHT = 0
const COL_TERRAIN = 1
const COL_OBJECT = 2
const COL_MAGIC = 3
const CARDINALS = [[0,-1],[1,-1],[1,0],[1,1],[0,1],[-1,1],[-1,0],[-1,-1]]
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
var influence = preload("res://objects/units/influence.gd").new()
var data = preload("res://classes/json.gd").new()
var command = preload("res://classes/command.gd").new()
var rng = preload("res://classes/random.gd").new()
var time = preload("res://classes/time.gd").new()
var turn = preload("res://classes/turn.gd").new()
var field = preload("res://world/field.gd").new()
var factory = preload("res://classes/factory.gd").new()
var world = preload("res://world/World.tscn").instance()
var ui = preload("res://interface/Interface.tscn").instance()
var events = []
var you


func _ready():
	get_tree().get_root().call_deferred("add_child", G.ui)
	G.rng.randomize()
#	G.rng.set_seed(11111)
	print(G.rng.seed)

func _process(delta):
	time.on_process(delta)
	if time.eighth_second:
		turn.on_process()
	elif !events.empty():
		var ev = events.pop_back()
		ev.call_func()

func pixel_to_pos(pos):
	return Vector2(pos.x / G.W, pos.y / G.H).floor()

func pos_to_pixel(pos):
	return Vector2(pos.x*G.W+G.HW, pos.y*G.H+G.HH)

func vector_to_dir(x, y):
	var count = 0
	for i in CARDINALS:
		if i[0] == x and i[1] == y:
			return count
		count += 1

func get_tile(pos):
	return field.tiles[pos.y][pos.x]

func cmd(args, host=null):
	rpc("synced_cmd", args, host)
	return command.tgt

puppetsync func synced_cmd(args, host):
	command.assign(host)
	for arg in args:
		command.tgt = command.run(arg)
		if command.stop:
			break
	return command.tgt

func msg(msg):
	ui.message.add(msg)

func fx(host, effect):
	influence.do(host, effect)
