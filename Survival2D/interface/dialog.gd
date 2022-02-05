extends Control

var page_data
var host

func display(_page, _host):
	var data = G.data.dialog_data.get(_page)
	if data != null:
		display_data(data, _host)

func display_data(_data, _host):
	page_data = _data
	host = _host
	var cmd = page_data.get("cmd")
	if cmd != null:
		G.cmd(cmd, host)
	var title = page_data.get("title")
	if title != null:
		show()
		set_name(page_data.title)
		var text
		var req_met = true
		var req = page_data.get("req")
		if req != null:
			req_met = is_req_met(req)
		if req_met:
			text = page_data.get("true", "")
		else:
			text = page_data.get("false", "")
		text = text.replace("$u", gamestate.player_name)
		get_node("Dialog/RichTextLabel").set_bbcode(text)

func is_req_met(reqs):
	for req in reqs:
		if req[0] == "hostvar":
			if !host.vars.equals(req[1], req[2]):
				return false
		elif req[1] == "pvar":
			if !G.you.unit.vars.equals(req[1], req[2]):
				return false
	return true

func _on_meta_clicked(meta):
	var opts = page_data.get("opt", [])
	if opts.size() > int(meta):
		var option = page_data.opt[int(meta)]
		var req = option.get("req")
		if req != null:
			if !is_req_met(req):
				return
		var cmd = option.get("cmd")
		if cmd != null:
			G.cmd(cmd, host)

func _on_meta_hover_started(meta):
	var opts = page_data.get("opt", [])
	if opts.size() > int(meta):
		var option = page_data.opt[int(meta)]
		var hover = option.get("hover")
		if hover != null:
			if hover[0] == "text":
				G.ui.describe("text", hover[1], hover[2])
			elif hover[0] == "item":
				var item = G.data.item_data.get(hover[1])
				if item != null:
					G.ui.describe("item", hover[1], item)

func _on_meta_hover_ended(_meta):
	G.ui.description.hide()
