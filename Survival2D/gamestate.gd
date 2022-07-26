extends Node

signal game_ended()
var player_name = "Player"


func end_game():
	if has_node("/root/World"):
		get_node("/root/World").queue_free()
	emit_signal("game_ended")

func start_local():
	var Player = load("res://view/Player.tscn")
	G.you = Player.instance()
	G.set_process(true)
	load_game()

func create_game(_player_units):
	G.world.create("city")
	for unit in _player_units:
		var player_pos = G.world.get_spawn_point()
		var player_unit = G.cmds([["make", "player", player_pos]])
		player_unit.possess(unit)

func restart():
	var root = G.get_tree().get_root()
	for i in root.get_children():
		i.queue_free()
		root.remove_child(i)
	root.add_child(load("res://G.gd").new())
	root.add_child(load("res://Start.tscn").instance())

func save_game(_map="city"):
	var save_game = File.new()
	save_game.open("user://savegame.save", File.WRITE)
	if G.you.unit.item_name == "ghost":
		save_game.store_line("")
	else:
		G.vars["seed"] = R.init_seed
		save_game.store_line(to_json(G.vars))
		var node_data = G.you.save_data()
		save_game.store_line(to_json(node_data))
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

func _notification(what):
	if what == Node.NOTIFICATION_WM_QUIT_REQUEST:
		save_game()
