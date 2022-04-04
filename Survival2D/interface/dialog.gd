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
		G.cmds(cmd, host)
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
			G.cmds(cmd, host)
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
	if !("opt" in page_data):
		page_data["opt"] = []
	R.set_seed(G.vars.seed + int(G.vars.time/60))
	if script[0] == "bulletin":
		add_bulletin()
	elif script[0] == "trade":
		add_trade(page_data.get("type"))
	elif script[0] == "assign":
		add_assign()
	elif script[0] == "upgrade":
		add_upgrade(page_data.get("type"))

func add_trade(type):
	G.ui.display(0)
	var items = ""
	var count = 0
	var groups = G.data.get_group(type)
	for group in groups:
		var item_name = group[0]
		var price = group[1]
		items += "[url="+str(count)+"]> [i]Buy " + item_name + " for $" + str(price) + "[/i][/url]\n"
		count += 1
		var option = {"hover": ["item", item_name]}
		option["cmd"] = [["money",-price],["give", "$p", item_name],["menu","msg","Bought "+item_name+" for $" + str(price)+"."]]
		page_data.opt.append(option)
	get_node("Dialog/RichTextLabel").append_bbcode(items)

func add_upgrade(type):
	G.ui.display(0)
	var items = ""
	var count = 0
	var groups = G.data.get_group(type)
	for group in groups:
		var item_name = group[0]
		var price = group[1]
		items += "[url="+str(count)+"]> [i]Buy " + item_name + " for $" + str(price) + "[/i][/url]\n"
		count += 1
		var option = {"hover": ["item", item_name]}
		option["cmd"] = [["money",-price],["make", item_name, "$hp"], ["remove", "$h"]]
		page_data.opt.append(option)
	get_node("Dialog/RichTextLabel").append_bbcode(items)

func add_bulletin():
	var items = ""
	var count = 0
	var groups = G.data.get_group("g_conscript")
	if groups.empty():
		items = "The board is empty.\n\n"
	else:
		items = "You see a list of contracts.\n\n"
		for group in groups:
			var item_name = group[0]
			var price = group[1]
			items += "[url="+str(count)+"]> [i]Hire " + item_name + " for $"+str(price)+"[/i][/url]\n"
			count += 1
			var option = {"hover": ["item", item_name]}
			var ann = "Hired "+item_name+" for "+str(price)+"."
			option["cmd"] = [["buy",price],["vars","a+","hire",item_name],["menu","msg",ann]]
			page_data.opt.append(option)
	get_node("Dialog/RichTextLabel").append_bbcode(items)

func add_assign():
	var items = ""
	var count = 0
	if G.vars.hire.empty():
		items = "You have no hires.\n\nUse the bulletin board to hire more units.\n\n"
	else:
		items = "Place a hired unit on the map.\n\n"
		for hire in G.vars.hire:
			items += "[url="+str(count)+"]> [i]Assign " + hire + "[/i][/url]\n"
			count += 1
			var option = {"hover": ["text", "Assign", "Assign a hired unit on the map."]}
			var pt = {"target": "tile", "onstart": [["make",hire,"$t"],["ally"]], "col": 15}
			option["cmd"] = [["vars","a-","hire",hire],["point",pt]]
			page_data.opt.append(option)
	get_node("Dialog/RichTextLabel").append_bbcode(items)
