extends Node

const Properties = preload("res://classes/properties.gd")
var world = preload("res://world/world.tscn").instance()
var rng = preload("res://classes/random.gd").new()
var time = preload("res://classes/time.gd").new()
var field = preload("res://world/field.gd").new()
var factory = preload("res://classes/factory.gd").new()
var you


func _ready():
	G.rng.randomize()


func _process(delta):
	time.on_process(delta)
