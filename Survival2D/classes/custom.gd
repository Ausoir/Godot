#Hardcoded events

func run(p, _params):
	if p == "sleep":
		G.cmds([["menu","msg","Sleeping..."],["fade"],["vars","+","time",1]])
	elif p == "sabotaged":
		var machines = G.temp.sabotage
		G.msg("A target was sabotaged! Remaining: "+str(machines.size()))
		if machines.size() == 1:
			G.cmds([["attack","$p","$p","true",999]])
			G.cmds([["menu","dialog","Game Over"]])
	elif p == "start menu":
		var root = G.get_tree().get_root()
		for i in root.get_children():
			i.queue_free()
			root.remove_child(i)
		root.add_child(load("res://G.gd").new())
		root.add_child(load("res://Start.tscn").instance())
	elif p == "respawn":
		var pos = _params.pos
		if G.you.unit.pos == pos:
			_params.remove()
			var old_unit = G.you.unit
			var player_unit = G.cmds([["make", "player", pos]])
			player_unit.possess(G.you)
			old_unit.die()

func on_time():
	G.vars.money = min(G.vars.money, G.vars.money_)
	G.vars.time += 1
	G.ui.menu.display_time()
