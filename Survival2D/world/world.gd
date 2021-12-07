extends Node

var tileset = preload("res://assets/tileset.tres")
var generator_field = preload("res://world/generator_field.gd").new()

onready var tilemap = $Tilemap
onready var objects = $Objects

var map_size = Vector2(0, 0)

var aggro_turn = 0


func _physics_process(_delta):
	var players = gamestate.players.values()
	if aggro_turn >= players.size():
		aggro_turn = 0
	else:
#		players[aggro_turn].aggro($NPCs.get_children())
		aggro_turn += 1


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
