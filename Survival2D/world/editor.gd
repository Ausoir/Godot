extends Node

onready var n_base = $Base
onready var n_tileset = n_base.tile_set

func _ready():
	G.ui.queue_free()
	var chars = {}
	var rows = []
	var list = []
	for y in range(40):
		var row = ""
		for x in range(55):
			var id = n_base.get_cell(x, y)
			var idc = char(33+id)
			if id in list:
				row += idc
			else:
				if id != -1:
					list.append(id)
					chars[idc] = [n_tileset.tile_get_name(id)]
					row += idc
				else:
					row += " "
		rows.append(row)
	save([[100, rows, chars]])


func save(_data):
	var save_game = File.new()
	save_game.open("res://assets/json/vaults/map.json", File.WRITE)
	save_game.store_line(to_json(_data))
	save_game.close()
