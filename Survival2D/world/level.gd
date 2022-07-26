extends BaseButton

var area
var position
var difficulty: float
var mission
var map
var side = 0
var x
var y

func refresh(px, py, pp):
	x = px
	y = py
	var diffx = map.position_x - x
	var diffy = map.position_y - y
	if abs(diffx) > abs(diffy):
		if diffx > 0:
			side = 1
		else:
			side = 3
	elif diffy > 0:
		side = 2
	position = pp
	var objective = "[color=#BA6]Scavenge[/color]"
	if mission == 1:
		objective = "[color=#BA6]Survive[/color]"
	elif mission == 2:
		objective = "[color=#BA6]Escape[/color]"
	elif mission == 3:
		objective = "[color=#BA6]Assault[/color]"
	var rating = "[color=#AA4]mild[/color]"
	if difficulty > .8:
		rating = "[color=#F20]brutal[/color]"
	elif difficulty > .6:
		rating = "[color=#C60]savage[/color]"
	elif difficulty > .4:
		rating = "[color=#EE4]wild[/color]"
	elif difficulty > .2:
		rating = "[color=#AAA]normal[/color]"
	$Control.set_bbcode(area.capitalize() + "\n" + objective + "\n" + rating)

func set_mode(p):
	if p == 1:
		set_disabled(false)
		set_mouse_filter(Control.MOUSE_FILTER_PASS)
	else:
		set_disabled(true)
		set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
		if p == 0:
			modulate.b = .8
		else:
			modulate.r = 0
			modulate.b = .4

func _on_pressed():
	G.get_tree().get_root().remove_child(map)
	R.set_seed(G.vars.seed)
	G.travel(area)
	G.world.paint_spawn(side, "dirt")
	G.you.load_data(G.vars.load_data)
	G.vars.erase("load_data")
	G.set_process(true)
