#Hardcoded events

func run(p, _params):
	if p == "save":
		G.game.save_game()
	elif p == "start menu":
		G.game.restart()
	elif p == "level select":
		G.game.level_select()
	elif p == "end game":
		G.game.end_game()
	elif p == "recall":
		var host = G.you.unit
		var adjs = host.pos.get_available_adjacents(12)
		var adj = G.rng.r_arr(adjs)
		if adj != null:
			var members = host.dat.g("members", [])
			for i in members:
				var member = G.world.get_item_by_seed(i)
				member.relocate(adj)
	elif p == "respawn":
		var pos = _params[0].pos
		if G.you.unit.pos == pos:
			_params[0].remove()
			var old_unit = G.you.unit
			var player_unit = G.cmds([["make", "player", pos]])
			player_unit.possess(G.you)
			old_unit.die()

func on_time():
	G.vars.time += 1
