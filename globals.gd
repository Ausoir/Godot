extends Node


var you
var younit
var world

var time = 0
var resource = {"wood": 9, "stone": 9, "food": 9}
var craftables = {
	"craft": ["stone table", "axe", "bed occupied"],
	"stonecraft": ["hammer", "shovel"]
}
var factions = [
	[], [], []
]


func add_resource(wood, stone, food):
	resource["wood"] += wood
	resource["stone"] += stone
	resource["food"] += food


func require_resource(wood, stone, food):
	var nwood = resource["wood"] - wood
	var nstone = resource["stone"] - stone
	var nfood = resource["food"] - food
	if nwood >= 0:
		if nstone >= 0:
			if nfood >= 0:
				resource["wood"] = nwood
				resource["stone"] = nstone
				resource["food"] = nfood
				return null
			return "food"
		return "stone"
	return "wood"
