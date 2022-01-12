extends RandomNumberGenerator


func rnd_arr(arr):
	if arr and !arr.empty():
		return arr[randi_range(0, len(arr)-1)]
	return null

func rnd_pop(arr):
	if arr and !arr.empty():
		var idx = randi_range(0, len(arr)-1)
		var r = arr[idx]
		arr.remove(idx)
		return r

func rnd_range(p):
	return randi_range(p[0], p[1])

func rndb():
	return randi_range(0, 1) == 1

func rnd_percent(p):
	return randi_range(0, 99) < p

func rnd_dice(times, dice):
	var r = 0
	for _i in range(times):
		r += randi_range(1, dice)
	return r
