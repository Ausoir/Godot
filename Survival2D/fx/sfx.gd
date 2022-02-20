extends AudioStreamPlayer2D

var lifetime = 1

func start(sound, ppos):
	position = ppos
	G.world.others.add_child(self)
	set_stream(G.data.get_sound(sound))
	play(0)

func _on_finished():
	G.world.others.remove_child(self)
	queue_free()
