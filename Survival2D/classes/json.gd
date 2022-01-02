var images = {}
var image_map
var terrain_data
var item_data
var unit_data
var mob_data
var skill_data


func _init():
	var timages = get_json_data("res://assets/json/images.json")
	for i in timages:
		images[i] = load(timages[i])
	image_map = get_json_data("res://assets/json/image_map.json")
	terrain_data = get_json_data("res://assets/json/terrains.json")
	item_data = get_json_data("res://assets/json/items.json")
	unit_data = get_json_data("res://assets/json/units.json")
	mob_data = get_json_data("res://assets/json/mobs.json")
	skill_data = get_json_data("res://assets/json/skills.json")

func get_tile_image_pos(img):
	var r = image_map.get(img)
	if r == null:
		return Vector2()
	else:
		return Vector2(r.x, r.y)

func get_tile_image(p):
	var r = image_map.get(p)
	if r != null:
		var item_sprite = Sprite.new()
		item_sprite.texture = images.tileset
		item_sprite.region_enabled = true
		item_sprite.region_rect.position = Vector2(r.x, r.y)
		item_sprite.region_rect.size = Vector2(32, 32)
		return item_sprite

func get_image(p):
	return images[p]

func get_json_data(dir):
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
