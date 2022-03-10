const WORK_DELAY = 5
const Item = preload("res://objects/item.gd")
const Unit = preload("res://objects/Unit.tscn")
const Script_Unit = preload("res://objects/unit.gd")
const Script_Humanoid = preload("res://objects/humanoid.gd")
const Properties = preload("res://classes/properties.gd")
const UnitProperties = preload("res://objects/unit_properties.gd")

const CMD_GRAB = [["wait", 6, "grab"],["cmd", 0, [["wield"]]]]
const ACT_CONSTRUCT = ["icon_construct", [["wait",6,"work"],["cmd",0,[["equip"]]]]]
const ACT_EQUIP = ["icon_equip", [["wait",6,"work"],["cmd",0,[["equip"]]]]]
var scripter

var spells = [
	[
		["Transmute Gold to Mana", [0,5], [["cost",0,5],["cost",-2,0]]],
		["Revitalize", [1,0], [["v","host"],["state","regenerate",45],["cost",1,0]]],
		["Enchant Health", [5,0], [["dat","g","hp",null],["v","add","$t",Vector2(1,1)],["dat","=","hp","$"],["cost",10,0]]],
	],
	[
		["Summon Torch", [1,0], [["make","torch"],["wield"],["cost",1,0]]],
		["Summon Pickaxe", [2,0], [["make","pickaxe"],["wield"],["cost",2,0]]],
		["Summon Shortsword", [2,0], [["make","shortsword"],["wield"],["cost",2,0]]],
		["Summon Warrior", [2,5], [["v","$h","pos"], ["make","warrior"],["v","controller","$h"],["faction",1]]],
		["Summon Soldier", [2,10], [["v","$h","pos"], ["make","soldier"],["v","controller","$h"],["faction",1]]],
	],
]

func make_script(arg, pos=null):
	var script_data = G.data.script_data.get(arg)
	if script_data != null:
		place_scripter(pos)
		G.cmd(script_data, scripter)
		return true

func make_group(arg, pos):
	var groups = G.data.get_group(arg)
	if !groups.empty():
		var adjs
		var adj = pos
		for group in groups:
			for _i in range(group[1]):
				if adj != null:
					var made = G.factory.make_mob(group[0], adj)
					if made == null:
						made = G.factory.make_unit(group[0], adj)
						if made == null:
							made = G.factory.make_item(group[0], adj)
					if made.col & 4 > 0:
						adjs = adj.get_available_adjacents(12)
						adj = R.r_arr(adjs)
		return true

func make_mob(arg, pos):
	var mob_data = G.data.mob_data.get(arg)
	if mob_data != null:
		var unit
		var unit_pos = pos
		unit = make_unit(mob_data.unit, unit_pos)
		if unit != null:
			if !mob_data.get("controlled", false):
				unit.possess()
			unit.item_name = arg
			unit.faction = mob_data.faction
			G.world.team[unit.faction].append(unit)
			unit.dat.combine(mob_data.get("dat", {}))
			var equips = mob_data.get("equip")
			if equips != null:
				for equip in equips:
					var list = G.data.get_combo(equip)
					for list_item in list:
						var equip_item = G.factory.make_item(list_item)
						if equip_item != null:
							unit.auto_equip(equip_item)
			unit.dat.fill_skills()
			return unit
		else:
			push_error("Invalid unit "+str(mob_data[1]))

func make_unit(arg, pos):
	var unit_data = G.data.unit_data.get(arg)
	if unit_data != null:
		var r = Unit.instance()
		var sprite
		if unit_data.get("type") != "other":
			r.set_script(Script_Humanoid)
		else:
			r.set_script(Script_Unit)
		sprite = G.data.get_image(unit_data.img)
		if !sprite:
			return
		r.get_node("Sprites/Sprite").texture = sprite
		var img_size = sprite.get_size()
		if img_size.y > 32:
			r.get_node("Sprites/Sprite").offset.y = -int((img_size.y - 32) / 2)
		r.item_name = arg
		r.item_type = "unit"
		r.dat = UnitProperties.new(unit_data)
		if !r.dat.g("col"):
			r.dat.a("col", 12)
		r.on_dat()
		r.place(pos)
		r.set_seed()
		G.world.turn.add(r)
		return r

func make_item(arg, pos=null):
	var item_data = G.data.item_data.get(arg)
	if item_data != null:
		var r = Sprite.new()
		G.data.set_sprite_texture(r, item_data.img, item_data.get("autotile", 0))
		if r.texture != null:
			if !r.region_enabled:
				var img_size = r.texture.get_size()
				if img_size.y > 32:
					r.offset.y = -int((img_size.y - 32) / 2)
		r.set_script(Item)
		r.item_name = arg
		r.item_type = "item"
		r.dat = Properties.new(item_data)
		var onmake = item_data.get("onmake")
		if onmake != null:
			G.cmd(onmake, r)
		var onload = item_data.get("onload")
		if onload != null:
			G.world.onloads.append([r, onload])
		r.on_dat()
		if pos != null:
			r.place(pos)
		if r.dat.g("turn", 0) > 0:
			G.world.turn.add(r)
		return r

func make_corpse(host, pos):
	var r = G.data.get_particle("Corpse")
	r.item_name = "corpse"
	r.item_type = "item"
	r.make(host)
	var item_data = G.data.item_data.get("corpse")
	if item_data != null:
		r.dat = G.factory.Properties.new(item_data)
	if pos != null:
		r.place(pos)
	return r

func place_scripter(pos):
	if scripter == null:
		scripter = Sprite.new()
		scripter.set_script(Item)
		scripter.item_name = "scripter"
		scripter.item_type = "other"
		scripter.dat = G.Properties.new({})
		scripter.place(pos)
	else:
		scripter.relocate(pos)

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
			if R.ir(0, 3) == 0:
				new_types.append(spell)
		r.append(new_types)
	return r
