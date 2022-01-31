extends Particles2D

export var duration: float = 1.0

func _ready():
	set_emitting(true)

func _process(delta):
	duration -= delta
	if duration < 0:
		G.world.others.remove_child(self)
		queue_free()

func run_details(args):
	for i in args:
		if i == "direction":
			process_material.direction = args[i]
		elif i == "spread":
			process_material.spread = args[i]

func change_text(p):
	$Label/Control/Label.text = str(p)
