var tileset = preload("res://assets/images/dcss.png")
var tileset_map
var images_cache = {}
var particles_cache = {}
var vault_cache = {}
var json_cache = {}
var terrain_data
var palette_data
var item_data
var unit_data
var mob_data
var skill_data


func _init():
	tileset_map = get_json_from_dir("res://assets/json/tileset_map.json")
	terrain_data = get_json_from_dir("res://assets/json/terrains.json")
	palette_data = get_json_from_dir("res://assets/json/map_palette.json")
	item_data = get_json_from_dir("res://assets/json/items.json")
	unit_data = get_json_from_dir("res://assets/json/units.json")
	mob_data = get_json_from_dir("res://assets/json/mobs.json")
	skill_data = get_json_from_dir("res://assets/json/skills.json")

func set_tile_image(sprite, to):
	var dat = tileset_map.get(to)
	if dat != null:
		sprite.texture = tileset
		sprite.region_enabled = true
		sprite.region_rect.size = Vector2(32, 32)
		sprite.region_rect.position = Vector2(dat[0] * 32, dat[1] * 32)
	return sprite

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

func get_particle(p):
	var r = particles_cache.get(p)
	if r != null:
		return r.instance()
	else:
		r = load("res://objects/particles/" + p + ".tscn")
		particles_cache[p] = r
		return r.instance()

func get_json_data(p):
	var r = json_cache.get(p)
	if r != null:
		return r
	else:
		r = get_json_from_dir("res://assets/json/" + p + ".json")
		particles_cache[p] = r
		return r

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
