extends KinematicBody2D

puppet var puppet_pos = Vector2()
puppet var puppet_motion = Vector2()
puppet var puppet_rot = 0

export var stunned = false

var move_speed = 500
var velocity = 0
var current_anim = ""

var player_name = ""

var task_queue = []
var task = ["idle", -1]
var locked = false

var weapon = null

	
func _physics_process(_delta):
	var new_anim = "standing"
	var motion = Vector2()

	if task[1] == 0:
		task = task_queue.pop_back()
		task = ["idle", -1] if task == null else task
		locked = false
	elif task[1] > 0:
		task[1] -= 1
	if is_network_master():
		if task[0] == "move":
			var reach = 32
			if task.size() > 3:
				reach = task[3]
			if task[2].distance_to(position) > reach:
				new_anim = "walk"
				var rot = (task[2] - position).angle()
				var diff = rot - rotation
				if (rotation < 0) != (rot < 0) and abs(rot) > 1.57:
					diff = (3.14 - abs(rot)) + (3.14 - abs(rotation))
					if rot > 0:
						diff *= -1
				velocity += (move_speed - velocity) / 20
				rotate(diff / 5)
			else:
				task[1] = 0
		elif task[0] == "menu":
			get_parent().get_node("menu").display(task[2], self)
		elif task[0] == "attack":
			new_anim = "attack"
			locked = true
			if task[2] is Vector2 and task[2].distance_to(position) > 32 and task[1] > 100:
				var rot = (task[2] - position).angle()
				var diff = rot - rotation
				if (rotation < 0) != (rot < 0) and abs(rot) > 1.57:
					diff = (3.14 - abs(rot)) + (3.14 - abs(rotation))
					if rot > 0:
						diff *= -1
				velocity += (move_speed - velocity) / 20
				rotate(diff / 5)
		elif task[0] == "idle":
			if task.size() > 2:
				new_anim = task[2]
		elif task[0] == "grab":
			new_anim = "grab"
			if task[1] == 0:
				if weapon != null:
					weapon.held = false
				weapon = task[2]
				weapon.held = true
		elif task[0] == "interact":
			new_anim = "grab"
			if task[1] == 0:
				task[2].interact(self)
		elif task[0] == "work":
			new_anim = "work"
			if task[1] == 0:
				task[2].work(self)
		elif task[0] == "drop":
			if weapon != null:
				weapon.held = false
			weapon = null

		if velocity > 0:
			motion = Vector2(velocity, 0).rotated(rotation)
			velocity *= 0.9

		rset("puppet_motion", motion)
		rset("puppet_pos", position)
		rset("puppet_rot", rotation)
	else:
		position = puppet_pos
		motion = puppet_motion
		rotation = puppet_rot
		
	if weapon != null:
		weapon.rotation = $handR.rotation + rotation
		weapon.position = position + ($handR.offset + Vector2(4, -10)).rotated(weapon.rotation)

	if move_and_slide(motion).length() < 32 and new_anim == "walk":
		new_anim = "standing"
	
	if new_anim != current_anim:
		current_anim = new_anim
		$anim.play(current_anim)
		
	if not is_network_master():
		puppet_pos = position # To avoid jitter


func get_task_size():
	return task_queue.size()


func add_task(newtask):
	task_queue.insert(0, newtask)


func set_task(newtask, force=false):
	if force or task[1] <= 0 or task[0] == "idle":
		task = newtask
		task_queue = []


puppet func stun():
	stunned = true


master func exploded(_by_who):
	if stunned:
		return
	rpc("stun") # Stun puppets
	stun() # Stun master - could use sync to do both at once


func set_player_name(new_name):
	player_name = new_name


func _ready():
	stunned = false
	puppet_pos = position
