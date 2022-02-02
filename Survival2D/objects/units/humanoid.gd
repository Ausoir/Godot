extends "res://objects/units/unit.gd"

const LAYER_ORDER = ["body", "head", "weapon"]
var equipment_nodes = {}
var equipments = {}
var inventory = [null]
var belt = [[2, null],[0, null],[0, null],[0, null]]
var selected_belt = -1
var weight = 0

func remove():
	for i in equipment_nodes:
		equipment_nodes[i].queue_free()
	for i in equipments:
		equipments[i].queue_free()
	.remove()

func get_damage(ptype, p):
	var r = .get_damage(ptype, p)
	if ptype == "cut":
		var wpn = get_weapon()
		if wpn:
			r += wpn.dat.g("cut", 0)
	elif ptype == "bash":
		var wpn = get_weapon()
		if wpn:
			r += wpn.dat.g("bash", 0)
	return r

func get_weapon():
	return belt[selected_belt][1]

func remove_overlay(_part):
	var wpn = equipment_nodes.get(_part)
	if wpn != null:
		wpn.queue_free()
		node_sprites.remove_child(wpn)
		equipment_nodes.erase(_part)

func create_overlay(_part, _texturename):
	if _texturename != null:
		var newsprite = sprite.duplicate()
		newsprite.set_name(_part)
		newsprite.set_texture(G.data.get_image(_texturename))
		equipment_nodes[_part] = newsprite
		node_sprites.add_child(newsprite)
		for child in node_sprites.get_children():
			var child_order = LAYER_ORDER.find(child.name)
			child.set_z_index(child_order)

func select_weapon(p):
	if p != selected_belt:
		remove_overlay("weapon")
		if belt[selected_belt][1] != null:
			unaccomodate_stats(belt[selected_belt][1])
		selected_belt = p
		var item = belt[p][1]
		if item != null:
			accomodate_stats(item)
			if !("weapon" in equipment_nodes):
				create_overlay("weapon", item.dat.g("sprite"))

func is_equipment_valid(part, item):
	var item_part = item.dat.g("part", "")
	if item_part == part:
		var parts = dat.g("bodyparts")
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
