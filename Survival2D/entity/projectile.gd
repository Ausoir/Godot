extends KinematicBody2D

var dest: Vector2
var vel: Vector2
var speed: int
var host
var lifetime = 2

var onattack
var onshoot
var onmiss

func init(phost, img, from, to, spd, variation):
	host = phost
	get_node("Sprite").texture = img
	G.world.others.add_child(self)
	position = from + G.rng.vfr(variation[0])
	dest = to
	speed = spd
	var space_state = get_world_2d().direct_space_state
	var result = space_state.intersect_ray(position, to, [host.n_collider], collision_mask)
	if !result.empty():
		dest = result.position
	var rot = atan2(dest.y - from.y, dest.x - from.x) + G.rng.fr(-variation[1], variation[1])
	rotate(rot)
	vel.x = cos(rot) * speed
	vel.y = sin(rot) * speed
	add_collision_exception_with(host.n_collider)

func _physics_process(_delta):
	var c = move_and_collide(vel)
	if c != null:
		on_collide(c.collider)
	elif lifetime < 0:
		if onmiss != null:
			G.cmds(onmiss, host, position)
		remove()
	else:
		lifetime -= _delta

func on_collide(body):
	if onattack != null:
		if "item_type" in body:
			G.cmds(onattack, host, body.get_parent())
			remove()
			return
	if onmiss != null:
		G.cmds(onmiss, host, position)
	remove()

func remove():
	G.world.others.remove_child(self)
	queue_free()
