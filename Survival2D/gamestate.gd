extends Node

var player_name = "Player"

func travel(_map):
	G.get_tree().set_pause(true)
	G.time.reset()
	var root = get_tree().get_root()
	if G.world.get_parent() != null:
		root.remove_child(G.world)
		G.world.others.remove_child(G.sfx)
	var newworld = load('res://world/World.tscn').instance()
	root.add_child(newworld)
	G.world = newworld
	G.world.create(_map)
	G.world.others.add_child(G.sfx)
	if G.you.get_parent() != null:
		G.you.get_parent().remove_child(G.you)
	G.world.players.add_child(G.you)
	if G.you.unit != null:
		G.you.unit.move_world(G.world)
	G.get_tree().set_pause(false)

func level_select():
	clean_up()
	start_game()

func end_game():
	get_tree().notification(MainLoop.NOTIFICATION_WM_QUIT_REQUEST)

func restart():
	clean_up()
	get_tree().change_scene_to(load("res://Start.tscn").instance())

func clean_up():
	G.time.set_process(false)
	var root = G.get_tree().get_root()
	for i in root.get_children():
		if i != self and i != G and i != R:
			i.queue_free()
			root.remove_child(i)
	for i in G.get_children():
		i.queue_free()
		G.remove_child(i)
	G._ready()
	G.temp.clear()
	G.temp.discover = null

func start_game():
	if !gamestate.load_game():
		G.get_tree().change_scene_to(load("res://world/Creation.tscn"))
	else:
		G.get_tree().change_scene_to(load("res://world/Levels.tscn"))

func save_game():
	var save_game = File.new()
	save_game.open("user://savegame.save", File.WRITE)
	if "dead" in G.vars:
		save_game.store_line("")
	elif G.you.unit != null:
		G.vars["seed"] = R.init_seed
		save_game.store_line(to_json(G.vars))
		var player_data = G.you.unit.serialize()
		save_game.store_line(to_json(player_data))
	save_game.close()

func load_game():
	var r = true
	var save_game = File.new()
	var line
	var save_exists = save_game.file_exists("user://savegame.save")
	if save_exists:
		save_game.open("user://savegame.save", File.READ)
		line = save_game.get_line()
	if !save_exists or line.empty():
		save_game.close()
		save_game = File.new()
		save_game.open("res://assets/template.save", File.READ)
		line = save_game.get_line()
		r = false
	G.vars = parse_json(line)
	G.vars.load_data = parse_json(save_game.get_line())
	save_game.close()
	return r
