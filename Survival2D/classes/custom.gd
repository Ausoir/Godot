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
		if G.vars.time == 0 and "ontime" in G.vars:
			G.cmds(G.vars.ontime)
			G.vars.erase("ontime")
