extends Node

func refresh():
	var txt = ""
	txt += "[color=#A64][url=abandon]Abandon Map[/url][/color]\n"
	$Top.set_bbcode(txt)

	var txt2 = ""
	txt2 += "[color=#942]Sound[/color]: [url=sound]"+G.vars.sound.capitalize()+"[/url]\n"
	txt2 += "[color=#942][url=retire]Retire[/url][/color]\n"
	txt2 += "[color=#942][url=exit]Exit Game[/url][/color]\n"
	$Bottom.set_bbcode(txt2)

func _on_meta_clicked(meta):
	if meta == "abandon":
		G.cmds([["menu","confirm","Abandon current level?",[["custom","level select",null]]]])
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
		G.cmds([["menu","confirm","Abandon character and start over?",[["^=","dead",1],["custom","start menu",null]]]])
	elif meta == "exit":
		G.cmds([["menu","confirm","Exit game?",[["custom","end game",null]]]])
