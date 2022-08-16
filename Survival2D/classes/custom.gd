#Hardcoded events

func run(p, _params):
	if p == "save":
		gamestate.save_game()
	elif p == "start menu":
		gamestate.restart()
	elif p == "level select":
		gamestate.level_select()
	elif p == "end game":
		gamestate.end_game()
	elif p == "recall":
		var host = G.you.unit
		var adjs = host.pos.get_available_adjacents(12)
		var adj = R.r_arr(adjs)
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
	if G.vars.time > 0:
		G.vars.time -= 1
		G.ui.menu.display_time()
		if G.vars.time == 0 and "ontime" in G.temp:
			G.cmds(G.temp.ontime)
			if G.vars.time == 0:
				G.temp.erase("ontime")
