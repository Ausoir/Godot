const WORK_DELAY = 5
const Item = preload("res://objects/item.gd")
const Unit = preload("res://objects/units/Unit.tscn")
const Script_Unit = preload("res://objects/units/unit.gd")
const Script_Humanoid = preload("res://objects/units/humanoid.gd")

const CMD_GRAB = [["wait", 6, "grab"],["cmd", 0, [["wield"]]]]
const ACT_CONSTRUCT = ["icon_construct", [["wait",6,"work"],["cmd",0,[["equip"]]]]]
const ACT_EQUIP = ["icon_equip", [["wait",6,"work"],["cmd",0,[["equip"]]]]]
const DESCRIPTIONS = {
	"true": "Ignores armor.",
}

var spells = [
	[
		["Transmute Gold to Mana", [0,5], [["cost",0,5],["cost",-2,0]]],
		["Revitalize", [1,0], [["v","host"],["state","regenerate",45],["cost",1,0]]],
		["Enchant Health", [5,0], [["dat","g","hp",null],["v","add","$t",Vector2(1,1)],["dat","a","hp","$"],["cost",10,0]]],
	],
	[
		["Summon Torch", [1,0], [["make","torch"],["wield"],["cost",1,0]]],
		["Summon Pickaxe", [2,0], [["make","pickaxe"],["wield"],["cost",2,0]]],
		["Summon Shortsword", [2,0], [["make","shortsword"],["wield"],["cost",2,0]]],
		["Summon Warrior", [2,5], [["v","$h","pos"], ["make","warrior"],["v","controller","$h"],["faction",1]]],
		["Summon Soldier", [2,10], [["v","$h","pos"], ["make","soldier"],["v","controller","$h"],["faction",1]]],
	],
]


func get_description(name):
	if name in DESCRIPTIONS:
		return DESCRIPTIONS[name]
	return ""

func make_mob(arg, pos):
	var mob_data = G.data.mob_data.get(arg)
	if mob_data != null:
		var unit
		var unit_pos = pos
		for mob in mob_data:
			var params = mob_data[mob]
			var num = G.rng.randi_range(params[0], params[1])
			for _i in range(num):
				unit = make_unit(mob, unit_pos)
				if unit != null:
					unit.possess()
					unit_pos = unit_pos.get_rnd_adjacent(unit.col, 8)
					if unit_pos == null:
						return
					if unit.dat.g("bodyparts"):
						for ii in range(2, params.size()):
							var item_param = params[ii]
							if G.rng.rnd_percent(item_param[1]):
								var item = G.factory.make_item(item_param[0])
								unit.auto_equip(item)
				else:
					push_error("Invalid mob unit "+str(mob))
		return unit

func make_unit(arg, pos):
	var unit_data = G.data.unit_data.get(arg)
	if unit_data != null:
		var r = Unit.instance()
		if unit_data.get("bodyparts") != null:
			r.set_script(Script_Humanoid)
		else:
			r.set_script(Script_Unit)
		var sprite = G.data.get_image(unit_data.img)
		if !sprite:
			return
		r.get_node("Sprites/Sprite").texture = sprite
		G.turn.add(r)
		r.item_name = arg
		r.item_type = "unit"
		r.dat = G.Properties.new(unit_data)
		r.vars = G.Properties.new({})
		for stat in G.STATS:
			r.vars.a(stat, G.rng.rnd_range(r.dat.g(stat, [1,1])))
		r.vars.a("move speed", r.dat.g("move speed", 2))
		r.col = r.dat.g("col", "0110")
		r.place(pos)
		return r

func make_item(arg, pos=null):
	var item_data = G.data.item_data.get(arg)
	if item_data != null:
		var r = Sprite.new()
		r.texture = G.data.get_image(item_data.img)
		r.set_script(Item)
		r.item_name = arg
		r.item_type = "item"
		r.dat = G.Properties.new(item_data)
		r.vars = G.Properties.new({})
		r.col = r.dat.g("col", "0000")
		if pos != null:
			r.place(pos)
		return r

func make_corpse(host, pos):
	var r = G.data.get_particle("Corpse")
	r.item_name = "corpse"
	r.item_type = "item"
	r.make(host)
	var item_data = G.data.item_data.get("corpse")
	if item_data != null:
		r.dat = G.Properties.new(item_data)
	if pos != null:
		r.place(pos)
	return r

func get_duplicate(this, arr):
	var r = []
	for i in arr:
		if i == null:
			r.append(this)
		else:
			r.append(i)
	return r

func get_known_spells():
	var r = []
	for spell_type in spells:
		var new_types = []
		for spell in spell_type:
			if G.rng.randi_range(0, 3) == 0:
				new_types.append(spell)
		r.append(new_types)
	return r
