extends ConfirmationDialog

const SIZE = Vector2(480, 320)
var onconfirm

func make(text, p):
	set_text(text)
	onconfirm = p
	popup_centered_clamped(SIZE)

func _on_confirmed():
	queue_free()
	get_parent().remove_child(self)
	G.cmds(onconfirm, G.command.prev_host)
