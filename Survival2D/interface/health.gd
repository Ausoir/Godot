extends Node2D

onready var n_bg = $Bg
onready var n_mg = $Mg
onready var n_fg = $Fg
var lifetime = 3
var color = Color(1, 1, 1, 1)
var maxHp = 1
var hp = 1
var ratio_from = 1
var ratio_to = 1
var phase = 0

func set_mhp(_p):
	ratio_from = hp / maxHp
	maxHp = max(_p, 1)
	on_change()

func set_hp(_p):
	ratio_from = hp / maxHp
	hp = _p
	on_change()

func on_change():
	ratio_to = hp / maxHp
	if ratio_from != ratio_to:
		phase = 1
		lifetime = 3
		n_mg.rect_scale.x = n_fg.rect_scale.x
		set_process(true)
		color.a = 1
		set_modulate(color)
		show()

func _process(delta):
	lifetime -= delta
	if lifetime <= 0:
		set_process(false)
		hide()
	elif lifetime < 1:
		color.a = lifetime * .1
		set_modulate(color)
	else:
		if phase == 1:
			lifetime = 2
			var diff = n_fg.rect_scale.x - ratio_to
			n_fg.rect_scale.x -= diff * delta * 10
			if diff < .01:
				phase = 2
		elif phase == 2:
			lifetime = 2
			var diff = n_mg.rect_scale.x - ratio_to
			n_mg.rect_scale.x -= diff * delta * 10
			if diff < .01:
				phase = 3
