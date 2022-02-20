var v

func _init(_dict):
	v = {}
	for key in _dict:
		var value = _dict[key]
		if value is Dictionary or value is Array:
			v[key] = value.duplicate()
		else:
			v[key] = value

func load_data(_data):
	for key in _data:
		v[key] = _data[key]

func g(key, default=null):
	if key in v:
		return v[key]
	return default

func a(key, val):
	v[key] = val

func d(key):
	v.erase(key)

func equals(key, compare):
	var t = v.get(key)
	return t != null and t == compare

func erase(key, val):
	var tag = v.get(key)
	if tag != null:
		for i in val:
			tag.erase(i)

func add(key, val, pmin=null, pmax=null):
	if val != null:
		if !(key in v):
			v[key] = val
		else:
			v[key] += val
	if pmin != null:
		v[key] = max(v[key], pmin)
	if pmax != null:
		v[key] = min(v[key], pmax)

func combine(_dict):
	for key in _dict:
		a(key, _dict[key])
