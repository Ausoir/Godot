extends "res://objects/unit.gd"

var overlay_sprites = {}
var equipments = {}
var inventory = [null]
var gender = "m"
var item_skills = []

func ability(idx, at):
	var abilities = dat.g("abilities", [])
	var s_abilities = abilities.size()
	if idx < s_abilities:
		face_toward(at)
		var ability = abilities[idx]
		return G.influence.do(ability, self, at, 0, null)
	else:
		var items = get_usable_items()
		var s_items = items.size()
		if idx < s_abilities + s_items:
			face_toward(at)
			G.cmds(items[idx - s_abilities].dat.g("onuse"), self, at)

func get_usable_items():
	var r = []
	for i in inventory:
		if i != null:
			var onuse = i.dat.g("onuse")
			if onuse != null:
				r.append([i, "item"])
	return r

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
			list = G.data.vars.male
		else:
			list = G.data.vars.female
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
		if ptype == "bash":
			r += round(R.f() * wpn.dat.g("bash", 0))
		elif ptype == "cut":
			r += round(R.f() * wpn.dat.g("cut", 0))
	return r

func can_carry(w):
	if w < 0:
		return false
	elif w == 0:
		return true
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
		item.host = self
		equipments[part] = item
		accomodate_stats(item)
		if part == "body" and item.dat.g("gender") != null:
			create_overlay(part, item.dat.g("sprite")+"_"+gender)
		else:
			create_overlay(part, item.dat.g("sprite"))
		G.sfx.play("equip_metal", pos.position)
		return true
	return false

func unequip(part):
	for eq in equipments:
		if eq == part:
			var r = equipments[eq]
			unaccomodate_stats(r)
			remove_overlay(part)
			equipments.erase(eq)
			r.host = null
			return r

func on_item_remove(item):
	if item in inventory:
		unstore(item)
	else:
		var part = item.dat.g("part", "weapon")
		if part in equipments and equipments[part] == item:
			unequip(part)
	controller.on_change("ui")

func roll_skill(type, mode=0):
	var data
	for skill in item_skills + dat.g("skills", []) + ["wait"]:
		data = G.data.skill_data.get(skill)
		if data != null and data.target == type:
			if R.r_percent(data.chance):
				G.influence.do(skill, self, controller.target, mode, data)
				return [skill, data]
	return null

func accomodate_stats(item):
	var abilities = dat.g("abilities", [])
	abilities += item.dat.g("abilities", [])
	dat.a("abilities", abilities)
	item_skills += item.dat.g("skills", [])
	for _i in range(item.dat.g("space", 0)):
		inventory.append(null)
	for i in G.data.vars.stats:
		var s = G.data.vars.stats[i].name
		var stat = item.dat.g(s)
		if stat != null:
			dat.add(s, stat)
	dirty_dat = true

func unaccomodate_stats(item):
	var abilities = dat.g("abilities", [])
	for i in item.dat.g("abilities", []):
		abilities.erase(i)
	dat.a("abilities", abilities)
	for i in item.dat.g("skills", []):
		item_skills.erase(i)
	for i in G.data.vars.stats:
		var s = G.data.vars.stats[i].name
		var stat = item.dat.g(s)
		if stat != null:
			dat.add(s, -stat)
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

func store_at(item, index):
	if index >= inventory.size():
		store(item)
	else:
		inventory[index] = item
		item.host = self
		item.pos = pos
		if controller != null:
			controller.on_change("ui")
	return true

func store(item, drop=false):
	for i in range(inventory.size()):
		if inventory[i] == null:
			inventory[i] = item
			item.host = self
			item.pos = pos
			if controller != null:
				controller.on_change("ui")
			return true
	if drop:
		drop(item)
	return false

func unstore(item):
	for i in range(inventory.size()):
		if inventory[i] == item:
			item.host = null
			inventory[i] = null
			if controller != null:
				controller.on_change("ui")
			return true
	return false

func drop(item):
	pos.add_item(item)

func get_defense(_type):
	var def = .get_defense(_type)
	if _type == "bash":
		return def + dat.g("abash", 0)
	elif _type == "cut":
		return def + dat.g("acut", 0)

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
