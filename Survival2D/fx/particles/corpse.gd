extends "res://objects/item.gd"

var texture

func make(host):
	texture = host.n_sprite.texture
	for i in range(1, 8):
		var node = get_node("Part" + str(i))
		node.texture = texture
	$AnimationPlayer.play("Die" + str(R.ir(1, 3)))
