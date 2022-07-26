extends Control

var state = 0

func _ready():
	state = 0
	var screen_size = get_viewport().get_size_override()
	$Label.rect_position.x = screen_size.x / 2 - $Label.rect_size.x / 2
	$Label.rect_position.y = screen_size.y - 40
	$Sprite.position = screen_size / 2
#	$AnimationPlayer.play("FadeIn")
	on_fadeout()

func _input(event):
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

func on_fadein():
	state = 1

func on_fadeout():
	if !gamestate.load_game():
		get_tree().change_scene_to(load("res://world/Creation.tscn"))
	else:
		get_tree().change_scene_to(load("res://world/Levels.tscn"))
