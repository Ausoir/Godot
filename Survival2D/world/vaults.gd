var data

func load_vault(p):
	data = G.data.get_json_data("vaults/" + p)

func make_vault(_map, room, dir):
	var flip = 0
	var rot = false
	if dir == 0:
		flip = G.rng.randi_range(0, 1)
		rot = false
	elif dir == 1:
		flip = G.rng.randi_range(2, 3)
		rot = true
	elif dir == 2:
		flip = G.rng.randi_range(2, 3)
		rot = false
	elif dir == 3:
		flip = G.rng.randi_range(0, 1)
		rot = true
	var fromx = room[0]
	var fromy = room[1]
	var width = room[2] - fromx
	var height = room[3] - fromy
	var candidates = []
	for vault_data in data:
		var vault = vault_data[1]
		var diffX = width - len(vault[0]) + 1
		var diffY = height - len(vault) + 1
		var diffX2 = width - len(vault) + 1
		var diffY2 = height - len(vault[0]) + 1
		var startX
		var startY
		if diffX >= 0 and diffY >= 0 and diffX2 >= 0 and diffY2 >= 0:
			if rot:
				startX = fromx + G.rng.randi_range(0, diffX2)
				startY = fromy + G.rng.randi_range(0, diffY2)
			else:
				startX = fromx + G.rng.randi_range(0, diffX)
				startY = fromy + G.rng.randi_range(0, diffY)
			candidates.append([vault_data, startX, startY, flip, rot])
		elif diffX >= 0 and diffY >= 0 and !rot:
			startX = fromx + G.rng.randi_range(0, diffX)
			startY = fromy + G.rng.randi_range(0, diffY)
			candidates.append([vault_data, startX, startY, flip, false])
		elif diffX2 >= 0 and diffY2 >= 0 and rot:
			startX = fromx + G.rng.randi_range(0, diffX2)
			startY = fromy + G.rng.randi_range(0, diffY2)
			candidates.append([vault_data, startX, startY, flip, true])
	#print(size, " ", len(candidates), " ", from, " ", to)
	for candidate in candidates:
		var vault_data = candidate[0]
		var chance = vault_data[0]
		var map = vault_data[1]
		var palette = vault_data[2]
		if G.rng.randi_range(0, 99) < chance:
			place_vault(_map, map, palette, candidate[1], candidate[2], candidate[3], candidate[4])
			return true
	return false

func place_vault(_map, vault, palette, startX, startY, flip, rot):
	for y in range(len(vault)):
		for x in range(len(vault[0])):
			var sX = x
			var sY = y
			var fX
			var fY
			if flip == 1 or flip == 3:
				sX = (len(vault[0])-1 - x)
			if flip == 2 or flip == 3:
				sY = (len(vault)-1 - y)
			if rot:
				fX = startX + sY
				fY = startY + sX
			else:
				fX = startX + sX
				fY = startY + sY
			var val = vault[y][x]
			var palet = palette.get(val)
			if val != null:
				_map[fY][fX] = palet
			else:
				push_error("Invalid vault palette value: "+str(palet))

func boundary_dist(vault, x, y):
	var xdist = min(x, len(vault[0])-1-x)
	var ydist = min(y, len(vault)-1-y)
	return min(xdist, ydist)
