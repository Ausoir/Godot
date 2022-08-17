extends Control

var state = 1

func _ready():
	G.rng.set_seed()

func _input(event):
	G.get_tree().set_input_as_handled()
	if state == 1:
		if event is InputEventMouseButton:
			if !event.pressed:
				start()
		elif event is InputEventKey:
			if !event.pressed:
				start()

func start():
	if state < 2:
		state = 2
		$AnimationPlayer.play("FadeOut")

func on_fadeout():
	G.game.start_game()
