const WORK_DELAY = 5
const Item = preload("res://objects/Item.tscn")
const Unit = preload("res://objects/units/Unit.tscn")
const Script_Unit = preload("res://objects/units/unit.gd")
const Script_Humanoid = preload("res://objects/units/humanoid.gd")
const Ai = preload("res://objects/units/ai.gd")

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

func make_unit(arg, pos):
	if arg in G.data.unit_data:
		var item = G.data.unit_data[arg]
		var r = Unit.instance()
		if item[1].get("parts") != null:
			r.set_script(Script_Humanoid)
		else:
			r.set_script(Script_Unit)
		var sprite = G.data.images.get(item[0])
		if !sprite:
			return
		r.get_node("Sprite").texture = sprite
		G.turn.add(r)
		r.item_name = arg
		r.item_type = "unit"
		r.dat = G.Properties.new(item[1])
		pos.add_item(r)
		r.get_node("Sprite").get_node("Weapon").texture = G.data.images.get('axe')
		return r

func make_item(arg, pos):
	if arg in G.data.item_data:
		var item = G.data.item_data[arg]
		var r = Item.instance()
		var sprite = G.data.image_map.get(item[1])
		if !sprite:
			return
		r.region_rect.position.x = sprite.x
		r.region_rect.position.y = sprite.y
		r.item_name = arg
		r.item_type = item[0]
		r.dat = G.Properties.new(item[2])
		pos.add_item(r)
		if item[0] == "item":
			r.dat.a("onuse", CMD_GRAB)
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
