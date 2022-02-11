extends "res://world/generator.gd"

var min_room_size = Vector2(6, 6)
var sector_borders
var sectors
var dungeon_rooms
var dungeon_objects
var door_candidates

func generate():
	var times = 7
	var halls = 2
	.create(30, 30)
	base = make_base(width, height, '.')
	sectors = {}
	sector_borders = []
	dungeon_rooms = []
	door_candidates = []
	dungeon_objects = make_base(width, height, null)
	divide(Vector2.ZERO, Vector2(width, height), times, halls+1, .5)
	make_doors()
	make_rooms(["living", "storage", "lab"])
	return base

func divide(from, to, times, times_hall, h_chance):
	var tsize = to - from
	var gap = 0
	if times_hall > 2:
		gap = 2
	elif times_hall > 0:
		gap = 1
	elif (tsize.x <= min_room_size.x*2 and tsize.y <= min_room_size.y*2) or times <= 0:
		dungeon_rooms.append([from, to])
		return 0
	if tsize.x <= min_room_size.x*2:
		h_chance = 1
	elif tsize.y <= min_room_size.y*2:
		h_chance = 0
	elif times_hall == 0:
		h_chance = .5#tsize.y / (tsize.x + tsize.y)
	var horizontal = rng.randf() < h_chance
	if times_hall == 1 or (tsize.x<min_room_size.x*2+gap and horizontal) or (tsize.y<min_room_size.y*2+gap and !horizontal):
		sector_borders.append([from, to])
		gap = 0
		times_hall = 0
	var halfgap = 0
	var oddgap = gap % 2
	halfgap = floor(gap/2)
	if horizontal:
		var wall = rng.r_i(from.y+min_room_size.y, to.y-min_room_size.y)
		wall += wall % 2 + oddgap
		var wall_from = wall-gap
		var wall_to = wall+gap
		fill(Vector2(from.x, wall_from), Vector2(to.x, wall_to), 'W')
		divide(Vector2(from.x, from.y), Vector2(to.x, wall_from), times-1, times_hall-1, 0)
		divide(Vector2(from.x, wall_to), Vector2(to.x, to.y), times-1, times_hall-1, 0)
		if gap > 0:
			dungeon_rooms.append([Vector2(from.x, wall_from), Vector2(to.x, wall_to)])
			fill(Vector2(from.x, wall-halfgap), Vector2(to.x, wall+halfgap), '.')
			door_candidates.append([Vector2(from.x+1,wall_from), Vector2(to.x-1,wall_from)])
			door_candidates.append([Vector2(from.x+1,wall_to), Vector2(to.x-1,wall_to)])
		else:
			door_candidates.append([Vector2(from.x+1,wall), Vector2(to.x-1,wall)])
	else: #vertical
		var wall = rng.r_i(from.x+min_room_size.x, to.x-min_room_size.x)
		wall += wall % 2 + oddgap
		var wall_from = wall-gap
		var wall_to = wall+gap
		fill(Vector2(wall_from, from.y), Vector2(wall_to, to.y), 'W')
		divide(Vector2(from.x, from.y), Vector2(wall_from, to.y), times-1, times_hall-1, 1)
		divide(Vector2(wall_to, from.y), Vector2(to.x, to.y), times-1, times_hall-1, 1)
		if gap > 0:
			dungeon_rooms.append([Vector2(wall_from, from.y), Vector2(wall_to, to.y)])
			fill(Vector2(wall-halfgap, from.y), Vector2(wall+halfgap, to.y), '.')
			door_candidates.append([Vector2(wall_from,from.y+1), Vector2(wall_from,to.y-1)])
			door_candidates.append([Vector2(wall_to,from.y+1), Vector2(wall_to,to.y-1)])
		else:
			door_candidates.append([Vector2(wall,from.y+1), Vector2(wall,to.y-1)])

func make_doors():
	for door in door_candidates:
		var x = rng.r_i(door[0].x, door[1].x)
		var y = rng.r_i(door[0].y, door[1].y)
		base[y][x] = 'D'

func make_rooms(departments):
	for room in dungeon_rooms:
		var sector = get_sector(Vector2(room[1].x + 1, room[1].y + 1))
		if sector != null:
			sectors[sector] = ""
		room.append(sector)

	var tpartments = departments.duplicate()
	for s in sectors:
		if tpartments.empty():
			sectors[s] = rng.r_arr(departments)
		else:
			var idx = rng.r_i(0, len(tpartments)-1)
			sectors[s] = tpartments[idx]
			tpartments.remove(idx)
	print(sectors)

	for room in dungeon_rooms: #name, from, to, sector, door
		#print(room)
		if room[2] == null: #halls
			pass
		elif sectors[room[2]] == "living":
			make_terrain(room, "map_houses")
		elif sectors[room[2]] == "storage":
			pass
		elif sectors[room[2]] == "lab":
			pass

func make_terrain(room, vault_type):
	vaults.load_vault(vault_type)
	return vaults.make_vault(rng, base, room[0], room[1])

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
