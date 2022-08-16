var tgt

func do(skill, host=null, dest=null, mode=0):
	if !find_victim(skill, host, dest):
		return false
	else:
		if "delay" in skill:
			host.delay = skill.delay
		if mode == 0:
			if "duration" in skill and host.item_type == "unit":
				if host.buffs.has(skill.name):
					G.cmds(skill.get("onstack", []), host, tgt)
					return true
				else:
					host.buffs.add(skill, skill.duration, tgt)
			G.cmds(skill.get("onstart", []), host, tgt)
		elif mode == 1:
			G.cmds(skill.get("onturn", []), host, tgt)
		elif mode == 2:
			G.cmds(skill.get("onend", []), host, tgt)
		elif mode == 3:
			G.cmds(skill.get("retaliate", []), host, tgt)
			G.cmds(skill.get("compensate", []), host, host)
		if host == G.you.unit:
			if "noise" in skill:
				G.you.noise = skill.noise
		if tgt != null:
			if !is_instance_valid(tgt) or (tgt.item_type == "unit" and tgt.is_dead):
				G.cmds(skill.get("onkill", []), host, tgt)
		return true

func find_victim(skill, host, to):
	var target = skill.get("target")
	if target == null:
		tgt = host
		return true
	elif target == "auto":
		tgt = to
		return true
	elif to != null:
		if target == "tile":
			tgt = get_tile(to)
			return true
		elif target == "self":
			if is_req_met(host, host, skill):
				tgt = host
				return true
		elif target == "body":
			var raycast = host.n_collider.cast_ray(to, [host], skill.get("col", 0))
			if !raycast.empty() and raycast.collider is KinematicBody2D and raycast.collider.item_type == "unit":
				var tgt_point = raycast.position
				if host.pos.world.from_vec(tgt_point).distance_to(host.pos) <= skill.get("range", 16):
					tgt = raycast.collider.get_parent()
					return is_req_met(tgt, host, skill)
		elif target == "beam":
			var rng = skill.get("range", 16)
			tgt = host.pos.get_beam_to(get_tile(to), skill.get("col", 0), rng)[0]
			return is_req_met(tgt, host, skill)
		else:
			tgt = to
			if tgt != null and is_instance_valid(tgt):
				if target == "onattack" or target == "oncharge" or target == "onhit":
					if tgt.item_type == "unit" and is_req_met(tgt, host, skill):
						return true
	return false

func get_tile(p):
	return G.world.from_vec(p)

func is_req_met(p, host, data):
	if "reqs" in data:
		var is_tile = p.item_type == "tile"
		var is_unit = p.item_type == "unit"
		for law in data.reqs:
			if is_tile:
				if law == "solid" and p.is_col(4):
					continue
				elif law == "open" and !p.is_col(14):
					continue
				elif law == "seen" and p.visible:
					continue
				elif law == "adjacent" and p.distance_to(host.pos) <= 1:
					continue
			elif is_unit:
				if law == "unit":
					continue
				elif law == "humanoid" and p.dat.g("type") != "man":
					continue
				elif law == "foe" and host.dat.g("faction", -1) != p.dat.g("faction", -1):
					continue
				elif law == "ally" and host.dat.g("faction", -1) == p.dat.g("faction", -1):
					continue
				elif law == "larger size" and host.dat.g("size",0) > p.dat.g("size", 0):
					continue
				elif law == "smaller size" and host.dat.g("size",0) < p.dat.g("size", 0):
					continue
				elif law == "same size" and host.dat.g("size",0) == p.dat.g("size", 0):
					continue
				elif law == "adjacent" and p.pos.distance_to(host.pos) <= 1:
					continue
			return false
	return true
