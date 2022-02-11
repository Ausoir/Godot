extends "res://objects/units/unit.gd"

var overlay_sprites = {}
var equipments = {}
var inventory = [null]
var belt = [[2, null],[0, null],[0, null],[0, null]]
var selected_belt = -1
var weight = 0

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
	return belt[selected_belt][1]

func remove_overlay(_part):
	var wpn = overlay_sprites.get(_part)
	if wpn != null:
		wpn.queue_free()
		node_sprites.remove_child(wpn)
		overlay_sprites.erase(_part)

func create_overlay(_part, _texturename):
	if _texturename != null:
		var newsprite = sprite.duplicate()
		newsprite.set_name(_part)
		newsprite.set_texture(G.data.get_image(_texturename))
		overlay_sprites[_part] = newsprite
		if _part == "weapon":
			node_sprites.add_child(newsprite)
		else:
			node_sprites.add_child(newsprite)
			var wpn = overlay_sprites.get("weapon")
			if wpn != null:
				node_sprites.remove_child(wpn)
				node_sprites.add_child(wpn)

func select_weapon(p):
	if p != selected_belt:
		remove_overlay("weapon")
		if belt[selected_belt][1] != null:
			unaccomodate_stats(belt[selected_belt][1])
		selected_belt = p
		var item = belt[p][1]
		if item != null:
			accomodate_stats(item)
			if !("weapon" in overlay_sprites):
				create_overlay("weapon", item.dat.g("sprite"))

func is_equipment_valid(part, item):
	var item_part = item.dat.g("part", "")
	if item_part == part:
		var bodytype_list = G.data.get_json_data("bodytypes")
		var parts = bodytype_list.get(dat.g("type"))
		if part in parts:
			var item_size = item.dat.g("size", 2)
			var valid_size = item_size <= parts[part]
			var valid_part = item_part in parts
			return valid_part and valid_size
	return false

func auto_equip(item):
	var part = item.dat.g("part", "")
	if !equip(part, item):
		return sheathe(-1, item)
	return true

func equip(part, item):
	if !has_part(part) and is_equipment_valid(part, item):
		equipments[part] = item
		accomodate_stats(item)
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
	return unsheathe(-1)

func accomodate_stats(item):
	abilities += item.dat.g("abilities", [])
	for i in item.dat.g("skills", []):
		add_skill(i)
	for _i in range(item.dat.g("space", 0)):
		inventory.append(null)
	for i in range(4):
		var belt_size = item.dat.g("belt" + str(i + 1), 0)
		if belt_size > 0:
			belt[i][0] = belt_size
	for i in G.STATS:
		var stat = item.dat.g(i)
		if stat != null:
			dat.add(i, stat)
	weight += item.dat.g("weight", 0)

func unaccomodate_stats(item):
	for i in item.dat.g("abilities", []):
		abilities.erase(i)
	for i in item.dat.g("passives", []):
		var idx = skills.find(i)
		skills.remove(idx)
	var remove_spaces = item.dat.g("space", 0)
	var old_inventory = inventory
	inventory = inventory.slice(0, inventory.size()-remove_spaces-1)
	if remove_spaces > 0:
		for i in range(old_inventory.size()):
			if i >= old_inventory.size() - remove_spaces:
				store(old_inventory[i], true)
	for i in range(4):
		if item.dat.g("belt" + str(i + 1), 0) > 0:
			belt[i][0] = 0
	weight -= item.dat.g("weight", 0)

func has_part(p):
	for eq in equipments:
		if equipments[eq].dat.g("part") == p:
			return true
	return false

func sheathe(idx, item):
	if idx == -1:
		for _i in range(4):
			if sheathe(0, item):
				return true
	elif belt[idx][1] == null and belt[idx][0] >= item.dat.g("size", 2):
		belt[idx][1] = item
		select_weapon(idx)
		return true
	return false

func unsheathe(idx):
	if idx == -1:
		for i in range(4):
			var r = unsheathe(i)
			if r != null:
				return r
	if belt[idx][1] != null:
		select_weapon(-1)
		var t = belt[idx][1]
		belt[idx][1] = null
		select_weapon(selected_belt)
		return t
	return null

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
	var save_eq = []
	var save_belt = []
	var save_inv = []
	for i in equipments:
		save_eq.append(equipments[i].item_name)
	for i in belt:
		if i[1] != null:
			save_belt.append(i[1].item_name)
	for i in inventory:
		if i != null:
			save_inv.append(i.item_name)
	_data["equip"] = save_eq
	_data["belt"] = save_belt
	_data["inv"] = save_inv
	return _data

func load_item_data(_data):
	var load_eq = _data.get("equip")
	var load_belt = _data.get("belt")
	var load_inv = _data.get("inv")
	for i in load_belt:
		var item = G.factory.make_item(i, null)
		sheathe(-1, item)
	for i in load_eq:
		var item = G.factory.make_item(i, null)
		auto_equip(item)
	for i in load_inv:
		var item = G.factory.make_item(i, null)
		store(item, true)
