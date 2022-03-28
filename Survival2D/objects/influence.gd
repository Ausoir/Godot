var tgt

func do(name, host=null, p=null, mode=0, pdata=null):
	var data = pdata
	if data == null:
		data = G.data.skill_data.get(name)
		if data == null:
			return false
	if !find_victim(p, host, data):
		return false
	else:
		if "cooldown" in data:
			if name in host.cooldowns:
				return false
			host.cooldowns[name] = data.cooldown
		if "delay" in data:
			host.delay = data.delay
		if mode == 0:
			if "duration" in data:
				if host.buffs.has(name):
					G.cmds(data.get("onstack", []), host, tgt)
					return true
				else:
					host.buffs.add(name, data, data.duration, tgt)
			G.cmds(data.get("onstart", []), host, tgt)
		elif mode == 1:
			G.cmds(data.get("onturn", []), host, tgt)
		elif mode == 2:
			G.cmds(data.get("onend", []), host, tgt)
		elif mode == 3:
			G.cmds(data.get("retaliate", []), host, tgt)
			G.cmds(data.get("compensate", []), host, host)
		if tgt != null:
			if !is_instance_valid(tgt) or (tgt.item_type == "unit" and tgt.is_dead):
				G.cmds(data.get("onkill", []), host, tgt)
		return true

func find_victim(p, host, data):
	if data.target == "auto":
		tgt = p
		return true
	elif p != null:
		if data.target == "tile":
			tgt = get_tile(p)
			return true
		elif data.target == "self":
			if is_req_met(host, host, data):
				tgt = host
				return true
		elif data.target == "body":
			var raycast = host.n_collider.cast_col_ray(p, [host], data.get("col", 0))
			if !raycast.empty() and raycast.collider is KinematicBody2D and raycast.collider.item_type == "unit":
				var tgt_point = raycast.position
				if host.pos.world.from_vec(tgt_point).distance_to(host.pos) <= data.get("range", 16):
					tgt = raycast.collider.get_parent()
					return is_req_met(tgt, host, data)
		elif data.target == "beam":
			var rng = data.get("range", 16)
			tgt = host.pos.get_beam_to(get_tile(p), data.get("col", 0), rng)[0]
			return is_req_met(tgt, host, data)
		else:
			tgt = host.controller.target
			if tgt != null and is_instance_valid(tgt):
				if data.target == "onattack" or data.target == "oncharge" or data.target == "onhit":
					if tgt.item_type == "unit" and is_req_met(tgt, host, data):
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
				elif law == "seen" and p.sight_frame == G.you.n_camera.sight_frame - 1:
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
