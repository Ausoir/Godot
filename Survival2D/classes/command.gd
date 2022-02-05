var host
var tgt
var stop
var args

func assign(phost):
	host = phost
	tgt = host

func replace_vars(_args):
	var r = []
	for arg in _args:
		if arg is String:
			if arg == "$t":
				r.append(tgt)
				continue
			elif arg == "$h":
				r.append(host)
				continue
			elif arg == "$hp":
				r.append(host.pos)
				continue
			elif arg == "$tp":
				r.append(tgt.pos)
				continue
			elif arg == "$pu":
				r.append(G.you.unit)
				continue
		r.append(arg)
	return r

func run(_args):
	args = replace_vars(_args)
	var command = args[0]
	if command == "=":
		if args[1] == "t":
			return args[2]
		elif args[1] == "h":
			host = args[2]
	elif command == "v":
		if args[1] == "parent":
			return args[2].get_parent()
		elif args[1] == "controller":
			return args[2].controller
		elif args[1] == "add":
			return args[2] + args[3]
		elif args[1] == "pos":
			return args[2].pos
	elif command == "r":
		if args[1] == "int":
			return G.rng.randi_range(args[2], args[3])
		elif args[1] == "float":
			return G.rng.randf()
		elif args[1] == "cmd":
			var chosen = args[2][G.rng.randi_range(0, len(args[2])-1)]
			return G.cmds([["t",tgt]]+chosen, host)
	elif command == "?":
		if args[1] == "=":
			stop = tgt == args[2]
		elif args[1] == "<":
			stop = tgt < args[2]
		elif args[1] == "<=":
			stop = tgt <= args[2]
		if len(args) > 3 and args[3] == true:
			stop = !stop
	elif command == "dat":
		if args[1] == "g":
			return host.dat.g(args[2], args[3])
		elif args[1] == "a":
			host.dat.a(args[2], args[3])
	elif command == "var":
		if args[1] == "g":
			return args[2].dat.g(args[3], args[4])
		elif args[1] == "a":
			args[2].dat.a(args[3], args[4])
	elif command == "run":
		return G.cmds(args[1], tgt)
	elif command == "make":
		tgt = G.factory.make_item(args[1], args[2])
		if tgt == null:
			tgt = G.factory.make_mob(args[1], args[2])
			if tgt == null:
				tgt = G.factory.make_unit(args[1], args[2])
	elif command == "possess":
		args[1].possess(get_arg(2))
	elif command == "menu":
		if args[1] == "msg":
			G.msg(args[2])
		elif args[1] == "menu":
			G.ui.display(args[2])
		elif args[1] == "dialog":
			G.ui.display_dialog(args[2], host)
		else:
			G.ui.clear()
	elif command == "particle":
		G.make_particle(args[1], args[2].to_pixel())
	elif command == "cast":
		host.buffs.add(args[1], args[2])
	elif command == "refresh":
		G.you.camera.update(G.you.unit.pos, G.you.last_pos, G.you.unit.sight_col)
	elif command == "remove":
		args[1].remove()
	elif command == "give":
		args[2].store(args[1], true)
	elif command == "read":
		return G.data.get_json_data(args[1], false).get(args[2], "")
	elif command == "travel":
		G.world.change("base")
	return tgt

func get_arg(idx, default=null):
	if args.size() > idx:
		return args[idx]
	return default
