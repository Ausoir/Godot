extends KinematicBody2D

puppet var puppet_pos = Vector2()
puppet var puppet_motion = Vector2()
puppet var puppet_rot = 0

export var stunned = false

var move_speed = 300
var velocity = 0
var current_anim = ""
var goal = Vector2()

var player_name = ""
var state = "moving"

func _physics_process(_delta):
	var new_anim = "standing"
	var motion = Vector2()

	if is_network_master():
		if goal.distance_to(position) > 32:
			new_anim = "walk"
			var rot = (goal - position).angle()
			var diff = rot - rotation
			if (rotation < 0) != (rot < 0) and abs(rot) > 1.57:
				diff = (3.14 - abs(rot)) + (3.14 - abs(rotation))
				if rot > 0:
					diff *= -1
			velocity += (move_speed - velocity) / 20
			rotate(diff / 5)
		else:
			velocity -= velocity / 8

		if velocity > 32:
			motion = Vector2(velocity, 0).rotated(rotation)

		rset("puppet_motion", motion)
		rset("puppet_pos", position)
		rset("puppet_rot", rotation)
	else:
		position = puppet_pos
		motion = puppet_motion
		rotation = puppet_rot

	if move_and_slide(motion).length() < 32:
		new_anim = "standing"
		
	if stunned:
		new_anim = "stunned"

	if new_anim != current_anim:
		current_anim = new_anim
		$anim.play(current_anim)
		
	if not is_network_master():
		puppet_pos = position # To avoid jitter


func set_goal(pos):
	goal = pos


puppet func stun():
	stunned = true


master func exploded(_by_who):
	if stunned:
		return
	rpc("stun") # Stun puppets
	stun() # Stun master - could use sync to do both at once


func set_player_name(new_name):
	player_name = new_name
	pass


func _ready():
	goal = position
	stunned = false
	puppet_pos = position
