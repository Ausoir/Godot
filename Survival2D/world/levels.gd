extends Control

const Level = preload("res://world/Level.tscn")
const sx = 13
const sy: int = 9
var blueprint
var mouse_vec
var position: int
var position_x: int
var position_y: int
var pressed

func _ready():
	R.set_seed(G.vars.map.seed)
	G.vars.map.seed = R.init_seed
	position = int(G.vars.map.current)
	position_x = position % sx
	#warning-ignore:integer_division
	position_y = int(position / sx)
	if position == -1:
		position_x = -999 #make entrance from left
	var biome = load("res://world/generator.gd").new()
	var biomemap = biome.make_perlin(sx, sy, 2)
	var maze = load("res://world/generator_maze.gd").new()
	var map = maze.generate_maze(sx+1, sy+1)
	blueprint = biome.make_base(sx, sy, null)
	for y in range(sy):
		for x in range(sx):
			var v = map[y+1][x+1]
			var routes = get_routes(map, x+1, y+1, sx, sy)
			if v == 1:
				var placeholder = Control.new()
				placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
				$Grid.add_child(placeholder)
			elif v == 2 or routes == 1:
				var lvl = Level.instance()
				blueprint[y][x] = lvl
				lvl.modulate.b = 0
				$Grid.add_child(lvl)
			else:
				var lvl = Level.instance()
				blueprint[y][x] = lvl
				lvl.rating = int(clamp(max(x/float(sx), y/float(sy*1.4)) + R.fr(-.4, 0), 0, 1)/.25)+1
				lvl.set_area(biomemap[y][x])
				lvl.map = self
				lvl.refresh(x, y, y*sy+x)
				if position == -1 and x == 0:
					lvl.set_mode(1)
				elif lvl.position == position:
					lvl.set_mode(2)
				$Grid.add_child(lvl)
	if position != -1:
		var poi = []
		for comppos in G.vars.map.complete:
			var cx = int(comppos) % sx
			var cy = int(comppos / sx)
			for i in range(4):
				var t = find_adjacent_poi(i, cx, cy)
				if t != null and !(t in poi) and !((t[0]+t[1]*sy) in G.vars.map.complete):
					poi.append(t)
			if blueprint[cy][cx] != null:
				blueprint[cy][cx].set_mode(0)
		for i in poi:
			blueprint[i[1]][i[0]].set_mode(1)

func find_adjacent_poi(dir, x, y):
	if x < 0 or y < 0 or x > sx or y > sy or blueprint[y][x] == null:
		return null
	if blueprint[y][x].area != null and blueprint[y][x].position != G.vars.map.current:
		return [x, y, dir]
	if dir == 0:
		return find_adjacent_poi(dir, x, y-1)
	elif dir == 1:
		return find_adjacent_poi(dir, x+1, y)
	elif dir == 2:
		return find_adjacent_poi(dir, x, y+1)
	elif dir == 3:
		return find_adjacent_poi(dir, x-1, y)

func get_routes(map, x, y, sx, sy):
	var left = x <= 1 or map[y][x-1] == 1
	var right = x >= sx or map[y][x+1] == 1
	var up = y <= 1 or map[y-1][x] == 1
	var down = y >= sy or map[y+1][x] == 1
	if left and right and !up and !down:
		return 1
	elif up and down and !left and !right:
		return 1
	elif !up and !down and !left and !right:
		return 2
	return 0

func _on_gui_input(event):
	if event is InputEventMouseMotion:
		if pressed:
			$Grid.rect_position += event.position - mouse_vec
			mouse_vec = event.position
	elif event is InputEventMouseButton:
		pressed = event.is_pressed()
		if pressed:
			mouse_vec = event.position
