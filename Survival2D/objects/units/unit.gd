extends KinematicBody2D

puppet var puppet_pos = Vector2()
puppet var puppet_motion = Vector2()
puppet var puppet_rot = 0

export var stunned = false

var move_speed = 500
var velocity = 0
var direction = 0
var current_anim = ""

var player_name = ""

var task_queue = []
var task = ["idle", -1]
var locked = false

var weapon = null
var controller

	
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
				if (task[2].x - position.x > 0) == ($Sprite.scale.x > 0):
					$Sprite.scale.x *= -1
				velocity += (move_speed - velocity) / 40
				direction = (task[2] - position).angle()
			else:
				task[1] = 0
		elif task[0] == "menu":
			get_parent().get_node("menu").display(task[2], self)
		elif task[0] == "attack":
			if task[1] == -1:
				task[1] = 100
			new_anim = "attack"
			locked = true
			if task[2] is Vector2 and task[1] > 50:
				var acc = 1 + (task[1] - 50) * .01
				velocity += (move_speed * acc - velocity) / 20
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
			motion = Vector2(velocity, 0).rotated(direction)
			velocity *= 0.9

		rset("puppet_motion", motion)
		rset("puppet_pos", position)
	else:
		position = puppet_pos
		motion = puppet_motion
		
	if weapon != null:
		weapon.position = position + ($handR.offset + Vector2(10, 4)).rotated(weapon.rotation)

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


func set_task(newtask):
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
