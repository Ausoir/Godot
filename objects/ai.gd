extends Node


const aggro_range = 800

var rng = RandomNumberGenerator.new()

var world
var target
var state = "idle"

var Pathing = preload("res://objects/pathing.gd")
var pathing


func _ready():
	$Timer.connect("timeout", self, "_on_timer_timeout")
	world = get_node("/root/globals").world
	pathing = Pathing.new(world)


func _on_timer_timeout():
	target = find_target(world.get_node("Players").get_children())
	if target != null:
		state = "hunt"
		var unit = $unit
		var path = pathing.update(unit.position, target.position)
		unit.set_task(["move", 5, target.position])
		if path:
			for p in path:
				unit.add_task(["move", -1, p * 64, 24])
			unit.add_task(["move", -1, target.position, 32])
			unit.add_task(["attack", 150, target.position])
	else:
		state = "idle"


func find_target(nodes):
	var unit = $unit
	var shortest_unit
	var shortest_dist = aggro_range
	for node in nodes:
		var to = node.get_node("unit")
		var dist = unit.position.distance_to(to.position)
		if dist < shortest_dist:
			shortest_unit = to
			shortest_dist = dist
	return shortest_unit


func _physics_process(_delta):
	var unit = $unit
	if state == "hunt":
		if unit.task[0] == "attack":
			unit.task[2] = target.position
