extends Node

onready var stat_panel = $"Dialog/Character Creation/Control"
var specie = "Human"
var stats = {}
var skill
var ability
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
	if skill != null:
		cmds.append(["*","$p","skills",[]])
		cmds.append(["&=","t","$t"])
		cmds.append(["&^","t",skill])
		cmds.append(["*=","$p","skills","$t"])
		cmds.append(["&d","t"])
	if ability != null:
		cmds.append(["*","$p","abilities",[]])
		cmds.append(["&=","t","$t"])
		cmds.append(["&^","t",ability])
		cmds.append(["*=","$p","abilities","$t"])
		cmds.append(["&d","t"])
	for i in stats:
		cmds.append(["*=", "$p", i, stats[i]])
	G.temp.creation = cmds
	get_tree().change_scene_to(load("res://world/Levels.tscn"))

func update():
	var txt = "[i]" + specie.capitalize() + "[/i]\n"
	txt += stat_panel.get_stats_text(stats)
	txt += "\n\n[url=reroll][u]REROLL[/u][/url]\n[url=start][u]START[/u][/url]"
	stat_panel.set_bbcode(txt)
	var txt2 = ""
	for i in items:
		if i != null:
			txt2 += "[url="+i+"][color=#874]"+i.capitalize()+"[/color][/url]\n"
	$"Dialog/Character Creation/Rightside/Text2".set_bbcode(txt2)
	if ability != null:
		var txt3 = "[url=#"+ability+"][color=#2A9]"+ability.capitalize()+"[/color][/url]\n"
		if skill != null:
			txt3 += "[url=#"+skill+"][color=#56A]"+skill.capitalize()+"[/color][/url]"
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
	specie = R.r_arr(G.data.vars.species)
	var count = 0
	var distribution = R.r_pie(G.data.vars.stats.size()+1)
	for i in G.data.vars.stats:
		var s = G.data.vars.stats[i]
		var maxvariance = s.variance * (distribution[count] - 1)
		stats[s.name] = round(s.default + maxvariance)
		count += 1
	if distribution[count] < .7:
		skill = R.r_arr(G.data.vars.skills.bad)
	elif distribution[count] < 1.4:
		skill = R.r_arr(G.data.vars.skills.good)
	elif R.b():
		skill = R.r_arr(G.data.vars.skills.great)
	else:
		skill = R.r_arr(G.data.vars.skills.bad)
		ability = R.r_arr(G.data.vars.skills.active)

	items = [R.r_arr(G.data.vars.loadouts.armor)]
	var loadout_heavy = R.b()
	if loadout_heavy:
		items.append(R.r_arr(G.data.vars.loadouts.good_weapon))
	else:
		items.append(R.r_arr(G.data.vars.loadouts.equipment))
		items.append(R.r_arr(G.data.vars.loadouts.bad_weapon))
		items.append(R.r_arr(G.data.vars.loadouts.accessory))
