#Hardcoded events

func run(p):
	if p == "sleep":
		G.cmds([["menu","msg","Sleeping..."],["fade"],["vars","+","time",1]])
	elif p == "sabotaged":
		var solars = G.world.get_items_by_name("solar panel")
		G.msg("A solar panel was sabotaged! Remaining panels: "+str(solars.size()))
		if solars.empty():
			run("game over")
	elif p == "game over":
		pass
