extends Node

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

func add(tag, val):
	if !(tag in v):
		v[tag] = val
	else:
		v[tag] += val

func has_flag(tag):
	var tags = g("tags", [])
	return tag in tags
