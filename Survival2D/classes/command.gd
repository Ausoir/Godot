var host
var tgt
var stop

func _init(phost):
	host = phost
	tgt = host

func replace_vars(args):
	var r = []
	for arg in args:
		if arg is String:
			if arg == "$t":
				r.append(tgt)
				continue
			elif arg == "$h":
				r.append(host)
				continue
		r.append(arg)
	return r

func run(args):
	args = replace_vars(args)
	if args[0] == "t":
		return args[1]
	elif args[0] == "v":
		if args[1] == "host":
			return host
		elif args[1] == "tgt":
			var t = host
			host = tgt
			return t
		elif args[1] == "parent":
			return args[2].get_parent()
		elif args[1] == "controller":
			return args[2].controller
		elif args[1] == "usepos":
			return args[2].get_interact_position()
		elif args[1] == "frontpos":
			return args[2].get_adjacent(0, args[3])
		elif args[1] == "add":
			return args[2] + args[3]
		elif args[1] == "holder":
			return args[2].holder
		elif args[1] == "weapon":
			return args[2].weapon
		elif args[1] == "pos":
			return args[2].global_transform.origin
		elif args[1] == "transform":
			if !args[2].is_inside_tree():
				return Transform()
			return args[2].global_transform
		elif args[1] == "spawnpoint":
			return args[2].get_spawnpoint(args[3])
	elif args[0] == "r":
		if args[1] == "int":
			return G.rng.randi_range(args[2], args[3])
		elif args[1] == "cmd":
			var chosen = args[2][G.rng.randi_range(0, len(args[2])-1)]
			return G.cmds([["t",tgt]]+chosen, host)
	elif args[0] == "rnd":
		if G.rng.randf() > args[1]:
			stop = true
	elif args[0] == "dat":
		if args[1] == "g":
			return host.dat.g(args[2], args[3])
		elif args[1] == "a":
			host.dat.a(args[2], args[3])
	elif args[0] == "run":
		return G.cmds(args[1], tgt)
	elif args[0] == "!if":
		if tgt == args[1]:
			stop = true
	elif args[0] == "if":
		if tgt != args[1]:
			stop = true
	elif args[0] == "req":
		var player = G.get_unit_player(host)
		if player:
			if !player.require_resource(false, args[1]):
				stop = true
	elif args[0] == "cost":
		var player = G.get_unit_player(host)
		if player:
			if len(args) > 3:
				player.add_resource(-args[1], -args[2], true)
			else:
				player.add_resource(-args[1], -args[2])
	elif args[0] == "order":
		tgt.set_tasks(args[1])
	elif args[0] == "spell":
		if args[1] == "learn":
			if len(args) > 3:
				return tgt.learn_spell(args[2], true)
		elif args[1] == "forget":
			if len(args) > 2:
				return tgt.forget_spell(true)
			return tgt.forget_spell()
		elif args[1] == "memorize":
			if len(args) > 3:
				return tgt.add_ability(args[2], true)
			return tgt.add_ability(args[2])
	elif args[0] == "trigger":
		if is_instance_valid(tgt):
			if len(args) == 1:
				tgt.trigger(host)
			else:
				tgt.trigger(args[1])
	elif args[0] == "wield":
		host.set_weapon(tgt)
	elif args[0] == "offhand":
		host.set_offhand(tgt)
	elif args[0] == "equip":
		if tgt.dat.g("part"):
			host.set_armor(tgt)
		else:
			host.set_weapon(tgt)
	elif args[0] == "unequip":
		host.unset_armor(args[1])
	elif args[0] == "unstate":
		tgt.status.remove_state(args[1])
	elif args[0] == "state":
		tgt.status.add_state(tgt, args[1], args[2])
	elif args[0] == "particle":
		G.make_particle(args[1],tgt,args[2])
	elif args[0] == "oncall":
		if args[1] == "onmake":
			host.onmake = args[2]
		elif args[1] == "onwork":
			host.onwork = args[2]
		elif args[1] == "onuse":
			host.onuse = args[2]
		elif args[1] == "onswing":
			host.onswing = args[2]
	elif args[0] == "alert":
		G.sounds.append([args[1], args[2]])
	elif args[0] == "setwork":
		if len(args) == 1:
			host.progress_bar = null
		else:
			host.set_work(args[1])
			host.set_progress_bar(args[2])
	elif args[0] == "getobj":
		return G.world.get_item_type_at(args[1], tgt, 0)
	elif args[0] == "act":
		if args[1].item_type == "unit":
			args[1].set_state(args[2], args[3])
	elif args[0] == "task":
		tgt.set_task()
		tgt.set_tasks(args[1])
	elif args[0] == "seed":
		tgt.set_seed(args[1])
	elif args[0] == "make":
		var newitem = G.factory.make(args[1])
		if newitem == null:
			newitem = G.factory.make_unit(args[1])
		if tgt is Transform:
			newitem.transform = tgt.translated(newitem.translation)
		elif tgt is Vector3:
			newitem.translate(tgt)
		newitem.on_make()
		return newitem
	elif args[0] == "drop":
		G.drop(tgt, [tgt])
	elif args[0] == "die":
		if tgt:
			tgt.die()
		else:
			return null
	elif args[0] == "hit":
		args[1].on_hit(args[2], args[3], args[4], args[5])
	elif args[0] == "damage":
		if tgt:
			tgt.damage(args[1])
	elif args[0] == "menu":
		G.ui.display(args[1], tgt)
	elif args[0] == "message":
		G.message(args[1])
	elif args[0] == "faction":
		tgt.faction = args[1]
		return tgt
	elif args[0] == "rotate":
		var t
		if len(args) > 1:
			t = Transform().looking_at(args[1], Vector3.UP)
		else:
			t = Transform().looking_at(Vector3(G.rng.randf_range(-1,1),0,G.rng.randf_range(-1,1)), Vector3.UP)
		tgt.transform.basis = t.basis.orthonormalized()
		return tgt
	elif args[0] == "brighten":
		G.world.get_node("WorldEnvironment/OmniLight").show()
	return tgt
