const WORK_DELAY = 5
const Item = preload("res://objects/Item.tscn")
const Unit = preload("res://objects/units/Unit.tscn")
const Ai = preload("res://objects/units/ai.gd")
const Player = preload("res://objects/units/Player.tscn")

const CMD_GRAB = [["wait", 6, "grab"],["cmd", 0, [["wield"]]]]
const ACT_CONSTRUCT = ["icon_construct", [["wait",6,"work"],["cmd",0,[["equip"]]]]]
const ACT_EQUIP = ["icon_equip", [["wait",6,"work"],["cmd",0,[["equip"]]]]]
const DESCRIPTIONS = {
	"true": "Ignores armor.",
}

var data = preload("res://classes/json.gd").new()
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
	if arg in data.unit_data:
		var item = data.unit_data[arg]
		var r = Unit.instance()
		var sprite = data.images.get(item[1])
		if !sprite:
			return
		r.get_node("Sprite").texture = sprite
		G.world.units.add_child(r)
		G.turn.add(r)
		if item[3] == "player":
			Player.instance().assign(r)
			G.world.players.add_child(r.controller)
		r.item_name = arg
		r.item_type = item[0]
		r.dat = G.Properties.new(item[2])
		r.relocate(pos)
		r.position = pos.to_pixel()
		return r

func make_item(arg, pos):
	if arg in data.item_data:
		var item = data.item_data[arg]
		var r = Item.instance()
		var sprite = data.image_map.get(item[1])
		if !sprite:
			return
		r.region_rect.position.x = sprite.x
		r.region_rect.position.y = sprite.y
		if item[0] == "item":
			r.dat.a("onuse", CMD_GRAB)
			G.world.items.add_child(r)
		elif item[0] == "object":
			G.world.objects.add_child(r)
		r.item_name = arg
		r.item_type = item[0]
		r.dat = G.Properties.new(item[2])
		r.relocate(pos)
		r.position = pos.to_pixel()
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
