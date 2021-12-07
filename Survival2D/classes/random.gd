extends RandomNumberGenerator


func rand_arr(arr):
	if arr and !arr.empty():
		return arr[randi_range(0, len(arr)-1)]
	return null
