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

func g(tag, default=null):
	if tag in v:
		return v[tag]
	return default

func a(tag, val):
	v[tag] = val

func d(tag):
	v.erase(tag)

func is_dead():
	return g("hp", Vector2()).x <= 0

func equals(tag, compare):
	var t = v.get(tag)
	return t != null and t == compare

func add(tag, val, pmin=null, pmax=null):
	if !(tag in v):
		v[tag] = val
	else:
		v[tag] += val
	if pmin != null:
		v[tag] = max(v[tag], pmin)
	if pmax != null:
		v[tag] = min(v[tag], pmax)

func combine(_dict):
	for key in _dict:
		a(key, _dict[key])
