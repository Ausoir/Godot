extends Node

func refresh():
	var txt = ""
	txt += "[color=#A64][url=abandon]Abandon Map[/url][/color]\n"
	txt += "[color=#A64][url=test]Test[/url][/color]\n"
	$Top.set_bbcode(txt)

	var txt2 = ""
	txt2 += "[color=#A64][url=autofight]Autofight "+str(G.vars.setting.autofight)+"[/url][/color]\n"
	txt2 += "[color=#A64][url=autoaim]Autoaim "+str(G.vars.setting.autoaim)+"[/url][/color]\n"
	txt2 += "[color=#A64][url=autofire]Autofire "+str(G.vars.setting.autofire)+"[/url][/color]\n"
	txt2 += "[color=#A64]Sound[/color]: [url=sound]"+G.vars.setting.sound.capitalize()+"[/url]\n"
	txt2 += "[color=#A64][url=retire]Retire[/url][/color]\n"
	txt2 += "[color=#942][url=exit]Exit Game[/url][/color]\n"
	$Bottom.set_bbcode(txt2)

func _on_meta_clicked(meta):
	if meta == "abandon":
		G.cmds([["menu","confirm","Abandon current level?",[["custom","level select",null]]]])
	elif meta == "test":
		G.cmds([["custom","save",null]])
	elif meta == "autofight":
		G.vars.setting.autofight = !G.vars.setting.autofight
		refresh()
	elif meta == "autoaim":
		G.vars.setting.autoaim = !G.vars.setting.autoaim
		refresh()
	elif meta == "autofire":
		G.vars.setting.autofire = !G.vars.setting.autofire
		refresh()
		G.ui.update_hud()
	elif meta == "sound":
		if G.vars.setting.sound == "low":
			G.vars.setting.sound = "normal"
		elif G.vars.setting.sound == "normal":
			G.vars.setting.sound = "high"
		elif G.vars.setting.sound == "high":
			G.vars.setting.sound = "off"
		elif G.vars.setting.sound == "off":
			G.vars.setting.sound = "low"
		refresh()
	elif meta == "retire":
		G.cmds([["menu","confirm","Abandon character and start over?",[["^=","dead",1],["custom","start menu",null]]]])
	elif meta == "exit":
		G.cmds([["menu","confirm","Exit game?",[["custom","end game",null]]]])
