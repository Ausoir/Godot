extends KinematicBody2D

var item_type = "projectile"
var item_name = "projectile"
var dest: Vector2
var vel: Vector2
var speed: int
var host
var lifetime = 2

var onattack

func init(phost, img, from, to, time, spd, variation):
	host = phost
	get_node("Sprite").texture = img
	G.world.others.add_child(self)
	position = from + R.vfr(variation[0])
	dest = to + R.vfr(variation[1])
	speed = spd
	lifetime = time
	var space_state = get_world_2d().direct_space_state
	var result = space_state.intersect_ray(position, to, [host.n_collider], collision_mask)
	if !result.empty():
		dest = result.position
	vel = (dest - from).normalized() * speed
	rotate(atan2(vel.y, vel.x))
	add_collision_exception_with(host.n_collider)

func _physics_process(_delta):
	var c = move_and_collide(vel)
	if c != null:
		on_collide(c.collider)
	elif (position - dest).length_squared() <= speed:
		remove()
	elif lifetime < 0:
		remove()
	else:
		lifetime -= _delta

func on_collide(body):
	if onattack != null:
		if body is PhysicsBody2D:
			G.cmds(onattack, host, body.get_parent())
	remove()

func remove():
	G.world.others.remove_child(self)
	queue_free()
