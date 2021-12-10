extends "res://objects/units/controller.gd"

var target
var sight_range = 800
var state = "idle"


func think():
	if target != null:
		var collision = G.world.check_collision(unit.position, target.position, [unit])
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
	var collision = G.world.check_collision(unit.position, playerunit.position, [unit])
	if collision and collision.collider == playerunit:
		var dist = unit.position.distance_to(playerunit.position)
		if dist < sight_range:
			target = playerunit
