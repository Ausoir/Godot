var name
var data
var host
var tgt_item
var tgt_point
var tgt_tile
var tgt

func do(phost, pname, pdata=null, mode=0, dest=null):
	host = phost
	name = pname
	tgt_point = dest
	if pdata == null:
		data = G.data.skill_data.get(name)
		if data == null:
			return false
	else:
		data = pdata
	if !find_victim():
		return false
	else:
		if tgt_point != null:
			tgt = tgt_point
		elif tgt_item != null:
			tgt = tgt_item.position
		if "cooldown" in data:
			if name in host.cooldowns:
				return false
			host.cooldowns[name] = data.cooldown
		if "delay" in data:
			host.delay = data.delay
		if mode == 0:
			if "duration" in data:
				if host.buffs.has(name):
					run_cmds(data.get("onstack", []))
					return true
				else:
					host.buffs.add(name, data, data.duration)
			run_cmds(data.get("onstart", []))
		elif mode == 1:
			run_cmds(data.get("onturn", []))
		elif mode == 2:
			run_cmds(data.get("onend", []))
		elif mode == 3:
			run_cmds(data.get("retaliate", []))
			tgt_item = host
			run_cmds(data.get("compensate", []))
		if tgt_item != null:
			if !is_instance_valid(tgt_item) or (tgt_item.item_type == "unit" and tgt_item.is_dead):
				run_cmds(data.get("onkill", []))
		return true

func run_cmds(cmds):
	for cmd in cmds:
		var type = cmd[0]
		if type == "gfx":
			if cmd[1] == "projectile":
				var gfx = G.Gfx.instance()
				var shoot_from = host.pos.to_pixel()
				var shoot_to = tgt
				if cmd.size() > 3:
					shoot_from += R.vfr(cmd[3][0])
					shoot_to += R.vfr(cmd[3][1])
				gfx.shoot(cmd[2], shoot_from, shoot_to)
			elif cmd[1] == "particle":
				G.make_particle(cmd[2], host.position, {"follow": host})
			elif cmd[1] == "particleto":
				G.make_particle(cmd[2], tgt, {"follow": tgt_item})
			elif cmd[1] == "label":
				G.display_damage(host.pos.to_pixel(), cmd[2], cmd[3], .8)
		elif type == "sfx":
			var sound = G.Sfx.instance()
			if cmd[2] == "host":
				sound.start(cmd[1], host.pos.to_pixel())
			elif cmd[2] == "target":
				sound.start(cmd[1], tgt)
		elif type == "expend":
			var wpn = host.get_weapon()
			if wpn:
				var uses = wpn.dat.g("uses", 1)
				if uses < 1:
					var r = host.unequip(host.selected_weapon)
					if r != null:
						r.remove()
				else:
					wpn.dat.a("uses", uses - 1)
		elif type == "cooldown":
			host.cooldowns[cmd[1]] = cmd[2]
		elif type == "adat":
			host.dat.add(cmd[1], cmd[2])
			host.dirty_dat = true
		elif type == "sdat":
			host.dat.erase(cmd[1], cmd[2])
			host.dirty_dat = true
		elif type == "cdat":
			host.dat.a(cmd[1], host.dat.g(cmd[2]))
			host.dirty_dat = true
		elif type == "dat":
			host.dat.a(cmd[1], cmd[2])
			host.dirty_dat = true
		elif type == "dmg":
			var dmg_type = cmd[1]
			var dmg = host.get_damage(dmg_type, cmd[2])
			G.events.append([funcref(tgt_item, "hit"), [dmg_type, dmg, host]])
		elif type == "heal":
			host.hit("heal", -cmd[1], host)
		elif type == "interrupt":
			tgt_item.buffs.on_interrupt(cmd[1])
		elif type == "reaction":
			tgt_item.delay = cmd[2]
			tgt_item.set_animation(cmd[1], cmd[2])
		elif type == "action":
			host.set_animation(cmd[1], host.delay)
		elif type == "cast":
			G.influence.do(host, cmd[1])
		elif type == "castto":
			G.influence.do(tgt_item, cmd[1])
		elif type == "move":
			host.relocate(tgt_tile)
			host.position.x = tgt_point.x
			host.position.y = tgt_point.y
		elif type == "mob":
			G.factory.make_mob(cmd[1], tgt_tile)
		elif type == "spawn":
			G.cmd([["make", cmd[1], tgt_tile], ["possess", "$t"]])
		elif type == "morph":
			var husk = host
			var player_unit = G.cmd([["make", cmd[1], host.pos]])
			player_unit.possess(husk.controller)
			husk.remove()
		elif type == "visibility":
			if cmd[1] == 0:
				host.n_sprites.hide()
			else:
				host.n_sprites.show()
		elif type == "energy":
			host.energy = max(host.dat.g("agility", 0), host.energy + cmd[1])
		elif type == "draw":
			host.select_weapon(cmd[1])
		elif type == "unsight":
			host.sight_col = host.dat.g("sight col")
			if host == G.you.unit:
				G.cmd([["refresh"]])
		elif type == "flag":
			host.flags.append(cmd[1])
			host.dirty_dat = true
		elif type == "unflag":
			host.flags.erase(cmd[1])
			host.dirty_dat = true
		elif type == "cmd":
			G.cmd([cmd.slice(1, cmd.size() - 1)], host)
		elif type == "end":
			host.buffs.end(cmd[1])

func find_victim():
	if data.target == "self":
		if is_valid(host):
			tgt_item = host
			return true
	elif data.target == "point":
		tgt_tile = host.pos.world.from_vec(tgt_point)
		return true
	elif data.target == "body":
		var raycast = host.n_collider.cast_col_ray(tgt_point, [host], data.get("col", 0))
		if !raycast.empty() and raycast.collider is KinematicBody2D:
			tgt_point = raycast.position
			tgt_tile = host.pos.world.from_vec(tgt_point)
			if tgt_tile.distance_to(host.pos) <= data.get("range", 16):
				tgt_item = raycast.collider.get_parent()
				return is_valid(tgt_item)
	elif data.target == "beam":
		tgt_point = host.n_collider.cast_ray(tgt_point, [host], data.get("col", 0))
		tgt_tile = host.pos.world.from_vec(tgt_point)
		return tgt_tile.distance_to(host.pos) <= data.get("range", 16)
	else:
		tgt_item = host.controller.target
		if tgt_item != null and is_instance_valid(tgt_item):
			if data.target == "onattack" or data.target == "oncharge" or data.target == "onhit":
				if tgt_item.item_type == "unit" and is_valid(tgt_item):
					return true
	return false

func is_valid(p):
	if "reqs" in data:
		var is_tile = p.item_type == "tile"
		var is_unit = p.item_type == "unit"
		for law in data.reqs:
			if is_tile:
				if law == "solid" and p.is_col(4):
					continue
				elif law == "open" and !p.is_col(14):
					continue
				elif law == "seen" and p.sight_frame == G.you.n_camera.sight_frame - 1:
					continue
			elif is_unit:
				if law == "unit":
					continue
				elif law == "humanoid" and p.dat.g("type") != "man":
					continue
				elif law == "foe" and host.faction != p.faction:
					continue
				elif law == "ally" and host.faction == p.faction:
					continue
				elif law == "larger size" and host.dat.g("size",0) > p.dat.g("size", 0):
					continue
				elif law == "smaller size" and host.dat.g("size",0) < p.dat.g("size", 0):
					continue
				elif law == "same size" and host.dat.g("size",0) == p.dat.g("size", 0):
					continue
			return false
	return true
