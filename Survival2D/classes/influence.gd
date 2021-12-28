
var host
var target
var data
var duration = 1

func _init(phost, effect, ptarget):
	host = phost
	target = ptarget
	data = G.data.skill_data[effect]
	if "cooldown" in data:
		host.cooldowns[effect] = data.cooldown
	if "duration" in data:
		duration = data.duration
		G.turn.add(self)
	if "onstart" in data:
		run_cmds(data.onstart)

func run_cmds(cmds):
	for cmd in cmds:
		var type = cmd[0]
		if type == "gfx":
			if cmd[1] == "projectile":
				var dest = host.pos.get_beam_to(target, G.COL_TERRAIN, data.range)
				var gfx = G.Gfx.new("tween", .1)
				gfx.shoot(cmd[2], host.pos.to_pixel(), dest.to_pixel())
			elif cmd[1] == "sprite":
				G.cmds([["gfx", cmd[1], target]])
		elif type == "expend":
			var wpn = host.get_weapon()
			if wpn:
				var quant = wpn.dat.g("uses", 1)
				if quant <= 1:
					host.unequip("weapon")
					host.update()
				else:
					wpn.dat.a("uses", quant - 1)

func get_damage():
	if "damage" in data:
		return data.damage

func _on_turn():
	if duration > 0:
		duration -= 1
		if "onturn" in data:
			run_cmds(data.onturn)
		if duration == 0:
			if "onend" in data:
				run_cmds(data.onend)
			G.turn.remove(self)
