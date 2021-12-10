extends Node

# Default game server port. Can be any number between 1024 and 49151.
# Not on the list of registered or common ports as of November 2020:
# https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
const DEFAULT_PORT = 10567

# Max number of players.
const MAX_PEERS = 12

var peer = null

# Name for my player.
var player_name = "The Warrior"

# Names for remote players in id:name format.
var other_players = {}

# Signals to let lobby GUI know what's going on.
signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(what)

var rng = RandomNumberGenerator.new()


# Callback from SceneTree.
func _player_connected(id):
	# Registration of a client beings here, tell the connected player that we are here.
	rpc_id(id, "register_player", player_name)


# Callback from SceneTree.
func _player_disconnected(id):
	if has_node("/root/World"): # Game is in progress.
		if get_tree().is_network_server():
			emit_signal("game_error", "Player " + other_players[id]["name"] + " disconnected")
			end_game()
	else: # Game is not in progress.
		# Unregister this player.
		unregister_player(id)


# Callback from SceneTree, only for clients (not server).
func _connected_ok():
	# We just connected to a server
	emit_signal("connection_succeeded")


# Callback from SceneTree, only for clients (not server).
func _server_disconnected():
	emit_signal("game_error", "Server disconnected")
	end_game()


# Callback from SceneTree, only for clients (not server).
func _connected_fail():
	get_tree().set_network_peer(null) # Remove peer
	emit_signal("connection_failed")


# Lobby management functions.

remote func register_player(new_player_name):
	var id = get_tree().get_rpc_sender_id()
	print("Player ", id, " registered")
	other_players[id] = {"name": new_player_name, "ready": false, "controller": null}
	emit_signal("player_list_changed")


func unregister_player(id):
	other_players.erase(id)
	emit_signal("player_list_changed")


remote func pre_start_game():
	# Change scene.
	get_tree().get_root().add_child(G.world)
	G.world.generate()

	get_tree().get_root().get_node("Lobby").hide()

	var spawn_points = {}
	spawn_points[1] = 0 # Server in spawn point 0.
	var spawn_point_idx = 1
	for p in other_players:
		spawn_points[p] = spawn_point_idx
		spawn_point_idx += 1

	for p_id in spawn_points:
		var player_pos = G.field.get_spawn_point()
		var player_unit = G.cmd([["spawn", "player", player_pos]])
		var player = player_unit.controller
		player.set_name(str(p_id)) # Use unique ID as node name.
		player.set_network_master(p_id) #set unique id as master.

		if p_id == get_tree().get_network_unique_id():
			# If node for this peer id, set name.
			player_unit.item_name = player_name
			G.you = player
		else:
			# Otherwise set name from peer.
			player_unit.item_name = other_players[p_id]["name"]
			other_players[p_id]["controller"] = player

	if not get_tree().is_network_server():
		# Tell server we are ready to start.
		rpc_id(1, "ready_to_start", get_tree().get_network_unique_id())
	elif other_players.size() == 0:
		post_start_game()


remote func post_start_game():
	get_tree().set_pause(false) # Unpause and unleash the game!


remote func ready_to_start(id):
	assert(get_tree().is_network_server())

	other_players[id]["ready"] = true

	for p in other_players.values():
		if p["ready"] == false:
			return

	for p in other_players.values():
		rpc_id(p["name"], "post_start_game")
	post_start_game()


func host_game(new_player_name):
	player_name = new_player_name
	peer = NetworkedMultiplayerENet.new()
	peer.create_server(DEFAULT_PORT, MAX_PEERS)
	get_tree().set_network_peer(peer)


func join_game(ip, new_player_name):
	player_name = new_player_name
	peer = NetworkedMultiplayerENet.new()
	peer.create_client(ip, DEFAULT_PORT)
	get_tree().set_network_peer(peer)


func get_player_names():
	var r = []
	for p in other_players.values():
		r.append(p["name"])
	return r


func begin_game():
	assert(get_tree().is_network_server())

	for p in other_players:
		rpc_id(p, "pre_start_game")

	pre_start_game()


func end_game():
	if has_node("/root/World"): # Game is in progress.
		# End it
		get_node("/root/World").queue_free()

	emit_signal("game_ended")
	other_players.clear()


func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self,"_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
