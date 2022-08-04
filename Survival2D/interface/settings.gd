extends Node

func refresh():
	var txt = ""
	txt += "[color=#A64][url=abandon]Abandon Map[/url][/color]\n"
	$Top.set_bbcode(txt)

	var txt2 = ""
	txt2 += "[color=#942]Sound[/color]: [url=sound]"+G.vars.sound+"[/url]\n"
	txt2 += "[color=#942][url=retire]Retire[/url][/color]\n"
	txt2 += "[color=#942][url=exit]Exit Game[/url][/color]\n"
	$Bottom.set_bbcode(txt2)

func _on_meta_clicked(meta):
	if meta == "abandon":
		G.script("level select", null)
	elif meta == "sound":
		if G.vars.sound == "low":
			G.vars.sound = "normal"
		elif G.vars.sound == "normal":
			G.vars.sound = "high"
		elif G.vars.sound == "high":
			G.vars.sound = "off"
		elif G.vars.sound == "off":
			G.vars.sound = "low"
		refresh()
	elif meta == "retire":
		G.vars["dead"] = 1
		G.script("start menu", null)
	elif meta == "exit":
		gamestate.end_game()
