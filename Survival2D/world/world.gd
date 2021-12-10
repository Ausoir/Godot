extends Node

var tileset = preload("res://assets/tileset.tres")
var generator_field = preload("res://world/generator_field.gd").new()

onready var tilemap = $Tilemap
onready var units = $Units
onready var objects = $Objects
onready var items = $Items
onready var players = $Players

var map_size = Vector2(0, 0)


func generate():
	generator_field.generate()


func get_tile_pos(x, y):
	return Vector2(x * 64 + 32, y * 64 + 32)


func check_collision(from, to, exclude):
	var space_state = $tilemap.get_world_2d().direct_space_state
	var result = space_state.intersect_ray(from, to, exclude, 1)
	return result


func make_particle(arg, pos):
	var r = load("res://objects/particles/" + arg + ".tscn").instance()
	r.position = pos
	$Particles.add_child(r)
	return r
