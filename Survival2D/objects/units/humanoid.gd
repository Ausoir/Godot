extends "res://objects/units/unit.gd"

var equipments = {}
var inventory = [[2, null]]
var belt = [[2, null],[0, null],[0, null],[0, null]]
var selected_belt = 0
var weight = 0

func get_weapon():
	return belt[selected_belt][1]

func select_weapon(p):
	selected_belt = p
	var item = belt[p][1]
	if item == null:
		weapon_sprite.hide()
	else:
		var item_sprite = item.dat.g("sprite")
		if item_sprite != null:
			weapon_sprite.show()
			weapon_sprite.texture = G.data.get_image(item_sprite)
		else:
			weapon_sprite.hide()

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
		dirty = true
		equipments[part] = item
		return true
	return false

func unequip(part):
	for eq in equipments:
		if eq == part:
			dirty = true
			var r = equipments[eq]
			equipments.erase(eq)
			return r
	return unsheathe(-1)

func has_part(p):
	for eq in equipments:
		if equipments[eq].dat.g("part") == p:
			return true
	return false

func sheathe(idx, item, drop=false):
	if idx == -1:
		for i in range(4):
			if belt[i][0] >= item.dat.g("size", 2):
				dirty = true
				belt[i][1] = item
				return true
	elif belt[idx][0] >= item.dat.g("size", 2):
		dirty = true
		belt[idx][1] = item
		if idx == selected_belt:
			select_weapon(selected_belt)
		return true
	if drop:
		dirty = true
		drop(item)
	return false

func unsheathe(idx):
	if idx == -1:
		for i in range(4):
			var r = unsheathe(i)
			if r != null:
				return r
	if belt[idx][1] != null:
		var t = belt[idx][1]
		belt[idx][1] = null
		if idx == selected_belt:
			select_weapon(selected_belt)
		return t
	return null

func store(item, drop=false):
	var item_size = item.dat.g("size", 2)
	var candidates = []
	for i in range(inventory.size()):
		var inventory_slot = inventory[i]
		if inventory_slot[1] == null:
			if inventory_slot[0] == item_size:
				dirty = true
				inventory[i][1] = item
				return true
			elif inventory_slot[0] > item_size:
				candidates.append(i)
	if !candidates.empty():
		dirty = true
		inventory[candidates.pop_front()][1] = item
		return true
	if drop:
		drop(item)
	return false

func unstore(item):
	for i in range(inventory.size()):
		if inventory[i][1] == item:
			inventory[i][1] = null
			return true
	return false

func update():
	.update()
	var r_inventory = [[2,null]]
	var r_belt = [[2, null],[0, null],[0, null],[0, null]]
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
				var count = 0
				for belt_i in item.dat.g("belt", 0):
					r_belt[count][0] = belt_i
					count += 1
		weight += item.dat.g("weight", 0)
	for _i in range(space_inventory_l):
		r_inventory.append([2,null])
	for _i in range(space_inventory_s):
		r_inventory.append([1,null])
	for i in range(4):
		var belt_slot = belt[i]
		var belt_item = belt_slot[1]
		if belt_item != null:
			var item_size = belt_item.dat.g("size", 2)
			if item_size <= r_belt[i][0]:
				r_belt[i][1] = belt_item
				if i == selected_belt:
					actives += belt_item.dat.g("actives")
					passives += belt_item.dat.g("passives")
			else:
				sheathe(-1, belt_item, true)
	for i in range(inventory.size()):
		var item = inventory[i][1]
		if item != null:
			if i > r_inventory.size():
				store(item, true)
			else:
				var item_size = item.dat.g("size", 2)
				if item_size <= r_inventory[i][0]:
					r_inventory[i][1] = item
				else:
					store(item, true)
	belt = r_belt
	inventory = r_inventory

func drop(item):
	pos.add_item(item)
