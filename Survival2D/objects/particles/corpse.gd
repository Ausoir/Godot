extends "res://objects/item.gd"

var region_rect

func make(host):
	region_rect = Rect2(576, 928, 32, 32)
	dat = host.dat
	vars = host.vars
	for i in range(1, 8):
		var node = get_node("Part" + str(i))
		node.texture = host.sprite.texture
	$AnimationPlayer.play("Die")
