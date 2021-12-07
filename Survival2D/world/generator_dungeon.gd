extends "res://world/Generator.gd"

var vaults = preload("res://world/Vaults.gd").new()
var biome
var sector_borders
var sectors
var dungeon_rooms
var dungeon_objects
var dungeon_floors
var door_candidates
var special_terrain = {
	"default": ["campfire"],
	"chapel": ["altar", "bookcase", "benchs"],
	"lab": ["cauldron", "desk", "bookcase", "mageaura", "bubblelight", "dissection", "bench"],
	"entrance": ["bench","crates"],
}


func _init(prng, psize).(prng, psize):
	vaults.audit_vaults() #TODO: Remove at production

func make_dungeon(times, halls):
	biome = make_perlin(map_size.x, map_size.y)
	base = make_base(map_size.x, map_size.y, '.')
	sectors = {}
	sector_borders = []
	dungeon_rooms = []
	door_candidates = []
	dungeon_objects = make_base(map_size.x, map_size.y, null)
	dungeon_floors = make_base(map_size.x, map_size.y, null)
	divide(Vector2.ZERO, map_size, times, halls+1, .5)
	return base

func make_rooms(departments):
	for room in dungeon_rooms:
		var doors = 0
		for y in range(room[1].y, room[2].y+1):
			if base[y][room[1].x] == 'D':
				doors += 1
			if base[y][room[2].x] == 'D':
				doors += 1
		for x in range(room[1].x, room[2].x+1):
			if base[room[1].y][x] == 'D':
				doors += 1
			if base[room[2].y][x] == 'D':
				doors += 1
		var sector = get_sector(Vector2(room[1].x + 1, room[1].y + 1))
		if sector != null:
			sectors[sector] = ""
		room.append(sector)
		room.append(doors)

	var tpartments = departments.duplicate()
	for s in sectors:
		if tpartments.empty():
			sectors[s] = rng.rand_arr(departments)
		else:
			var idx = rng.randi_range(0, len(tpartments)-1)
			sectors[s] = tpartments[idx]
			tpartments.remove(idx)
	print(sectors)

	var unique_rooms = []
	var queue_make = []
	for room in dungeon_rooms: #name, from, to, sector, door
		#print(room)
		if room[3] == null: #halls
			make_hall(room)
		elif sectors[room[3]] == "living":
			if room[0] != "small" and !("chapel" in unique_rooms):
				unique_rooms.append("chapel")
				make_terrain(room, "chapel")
				queue_make.append(["chapel", room])
			else:
				make_terrain(room)
				queue_make.append(["living", room])
		elif sectors[room[3]] == "storage":
			if !("entrance" in unique_rooms):
				unique_rooms.append("entrance")
				if !make_terrain(room, "entrance"):
					queue_make.append(["entrance", room])
			elif !("waste" in unique_rooms):
				unique_rooms.append("waste")
				make_terrain(room)
				queue_make.append(["waste", room])
			else:
				make_terrain(room)
				if rng.randi_range(0, 3) == 0:
					queue_make.append(["defense", room])
				else:
					queue_make.append(["storage", room])
		elif sectors[room[3]] == "lab":
			if rng.randi_range(0, 3) == 0:
				make_terrain(room)
				if rng.randf() < .5:
					queue_make.append(["storage", room])
				else:
					queue_make.append(["living", room])
			else:
				make_terrain(room, "lab")
				queue_make.append(["lab", room])
	for make_room in queue_make:
		call("make_"+make_room[0], make_room[1])

	make_doors()
	clear_doorways()
	make_exit()
	make_exit()

func make_doors():
	for candidate in door_candidates:
		var doors = []
		var doors2 = []
		var doors3 = []
		if candidate[0] == 0:
			for i in range(candidate[1].x+2, candidate[2].x, 2):
				if boundary_dist(i, candidate[1].y) > 1:
					if base[candidate[1].y][i+1] in G.world.SEMIWALLTILES and base[candidate[1].y][i-1] in G.world.SEMIWALLTILES:
						var open1 = base[candidate[1].y+1][i] in G.world.OPENTILES
						var open2 = base[candidate[1].y-1][i] in G.world.OPENTILES
						if open1 and open2:
							doors.append([0, i, candidate[1].y])
						elif open1:
							doors2.append([0, i, candidate[1].y])
						elif open2:
							doors2.append([0, i, candidate[1].y])
					doors3.append([0, i, candidate[1].y])
		else:
			for i in range(candidate[1].y+2, candidate[2].y, 2):
				if boundary_dist(candidate[1].x, i) > 1:
					if base[i+1][candidate[1].x] in G.world.SEMIWALLTILES and base[i-1][candidate[1].x] in G.world.SEMIWALLTILES:
						var open1 = base[i][candidate[1].x+1] in G.world.OPENTILES
						var open2 = base[i][candidate[1].x-1] in G.world.OPENTILES
						if open1 and open2:
							doors.append([1, candidate[1].x, i])
						elif open1:
							doors2.append([1, candidate[1].x, i])
						elif open2:
							doors2.append([1, candidate[1].x, i])
					doors3.append([1, candidate[1].x, i])
		if !doors.empty():
			var t = doors[rng.randi_range(0, len(doors)-1)]
			base[t[2]][t[1]] = 'D'
		elif !doors2.empty():
			var t = doors2[rng.randi_range(0, len(doors2)-1)]
			base[t[2]][t[1]] = 'D'
		elif !doors3.empty():
			var t = doors3[rng.randi_range(0, len(doors3)-1)]
			base[t[2]][t[1]] = ','
			base[t[2]+1][t[1]] = '.'
			base[t[2]-1][t[1]] = '.'
			base[t[2]][t[1]+1] = '.'
			base[t[2]][t[1]-1] = '.'
			print("Door couldn't be placed: ", candidate)

func clear_doorways():
	var walltiles = G.world.WALLTILES
	var doorCandidates = []
	for x in range(0,map_size.x):
		for y in range(0,map_size.y):
			var isOdd = x%2==1 or y%2==1
			if !isOdd:
				if base[y][x] in ['D', '=']:
					if boundary_dist(x, y) > 1:
						doorCandidates.append([x, y])
					else:
						base[y][x] = 'W'
			elif base[y][x] in G.world.SEMIWALLTILES:
				var opens = len(get_possible_sides(x, y, '.'))
				opens += len(get_possible_sides(x, y, ','))
				if opens == 3:
					base[y][x] = '.'
	for _i in range(2):
		for i in doorCandidates:
			var x = i[0]
			var y = i[1]
			var wallX = 0
			var wallY = 0
			if base[y+1][x] in walltiles:
				wallY += 1
			if base[y-1][x] in walltiles:
				wallY += 1
			if base[y][x+1] in walltiles:
				wallX += 1
			if base[y][x-1] in walltiles:
				wallX += 1
			if wallX == 2 and wallY == 2:
				dungeon_objects[y][x] = null
				base[y][x] = ','
				base[y+1][x] = ','
				base[y-1][x] = ','
				base[y][x+1] = ','
				base[y][x-1] = ','
			elif wallX == 2:
				if base[y][x] == 'D' and rng.randf() < .4:
					dungeon_objects[y][x] = ["door", rng.rand_arr([0, 10])]
				base[y+1][x] = ','
				base[y-1][x] = ','
				dungeon_objects[y+1][x] = null
				dungeon_objects[y-1][x] = null
			elif wallY == 2:
				if base[y][x] == 'D' and rng.randf() < .4:
					dungeon_objects[y][x] = ["door", rng.rand_arr([16, 22])]
				base[y][x+1] = ','
				base[y][x-1] = ','
				dungeon_objects[y][x+1] = null
				dungeon_objects[y][x-1] = null
			else:
				dungeon_objects[y][x] = null
				base[y][x] = 'W'

func make_exit():
	var rx
	var ry
	var tile = '^'
	while not tile in ['.', ',']:
		rx = rng.randi_range(0, map_size.x)
		ry = rng.randi_range(0, map_size.y)
		tile = base[ry][rx]
	dungeon_objects[ry][rx] = ['trapdoor', -1]

func make_entrance(room):
	var objs = [[], [null,null,null,"crates","chest"], [null,"crates"]]
	var center = (room[1] + (room[2] - room[1])/2).round()
	var cx = int(center.x)
	var cy = int(center.y)
	for y in range(room[1].y+1, room[2].y):
		for x in range(room[1].x+1, room[2].x):
			allocate_object(objs, x, y)
	base[cy][cx] = '@'
	dungeon_objects[cy][cx] = null

func make_chapel(room):
	var objs = [["bench"], ["bookcase"], ["bench"]]
	for y in range(room[1].y+1, room[2].y):
		for x in range(room[1].x+1, room[2].x):
			dungeon_floors[y][x] = "carpet"
			allocate_object(objs, x, y)

func make_waste(room):
	var objs = [["waste","bench"],["waste",null,"pots"],[]]
	for y in range(room[1].y+1, room[2].y):
		for x in range(room[1].x+1, room[2].x):
			allocate_object(objs, x, y)

func make_lab(room):
	var objs = [["bubblelight",null],["desk","wand rack","bookcase"],["bookcase"]]
	for y in range(room[1].y+1, room[2].y):
		for x in range(room[1].x+1, room[2].x):
			dungeon_floors[y][x] = "carpet"
			allocate_object(objs, x, y)

func make_defense(room):
	var objs = [["beds", "bed cluster"], ["barrels", "crates"]]
	for y in range(room[1].y+1, room[2].y):
		for x in range(room[1].x+1, room[2].x):
			allocate_object(objs, x, y)

func make_living(room):
	var objs = [["table", "large table", "pots", "beds", "bed cluster"],
				["pots", "bookcase", "barrels", "kegs"],["bookcase", "barrels"]]
	var flooring = rng.randf() < .5
	for y in range(room[1].y+1, room[2].y):
		for x in range(room[1].x+1, room[2].x):
			allocate_object(objs, x, y)
			if flooring:
				dungeon_floors[y][x] = "planks"
			if base[y][x] == '.':
				base[y][x] = '!'

func make_storage(room):
	var objs = [[],[null,null,"chest","crates","barrels"],[null,null,null,null,"barrels","crates","crates"]]
	for y in range(room[1].y+1, room[2].y):
		for x in range(room[1].x+1, room[2].x):
			allocate_object(objs, x, y)

func make_hall(room):
	var size = room[2] - room[1]
	if size.y <= 5:
		for x in range(room[1].x+2, room[2].x-1, 8):
			dungeon_objects[room[1].y+2][x] = ["mob",0]
			if rng.randi_range(0, 1) == 0:
				if base[room[1].y][x] == 'W' and base[room[1].y][x+1] == 'W':
					dungeon_objects[room[1].y][x] = ["torch", 10]
			else:
				if base[room[2].y][x] == 'W' and base[room[2].y][x-1] == 'W':
					dungeon_objects[room[2].y][x] = ["torch", 0]
	elif size.x <= 5:
		for y in range(room[1].y+2, room[2].y-1, 8):
			dungeon_objects[y][room[1].x+2] = ["mob",0]
			if rng.randi_range(0, 1) == 0:
				if base[y][room[1].x] == 'W' and base[y-1][room[1].x] == 'W':
					dungeon_objects[y][room[1].x] = ["torch", 16]
			else:
				if base[y][room[2].x] == 'W' and base[y+1][room[2].x] == 'W':
					dungeon_objects[y][room[2].x] = ["torch", 22]

func allocate_object(objs, x, y, force=false):
	if base[y][x] == '.' or force:
		var open = objs[0]
		var sides = objs[1]
		var cramped = sides
		if len(objs) > 2:
			cramped = objs[2]
		var candidate
		var possibleSides = get_possible_sides(x, y, G.world.SEMIWALLTILES)
		var sideNum = len(possibleSides)
		if sideNum == 0 and len(get_possible_sides(x, y, '.')) == 4:
			candidate = place_object(open, possibleSides)
		elif sideNum == 1:
			candidate = place_object(sides, possibleSides)
		elif sideNum < 4:
			candidate = place_object(cramped, possibleSides)
		elif force:
			candidate = place_object(open, possibleSides)
		if candidate != null:
			dungeon_objects[y][x] = candidate
			base[y][x] = ','

func place_object(objs, possibleSides):
	var obj = rng.rand_arr(objs)
	if obj != null:
		var orientation
		if len(possibleSides) == 0:
			orientation = rng.rand_arr([0,10,16,22])
		else:
			orientation = rng.rand_arr(possibleSides)
		return [obj, orientation]

func make_terrain(room, vault_type="default"):
	var rot = vaults.make_vault(rng, base, room[1], room[2], vault_type)
	if rot != -1:
		for y in range(room[1].y, room[2].y+1):
			for x in range(room[1].x, room[2].x+1):
				if base[y][x].is_valid_integer():
					var obj = special_terrain[vault_type][int(base[y][x])]
					base[y][x] = '.'
					allocate_object([[obj],[obj]], x, y)
				elif base[y][x] == '!':
					dungeon_objects[y][x] = ['mob', 0]
		return true

func divide(from, to, times, times_hall, horizontal):
	var size = to - from
	var gap = 0
	if times_hall > 2:
		gap = 2
	elif times_hall > 0:
		gap = 1
	elif (size.x <= 7 and size.y <= 7) or times <= 0:
		if size.x > 12 and size.y > 12:
			dungeon_rooms.append(["large", from, to])
		elif size.x <= 12 or size.y <= 12:
			dungeon_rooms.append(["small", from, to])
		else:
			dungeon_rooms.append(["room", from, to])
		return 0
	if size.x <= 7:
		horizontal = 1
	elif size.y <= 7:
		horizontal = 0
	elif times_hall == 0:
		horizontal = size.y / (size.x + size.y)
	var threshold = 4 + gap * 2
	if times_hall == 1 or (size.x<threshold*2 and horizontal==0) or (size.y<threshold*2 and horizontal==1):
		sector_borders.append([from, to])
		gap = 0
		times_hall = 0
	var halfgap = 0
	var oddgap = gap % 2
	halfgap = floor(gap/2)
	if rng.randf() < horizontal: #horizontal
		var wall = rng.randi_range(from.y+threshold, to.y-threshold-int(to.y)%2-oddgap-gap)
		wall += wall % 2 + oddgap
		var wall_from = wall-gap
		var wall_to = wall+gap
		fill(Vector2(from.x, wall_from), Vector2(to.x, wall_to), 'W')
		divide(Vector2(from.x, from.y), Vector2(to.x, wall_from), times-1, times_hall-1, 0)
		divide(Vector2(from.x, wall_to), Vector2(to.x, to.y), times-1, times_hall-1, 0)
		if gap > 0:
			dungeon_rooms.append(["hall", Vector2(from.x, wall_from), Vector2(to.x, wall_to)])
			fill(Vector2(from.x, wall-halfgap), Vector2(to.x, wall+halfgap), '.')
			door_candidates.append([0, Vector2(from.x,wall_from), Vector2(to.x,wall_from)])
			door_candidates.append([0, Vector2(from.x,wall_to), Vector2(to.x,wall_to)])
		else:
			door_candidates.append([0, Vector2(from.x,wall), Vector2(to.x,wall)])
	else: #vertical
		var wall = rng.randi_range(from.x+threshold, to.x-threshold-int(to.x)%2-oddgap-gap)
		wall += wall % 2 + oddgap
		var wall_from = wall-gap
		var wall_to = wall+gap
		fill(Vector2(wall_from, from.y), Vector2(wall_to, to.y), 'W')
		divide(Vector2(from.x, from.y), Vector2(wall_from, to.y), times-1, times_hall-1, 1)
		divide(Vector2(wall_to, from.y), Vector2(to.x, to.y), times-1, times_hall-1, 1)
		if gap > 0:
			dungeon_rooms.append(["hall", Vector2(wall_from, from.y), Vector2(wall_to, to.y)])
			fill(Vector2(wall-halfgap, from.y), Vector2(wall+halfgap, to.y), '.')
			door_candidates.append([1, Vector2(wall_from,from.y), Vector2(wall_from,to.y)])
			door_candidates.append([1, Vector2(wall_to,from.y), Vector2(wall_to,to.y)])
		else:
			door_candidates.append([1, Vector2(wall,from.y), Vector2(wall,to.y)])

func get_sector(pos):
	var count = 1
	if sector_borders.empty():
		return count
	for sector in sector_borders:
		if pos.x >= sector[0].x and pos.x <= sector[1].x and\
			pos.y >= sector[0].y and pos.y <= sector[1].y:
			return count
		count += 1


func check_adjacent_object(x, y, tile):
	if dungeon_objects[y][x] != null:
		if dungeon_objects[y][x][0] == tile or\
			(y+1 < len(dungeon_objects) and dungeon_objects[y+1][x][0] == tile) or\
			(y-1 >= 0 and dungeon_objects[y-1][x][0] == tile) or\
			(x+1 < len(dungeon_objects[0]) and dungeon_objects[y][x+1][0] == tile) or\
			(x-1 >= 0 and dungeon_objects[y][x-1][0] == tile):
				return true
	return false
