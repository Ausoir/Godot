extends Node

var graphic
var lifetime = 1
var tween

func _init(type, p):
	lifetime = p
	if type == "tween":
		tween = Tween.new()
		tween.connect("tween_all_completed", self, "_on_tween_done")
		add_child(tween)
	G.world.others.add_child(self)

func shoot(img_name, from, to):
	graphic = G.data.get_tile_image(img_name)
	add_child(graphic)
	tween.interpolate_property(graphic, "position",
		from, to, lifetime,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()

func _on_tween_done():
	if graphic != null:
		graphic.queue_free()
	if tween != null:
		tween.queue_free()
	G.world.others.remove_child(self)
