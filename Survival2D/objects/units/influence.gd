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
			return false
	else:
		data = pdata
	if host.controller != null:
		target = host.controller.target
	else:
		target = host.pos
	if !find_victim():
		return false
	else:
		if "cooldown" in data:
			if name in host.cooldowns:
				return false
			host.cooldowns[name] = data.cooldown
		if "delay" in data:
			host.set_delay(data.delay)
		if mode == 0:
			if "duration" in data:
				if host.buffs.has(name):
					if "onstack" in data:
						run_cmds(data.onstack)
					return true
				else:
					if "cancel" in data:
						for i in data.cancel:
							host.buffs.cancels.append([i, name])
					host.buffs.add(name, data, data.duration)
			run_cmds(data.onstart)
		elif mode == 1:
			run_cmds(data.onturn)
		elif mode == 2:
			run_cmds(data.onend)
		return true

func run_cmds(cmds):
	for cmd in cmds:
		var type = cmd[0]
		if type == "gfx":
			if cmd[1] == "projectile":
				var dest = host.pos.get_beam_to(target, "0010", data.range)
				var gfx = G.Gfx.new("tween", .1)
				gfx.shoot(cmd[2], host.pos.to_pixel(), dest.to_pixel())
				gfx.rotate(cmd[2], 0, 1280)
			elif cmd[1] == "sprite":
				G.cmds([["gfx", cmd[1], target]])
		elif type == "expend":
			var wpn = host.get_weapon()
			if wpn:
				var max_uses = wpn.dat.g("uses", 1)
				var uses = wpn.vars.g("uses", 0)
				if uses >= max_uses:
					host.unequip("weapon")
				else:
					wpn.vars.a("uses", uses + 1)
		elif type == "cooldown":
			host.cooldowns[cmd[1]] = cmd[2]
		elif type == "stat":
			host.vars.add(cmd[1], cmd[2])
		elif type == "bash":
			victim.hit(type, cmd[1], cmd[2]+host.get_damage())
		elif type == "fatigue":
			host.fatigue += cmd[1]
		elif type == "animation":
			if cmd[2] == 1:
				if target.x == host.pos.x:
					host.set_animation_direction(target.y - host.pos.y)
				host.set_animation(cmd[1])
			else:
				host.set_animation(cmd[1])
		elif type == "cast":
			G.fx(host, cmd[1])
		elif type == "move":
			host.relocate(victim)
		elif type == "spawn":
			G.cmd([["spawn", cmd[1], victim], ["possess", "$t"]])
		elif type == "morph":
			var husk = host
			var player_unit = G.cmd([["spawn", cmd[1], host.pos]])
			player_unit.possess(husk.controller)
			husk.remove()
		elif type == "visibility":
			if cmd[1] == 0:
				host.node_sprites.hide()
			else:
				host.node_sprites.show()
		elif type == "end":
			host.buffs.end(name)

func find_victim():
	if data.target == "unit":
		if target != null:
			if "col" in data:
				target = host.pos.get_beam_to(target, data.col, data.range)
			for i in target.get_items_by_type("unit"):
				if is_valid(i):
					return true
	elif data.target == "tile":
		if target != null:
			if "col" in data:
				target = host.pos.get_beam_to(target, data.col, data.range)
			if is_valid(target):
				return true
	elif data.target == "onattack":
		for i in target.get_items_by_type("unit"):
			if is_valid(i):
				return true
	else:
		if is_valid(host):
			return true
	return false

func is_valid(tgt):
	if "reqs" in data:
		var is_tile = tgt.item_type == "tile"
		var is_unit = tgt.item_type == "unit"
		for law in data.reqs:
			if is_tile:
				if law == "solid" and tgt.is_col(1):
					continue
				elif law == "open" and !tgt.is_cols("0110"):
					continue
				elif law == "seen" and tgt.sight_frame == G.you.camera.sight_frame - 1:
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
