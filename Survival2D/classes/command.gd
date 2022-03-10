var host
var tgt
var ignore = false
var stop = false
var args

func assign(phost):
	host = phost

func replace_vars(_args):
	var r = []
	for arg in _args:
		if arg is Array:
			arg = replace_vars(arg)
		elif arg is String and arg[0] == "$":
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
				var adjs = G.you.unit.pos.get_available_adjacents("0011")
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
			var adjs = args[2].get_available_adjacents("0011")
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
		elif args[1] == "=":
			args[2].dat.a(args[3], args[4])
		elif args[1] == "+":
			args[2].dat.add(args[3], args[4])
	elif command == "run":
		return G.cmd(args[1], tgt)
	elif command == "vars":
		if args[2] in G.vars:
			if args[1] == "=":
				G.vars[args[2]] = args[3]
			elif args[1] == "+":
				G.vars[args[2]] += args[3]
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
	elif command == "tasks":
		args[1].tasks.append(args[2])
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
		var item = G.factory.make_item(args[2])
		if item != null:
			args[1].store(item, true)
			return item
	elif command == "buy":
		if G.vars.money < args[1]:
			stop = true
			G.msg("Not enough money!")
		else:
			G.vars.money -= args[1]
			G.msg("Lost $"+str(args[1])+".")
	elif command == "travel":
		G.travel(args[1])
	elif command == "fade":
		G.ui.fadein()
	return tgt

func get_arg(idx, default=null):
	if args.size() > idx:
		return args[idx]
	return default
