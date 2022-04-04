var tgt
var ignore = false
var stop = false
var onstop = null
var args

func replace_dats(host, arg):
	var last = arg.find("}")
	if last != -1:
		var r = ""
		var v = ""
		var on = false
		var once = last == len(arg) - 1 and arg[0] == "{"
		for i in arg:
			if i == "{":
				on = true
			elif i == "}":
				var t
				if "~" in v:
					var split = v.split("~")
					t = R.ir(int(split[0]), int(split[1]))
				elif "," in v:
					t = R.r_arr(v.split(","))
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
					elif arg[1] == "p":
						unit = G.you.unit
					elif arg[1] == "$":
						r.append(arg.substr(1))
						continue
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
					else:
						r.append(unit)
					continue
				else:
					arg = replace_dats(host, arg)
		r.append(arg)
	return r

func run(host, _args):
	args = replace_vars(host, _args)
	var command = args[0]
	if command[0] == "=":
		if command[1] == "t":
			return args[1]
		elif command[1] == "h":
			host = args[1]
		elif command[1] == "+":
			return args[1] + args[2]
	elif command[0] == "?":
		if command == "?=":
			stop = args[1] != args[2]
		elif command == "?>":
			stop = args[1] <= args[2]
		elif command == "?>=":
			stop = args[1] < args[2]
	elif command[0] == "!":
		if command == "!stop":
			stop = !stop
		elif command == "!ignore":
			ignore = !ignore
	elif command[0] == "^":
		if args[1] in G.vars:
			if command == "^":
				return G.vars[args[1]]
			elif command[1] == "=":
				G.vars[args[1]] = args[2]
			elif command[1] == "+":
				G.vars[args[1]] += args[2]
			elif command[1] == "^":
				G.vars[args[1]].append(args[2])
			elif command[1] == "v":
				G.vars[args[1]].erase(args[2])
	elif command[0] == "&":
		if args[1] in G.temp:
			if command == "&":
				return G.temp[args[1]]
	elif command == "run":
		return G.cmds(args[1], tgt)
	elif command == "onstop":
		onstop = args[1]
	elif command == "make":
		tgt = G.factory.make_group(args[1], args[2])
		if tgt == null:
			tgt = G.factory.make_mob(args[1], args[2])
			if tgt == null:
				tgt = G.factory.make_unit(args[1], args[2])
				if tgt == null:
					tgt = G.factory.make_item(args[1], args[2])
	elif command == "menu":
		if args[1] == "msg":
			G.msg(args[2])
		elif args[1] == "menu":
			G.ui.display(args[2])
		elif args[1] == "dialog":
			G.ui.display_dialog(args[2], host)
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
			G.msg("Not enough money!")
		else:
			G.you.make_money(args[1])
	elif command == "travel":
		G.travel(args[1])
	elif command == "fade":
		G.ui.fadein()
	elif command == "custom":
		G.script(args[1], args[2])
	elif command == "point":
		G.you.on_point = [args[1], args[2]]
		G.you.aim_ability(-2)
	elif command == "cast":
		G.influence.do(args[1], args[2], args[3])
	elif command == "projectile":
		G.factory.make_projectile(host, args[1], host.position, tgt, args[2], args[3], args[4], args[5], args[6])
	elif command == "loot":
		G.ui.menu.search_inventory(args[1])
	else:
		var subject = args[1]
		if typeof(subject) == 17:
			if command == "remove":
				subject.remove()
			elif command[0] == "*":
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
				elif command == "*dmg":
					var hp = subject.dat.add("damage", args[2])
					subject.dat.a("damage", max(0, hp))
					subject.on_health_change()
				elif command == "*use":
					var use = subject.dat.add("uses", -1)
					if use == 0:
						subject.remove()
						G.msg(subject.item_name + " was used up.")
					elif use < 0:
						subject.dat.add("uses", 1)
						stop = true
			else:
				var type = subject.get("item_type")
				if type == "tile":
					run_tile(command, subject)
				elif is_instance_valid(subject):
					run_item(command, subject)
	return tgt

func run_tile(command, subject):
	if command == "col":
		stop = subject.is_col(int(args[2]))
	elif command == "terrain":
		stop = !(subject.terrain in args[2])
	elif command == "smash":
		subject.smash(args[2])

func run_item(command, subject):
	if command == "tasks":
		subject.tasks.append(args[2])
	elif command == "possess":
		subject.possess(get_arg(2))
	elif command == "textify":
		subject.textify(args[2])
	elif command == "give":
		var item = G.factory.make_item(args[2])
		if item != null:
			subject.store(item, true)
			return item
	elif command == "move":
		subject.position.x = args[2].x
		subject.position.y = args[2].y
		if subject.item_type == "unit":
			subject.on_slide()
	elif command == "push":
		if subject.item_type == "unit":
			var deg = atan2(subject.position.y - args[2].y, subject.position.x - args[2].x)
			subject.n_collider.vel.x += cos(deg) * args[3]
			subject.n_collider.vel.y += sin(deg) * args[3]
			subject.on_slide()
	elif command == "attack":
		if args[2] != null and is_instance_valid(args[2]):
			var dmg_type = args[3]
			var dmg = subject.get_damage(dmg_type, args[4])
			args[2].hit(dmg_type, dmg, subject)
	elif command == "+flag":
		subject.flags.append(args[2])
		subject.dirty_dat = true
	elif command == "-flag":
		subject.flags.erase(args[2])
		subject.dirty_dat = true
	elif command == "delay":
		subject.delay = args[2]
	elif command == "action":
		subject.set_animation(args[2], subject.delay)
	elif command == "cooldown":
		subject.cooldowns[args[2]] = args[3]
	elif command == "-buff":
		subject.buffs.end(args[2])
	elif command == "morph":
		var newunit = G.cmds([["make", args[2], subject.pos]])
		newunit.possess(subject.controller)
		subject.remove()

func get_arg(idx, default=null):
	if args.size() > idx:
		return args[idx]
	return default
