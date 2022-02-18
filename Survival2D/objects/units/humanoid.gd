extends "res://objects/units/unit.gd"

var overlay_sprites = {}
var equipments = {}
var inventory = [null]
var selected_weapon
var gender = "m"
var weight = 0

func _ready():
	select_weapon("primary")

func set_seed():
	var sd = dat.g("seed", -1)
	if sd == -1:
		sd = R.i()
		dat.a("seed", sd)
	else:
		sd = int(sd)
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
	var wpn = get_weapon()
	if wpn:
		r += wpn.dat.g("cut", 0)
	return r

func get_weapon():
	return equipments.get(selected_weapon)

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
		if _part != get_secondary_to(selected_weapon):
			n_sprites.add_child(newsprite)
			if _part != selected_weapon:
				var wpn = overlay_sprites.get(selected_weapon)
				if wpn != null:
					n_sprites.remove_child(wpn)
					n_sprites.add_child(wpn)

func get_secondary_to(p):
	if p == "primary":
		return "secondary"
	else:
		return "primary"

func select_weapon(p):
	remove_overlay(selected_weapon)
	var secondary = equipments.get(selected_weapon)
	if secondary != null:
		unaccomodate_stats(secondary)
	selected_weapon = p
	var item = equipments.get(p)
	if item != null:
		accomodate_stats(item)
		create_overlay(p, item.dat.g("sprite"))
	if !abilities.empty() and abilities[0].begins_with("swap to "):
		abilities.pop_front()
	if secondary != null:
		abilities.insert(0, "swap to "+get_secondary_to(p))

func is_equipment_valid(part, item):
	var item_part = item.dat.g("part", "")
	if item_part == part or (item_part == "" and (part == "primary" or part == "secondary")):
		var bodytype_list = G.data.get_json_data("bodytypes")
		var parts = bodytype_list.get(dat.g("type"))
		if part in parts:
			var item_size = item.dat.g("size", 1)
			var valid_size = item_size <= parts[part]
			return valid_size
	return false

func auto_equip(item):
	var part = item.dat.g("part", "")
	if part == "":
		if equipments.get("primary") == null:
			return equip("primary", item)
		elif equipments.get("secondary") == null:
			return equip("secondary", item)
	return equip(part, item)

func equip(part, item):
	if !has_part(part) and is_equipment_valid(part, item):
		equipments[part] = item
		accomodate_stats(item)
		if part == "body" and item.dat.g("gender") != null:
			create_overlay(part, item.dat.g("sprite")+"_"+gender)
		else:
			if part == "primary" or part == "secondary":
				select_weapon(part)
			else:
				create_overlay(part, item.dat.g("sprite"))
		return true
	return false

func unequip(part):
	for eq in equipments:
		if eq == part:
			var r = equipments[eq]
			unaccomodate_stats(r)
			equipments.erase(eq)
			remove_overlay(part)
			return r
	return false

func accomodate_stats(item):
	abilities += item.dat.g("abilities", [])
	for i in item.dat.g("skills", []):
		add_skill(i)
	for _i in range(item.dat.g("space", 0)):
		inventory.append(null)
	for i in G.STATS:
		var stat = item.dat.g(i)
		if stat != null:
			dat.add(i, stat)
	weight += item.dat.g("weight", 0)

func unaccomodate_stats(item):
	for i in item.dat.g("abilities", []):
		abilities.erase(i)
	for i in item.dat.g("passives", []):
		skills.erase(i)
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
				store(old_inventory[i], true)
	weight -= item.dat.g("weight", 0)

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

func update_save_data(_data):
	var save_eq = {}
	var save_inv = []
	for i in equipments:
		save_eq[i] = equipments[i].item_name
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
		if equip(i, item):
			unaccomodate_stats(item)
	for i in load_inv:
		var item = G.factory.make_item(i, null)
		store(item, true)
