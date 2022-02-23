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
	if script[0] == "storage":
		add_storage()
	elif script[0] == "bulletin":
		add_bulletin()
	elif script[0] == "tavern":
		add_tavern()
	elif script[0] == "trade":
		add_trade()
	elif script[0] == "store":
		G.vars.supplies.append(G.you.unit.inventory[script[1]].item_name)
		G.you.unit.inventory[script[1]] = null

func add_trade():
	var items = ""
	var count = 0
	for item in G.you.unit.inventory:
		if item != null:
			items += "[url="+str(count)+"]> [i]Store " + item.item_name + "[/i][/url]\n"
			count += 1
	get_node("Dialog/RichTextLabel").append_bbcode(items)
	if !("opt" in page_data):
		page_data["opt"] = []
	for i in range(count):
		var option = {"hover": ["item", G.you.unit.inventory[i].item_name]}
		option["script"] = ["store", i]
		page_data.opt.append(option)

func add_storage():
	var items = ""
	var count = 0
	for item in G.you.unit.inventory:
		if item != null:
			items += "[url="+str(count)+"]> [i]Store " + item.item_name + "[/i][/url]\n"
			count += 1
	get_node("Dialog/RichTextLabel").append_bbcode(items)
	if !("opt" in page_data):
		page_data["opt"] = []
	for i in range(count):
		var option = {"hover": ["item", G.you.unit.inventory[i].item_name]}
		option["script"] = ["store", i]
		page_data.opt.append(option)

func add_tavern():
	var items = ""
	var data = []
	var count = 0
	for item in G.you.unit.inventory:
		if item != null and item.type == "map":
			var dest = item.get("to","")
			items += "[url="+str(count)+"]> [i]To " + dest + "[/i][/url]\n"
			data.append(dest)
			count += 1
	get_node("Dialog/RichTextLabel").append_bbcode(items)
	if !("opt" in page_data):
		page_data["opt"] = []
	for _i in range(count):
		var option = {"script": ["store"]}
		page_data.opt.append(option)

func add_bulletin():
	var lseed = G.vars.baseseed
	R.set_seed(lseed + G.vars.time)
	var items = ""
	var count = 0
	var opt = []
	for _contract in range(R.ir(1, 5)):
		var pop = R.ir(1, 6)
		var map = R.ir(1, 3)
		var title
		if map == 1:
			title = "Urban scavenge run ("
		elif map == 2:
			title = "Dungeon crawl ("
		elif map == 3:
			title = "Explore lab ("
		items += "[url="+str(count)+"]> [i]"+title+str(pop)+")[/i][/url]\n"
		opt.append([map, pop])
		count += 1
	get_node("Dialog/RichTextLabel").append_bbcode(items)
	if !("opt" in page_data):
		page_data["opt"] = []
	for i in range(count):
		var map = opt[i][0]
		var pop = opt[i][1]
		var title
		if map == 1:
			title = "urban"
		elif map == 2:
			title = "dungeon"
		elif map == 3:
			title = "lab"
		var option = {"hover": ["text", "Location", title.capitalize()+"\nAllies: "+str(pop)]}
		option["cmd"] = [["dat","a","$pu","social","follow"], ["travel", title]]
		var social = "lead"
		for _i in range(pop-1):
			option["cmd"] += [["v","adj","$pup"],["make","scav","$t"],["dat","a","$t","social",social],["ally"]]
			social = "follow"
		page_data.opt.append(option)
