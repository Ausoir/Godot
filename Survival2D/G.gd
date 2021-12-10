extends Node

const CARDINALS = [[-1,0],[-1,-1],[0,-1],[1,-1],[1,0],[1,1],[0,1],[-1,1]]
const UP = 1
const UPRIGHT = 2
const RIGHT = 3
const DOWNRIGHT = 4
const DOWN = 5
const DOWNLEFT = 6
const LEFT = 7
const UPLEFT = 8

const Properties = preload("res://classes/properties.gd")
var command = preload("res://classes/command.gd").new()
var rng = preload("res://classes/random.gd").new()
var time = preload("res://classes/time.gd").new()
var turn = preload("res://classes/turn.gd").new()
var field = preload("res://world/field.gd").new()
var factory = preload("res://classes/factory.gd").new()
var world = preload("res://world/World.tscn").instance()
var you
var ui


func _ready():
	G.rng.randomize()

func _process(delta):
	time.on_process(delta)
	if time.eighth_second:
		turn.on_process()

func pixel_to_pos(pos):
	return (pos / 64).floor()

func pos_to_pixel(pos):
	return Vector2(pos.x*64+32, pos.y*64+32)

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

func message(msg):
	ui.message(msg)
