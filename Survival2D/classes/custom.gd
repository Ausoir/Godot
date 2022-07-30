#Hardcoded events

func run(p, _params):
	if p == "start menu":
		gamestate.restart()
	elif p == "respawn":
		var pos = _params.pos
		if G.you.unit.pos == pos:
			_params.remove()
			var old_unit = G.you.unit
			var player_unit = G.cmds([["make", "player", pos]])
			player_unit.possess(G.you)
			old_unit.die()

func on_time():
	G.vars.time += 1
	G.ui.menu.display_time()
