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
		G.ui.dialog.set_tab_title(0, title)
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
		show()
	var script = page_data.get("script")
	if script != null:
		run_script(script)

func is_req_met(reqs):
	for req in reqs:
		if !check_supplies(req[0], req[1]):
			return false
	return true

func check_supplies(item, amount):
	for supply in G.vars.supplies:
		if supply == item:
			amount -= 1
			if amount <= 0:
				return true
	return false

func _on_meta_clicked(meta):
	G.ui.clear()
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
		var script = option.get("script")
		if script != null:
			run_script(script)

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

func run_script(script):
	if script[0] == "bulletin":
		add_bulletin()
	elif script[0] == "trade":
		add_trade()

func add_trade():
	if !("opt" in page_data):
		page_data["opt"] = []
	G.ui.display(0)
	R.set_seed(G.vars.seed + G.vars.time)
	var items = ""
	var count = 0
	var groups = G.data.get_group("g_trade")
	for group in groups:
		var item_name = group[0]
		items += "[url="+str(count)+"]> [i]Buy " + item_name + "[/i][/url]\n"
		count += 1
		var option = {"hover": ["item", item_name]}
		option["cmd"] = [["buy",10],["give", "$pu", item_name],["menu","msg","Bought "+item_name+"."]]
		page_data.opt.append(option)
	get_node("Dialog/RichTextLabel").append_bbcode(items)

func add_bulletin():
	if !("opt" in page_data):
		page_data["opt"] = []
	R.set_seed(G.vars.seed + G.vars.time)
	var items = ""
	var count = 0
	for _contract in range(R.ir(1, 5)):
		var pop = R.ir(1, 6)
		var map = R.ir(1, 3)
		var title
		var desc
		if map == 1:
			title = "urban"
			desc = "Urban scavenge run ("
		elif map == 2:
			title = "dungeon"
			desc = "Dungeon crawl ("
		elif map == 3:
			title = "lab"
			desc = "Explore lab ("
		items += "[url="+str(count)+"]> [i]"+desc+str(pop)+")[/i][/url]\n"
		var option = {"hover": ["text", "Location", title.capitalize()+"\nAllies: "+str(pop)]}
		option["cmd"] = [["dat","=","$pu","social","follow"]]
		var social = "lead"
		for _i in range(pop-1):
			option["cmd"] += [["v","adj","$pup"],["make","scav","$t"],["dat","=","$t","social",social],["ally"]]
			social = "follow"
		page_data["opt"].append(option)
	get_node("Dialog/RichTextLabel").append_bbcode(items)
