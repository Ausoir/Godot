extends Node

onready var stat_panel = $"Dialog/Character Creation/Control"
var specie = "Human"
var stats = {}
var skills = [null, null]
var items = []

func _ready():
	randomize_unit()
	update()
	stat_panel.connect("meta_clicked", self, "_on_meta_clicked")

func start():
	var cmds = [["morph", "$p", specie],["*=","$p","faction",1]]
	for i in items:
		if i != null:
			cmds.append(["make", i, "$pp"])
			cmds.append(["give", "$p", "$t"])
	for i in skills:
		if i != null:
			cmds.append(["*","$p","skills",[]])
			cmds.append(["&=","t","$t"])
			cmds.append(["&^","t",i])
			cmds.append(["*=","$p","skills","$t"])
			cmds.append(["&d","t"])
	for i in stats:
		cmds.append(["*=", "$p", i, stats[i]])
	G.temp.creation = cmds
	G.game.load_travel("town")
#	get_tree().change_scene_to(load("res://world/Levels.tscn"))

func update():
	var txt = "[i]" + specie.capitalize() + "[/i]\n"
	txt += stat_panel.get_stats_text(stats)
	txt += "\n\n[url=reroll][u]REROLL[/u][/url]\n[url=start][u]START[/u][/url]"
	stat_panel.set_bbcode(txt)
	var txt2 = ""
	var txt3 = ""
	for i in items:
		if i != null:
			txt2 += "[url="+i+"][color=#874]"+i.capitalize()+"[/color][/url]\n"
	$"Dialog/Character Creation/Rightside/Text2".set_bbcode(txt2)
	if skills[0] != null:
		txt3 = "[url=#"+skills[0]+"][color=#2A9]"+skills[0].capitalize()+"[/color][/url]\n"
		if skills[1] != null:
			txt3 += "[url=#"+skills[1]+"][color=#56A]"+skills[1].capitalize()+"[/color][/url]"
	$"Dialog/Character Creation/Rightside/Text3".set_bbcode(txt3)

func _on_meta_clicked(_meta):
	G.ui.description.hide()
	if _meta == "start":
		start()
	elif _meta == "reroll":
		randomize_unit()
		update()
	else:
		on_describe(_meta)

func _on_meta_hover_started(meta):
	on_describe(meta)

func on_describe(meta):
	if meta[0] == "#":
		var skillname = meta.substr(1)
		G.ui.describe("skill", skillname.capitalize(), G.data.skill_data.get(skillname))
	else:
		G.ui.describe("item", meta.capitalize(), G.data.item_data.get(meta))

func _on_meta_hover_ended(_meta):
	G.ui.description.hide()

func randomize_unit():
	specie = G.rng.r_arr(G.data.vars.species)
	var specie_data = G.data.unit_data.get(specie)
	var count = 0
	var distribution = G.rng.r_pie(G.data.vars.stats.size()+1)
	for i in G.data.vars.stats:
		var s = G.data.vars.stats[i]
		var maxvariance = s.variance * (distribution[count] - 1)
		stats[s.name] = round(specie_data.get(s.name, 0) + maxvariance)
		count += 1
	if distribution[count] < .7:
		skills[0] = G.rng.r_arr(G.data.vars.skills.bad)
	elif distribution[count] < 1.4:
		skills[0] = G.rng.r_arr(G.data.vars.skills.good)
	elif G.rng.b():
		skills[0] = G.rng.r_arr(G.data.vars.skills.great)
	else:
		skills[0] = G.rng.r_arr(G.data.vars.skills.bad)
		skills[1] = G.rng.r_arr(G.data.vars.skills.active)

	items = [G.rng.r_arr(G.data.vars.loadouts.armor)]
	var loadout_heavy = G.rng.b()
	if loadout_heavy:
		items.append(G.rng.r_arr(G.data.vars.loadouts.good_weapon))
	else:
		items.append(G.rng.r_arr(G.data.vars.loadouts.equipment))
		items.append(G.rng.r_arr(G.data.vars.loadouts.bad_weapon))
		items.append(G.rng.r_arr(G.data.vars.loadouts.accessory))
