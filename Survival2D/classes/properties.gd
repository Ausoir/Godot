var v

func _init(p):
	v = p

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

func add(tag, val):
	if !(tag in v):
		v[tag] = val
	else:
		v[tag] += val
