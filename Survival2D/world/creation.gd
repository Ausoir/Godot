extends Node

var specie = "Human"
var stats = {}
var skill
var items = []

func _ready():
	randomize_unit()
	update()

func update():
	var txt = "[i]" + specie.capitalize() + "[/i]\n"
	for i in G.data.vars.stats:
		var s = G.data.vars.stats[i].name
		txt += "[url=_"+i+"][color=#A64]"+s.capitalize()+":[/color][/url] "+str(stats[i])+"\n"
	txt += "\n\n[url=reroll][u]REROLL[/u][/url]\n[url=start][u]START[/u][/url]"
	$"Dialog/Character Creation/Text1".set_bbcode(txt)
	var txt2 = ""
	for i in items:
		if i != null:
			txt2 += "[url="+i+"][color=#874]"+i.capitalize()+"[/color][/url]\n"
	$"Dialog/Character Creation/Rightside/Text2".set_bbcode(txt2)
	if skill != null:
		var txt3 = "[url=#"+skill+"][color=#56A]"+skill.capitalize()+"[/color][/url]"
		$"Dialog/Character Creation/Rightside/Text3".set_bbcode(txt3)

func start():
	G.get_tree().get_root().remove_child(self)
	gamestate.start_local()

func _on_meta_clicked(_meta):
	if _meta == "start":
		start()
	elif _meta == "reroll":
		randomize_unit()
		update()

func _on_meta_hover_started(meta):
	if meta[0] == "_":
		for key in G.data.vars.stats:
			if meta == "_" + key:
				var v = G.data.vars.stats[key]
				G.ui.describe("text", v.name, v.desc)
	elif meta[0] == "#":
		var skillname = meta.substr(1)
		G.ui.describe("skill", skillname.capitalize(), G.data.skill_data.get(skillname))
	else:
		G.ui.describe("item", meta.capitalize(), G.data.item_data.get(meta))

func _on_meta_hover_ended(_meta):
	G.ui.description.hide()

func randomize_unit():
	specie = R.r_arr(G.data.vars.species)
	var count = 0
	var distribution = R.r_pie(G.data.vars.stats.size()+1)
	for i in G.data.vars.stats:
		var s = G.data.vars.stats[i]
		print(i, " ", distribution[count])
		var maxvariance = s.variance * (distribution[count] - 1)
		stats[i] = round(s.default + maxvariance)
		count += 1
	if distribution[count] < .7:
		skill = R.r_arr(G.data.vars.skills.bad)
	elif distribution[count] < 1.4:
		skill = R.r_arr(G.data.vars.skills.good)
	else:
		skill = R.r_arr(G.data.vars.skills.great)

	items = [R.r_arr(G.data.vars.loadouts.armor)]
	var loadout_heavy = R.b()
	if loadout_heavy:
		items.append(R.r_arr(G.data.vars.loadouts.good_weapon))
	else:
		items.append(R.r_arr(G.data.vars.loadouts.bad_weapon))
		items.append(R.r_arr(G.data.vars.loadouts.equipment))
		items.append(R.r_arr(G.data.vars.loadouts.accessory))
