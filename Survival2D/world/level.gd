extends BaseButton

var loading_page
var area
var position
var rating
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
	var rating_txt = get_rating_text(rating)
	var obj = "[color=#BA6]"+objective.capitalize()+"[/color]"
	$Control.set_bbcode(area.capitalize() + "\n" + obj + "\n" + rating_txt)

func get_rating_text(p):
	var rating_txt = "[color=#C60]savage[/color]"
	if p == 3:
		rating_txt = "[color=#EE4]wild[/color]"
	elif p == 2:
		rating_txt = "[color=#AAA]normal[/color]"
	elif p == 1:
		rating_txt = "[color=#AA4]mild[/color]"
	return rating_txt

func set_area(p):
	for i in G.data.vars.area:
		var dat = G.data.vars.area[i]
		if p < dat.biome:
			area = i
			objective = G.rng.r_arr(dat.modes)
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
	pass
#	loading_page = Loading.instance()
#	G.ui.add_child(loading_page)
#	G.events.append([0.1, funcref(self, "on_loading"), []])
#	G.time.set_process(true)

func on_loading():
	G.get_tree().set_pause(true)
	G.get_tree().get_root().remove_child(map)
	map.queue_free()
	G.rng.set_seed(G.vars.seed)
	G.game.travel(area)
	if G.world.paint_spawn(side) != null:
		var load_data = G.vars.get("load_data")
		if load_data != null: #From char creation
			G.you.unserialize(load_data)
		G.vars.erase("load_data")
	else:
		push_error("No spawn points found")
	G.vars.map.next = position
	G.temp.enterside = side
	G.temp.area = area
	G.temp.rating = rating
	G.temp.objective = objective
	if "creation" in G.temp:
		G.cmds(G.temp.creation)
		G.temp.erase("creation")
	G.cmds([["make","mode "+objective,G.world.tiles[0][0]],["*=","$t","area",area],["*=","$t","rating",rating]])
	G.ui.remove_child(loading_page)
	G.get_tree().set_pause(false)
