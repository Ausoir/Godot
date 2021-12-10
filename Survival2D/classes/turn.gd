extends Node


var takers = [[],[],[],[],[],[],[],[]]
var add_idx = 0
var turn_idx = 0


func increment_index(idx):
	idx += 1
	if idx >= len(takers):
		idx = 0
	return idx

func add(p):
	takers[add_idx].append(p)
	increment_index(add_idx)

func remove(p):
	for i in takers:
		i.erase(p)

func on_process():
	for i in takers[turn_idx]:
		i._on_turn()
	increment_index(turn_idx)
