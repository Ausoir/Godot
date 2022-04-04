#Hardcoded events

func run(p, _params):
	if p == "sleep":
		G.cmds([["menu","msg","Sleeping..."],["fade"],["vars","+","time",1]])
	elif p == "sabotaged":
		var machines = G.world.get_items_by_name("machine")
		G.temp["machines"] = machines
		G.msg("A machine was sabotaged! Remaining panels: "+str(machines.size()))
		if machines.size() == 1:
			G.cmds([["attack","$p","$p","true",999]])
			run("game over", {})
	elif p == "pre gen":
		G.temp["spawner w"] = G.data.get_category("spawner variants")
	elif p == "post gen":
		G.temp["machines"] = G.world.get_items_by_name("machine")
	elif p == "game over":
		pass

func on_time():
	G.vars.money = min(G.vars.money, G.vars.money_)
	G.vars.time += 1
	G.ui.menu.display_time()
