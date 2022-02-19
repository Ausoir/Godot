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
			victim = host
			run_cmds(data.get("compensate", []))
		if victim.item_type == "unit":
			if !is_instance_valid(victim):
				run_cmds(data.get("onkill", []))
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
			elif cmd[1] == "particle":
				G.make_particle(cmd[2], victim.pos.to_pixel())
			elif cmd[1] == "label":
				G.display_damage(host.pos.to_pixel(), cmd[2], cmd[3], .8)
		elif type == "expend":
			var wpn = host.get_weapon()
			if wpn:
				var uses = wpn.dat.g("uses", 1)
				if uses < 1:
					host.unequip("weapon")
				else:
					wpn.dat.a("uses", uses - 1)
		elif type == "cooldown":
			host.cooldowns[cmd[1]] = cmd[2]
		elif type == "stat":
			host.dat.add(cmd[1], cmd[2])
		elif type == "dmg":
			var dmg_type = cmd[1]
			victim.hit(dmg_type, host.get_damage(dmg_type, cmd[2]), host)
		elif type == "heal":
			host.hit("heal", -cmd[1], host)
		elif type == "interrupt":
			victim.buffs.on_interrupt(cmd[1])
		elif type == "reaction":
			victim.delay = cmd[2]
			victim.set_animation(cmd[1])
		elif type == "action":
			if cmd[2] == 1:
				if target != null and target.x == host.pos.x:
					host.set_animation_direction(target.y - host.pos.y)
				host.set_animation(cmd[1])
			else:
				host.set_animation(cmd[1])
		elif type == "repeat":
			G.fx(host, host.last_skill)
		elif type == "cast":
			G.fx(host, cmd[1])
		elif type == "move":
			host.relocate(victim)
		elif type == "mob":
			G.factory.make_mob(cmd[1], victim)
		elif type == "spawn":
			G.cmd([["make", cmd[1], victim], ["possess", "$t"]])
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
		elif type == "sight":
			host.dat.a("sight col", host.sight_col)
			host.sight_col = cmd[1]
			if host == G.you.unit:
				G.cmd([["refresh"]])
		elif type == "unsight":
			host.sight_col = host.dat.g("sight col")
			if host == G.you.unit:
				G.cmd([["refresh"]])
		elif type == "flag":
			host.flags.append(cmd[1])
			host.update_flags()
		elif type == "unflag":
			host.flags.erase(cmd[1])
			host.update_flags()
		elif type == "respite":
			host.deck = []
			var actives = host.dat.g("actives", [])
			for i in actives:
				host.deck.append(i)
		elif type == "cmd":
			G.cmd([cmd.slice(1, cmd.size() - 1)], host)
		elif type == "end":
			host.buffs.end(cmd[1])

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
	elif data.target == "onattack" or data.target == "oncharge" or data.target == "onhit":
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
				elif law == "seen" and tgt.sight_frame == G.you.n_camera.sight_frame - 1:
					continue
			elif is_unit:
				if law == "unit":
					continue
				elif law == "humanoid" and tgt.dat.g("type") != "man":
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
