extends Node

onready var n_base = $Base
onready var n_2nd = $Base2
onready var n_sewer = $Sewer
onready var n_tileset = n_base.tile_set

func _ready():
	G.ui.queue_free()
	var f1 = get_floor_json(n_sewer)
	var f2 = get_floor_json(n_base)
	var f3 = get_floor_json(n_2nd)
	save([f1, f2, f3])

func get_floor_json(map):
	var chars = {
		'.': ['dirt'],
		',': ['grass'],
		'_': ['wood floor'],
		'~': ['water'],
		'#': ['rock wall'],
	}
	var rows = []
	var list = {}
	for i in chars:
		list[n_tileset.find_tile_by_name(chars[i])] = i
	for y in range(40):
		var row = ""
		for x in range(55):
			var id = map.get_cell(x, y)
			if id in list:
				row += list[id]
			else:
				if id != -1:
					var idc = char(33+id)
					list[id] = idc
					chars[idc] = [n_tileset.tile_get_name(id)]
					row += idc
				else:
					row += " "
		rows.append(row)
	return [100, rows, chars]


func save(_data):
	var save_game = File.new()
	save_game.open("res://assets/json/vaults/map.json", File.WRITE)
	save_game.store_line(to_json(_data))
	save_game.close()
