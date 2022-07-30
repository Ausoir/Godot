extends RichTextLabel


func get_stats_text(dict):
	var txt = ""
	for i in G.data.vars.stats:
		var stat = G.data.vars.stats[i].name
		txt += "[color=#A64][url="+i+"]"+stat.capitalize()+"[/url][/color]: "+str(dict[stat])+"\n"
	return txt

func _on_meta_hover_started(meta):
	on_describe(meta)

func on_describe(meta):
	for key in G.data.vars.stats:
		if meta == key:
			var v = G.data.vars.stats[key]
			G.ui.describe("text", v.name, v.desc)

func _on_meta_hover_ended(_meta):
	G.ui.description.hide()
