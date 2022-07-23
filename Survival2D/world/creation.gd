extends Node


func start():
	G.get_tree().get_root().remove_child(self)
	gamestate.start_local()

func _on_meta_clicked(_meta):
	start()

func _on_meta_hover_started(meta):
	if meta == "vit":
		G.ui.describe("text", "Vitality", "")

func _on_meta_hover_ended(_meta):
	G.ui.description.hide()
