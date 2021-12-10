var images = {}
var image_map
var terrain_data
var item_data
var unit_data


func _init():
	var timages = get_json_data("res://assets/json/images.json")
	for i in timages:
		images[i] = load(timages[i])
	image_map = get_json_data("res://assets/json/image_map.json")
	terrain_data = get_json_data("res://assets/json/terrain_data.json")
	item_data = get_json_data("res://assets/json/item_data.json")
	unit_data = get_json_data("res://assets/json/unit_data.json")

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
