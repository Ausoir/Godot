const WORK_DELAY = 5
const Item = preload("res://objects/item.tscn")

const CMD_GRAB = [["wait", 6, "grab"],["cmd", 0, [["wield"]]]]
const ACT_CONSTRUCT = ["icon_construct", [["wait",6,"work"],["cmd",0,[["equip"]]]]]
const ACT_EQUIP = ["icon_equip", [["wait",6,"work"],["cmd",0,[["equip"]]]]]
const data = {
	"@": ["item", "site", {}],
	"man": ["unit", "site", {
		hp=Vector2(5,5),
	}],
	"branch": ["item", "site", {
		actives=[ACT_CONSTRUCT],
		passives=["block"],
		onattack=[["die"]],
		damage="1d4", haste=1, weight=1, tags=["blunt"], mat="wood",
	}],
	"hoodie": ["item", "site", {
		actives=[ACT_EQUIP],
		defense="1d2", space=2, weight=1, part="torso", skin="skin_hoodie",
	}],

	"armor rack": ["building", "site",
		{mat="wood",hp=Vector2(6,6),onuse=[["wait",12,"work",true],["cmd",0,[["trigger"]]]], loot="armors"}],
}
var image_map = preload("res://assets/item_list.gd").new()

var descriptions = {
	"true": "Ignores armor.",
}

var spells = [
	[
		["Transmute Gold to Mana", [0,5], [["cost",0,5],["cost",-2,0]]],
		["Revitalize", [1,0], [["v","host"],["state","regenerate",45],["cost",1,0]]],
		["Forget Spells", [1,0], [["v","controller","$h"],["spell","forget"]]],
		["Enchant Health", [5,0], [["dat","g","hp",null],["v","add","$t",Vector2(1,1)],["dat","a","hp","$"],["cost",10,0]]],
		["Enchant Strength", [10,0], [["dat","g","strength",0],["v","add","$t",1],["dat","a","strength","$"],["cost",10,0]]],
		["Enchant Focus", [5,0], [["dat","g","focus",0],["v","add","$t",1],["dat","a","focus","$"],["cost",10,0]]],
	],
	[
		["Summon Torch", [1,0], [["make","torch"],["wield"],["cost",1,0]]],
		["Summon Pickaxe", [2,0], [["make","pickaxe"],["wield"],["cost",2,0]]],
		["Summon Shortsword", [2,0], [["make","shortsword"],["wield"],["cost",2,0]]],
		["Summon Saber", [5,0], [["make","saber"],["wield"],["cost",5,0]]],
		["Summon Halberd", [5,0], [["make","halberd"],["wield"],["cost",5,0]]],
		["Summon Mace", [3,0], [["make","mace"],["wield"],["cost",3,0]]],
		["Summon Cleaver", [3,0], [["make","cleaver"],["wield"],["cost",3,0]]],

		["Summon Full Iron Suit", [15,0], [["make","iron armor"],["equip"], ["make","iron gauntlets"],["equip"], ["make","iron boots"],["equip"],["cost",15,0]]],
		["Summon Iron Helmet", [2,0], [["make","helmet"],["equip"],["cost",2,0]]],
		["Summon Full Helmet", [3,0], [["make","full helmet"],["equip"],["cost",3,0]]],
		["Summon Iron Boots", [2,0], [["make","iron boots"],["equip"],["cost",2,0]]],
		["Summon Gauntlets", [2,0], [["make","iron gauntlets"],["equip"],["cost",2,0]]],
		["Summon Cuirass", [3,0], [["make","cuirass"],["equip"],["cost",3,0]]],
		["Summon Amulet of Protection", [4,0], [["make","amulet of protection"],["equip"],["cost",4,0]]],
		["Summon Amulet of Focus", [4,0], [["make","amulet of focus"],["equip"],["cost",4,0]]],
		["Summon Amulet of Strength", [4,0], [["make","amulet of strength"],["equip"],["cost",4,0]]],
		["Summon Amulet of Health", [4,0], [["make","amulet of health"],["equip"],["cost",4,0]]],

		["Summon Warrior", [2,5], [["v","$h","pos"], ["make","warrior"],["v","controller","$h"],["faction",1]]],
		["Summon Soldier", [2,10], [["v","$h","pos"], ["make","soldier"],["v","controller","$h"],["faction",1]]],
	],
	[
		["Memorize Flurry", [5,0], [["v","controller","$h"],["spell","memorize","flurry",true],["if",true],["cost",5,0]]],
		["Memorize Light", [1,0], [["v","controller","$h"],["spell","memorize","light",true],["if",true],["cost",1,0]]],
		["Memorize Cat's Eye", [5,0], [["v","controller","$h"],["spell","memorize","cateye",true],["if",true],["cost",5,0]]],
		["Memorize Haste", [5,0], [["v","controller","$h"],["spell","memorize","haste",true],["if",true],["cost",5,0]]],
		["Memorize Passwall", [5,0], [["v","controller","$h"],["spell","memorize","passwall",true],["if",true],["cost",5,0]]],
		["Memorize Missile", [5,0], [["v","controller","$h"],["spell","memorize","missile",true],["if",true],["cost",5,0]]],
		["Memorize Rune Trap", [5,0], [["v","controller","$h"],["spell","memorize","rune",true],["if",true],["cost",5,0]]],
		["Memorize Lightning", [5,0], [["v","controller","$h"],["spell","memorize","lightning",true],["if",true],["cost",5,0]]],
		["Memorize Clairvoyance", [5,0], [["v","controller","$h"],["spell","memorize","clairvoyance",true],["if",true],["cost",3,0]]],
		["Memorize Possess Weapon", [5,0], [["v","controller","$h"],["spell","memorize","phantom",true],["if",true],["cost",3,0]]],
		["Memorize Charm", [5,0], [["v","controller","$h"],["spell","memorize","charm",true],["if",true],["cost",3,0]]],
		["Memorize Invisibility", [5,0], [["v","controller","$h"],["spell","memorize","invisibility",true],["if",true],["cost",3,0]]],
		["Memorize Light Beam", [5,0], [["v","controller","$h"],["spell","memorize","stars",true],["if",true],["cost",5,0]]],
	]
]


func get_description(name):
	if name in descriptions:
		return descriptions[name]
	return ""


func make(arg):
	if arg in data:
		var item = data[arg]
		var r = Item.instance()
		var pos = image_map.items[item[1]]
		r.region_rect.position.x = pos.x
		r.region_rect.position.y = pos.y
		r.item_name = arg
		r.dat = G.Properties.new(item[2])
		if item[0] == "item":
			r.dat.a("onuse", CMD_GRAB)
		elif item[0] == "unit":
			r.set_seed(-1)
		G.world.objects.add_child(r)
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
