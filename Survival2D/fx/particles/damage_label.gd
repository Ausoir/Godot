extends Label

var lifetime = 200
var vel
var vel_angle
var scale_mod
var speed_mod = 800

func _ready():
	vel = Vector2(R.ir(-80, 80), R.ir(-120, 0))
	vel_angle = R.fr(-2, 2)

func set_damage(dmg, color, _scale, _speed):
	set_text(str(dmg))
	set_pivot_offset(rect_size / 2)
	add_color_override("font_color", color)
	scale_mod = _scale
	speed_mod = _speed

func _physics_process(delta):
	rect_position.x += delta * vel.x
	rect_position.y += delta * vel.y
	vel.x *= .99
	vel.y += delta * speed_mod
	var scale = min(1, lifetime/.2) * scale_mod
	rect_scale.x = scale
	rect_scale.y = scale
	set_rotation_degrees(rect_rotation + vel_angle)

	lifetime -= delta * speed_mod
	if lifetime < 0:
		G.world.others.remove_child(self)
		queue_free()
