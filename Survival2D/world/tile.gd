var terrain
var items = []
var passable

func set_terrain(val):
	terrain = val
	passable = val

func get_item(val):
	for item in items:
		if item.item_name == val:
			return item
	return null
