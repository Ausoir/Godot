#Hardcoded events

func run(p, _params):
	if p == "start menu":
		gamestate.save_game()
		gamestate.restart()
	elif p == "level select":
		gamestate.save_game()
		gamestate.level_select()
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
