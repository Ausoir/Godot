extends Node


var takers = [[],[],[],[]]
var add_idx = 0
var turn_idx = 0
var process_frames = 0


func increment_index(idx):
	idx += 1
	if idx >= len(takers):
		idx = 0
	return idx

func has(p):
	for i in takers:
		if p in i:
			return true
	return false

func add(p):
	takers[add_idx].append(p)
	add_idx = increment_index(add_idx)

func remove(p):
	for i in takers:
		var index = i.find(p)
		if index != -1:
			i.remove(index)
			return

func on_process():
	if process_frames > 0:
		for i in takers[turn_idx]:
			i.on_turn()
		turn_idx = increment_index(turn_idx)
		if turn_idx == 0:
			process_frames -= 1
