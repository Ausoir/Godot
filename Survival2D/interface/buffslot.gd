extends Panel

var stylebox = get_stylebox("panel", "")
var buff_name
var buff_description

func assign(p, img, desc):
	buff_name = p
	$Sprite.texture = G.data.get_image(img)
	buff_description = desc

func _on_mouse_entered():
	G.ui.describe(buff_name, buff_description)

func _on_mouse_exited():
	G.ui.description.hide()
