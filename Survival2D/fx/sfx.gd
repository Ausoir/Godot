extends Node

var current = -1
var nodes
var size

func _ready():
	nodes = []
	size = get_child_count()
	for i in range(size):
		nodes.append(get_node(str(i)))

func play_hit(_type, mat, ppos):
	if mat=="metal" or mat=="wood" or mat=="flesh" or mat=="glass":
		play("hit_"+mat, ppos)
	else:
		play("hit_other", ppos)

func play(sound, ppos):
	if nodes != null:
		increment_player()
		var player = nodes[current]
		player.position = ppos
		player.set_stream(G.data.get_sound(sound))
		player.play(0)

func increment_player():
	current += 1
	if current >= size:
		current = 0

func _on_finished(_p):
	return
