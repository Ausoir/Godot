extends Label

var vel = 0

func _ready():
	set_process(false)

func display(p):
	set_text("$" + str(G.vars.money))
	if p != 0:
		set_process(true)
		var label = Label.new()
		label.set("custom_fonts/font", get("custom_fonts/font"))
		label.grow_horizontal = label.GROW_DIRECTION_BEGIN
		label.set_use_parent_material(true)
		if p < 0:
			label.set_text("-$" + str(-p))
		else:
			label.set_text("$" + str(p))
		label.rect_position.x = rect_size.x
		add_child(label)

func _process(delta):
	for child in get_children():
		var color = child.get("custom_colors/font_color")
		if color == null:
			child.set("custom_colors/font_color", Color(1, 1, 1, 1))
		elif color.a > .2:
			var alpha = color.a-delta
			child.set("custom_colors/font_color", Color(color.r, color.g, color.b, alpha))
			child.rect_position.y += alpha
		else:
			remove_child(child)
			child.queue_free()
			if get_child_count() == 0:
				set_process(false)
