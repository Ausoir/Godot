extends "res://objects/unit.gd"

var overlay_sprites = {}
var equipments = {}
var inventory = [null]
var gender = "m"
var item_skills = []

func set_seed():
	var sd = dat.g("seed", -1)
	if sd == -1:
		sd = R.i()
		dat.a("seed", sd)
	else:
		sd = int(sd)
	if dat.g("type") == "man":
		var list
		if sd % 2 == 0:
			sd /= 2
			list = G.data.vars_data.male
		else:
			list = G.data.vars_data.female
		var sprite_name = list[sd % list.size()]
		n_sprite.texture = G.data.get_image("units/human/"+sprite_name)

func remove():
	for i in overlay_sprites:
		overlay_sprites[i].queue_free()
	for i in equipments:
		equipments[i].queue_free()
	.remove()

func get_damage(ptype, p):
	var r = .get_damage(ptype, p)
	var wpn = equipments.get("weapon")
	if wpn:
		r += wpn.dat.g("cut", 0)
	return r

func can_carry(w):
	if w < 0:
		return false
	var r = 0
	for i in equipments:
		var item = equipments[i]
		r += item.dat.g("weight", 0)
	for i in inventory:
		if i != null:
			r += i.dat.g("weight", 0)
	return dat.g("strength", 1) >= r + w

func remove_overlay(_part):
	var wpn = overlay_sprites.get(_part)
	if wpn != null:
		wpn.queue_free()
		n_sprites.remove_child(wpn)
		overlay_sprites.erase(_part)

func create_overlay(_part, _texturename):
	if _texturename != null:
		var newsprite = n_sprite.duplicate()
		newsprite.set_name(_part)
		newsprite.set_texture(G.data.get_image(_texturename))
		overlay_sprites[_part] = newsprite
		n_sprites.add_child(newsprite)
		if _part != "weapon":
			var wpn = overlay_sprites.get("weapon")
			if wpn != null:
				n_sprites.remove_child(wpn)
				n_sprites.add_child(wpn)

func is_equipment_valid(part, item):
	if item != null:
		var item_part = item.dat.g("part", "")
		if item_part == part or (item_part == "" and part == "weapon"):
			var bodytype_list = G.data.get_json_data("bodytypes")
			var parts = bodytype_list.get(dat.g("type"))
			if part in parts:
				var item_size = item.dat.g("size", 1)
				var valid_size = item_size <= parts[part]
				return valid_size
	return false

func auto_equip(item):
	var part = item.dat.g("part", "weapon")
	return equip(part, item)

func equip(part, item):
	if !has_part(part) and is_equipment_valid(part, item):
		equipments[part] = item
		accomodate_stats(item)
		if part == "body" and item.dat.g("gender") != null:
			create_overlay(part, item.dat.g("sprite")+"_"+gender)
		else:
			create_overlay(part, item.dat.g("sprite"))
		G.Sfx.instance().start("equip_metal", pos.to_pixel())
		return true
	return false

func unequip(part):
	for eq in equipments:
		if eq == part:
			var r = equipments[eq]
			unaccomodate_stats(r)
			remove_overlay(part)
			equipments.erase(eq)
			return r

func accomodate_stats(item):
	var abilities = dat.g("abilities", [])
	abilities += item.dat.g("abilities", [])
	dat.a("abilities", abilities)
	item_skills += item.dat.g("skills", [])
	var item_light = item.dat.g("light", 0)
	if item_light != 0:
		dat.add("light", item_light)
		pos.radiate(item_light)
	for _i in range(item.dat.g("space", 0)):
		inventory.append(null)
	for i in G.STATS:
		var stat = item.dat.g(i)
		if stat != null:
			dat.add(i, stat)
	dirty_dat = true

func unaccomodate_stats(item):
	var abilities = dat.g("abilities", [])
	for i in item.dat.g("abilities", []):
		abilities.erase(i)
	dat.a("abilities", abilities)
	for i in item.dat.g("skills", []):
		item_skills.erase(i)
	var item_light = item.dat.g("light", 0)
	if item_light != 0:
		dat.add("light", -item_light)
		pos.radiate(-item_light)
	for i in G.STATS:
		var stat = item.dat.g(i)
		if stat != null:
			dat.add(i, -stat)
	var remove_spaces = item.dat.g("space", 0)
	var old_inventory = inventory
	inventory = inventory.slice(0, inventory.size()-remove_spaces-1)
	if remove_spaces > 0:
		for i in range(old_inventory.size()):
			if i >= old_inventory.size() - remove_spaces:
				if old_inventory[i] != null:
					store(old_inventory[i], true)
	dirty_dat = true

func has_part(p):
	for eq in equipments:
		if equipments[eq].dat.g("part") == p:
			return true
	return false

func store(item, drop=false):
	for i in range(inventory.size()):
		if inventory[i] == null:
			inventory[i] = item
			return true
	if drop:
		drop(item)
	return false

func unstore(item):
	for i in range(inventory.size()):
		if inventory[i] == item:
			inventory[i] = null
			return true
	return false

func drop(item):
	pos.add_item(item)

func expend():
	var wpn = equipments.get("weapon")
	if wpn:
		var uses = wpn.dat.g("uses", 1)
		if uses < 1:
			var r = unequip("weapon")
			if r != null:
				r.remove()
		else:
			wpn.dat.a("uses", uses - 1)

func update_save_data(_data):
	var save_eq = {}
	var save_inv = []
	for i in equipments:
		save_eq[i] = equipments[i].item_name
		unaccomodate_stats(equipments[i])
	for i in inventory:
		if i != null:
			save_inv.append(i.item_name)
	_data["equip"] = save_eq
	_data["inv"] = save_inv
	return _data

func load_item_data(_data):
	var load_eq = _data.get("equip")
	var load_inv = _data.get("inv")
	for i in load_eq:
		var item = G.factory.make_item(load_eq[i], null)
		equip(i, item)
	for i in load_inv:
		var item = G.factory.make_item(i, null)
		store(item, true)
