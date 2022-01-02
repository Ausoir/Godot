var name
var data
var host
var target
var victim

func do(phost, pname, pdata=null, mode=0):
	host = phost
	name = pname
	if pdata == null:
		data = G.data.skill_data.get(name)
		if data == null:
			return
	else:
		data = pdata
	target = host.controller.target
	if !find_victim():
		return
	else:
		if "cooldown" in data:
			if name in host.cooldowns:
				return
			host.cooldowns[name] = data.cooldown
		host.delay = data.delay
		if mode == 0:
			if "duration" in data:
				if "onstack" in data and host.buffs.has(name):
					run_cmds(data.onstack)
					return
				else:
					host.buffs.add(name, data, data.duration)
			run_cmds(data.onstart)
		elif mode == 1:
			run_cmds(data.onturn)
		elif mode == 2:
			run_cmds(data.onend)

func run_cmds(cmds):
	for cmd in cmds:
		var type = cmd[0]
		if type == "gfx":
			if cmd[1] == "projectile":
				var dest = host.pos.get_beam_to(target, G.COL_OBJECT, data.range)
				var gfx = G.Gfx.new("tween", .1)
				gfx.shoot(cmd[2], host.pos.to_pixel(), dest.to_pixel())
			elif cmd[1] == "sprite":
				G.cmds([["gfx", cmd[1], target]])
		elif type == "expend":
			var wpn = host.get_weapon()
			if wpn:
				var max_uses = wpn.dat.g("uses", 1)
				var uses = wpn.vars.g("uses", 0)
				if uses >= max_uses:
					host.unequip("weapon")
					host.dirty = true
				else:
					wpn.vars.a("uses", uses + 1)
		elif type == "cooldown":
			host.cooldowns[cmd[1]] = int(cmd[2])
		elif type == "swift":
			host.vars.add("move speed", int(cmd[1]))
			host.dirty = true
		elif type == "bash":
			var wpn = host.get_weapon()
			if wpn:
				host.buffs.end(name)
		elif type == "end":
			host.buffs.end(name)

func find_victim():
	if data.type == "buff":
		if is_valid(host):
			return true
	elif data.type == "smite":
		for i in target.items:
			if is_valid(i):
				return true
		return is_valid(target)
	elif data.type == "direction":
		var dir = host.pos.direction_to(target)
		var tile = host.pos.get_adjacent(dir, data.range)
		for i in tile.items:
			if is_valid(i):
				return true
		return is_valid(tile)
	elif data.type == "projectile":
		var tile = host.pos.get_beam_to(target, G.COL_OBJECT, data.range)
		for i in tile.items:
			if is_valid(i):
				return true
		return is_valid(tile)
	return false

func is_valid(tgt):
	if "restriction" in data:
		var is_tile = tgt.has("terrain")
		var is_unit = tgt.item_type == "unit"
		for law in data.restriction:
			if is_tile:
				if law == "solid" and tgt.is_col(1):
					continue
			elif is_unit:
				if law == "unit":
					continue
				elif law == "humanoid" and tgt.dat.g("bodyparts") == null:
					continue
				elif law == "foe" and host.faction != victim.faction:
					continue
				elif law == "ally" and host.faction == victim.faction:
					continue
				elif law == "larger size" and host.dat.g("size",0) > victim.dat.g("size", 0):
					continue
				elif law == "smaller size" and host.dat.g("size",0) < victim.dat.g("size", 0):
					continue
				elif law == "same size" and host.dat.g("size",0) == victim.dat.g("size", 0):
					continue
			return false
	victim = tgt
	return true
