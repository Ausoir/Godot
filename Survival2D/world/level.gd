extends BaseButton

onready var Loading = preload("res://interface/Loading.tscn")
var loading_page
var area
var position
var difficulty: float
var objective
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
	var rating = "[color=#AA4]mild[/color]"
	if difficulty > .8:
		rating = "[color=#F20]brutal[/color]"
	elif difficulty > .6:
		rating = "[color=#C60]savage[/color]"
	elif difficulty > .4:
		rating = "[color=#EE4]wild[/color]"
	elif difficulty > .2:
		rating = "[color=#AAA]normal[/color]"
	var obj = "[color=#BA6]"+objective.capitalize()+"[/color]"
	$Control.set_bbcode(area.capitalize() + "\n" + obj + "\n" + rating)

func set_area(p):
	for i in G.data.vars.area:
		var dat = G.data.vars.area[i]
		if p < dat.biome:
			area = i
			objective = R.r_arr(dat.modes)
			return

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
	var root = G.get_tree().get_root()
	root.remove_child(map)
	map.queue_free()
	loading_page = Loading.instance()
	loading_page.connect("ready",self,"on_loading")
	G.ui.add_child(loading_page)

func on_loading():
	R.set_seed(G.vars.seed)
	G.travel(area)
	if G.world.paint_spawn(side) != null:
		var load_data = G.vars.load_data
		if load_data: #From char creation
			G.you.load_data(load_data)
		G.vars.erase("load_data")
		G.set_process(true)
	else:
		push_error("No spawn points found")
	G.cmds([["make","mode "+objective,G.world.tiles[0][0]]])
	G.ui.remove_child(loading_page)
