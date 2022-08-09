var tgt
var stop = false
var onstop = null
var prev
var prev_host

func replace_dats(host, arg):
	var last = arg.find("}")
	if last != -1:
		var r = ""
		var v = ""
		var on = false
		var once = last == len(arg) - 1 and arg[0] == "{"
		for i in arg:
			if i == "{":
				if on:
					return arg.substr(1, arg.length()-1)
				else:
					on = true
			elif i == "}":
				var t
				if "~" in v:
					var split = v.split("~")
					t = R.ir(int(split[0]), int(split[1]))
				elif "," in v:
					t = R.r_arr(v.split(","))
				elif "d" in v:
					var total = 0
					t = v.split("d")
					for _i in range(int(t[0])):
						total += R.ir(1, int(t[1]))
					t = total
				elif v == "t":
					t = tgt
				else:
					t = host.dat.g(v,"")
				if once:
					return t
				r += str(t)
				v = ""
				on = false
			elif on:
				v += i
			else:
				r += i
		return r
	return arg

func replace_vars(host, _args):
	var r = []
	for arg in _args:
		if arg is Array:
			arg = replace_vars(host, arg)
		elif arg is String:
			var s = len(arg)
			if s >= 2:
				if arg[0] == "$":
					var unit
					if arg[1] == "t":
						unit = tgt
					elif arg[1] == "h":
						unit = host
					elif arg[1] == "$":
						r.append(arg.substr(1))
						continue
					elif arg[1] == "p":
						unit = G.you.unit
					elif arg[1] == "R":
						unit = get_rand_pos(14)
					elif arg[1] == "L":
						unit = get_los(14)
					if unit == null:
						r.append(null)
						continue
					if s >= 3:
						if arg[2] == "p":
							r.append(unit.pos)
						elif arg[2] == "v":
							r.append(unit.position)
						elif arg[2] == "a":
							var adjs = unit.pos.get_available_adjacents("0011")
							var adj = R.r_arr(adjs)
							if adj == null:
								r.append(unit.pos)
							else:
								r.append(adj)
						elif arg[2] == "c":
							r.append(unit.controller)
						elif arg[2] == "h":
							r.append(unit.host)
						elif arg[2] == "d":
							r.append(unit.dat.v)
					else:
						r.append(unit)
					continue
				else:
					arg = replace_dats(host, arg)
		r.append(arg)
	return r

func run_operation(command, args, dict, _tgt):
	if command.length() == 1:
		return dict.get(args[1])
	elif command[1] == "=":
		dict[args[1]] = args[2]
	elif args[1] in dict:
		if command[1] == "+":
			dict[args[1]] += args[2]
		elif command[1] == "^":
			dict[args[1]].append(args[2])
		elif command[1] == "v":
			dict[args[1]].erase(args[2])
		elif command[1] == "d":
			dict.erase(args[1])
		elif command[1] == "x":
			dict[args[1]] *= args[2]
	return _tgt

func run(p, host):
	prev_host = host
	var args = replace_vars(host, p)
	var command = args[0]
	if command[0] == "=":
		if command[1] == "t":
			return args[1]
		elif command[1] == "h":
			host = args[1]
		elif command[1] == "+":
			return args[1] + args[2]
		elif command[1] == "g":
			return G.data.get_group(args[1])
		elif command == "=items":
			return G.world.get_items_by_name(args[1])
	elif command[0] == "?":
		if command[1] == "=":
			stop = args[1] != args[2]
		elif command[1] == ">":
			stop = args[1] <= args[2]
		elif command[1] == ".":
			stop = args[1] < args[2]
		if command.length() > 2 and command[2] == "!":
			stop = !stop
	elif command[0] == "!":
		stop = !stop
	elif command[0] == "^":
		return run_operation(command, args, G.vars, tgt)
	elif command[0] == "&":
		return run_operation(command, args, G.temp, tgt)
	elif command == "make":
		if args.size() > 3:
			if !args[2].is_col(int(args[3])):
				tgt = G.factory.make_any(args[1], args[2])
		else:
			tgt = G.factory.make_any(args[1], args[2])
	elif command == "run":
		return G.cmds(args[1], host, tgt)
	elif command == "onstop":
		onstop = args[1]
	elif command == "repeat":
		for _i in range(args[1]):
			G.cmd(prev, host)
	elif command == "menu":
		if args[1] == "msg":
			G.msg(replace_vars(host, [args[2]])[0])
		elif args[1] == "menu":
			G.ui.display(args[2])
		elif args[1] == "dialog":
			G.ui.display_dialog(args[2], host)
		elif args[1] == "confirm":
			G.ui.popup(args[2], args[3])
		else:
			G.ui.clear()
	elif command == "gfx":
		if args[1] == "label":
			if args.size() > 5:
				G.display_damage(args[2], args[3], args[4], args[5], args[6], args[7])
			else:
				G.display_damage(args[2], args[3], args[4])
		elif args[1] == "$":
			if args[2] > 0:
				G.display_damage("+$"+str(args[2]), args[3], "#3D3", 1, 100, 50)
			elif args[2] < 0:
				G.display_damage("-$"+str(-args[2]), args[3], "#D33", 1, 100, 50)
		elif args[1] == "particle":
			G.make_particle(args[2], args[3])
	elif command == "sfx":
		G.sfx.play(args[1], args[2])
	elif command == "money":
		if G.vars.money + args[1] < 0:
			stop = true
			if get_arg(args, 2) == true:
				G.msg("Not enough money!")
		else:
			G.you.make_money(args[1])
	elif command == "travel":
		gamestate.travel(args[1])
	elif command == "fade":
		G.ui.fadein()
	elif command == "custom":
		G.script(args[1], args.slice(2, args.size()))
	elif command == "point":
		G.you.on_point = [args[1], args[2]]
		G.you.aim_ability(-2)
	elif command == "cast":
		G.influence.do(G.data.skill_data.get(args[1]), args[2], args[3])
	elif command == "projectile":
		G.factory.make_projectile(host, args[1], host.position, tgt)
	elif command == "loot":
		G.ui.menu.search_inventory(args[1])
	elif command == "time":
		G.vars.time = args[1]
		if args.size() > 2:
			G.temp["ontime"] = args[2]
	else:
		var subject = args[1]
		if typeof(subject) == 17 and is_instance_valid(subject):
			if command == "remove":
				subject.remove()
			else:
				var type = subject.get("item_type")
				if type == "tile":
					run_tile(command, args, host, subject)
				elif is_instance_valid(subject):
					if command[0] == "*":
						if command == "*":
							return subject.dat.g(args[2], args[3])
						elif command[1] == "=":
							subject.dat.a(args[2], args[3])
							subject.dirty_dat = true
						elif command[1] == "+":
							subject.dat.add(args[2], args[3])
							subject.dirty_dat = true
						elif command[1] == "-":
							subject.dat.d(args[2])
							subject.dirty_dat = true
						elif command[1] == "a":
							subject.dat.g(args[2]).append(args[3])
							subject.dirty_dat = true
						elif command == "*dmg":
							var hp = subject.dat.add("damage", args[2])
							subject.dat.a("damage", max(0, hp))
							subject.on_health_change()
							subject.show_healthbar()
						elif command == "*use":
							var use = subject.dat.add("uses", -1)
							if use == 0:
								subject.remove()
								G.msg(subject.item_name + " was used up.")
							elif use < 0:
								subject.dat.add("uses", 1)
								stop = true
					elif command == "relocate":
						subject.relocate(args[2])
						if type == "unit":
							subject.on_slide()
					elif type == "unit":
						run_unit(command, args, subject)
					else:
						run_item(command, args, subject)
	return tgt

func run_tile(command, args, host, subject):
	if command[0] == "*":
		return run_operation(command, args, subject.dat, tgt)
	elif command == "col":
		stop = subject.is_col(int(args[2]))
	elif command == "terrain":
		stop = !(subject.terrain in args[2])
	elif command == "smash":
		subject.smash(args[2])
	elif command == "aoe":
		var area = subject.get_area(args[2])
		for i in area:
			for item in i.items:
				if item != host:
					G.cmds(args[3], host, item)

func run_item(command, args, subject):
	if command == "textify":
		subject.textify(args[2])
	elif command == "+flag":
		subject.flags.append(args[2])
		subject.dirty_dat = true
	elif command == "-flag":
		subject.flags.erase(args[2])
		subject.dirty_dat = true

func run_unit(command, args, subject):
	if command == "delay":
		subject.delay = int(args[2])
	elif command == "attack":
		if args[2] != null and is_instance_valid(args[2]):
			var dmg_type = args[3]
			var dmg = subject.get_damage(dmg_type, args[4])
			args[2].hit(dmg_type, dmg, subject)
	elif command == "action":
		subject.set_animation(args[2], subject.delay)
	elif command == "push":
		var deg = atan2(subject.position.y - args[2].y, subject.position.x - args[2].x)
		subject.n_collider.vel.x += cos(deg) * args[3]
		subject.n_collider.vel.y += sin(deg) * args[3]
		subject.on_slide()
	elif command == "cooldown":
		subject.cooldowns[args[2]] = args[3]
	elif command == "-buff":
		subject.buffs.end(args[2])
	elif command == "morph":
		var newunit = G.cmds([["make", args[2], subject.pos]])
		newunit.possess(subject.controller)
		subject.remove()
		return newunit
	elif command == "move":
		subject.position.x = args[2].x
		subject.position.y = args[2].y
		subject.on_slide()
	elif command == "give":
		if subject.dat.g("type", "other") != "other":
			var item = args[2]
			if item != null:
				if !subject.auto_equip(item):
					subject.store(item, true)
				return item
	elif command == "take":
		if subject.dat.g("type", "other") != "other":
			var item = args[2]
			if item != null:
				subject.on_item_remove(item)
				return item
	elif command == "hunt":
		subject.controller.target = args[2]
	elif command == "tasks":
		subject.controller.tasks.append(args[2])
	elif command == "possess":
		subject.possess(get_arg(args, 2))

func get_arg(args, idx, default=null):
	if args.size() > idx:
		return args[idx]
	return default

func get_los(p):
	var tile
	while tile == null or tile.is_col(p):
		var x = R.ir(0, G.you.n_camera.sight_range)
		var y = R.ir(0, G.you.n_camera.sight_range_y)
		if R.b():
			x = G.you.n_camera.sight_range + 1
		else:
			y = G.you.n_camera.sight_range_y + 1
		if R.b():
			x *= -1
			y *= -1
		tile = G.world.get_tile(G.you.unit.pos.x + x, G.you.unit.pos.y + y)
	return tile

func get_rand_pos(p):
	var tile
	while tile == null or tile.is_col(p):
		tile = G.world.tiles[R.ir(0, G.world.size.y-1)][R.ir(0, G.world.size.x-1)]
	return tile
