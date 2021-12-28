extends RandomNumberGenerator


func rnd_arr(arr):
	if arr and !arr.empty():
		return arr[randi_range(0, len(arr)-1)]
	return null

func rnd_range(p):
	return randi_range(p[0], p[1])
