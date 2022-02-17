var host
var tgt
var ignore = false
var args

func assign(phost):
	host = phost

func replace_vars(_args):
	var r = []
	for arg in _args:
		if arg is String and arg[0] == "$":
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
			elif arg == "$pua":
				var adjs = G.you.unit.pos.get_available_adjacents("0100")
				var adj = R.r_arr(adjs)
				if adj == null:
					r.append(G.you.unit.pos)
				else:
					r.append(adj)
			elif arg == "$pup":
				r.append(G.you.unit.pos)
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
		elif args[1] == "adj":
			var adjs = args[2].get_available_adjacents("0100")
			var adj = R.r_arr(adjs)
			if adj == null:
				adj = args[2]
			return adj
	elif command == "r":
		if args[1] == "int":
			return R.ir(args[2], args[3])
		elif args[1] == "cmd":
			var chosen = args[2][R.ir(0, len(args[2])-1)]
			return G.cmds([["t",tgt]]+chosen, host)
	elif command == "?":
		if args[1] == "=":
			ignore = tgt != args[2]
		elif args[1] == "!=":
			ignore = tgt == args[2]
		elif args[1] == "<":
			ignore = tgt < args[2]
		elif args[1] == "<=":
			ignore = tgt <= args[2]
	elif command == "dat":
		if args[1] == "g":
			return args[2].dat.g(args[3], args[4])
		elif args[1] == "a":
			args[2].dat.a(args[3], args[4])
	elif command == "run":
		return G.cmd(args[1], tgt)
	elif command == "ally":
		G.you.allies.append(tgt)
	elif command == "make":
		tgt = G.factory.make_script(args[1], args[2])
		if tgt == null:
			tgt = G.factory.make_group(args[1], args[2])
			if tgt == null:
				tgt = G.factory.make_item(args[1], args[2])
				if tgt == null:
					tgt = G.factory.make_mob(args[1], args[2])
					if tgt == null:
						tgt = G.factory.make_unit(args[1], args[2])
	elif command == "order":
		if args[1] == "bottom":
			if args[2].get_parent() == G.world.items:
				G.world.items.move_child(args[2], 0)
		elif args[1] == "top":
			if args[2].get_parent() == G.world.items:
				G.world.items.remove_child(args[2])
				G.world.items.add_child(args[2])
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
	elif command == "remove":
		args[1].remove()
	elif command == "give":
		args[2].store(args[1], true)
	elif command == "read":
		return G.data.get_json_data(args[1], false).get(args[2], "")
	elif command == "travel":
		G.travel(args[1], args[2])
	return tgt

func get_arg(idx, default=null):
	if args.size() > idx:
		return args[idx]
	return default
