extends Node

var init_seed

func set_seed(_seed=-1):
	if _seed == -1:
		randomize()
		_seed = randi()
	init_seed = _seed
	seed(init_seed)

func ir(_from, _to):
	return randi() % int(_to - _from + 1) + _from

func fr(_from, _to):
	return randf() * (_to - _from) + _from

func f():
	return randf()

func r_arr(arr):
	if arr and !arr.empty():
		return arr[ir(0, len(arr)-1)]
	return null

func r_arr_pop(arr):
	if arr and !arr.empty():
		var idx = ir(0, len(arr)-1)
		var r = arr[idx]
		arr.remove(idx)
		return r

func r_range(p):
	return ir(p[0], p[1])

func b():
	return ir(0, 1) == 1

func r_percent(p):
	return ir(0, 99) < p

func r_dice(times, dice):
	var r = 0
	for _i in range(times):
		r += ir(1, dice)
	return r
