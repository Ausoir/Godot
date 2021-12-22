extends "res://objects/units/unit.gd"

var equipments = {}
var inventory = [2]
var belt = [2,0,0,0]
var weight = 0

func is_equipment_valid(part, item):
	var parts = dat.g("parts")
	var item_part = item.dat.g("part", "weapon")
	var item_size = item.dat.g("size", 2)
	var valid_size = item_size <= parts[part]
	var valid_part = item_part in parts
	return valid_part and valid_size

func equip(part, item):
	if !has_part(part) and is_equipment_valid(part, item):
		equipments[part] = item
		update_equipment()
		return true
	return false

func unequip(part):
	for eq in equipments:
		if eq == part:
			equipments.erase(eq)
			update_equipment()
			return true
	return false

func has_part(p):
	for eq in equipments:
		if equipments[eq].dat.g("part") == p:
			return true
	return false

func sheathe(idx, item, drop=false):
	if idx == -1:
		for i in range(4):
			if belt[i] is int and belt[i] >= item.dat.g("size", 2):
				belt[i] = item
				update_equipment()
				return true
	elif belt[idx] is int and belt[idx] >= item.dat.g("size", 2):
		belt[idx] = item
		update_equipment()
		return true
	if drop:
		drop(item)
	return false

func unsheathe(idx):
	if !(belt[idx] is int):
		var t = belt[idx]
		belt[idx] = 0
		return t
	return -1

func store(item, drop=false):
	var item_size = item.dat.g("size", 2)
	var candidates = []
	for i in range(inventory.size()):
		var inventory_slot = inventory[i]
		if inventory_slot is int:
			if inventory_slot == item_size:
				inventory[i] = item
				return true
			elif inventory_slot > item_size:
				candidates.append(i)
	if !candidates.empty():
		inventory[candidates.pop_front()] = item
		return true
	if drop:
		drop(item)
	return false

func unstore(item):
	for i in range(inventory.size()):
		if !(inventory[i] is int) and inventory[i] == item:
			inventory.remove(i)
			update_equipment()
			return true
	return false

func update_equipment():
	actives = []
	passives = []
	var r_inventory = [2]
	var r_belt = [2,0,0,0]
	var space_inventory_l = 0
	var space_inventory_s = 0
	for eq in equipments:
		var item = equipments[eq]
		var eq_part = item.dat.g("part")
		var eq_actives = item.dat.g("actives")
		var eq_passives = item.dat.g("passives")
		var eq_space_l = item.dat.g("space_l", 0)
		var eq_space_s = item.dat.g("space_s", 0)
		if eq_part == eq:
			actives += eq_actives
			passives += eq_passives
			space_inventory_l += eq_space_l
			space_inventory_s += eq_space_s
			if eq == "belt":
				r_belt = item.dat.g("belt", 0)
		weight += item.dat.g("weight", 0)
	for _i in range(space_inventory_l):
		r_inventory.append(2)
	for _i in range(space_inventory_s):
		r_inventory.append(1)
	for i in range(4):
		var belt_item = belt[i]
		if !(belt_item is int):
			var item_size = belt_item.dat.g("size", 2)
			if item_size <= r_belt[i]:
				r_belt[i] = belt_item
			else:
				sheathe(-1, belt_item, true)
	for i in range(inventory.size()):
		var item = inventory[i]
		if !(item is int):
			if i > r_inventory.size():
				store(item, true)
			else:
				var item_size = item.dat.g("size", 2)
				if item_size == r_inventory[i]:
					r_inventory[i] = item
				else:
					store(item, true)
	belt = r_belt
	inventory = r_inventory
	controller.on_equipment_update()

func drop(item):
	pos.add_item(item)
