extends Panel

var stylebox = get_stylebox("panel", "")
var buff_name
var buff_description

#func _ready():
#	stylebox.texture = G.data.tileset
#	stylebox.region_rect.position.y = 1600
#	stylebox.region_rect.size = Vector2(32, 32)

func assign(p, img, desc):
	buff_name = p
	$Sprite.texture = G.data.get_image(img)
	buff_description = desc

func _update_cooldown(cd):
	if cd > 0:
		$Label.text = str(cd)
	else:
		$Label.text = ""

func _on_mouse_entered():
	G.ui.describe(buff_name, buff_description)

func _on_mouse_exited():
	G.ui.description.hide()
