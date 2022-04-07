#Hardcoded events

func run(p, _params):
	if p == "sleep":
		G.cmds([["menu","msg","Sleeping..."],["fade"],["vars","+","time",1]])
	elif p == "sabotaged":
		var machines = G.temp.sabotage
		G.msg("A target was sabotaged! Remaining: "+str(machines.size()))
		if machines.size() == 1:
			G.cmds([["attack","$p","$p","true",999]])
			run("game over", {})
	elif p == "game over":
		pass

func on_time():
	G.vars.money = min(G.vars.money, G.vars.money_)
	G.vars.time += 1
	G.ui.menu.display_time()
