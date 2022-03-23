var host
var tgt
var ignore = false
var stop = false
var args

func replace_vars(_args):
	var r = []
	for arg in _args:
		if arg is Array:
			arg = replace_vars(arg)
		elif arg is String and arg[0] == "$":
			if arg == "$t":
				r.append(tgt)
			elif arg == "$h":
				r.append(host)
			elif arg == "$hp":
				r.append(host.pos)
			elif arg == "$hv":
				r.append(host.position)
			elif arg == "$tp":
				r.append(tgt.pos)
			elif arg == "$tv":
				r.append(tgt.position)
			elif arg == "$pu":
				r.append(G.you.unit)
			elif arg == "$pua":
				var adjs = G.you.unit.pos.get_available_adjacents("0011")
				var adj = R.r_arr(adjs)
				if adj == null:
					r.append(G.you.unit.pos)
				else:
					r.append(adj)
			elif arg == "$pup":
				r.append(G.you.unit.pos)
			elif arg[1] == "$":
				r.append(arg.substr(1))
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
		elif args[1] == "p":
			return R.r_percent(args[2])
		elif args[1] == "cmd":
			var chosen = R.ir(3, len(args)-1)
			return G.cmds(args[chosen], host)
	elif command == "?":
		if args[1] == "=":
			stop = tgt != args[2]
		elif args[1] == "!=":
			stop = tgt == args[2]
		elif args[1] == "<":
			stop = tgt < args[2]
		elif args[1] == "<=":
			stop = tgt <= args[2]
	elif command == "col":
		stop = args[1].is_col(int(args[2]))
	elif command == "@dat":
		return args[1].dat.g(args[2], args[3])
	elif command == "=dat":
		args[1].dat.a(args[2], args[3])
		args[1].dirty_dat = true
	elif command == "+dat":
		args[1].dat.add(args[2], args[3])
		args[1].dirty_dat = true
	elif command == "run":
		return G.cmds(args[1], tgt)
	elif command == "vars":
		if args[2] in G.vars:
			if args[1] == "=":
				G.vars[args[2]] = args[3]
			elif args[1] == "+":
				G.vars[args[2]] += args[3]
	elif command == "make":
		tgt = G.factory.make_group(args[1], args[2])
		if tgt == null:
			tgt = G.factory.make_mob(args[1], args[2])
			if tgt == null:
				tgt = G.factory.make_unit(args[1], args[2])
				if tgt == null:
					tgt = G.factory.make_item(args[1], args[2])
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
	elif command == "gfx":
		if args[1] == "label":
			if args.size() > 5:
				G.display_damage(args[2], args[3], args[4], args[5], args[6])
			else:
				G.display_damage(args[2], args[3], args[4])
		elif args[1] == "particle":
			G.make_particle(args[2], args[3])
	elif command == "sfx":
		var sound = G.Sfx.instance()
		sound.start(args[1], args[2])
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
	elif command == "custom":
		G.script(args[1])
	elif command == "move":
		if args[1].item_type == "unit":
			host.position.x = args[2].x
			host.position.y = args[2].y
			host.on_slide()
	elif command == "attack":
		var dmg_type = args[3]
		var dmg = args[1].get_damage(dmg_type, args[4])
		args[2].hit(dmg_type, dmg, args[1])
	elif command == "projectile":
		var r = G.factory.make_projectile(host, args[1], host.position, tgt, args[2], args[3], args[4])
		r.onattack = args[5]
	elif command == "+flag":
		args[1].flags.append(args[2])
		args[1].dirty_dat = true
	elif command == "-flag":
		args[1].flags.erase(args[2])
		args[1].dirty_dat = true
	elif command == "cast":
		G.influence.do(args[1], args[2], args[3])
	elif command == "delay":
		args[1].delay = args[2]
	elif command == "action":
		args[1].set_animation(args[2], args[1].delay)
	elif command == "cooldown":
		args[1].cooldowns[args[2]] = args[3]
	elif command == "-buff":
		args[1].buffs.end(args[2])
	elif command == "morph":
		var husk = args[1]
		var newunit = G.cmds([["make", args[2], husk.pos]])
		newunit.possess(husk.controller)
		husk.remove()
	return tgt

func get_arg(idx, default=null):
	if args.size() > idx:
		return args[idx]
	return default
