extends Node


var rng = RandomNumberGenerator.new()

var world
var target
var state = "idle"
var sight_range = 800

var object = preload("res://objects/object.tscn")
var Pathing = preload("res://objects/pathing.gd")
var pathing


func _ready():
	$think.connect("timeout", self, "_on_timer_timeout")
	world = get_node("/root/globals").world
	pathing = Pathing.new(world)


func _on_timer_timeout():
	if target != null:
		var unit = $unit
		var collision = world.check_collision(unit.position, target.position, [unit])
		if not collision or collision.collider == target:
			state = "hunt"
			pathing.result = []
			unit.set_task(["move", -1, target.position, 40])
		else:
			var health = collision.collider.get("health")
			if collision and health and health >= 0:
				state = "hunt"
				unit.set_task(["attack", -1, collision.collider.position])
			else:
				var path = pathing.update(unit.position, target.position)
				if path:
					state = "path"
					unit.set_task(["idle", 0])
					for p in path:
						unit.add_task(["move", -1, p, 8])
					pathing.result = []
	else:
		state = "idle"


func find_player(playerunit):
	var unit = $unit
	var collision = world.check_collision(unit.position, playerunit.position, [unit])
	if collision and collision.collider == playerunit:
		var dist = unit.position.distance_to(playerunit.position)
		if dist < sight_range:
			target = playerunit


func _physics_process(_delta):
	var unit = $unit
	if state == "hunt":
		if unit.task[0] == "move":
			if (target.position - unit.position).length() < 80:
				unit.set_task(["attack", -1, target.position])
			else:
				unit.task[2] = target.position
		elif unit.task[0] == "attack":
			unit.task[2] = target.position
