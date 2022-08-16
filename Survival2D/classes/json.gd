var json_cache = {}
var images_cache = {}
var sounds_cache = {}
var particles_cache = {}
var vars
var terrain_data
var palette_data
var item_data
var unit_data
var mob_data
var skill_data
var dialog_data
var group_data

func _init():
	vars = get_json_from_dir("res://assets/json/vars.json")
	terrain_data = get_json_from_dir("res://assets/json/terrains.json")
	palette_data = get_json_from_dir("res://assets/json/map_palette.json")
	item_data = {}
	for file in vars["item files"]:
		var t = get_json_from_dir("res://assets/json/"+file+".json")
		for key in t:
			item_data[key] = t[key]
	unit_data = get_json_from_dir("res://assets/json/units.json")
	attach_names(unit_data)
	mob_data = get_json_from_dir("res://assets/json/mobs.json")
	skill_data = get_json_from_dir("res://assets/json/skills.json")
	attach_names(skill_data)
	dialog_data = get_json_from_dir("res://assets/json/dialog.json")
	group_data = get_json_from_dir("res://assets/json/groups.json")
	var cache = get_json_from_dir("res://assets/json/cache.json")
	for key in cache.json:
		json_cache[key] = get_json_from_dir(cache.json[key])
	for key in cache.images:
		images_cache[key] = load("res://assets/images/" + cache.images[key])
	for key in cache.sounds:
		sounds_cache[key] = load("res://assets/audio/" + cache.sounds[key])

func set_tile_image(_sprite, _to):
#	var dat = tileset_map.get(to)
#	if dat != null:
#		sprite.texture = tileset
#		sprite.region_enabled = true
#		sprite.region_rect.size = Vector2(32, 32)
#		sprite.region_rect.position = Vector2(dat[0] * 32, dat[1] * 32)
	return _sprite

func get_combo(dat):
	var r = []
	if R.r_percent(dat[1]):
		r.append(dat[0])
		if dat.size() > 2 and dat[2] == "+":
			r += get_combo(dat[3])
	elif dat.size() > 2 and dat[2] == "/":
		r += get_combo(dat[3])
	return r

func get_category(p):
	var data = G.data.group_data.get(p)
	if data != null:
		for mobs in data:
			if R.r_percent(data[mobs]):
				return mobs

func get_group(p):
	var r = []
	var data = G.data.group_data.get(p)
	if data != null:
		for mobs in data:
			var mobs_data = data[mobs]
			if R.r_percent(mobs_data[0]):
				r.append([mobs, R.ir(mobs_data[2], mobs_data[3])])
				if mobs_data[1] == "/":
					return r
	return r

func get_tile_image(p):
	var item_sprite = Sprite.new()
	set_tile_image(item_sprite, p)
	return item_sprite

func get_image(p):
	var r = images_cache.get(p)
	if r != null:
		return r
	else:
		r = load("res://assets/images/" + p + ".png")
		images_cache[p] = r
		return r

func get_sprite(p):
	var r = Sprite.new()
	r.texture = get_image(p)
	return r

func set_sprite_texture(sprite, p, autotile):
	sprite.texture = get_image(p)
	if autotile != 0:
		sprite.set_region(true)
		sprite.set_region_rect(Rect2(0, 0, 32, 32))

func get_sound(p):
	var r = sounds_cache.get(p)
	if r != null:
		return r
	else:
		r = load("res://assets/audio/" + p + ".wav")
		sounds_cache[p] = r
		return r

func get_particle(p):
	var r = particles_cache.get(p)
	if r != null:
		return r.instance()
	else:
		r = load("res://fx/particles/" + p + ".tscn")
		particles_cache[p] = r
		return r.instance()

func get_json_data(p, _cache=true):
	if _cache:
		var r = json_cache.get(p)
		if r != null:
			return r
		else:
			r = get_json_from_dir("res://assets/json/" + p + ".json")
			json_cache[p] = r
			return r
	else:
		return get_json_from_dir("res://assets/json/" + p + ".json")

func get_json_from_dir(dir):
	var data_file = File.new()
	if data_file.open(dir, File.READ) == OK:
		var data_text = data_file.get_as_text()
		data_file.close()
		var data_parse = JSON.parse(data_text)
		if data_parse.error == OK:
			return data_parse.result
		else:
			push_error("Could not parse JSON file " + dir)
	else:
		push_error("Could not load JSON file " + dir)

func attach_names(p):
	for i in p:
		p[i].name = i
