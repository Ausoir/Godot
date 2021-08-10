extends Node


var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	get_node("Timer").connect("timeout", self, "_on_timer_timeout") 


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_timer_timeout():
	var unit = get_node("unit")
	unit.set_goal(Vector2(unit.position.x + rng.randi_range(-600, 600),
						unit.position.y + rng.randi_range(-600, 600)))
