const Item = preload("res://objects/item.gd")
const Unit = preload("res://objects/Unit.tscn")
const Script_Unit = preload("res://objects/unit.gd")
const Script_Humanoid = preload("res://objects/humanoid.gd")
const Properties = preload("res://classes/properties.gd")
const UnitProperties = preload("res://objects/unit_properties.gd")
const Projectile = preload("res://objects/Projectile.tscn")

func make_any(arg, pos):
	var r
	if arg[0] == "g" and arg[1] == "_":
		r = make_group(arg, pos)
	else:
		r = make_mob(arg, pos)
		if r == null:
			r = make_unit(arg, pos)
			if r == null:
				r = make_item(arg, pos)
	return r

func make_group(arg, pos):
	var groups = G.data.get_group(arg)
	if !groups.empty():
		var made
		var adjs
		var adj = pos
		for group in groups:
			for _i in range(group[1]):
				if adj != null:
					made = make_any(group[0], adj)
					if made != null and made.col & 4 > 0:
						adjs = adj.get_available_adjacents(12)
						adj = R.r_arr(adjs)
		return made

func make_mob(arg, pos):
	var mob_data = G.data.mob_data.get(arg)
	if mob_data != null:
		var unit
		var unit_pos = pos
		unit = make_unit(mob_data.unit, unit_pos)
		if unit != null:
			unit.item_name = arg
			unit.dat.combine(mob_data.get("dat", {}))
			var equips = mob_data.get("equip")
			if equips != null:
				for equip in equips:
					var list = G.data.get_combo(equip)
					for list_item in list:
						var equip_item = G.factory.make_item(list_item)
						if equip_item != null:
							unit.auto_equip(equip_item)
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
		r.col = -1
		r.place(pos)
		r.set_seed()
		G.world.turn.add(r)
		return r

func make_item(arg, pos=null):
	var item_data = G.data.item_data.get(arg)
	if item_data != null:
		var img = item_data.get("img")
		var r = Sprite.new()
		if img != null:
			G.data.set_sprite_texture(r, img, item_data.get("autotile", 0))
			if r.texture != null:
				if !r.region_enabled:
					var img_size = r.texture.get_size()
					if img_size.y > 32:
						r.offset.y = -int((img_size.y - 32) / 2)
		r.set_script(Item)
		r.item_name = arg
		r.item_type = "item"
		r.dat = Properties.new(item_data)
		if pos != null:
			r.place(pos)
		return r

func make_projectile(host, arg, pos, dest):
	if G.is_vec_visible(pos) or G.is_vec_visible(dest):
		var item_data = G.data.item_data.get(arg)
		if item_data != null:
			var r = Projectile.instance()
			r.item_name = arg
			var img = G.data.get_image(item_data.get("img"))
			r.init(host, img, pos, dest, item_data.get("speed"), item_data.get("variation", [0,0]))
			r.lifetime = item_data.get("time", 2)
			r.onattack = item_data.get("onattack")
			r.onmiss = item_data.get("onmiss")
			var onshoot = item_data.get("onshoot")
			if onshoot != null:
				G.cmds(onshoot, host, dest)
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
