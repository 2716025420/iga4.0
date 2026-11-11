class_name StudentTerminal
extends Control

signal close_requested
signal action_requested(action: String, payload: Dictionary)
const PAGES := {"overview":"终端概览","zodiac":"星座图鉴","cards":"行动卡","journal":"经历与成长","contacts":"同学资料","inventory":"物品收纳"}
var refs: Dictionary = {}
var context: Dictionary = {}
var current_tab := "overview"
var selected_zodiac := "hero"
var selected_card := ""
var selected_contact := ""
var selected_item := ""
var journal_tab := "journey"
var category := "all"
var search := ""
var sort_index := 0
var descending := false
var _canvas: Control
var _body: Control
var _message: Label
var _pending := false
var _scroll_positions: Dictionary = {}
var _caret := 0

static func create(page: String = "overview", panel_context: Dictionary = {}) -> StudentTerminal:
	var node := StudentTerminal.new()
	node.context = panel_context.duplicate(true)
	node.current_tab = str({"records":"overview","warehouse":"inventory","classmates":"contacts","growth":"journal","journey":"journal","today":"journal","anomaly":"journal"}.get(page,page))
	if not PAGES.has(node.current_tab): node.current_tab = "overview"
	var legacy := str(panel_context.get("tab",""))
	if legacy != "":
		node.current_tab = str({"warehouse":"inventory","classmates":"contacts","growth":"journal","journey":"journal"}.get(legacy,"journal"))
		node.journal_tab = "growth" if legacy == "growth" else "journey"
	return node

func _ready() -> void:
	size = Vector2(1920,1080)
	set_meta("full_scene_overlay",true)
	theme = DaylightUI.get_theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	_canvas = Control.new()
	_canvas.name = "TerminalCanvas"
	_canvas.size = size
	add_child(_canvas)
	SchoolObjectUI.art(_canvas,"DeviceChassis","res://assets/ui/student_terminal/layouts/"+current_tab+".png")
	TerminalUI.panel(_canvas,"NavigationRail",Rect2(144,191,222,708),Color("#E4EEF0"))
	TerminalUI.text(_canvas,"DeviceName","IGA / STUDENT TERMINAL",Rect2(168,121,840,62),26)
	TerminalUI.text(_canvas,"Date",GameState.get_detailed_time_string(),Rect2(1230,126,350,50),24)
	var close := TerminalUI.button(_canvas,"CloseButton","关闭 ×",Rect2(1610,116,145,60))
	close.pressed.connect(func(): close_requested.emit())
	refs["close"] = close
	var back := TerminalUI.button(_canvas,"BackButton","← 返回",Rect2(151,898,210,45))
	back.pressed.connect(func():
		if current_tab == "overview": close_requested.emit()
		else: show_page("overview")
	)
	refs["back"] = back
	TerminalUI.text(_canvas,"ReadOnlyTime","查看资料不消耗活动次数",Rect2(1170,898,570,38),23,true)
	var index := 0
	refs["tabs"] = {}
	for id in PAGES:
		var tab := TerminalUI.button(_canvas,"Tab_"+id,"",Rect2(160,218+index*88,190,65),id == current_tab)
		SchoolObjectUI.art(tab,"AppIcon","res://assets/ui/student_terminal/icons/"+id+".svg",Rect2(10,17,32,32))
		TerminalUI.text(tab,"AppName",PAGES[id],Rect2(52,9,136,48),24)
		tab.pressed.connect(show_page.bind(id))
		refs["tabs"][id] = tab
		index += 1
	TerminalUI.text(_canvas,"PersonalDevice","随行服务 · 在线",Rect2(163,842,190,40),20,true)
	_body = Control.new()
	_body.name = "Page"
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.size = size
	_canvas.add_child(_body)
	_message = TerminalUI.text(_canvas,"Feedback","",Rect2(410,891,1320,35),23,true)
	GameState.profile_changed.connect(_schedule_refresh)
	GameState.inventory_changed.connect(_schedule_refresh)
	GameState.deck_changed.connect(_schedule_refresh)
	refresh()

func _schedule_refresh() -> void:
	if _pending: return
	_pending = true
	_refresh_deferred.call_deferred()

func _refresh_deferred() -> void:
	_pending = false
	if is_inside_tree(): refresh()

func show_page(page: String) -> void:
	if not PAGES.has(page): return
	current_tab = page
	refresh()
	refs["tabs"][page].grab_focus()

func refresh(panel_context: Dictionary = {}) -> void:
	context.merge(panel_context,true)
	if not is_instance_valid(_body): return
	var focused := get_viewport().gui_get_focus_owner()
	var focus_name := str(focused.name) if focused != null and is_ancestor_of(focused) else ""
	if focused is LineEdit: _caret = focused.caret_column
	for scroll in _body.find_children("*","ScrollContainer",true,false): _scroll_positions[str(scroll.name)] = scroll.scroll_vertical
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	refs.erase("items")
	for id in PAGES:
		var button: Button = refs["tabs"][id]
		button.set_meta("choice_selected",id == current_tab)
		button.add_theme_stylebox_override("normal",StyleBoxEmpty.new())
	TerminalUI.text(_body,"PageTitle",PAGES[current_tab],Rect2(410,208,1250,62),42)
	TerminalUI.text(_body,"PageSubtitle","属于每一位学生的随身设备",Rect2(412,268,1250,36),23,true)
	_message.text = str(context.get("message",""))
	match current_tab:
		"overview": _overview()
		"zodiac": _zodiac()
		"cards": _cards()
		"journal": _journal()
		"contacts": _contacts()
		"inventory": _inventory()
	for scroll in _body.find_children("*","ScrollContainer",true,false): scroll.set_deferred("scroll_vertical",int(_scroll_positions.get(str(scroll.name),0)))
	TerminalConceptUI.apply(self,current_tab)
	if focus_name != "": _restore_focus.call_deferred(focus_name)

func _restore_focus(id: String) -> void:
	var node := find_child(id,true,false) as Control
	if node != null and node.is_visible_in_tree():
		node.grab_focus()
		if node is LineEdit: node.caret_column = _caret

func _overview() -> void:
	TerminalUI.panel(_body,"Greeting",Rect2(410,310,865,238),Color("#DBEBED"))
	TerminalUI.text(_body,"Hello",str({"morning":"早晨好，学生。","afternoon":"下午好，学生。","night":"晚上好，学生。"}.get(DayCycle.period(),"你好，学生。")),Rect2(442,337,800,65),36)
	TerminalUI.text(_body,"Welcome","今天也一起记录有意义的事。\n探索、收集，以及尚未说出口的话。",Rect2(444,410,780,50),27)
	TerminalUI.text(_body,"Status","体力 %d/%d    零用钱 %d" % [GameState.player_current_hp,GameState.player_max_hp,GameState.energy_crystals],Rect2(444,475,800,45),26)
	TerminalUI.panel(_body,"Collection",Rect2(1300,310,450,238),Color("#FCF0D7"))
	TerminalUI.text(_body,"CollectionTitle","十二星座",Rect2(1331,330,380,45),30)
	TerminalUI.text(_body,"CollectionCount","%d / 12" % SpecialCardCollection.snapshot()["collected"].size(),Rect2(1331,378,380,76),55)
	TerminalUI.button(_body,"OpenZodiac","打开星座图鉴 →",Rect2(1325,463,398,60)).pressed.connect(show_page.bind("zodiac"))
	var tiles := [["cards","行动卡资料","整理行动前的准备"],["journal","经历与成长","留下今天的足迹"],["contacts","同学资料","熟悉彼此的每一天"],["inventory","物品收纳","查看材料与补给"]]
	for i in tiles.size():
		var row: Array = tiles[i]
		var tile := TerminalUI.button(_body,"Open_"+row[0],"",Rect2(410+(i%2)*685,579+(i/2)*148,655,126))
		SchoolObjectUI.art(tile,"AppIcon","res://assets/ui/student_terminal/icons/"+str(row[0])+".svg",Rect2(26,35,54,54))
		TerminalUI.text(tile,"Title",row[1]+"   →",Rect2(104,15,520,48),31)
		TerminalUI.text(tile,"Note",row[2],Rect2(104,68,520,40),24,true)
		tile.pressed.connect(show_page.bind(row[0]))

func _zodiac() -> void:
	refs["badges"] = {}
	for index in ZodiacCatalog.ORDER.size():
		var id: String = ZodiacCatalog.ORDER[index]
		var data := ZodiacCatalog.definition(id)
		var owned := SpecialCardCollection.collected(id)
		var tile := TerminalUI.button(_body,"Badge_"+id,"",Rect2(410+(index%4)*208,308+(index/4)*184,188,170),id == selected_zodiac)
		var icon := SchoolObjectUI.art(tile,"BadgeIcon","res://assets/ui/student_terminal/badges/"+str(data["zodiac"])+".svg",Rect2(46,8,96,96))
		if not owned:
			var shader: Shader = load("res://assets/ui/student_terminal/uncollected_badge.gdshader")
			var badge_material := ShaderMaterial.new()
			badge_material.shader = shader
			icon.material = badge_material
		TerminalUI.text(tile,"Name",data["name"],Rect2(18,104,155,34),28)
		TerminalUI.text(tile,"State","已收录" if owned else "未收录",Rect2(18,140,155,27),20,true)
		tile.pressed.connect(func(): selected_zodiac = id; refresh())
		refs["badges"][id] = tile
	var selected := ZodiacCatalog.definition(selected_zodiac)
	TerminalUI.panel(_body,"ZodiacDetail",Rect2(1265,308,485,552))
	TerminalUI.text(_body,"ZodiacName",selected["name"],Rect2(1290,326,438,58),39)
	TerminalUI.text(_body,"Archetype","对应原型 · "+str(selected["archetype"]),Rect2(1290,389,438,38),25,true)
	var prose := "%s\n\n能力\n%s\n\n限制\n%s\n\n交互\n%s" % [selected["power"],selected["ability"],selected["limits"],selected["interactions"]]
	refs["detail"] = TerminalUI.prose(_body,"ZodiacDescription",prose,Rect2(1290,445,432,310),25)
	var progress := SpecialCardCollection.key_progress()
	TerminalUI.text(_body,"KeyProgress","其余星座 %d/11 · 钥匙%s" % [progress["other_collected"],"已收录" if progress["has_key"] else "未收录"],Rect2(1290,779,432,54),23)
	TerminalUI.text(_body,"PermanentStory","剧情收藏永久保留 · 不参与交易",Rect2(410,861,830,32),23,true)

func _cards() -> void:
	var cards: Array = []
	for id in GameState.all_cards:
		var data := GameState.get_card(id)
		cards.append({"id":id,"name":data.name,"level":data.level,"equipped":GameState.equipped_card_ids.has(id),"owned":GameState.unlocked_card_ids.has(id)})
	if selected_card == "" and not cards.is_empty(): selected_card = str(cards[0]["id"])
	var rows := TerminalUI.list(_body,"CardScroll",Rect2(410,312,825,550))
	refs["cards"] = {}
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation",18)
	grid.add_theme_constant_override("v_separation",18)
	rows.add_child(grid)
	for card in cards:
		var tile := TerminalUI.button(grid,"Card_"+str(card["id"]),"",Rect2(0,0,250,240),card["id"] == selected_card)
		tile.custom_minimum_size = Vector2(250,240)
		SchoolObjectUI.art(tile,"Art",SceneSkin.card_illustration_path(card["id"]),Rect2(15,12,220,145))
		TerminalUI.text(tile,"Name",card["name"],Rect2(18,162,220,38),27)
		TerminalUI.text(tile,"Level","尚未拥有" if not card["owned"] else "Lv.%d · %s" % [card["level"],"已装备" if card["equipped"] else "未装备"],Rect2(18,203,220,28),21,true)
		tile.pressed.connect(func(): selected_card = str(card["id"]); refresh())
		refs["cards"][card["id"]] = tile
	TerminalUI.panel(_body,"CardDetail",Rect2(1270,312,480,550))
	var card := GameState.get_card(selected_card)
	if card != null:
		TerminalUI.text(_body,"CardName",card.name,Rect2(1298,336,420,60),36)
		SchoolObjectUI.art(_body,"CardArt",SceneSkin.card_illustration_path(selected_card),Rect2(1300,410,420,170))
		var card_type: String = ["进攻","防御","恢复","干扰","反击"][int(card.card_type)]
		var target: String = ["单个敌人","敌方全体","自身"][int(card.target_type)]
		var description := "%s / %s · 冷却%d回合 · Lv.%d\n\n%s\n\n%s\n\n%s" % [card_type,target,card.get_current_cooldown(),card.level,card.get_dynamic_description(),card.get_upgrade_preview_text(),card.flavor_text]
		TerminalUI.prose(_body,"CardDescription",description,Rect2(1300,600,420,155),25)
	var open := TerminalUI.button(_body,"OpenWorkshop","打开卡牌整理 →",Rect2(1300,782,420,60))
	open.pressed.connect(func(): action_requested.emit("open_workshop",{}))

func _journal() -> void:
	for i in 2:
		var id := "journey" if i == 0 else "growth"
		TerminalUI.button(_body,"Journal_"+id,"经历回顾" if i == 0 else "成长目标",Rect2(410+i*235,310,215,60),journal_tab == id).pressed.connect(func(): journal_tab = id; refresh())
	TerminalUI.panel(_body,"JourneyBoard",Rect2(410,395,810,465))
	TerminalUI.panel(_body,"TrainingBoard",Rect2(1244,395,506,465),Color("#E2EBEC"))
	TerminalUI.text(_body,"TrainingHeading","最近的训练",Rect2(1270,415,450,50),32)
	var training_text := "暂无训练记录。\n走完、撤离或失败后，经历都会留在这里。"
	if not GameState.player_profile["exploration_log"].is_empty():
		training_text = ""
		for entry in GameState.player_profile["exploration_log"]:
			var status: String = {"completed":"完成","defeat":"落败","retreated":"撤离"}.get(str(entry["status"]),str(entry["status"]))
			training_text += "第%d天 · %s · 到访%d处\n" % [entry["day"],status,entry["visited"]]
	TerminalUI.prose(_body,"TrainingLog",training_text,Rect2(1270,490,450,335),25)
	var rows := TerminalUI.list(_body,"JournalScroll",Rect2(435,420,760,415))
	if journal_tab == "growth":
		for goal in PlayerJourney.milestones():
			var row := Control.new()
			row.custom_minimum_size = Vector2(735,160)
			rows.add_child(row)
			TerminalUI.panel(row,"Backing",Rect2(0,0,735,158))
			TerminalUI.text(row,"Title",goal["title"],Rect2(18,12,490,43),30)
			TerminalUI.text(row,"Condition",str(goal["condition"])+" · "+str(goal["progress"]),Rect2(18,65,490,80),24,true)
			var claim := TerminalUI.button(row,"Claim_"+str(goal["id"]),"已领取" if goal["claimed"] else "领取奖励",Rect2(520,48,190,62))
			claim.disabled = not goal["ready"] or goal["claimed"]
			claim.pressed.connect(func(): action_requested.emit("claim_milestone",{"id":goal["id"]}))
	else:
		var summary := HomePanels.content_snapshot("records")
		var intro := RichTextLabel.new()
		intro.custom_minimum_size = Vector2(735,190)
		intro.fit_content = true
		intro.text = str(summary["record_summary"])+"\n"+str(summary["record_anomaly"])
		intro.add_theme_font_override("normal_font",DaylightUI.get_theme().default_font)
		intro.add_theme_color_override("default_color",TerminalUI.INK)
		intro.add_theme_font_size_override("normal_font_size",26)
		rows.add_child(intro)
		for memory in PlayerJourney.memories():
			var button := TerminalUI.button(rows,"Memory_"+str(memory["dialogue_id"]),"回顾 · "+str(memory["title"]),Rect2(0,0,735,70))
			button.custom_minimum_size = Vector2(735,70)
			button.disabled = not PlayerJourney.safe_at_home()
			button.pressed.connect(func(): GameState.archive_return_tab = "journey"; action_requested.emit("replay_memory",{"dialogue_id":memory["dialogue_id"]}))

func _contacts() -> void:
	var contacts: Array = HomePanels.content_snapshot("records")["classmates"]
	if selected_contact == "" and not contacts.is_empty(): selected_contact = str(contacts[0]["id"])
	TerminalUI.panel(_body,"ContactDetail",Rect2(870,312,880,548))
	var index := 0
	for contact in contacts:
		var known: bool = contact["unlocked"]
		var tile := TerminalUI.button(_body,"Contact_"+str(contact["id"]),"",Rect2(410,312+index*181,425,156),selected_contact == contact["id"])
		TerminalUI.text(tile,"Initial",str(contact["name"]).left(1) if known else "?",Rect2(22,21,95,100),56)
		TerminalUI.text(tile,"Name",contact["name"] if known else "尚未结识",Rect2(128,30,270,50),31)
		TerminalUI.text(tile,"State","交流记录 %d" % int(contact["favor"]) if known else "等待相遇",Rect2(128,91,270,40),23,true)
		tile.pressed.connect(func(): selected_contact = str(contact["id"]); refresh())
		if selected_contact == contact["id"]:
			TerminalUI.text(_body,"ContactName",contact["name"] if known else "尚未结识",Rect2(905,344,790,70),43)
			TerminalUI.text(_body,"ContactStatus","已有测试档案 · 正式人物资料待完善" if known else "相遇后，将在这里留下资料。",Rect2(905,430,790,60),26,true)
			TerminalUI.prose(_body,"ContactNotes","交流记录：%d\n\n资料由已遇见的同学逐步补全。\n回到地区地点，可与在场的同学交流。" % int(contact["favor"]) if known else "暂未收录身份、外观与故事。",Rect2(905,530,790,245),28)
		index += 1

func _inventory() -> void:
	var index := 0
	for id in ItemCatalog.CATEGORIES:
		TerminalUI.button(_body,"Filter_"+id,ItemCatalog.CATEGORIES[id],Rect2(410+index*166,310,150,55),category == id).pressed.connect(func(): category = id; refresh())
		index += 1
	var input := LineEdit.new()
	input.name = "InventorySearch"
	input.text = search
	input.placeholder_text = "搜索物品"
	input.add_theme_font_size_override("font_size",24)
	for style in ["normal","focus","read_only"]: input.add_theme_stylebox_override(style,TerminalUI.field_style())
	input.add_theme_color_override("font_color",TerminalUI.INK)
	input.add_theme_color_override("font_placeholder_color",TerminalUI.MUTED)
	input.add_theme_color_override("caret_color",TerminalUI.INK)
	_body.add_child(input)
	DaylightUI.place(input,1100,310,330,55)
	input.text_changed.connect(func(value: String): search = value; _schedule_refresh())
	var sorting := OptionButton.new()
	sorting.name = "InventorySort"
	for label in ["物品序号","拼音首字母","获得时间"]: sorting.add_item(label)
	sorting.selected = sort_index
	sorting.add_theme_font_size_override("font_size",22)
	for style in ["normal","hover","pressed"]: sorting.add_theme_stylebox_override(style,TerminalUI.field_style())
	sorting.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	sorting.get_popup().add_theme_stylebox_override("panel",TerminalUI.field_style())
	for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]: sorting.add_theme_color_override(key,TerminalUI.INK)
	_body.add_child(sorting)
	DaylightUI.place(sorting,1450,310,300,55)
	sorting.item_selected.connect(func(value: int): sort_index = value; descending = value == 2; refresh())
	TerminalUI.button(_body,"SortDirection","降序 ↓" if descending else "升序 ↑",Rect2(1480,380,270,50)).pressed.connect(func(): descending = not descending; refresh())
	var items: Array = GameState.get_inventory_snapshot()["items"].filter(func(item: Dictionary): return (category == "all" or item["category"] == category) and (search == "" or str(item["name"]).contains(search)))
	items.sort_custom(func(a: Dictionary,b: Dictionary):
		var field: String = ["number","pinyin","acquired"][sort_index]
		if sort_index == 2: return int(a.get("acquired",{}).get("order",0)) > int(b.get("acquired",{}).get("order",0)) if descending else int(a.get("acquired",{}).get("order",0)) < int(b.get("acquired",{}).get("order",0))
		return a.get(field,0) > b.get(field,0) if descending else a.get(field,0) < b.get(field,0)
	)
	if not items.any(func(item: Dictionary): return item["id"] == selected_item): selected_item = str(items[0]["id"]) if not items.is_empty() else ""
	var rows := TerminalUI.list(_body,"InventoryScroll",Rect2(410,393,720,465))
	refs["items"] = {}
	TerminalUI.panel(_body,"ItemDetail",Rect2(1170,451,580,407))
	if items.is_empty(): TerminalUI.text(rows,"Empty","这里还没有物品。",Rect2(0,0,700,70),30,true)
	for item in items:
		var tile := TerminalUI.button(rows,"Item_"+str(item["id"]),"",Rect2(0,0,695,104),item["id"] == selected_item)
		tile.custom_minimum_size = Vector2(695,104)
		SchoolObjectUI.art(tile,"Icon",item["icon"],Rect2(15,12,80,80))
		TerminalUI.text(tile,"Name",item["name"],Rect2(118,13,445,42),27)
		TerminalUI.text(tile,"Count","%s · ×%d" % [item["quality"],item["quantity"]],Rect2(118,57,445,36),23,true)
		tile.pressed.connect(func(): selected_item = str(item["id"]); refresh())
		refs["items"][item["id"]] = tile
		if item["id"] == selected_item:
			SchoolObjectUI.art(_body,"ItemIcon",item["icon"],Rect2(1195,474,100,100))
			TerminalUI.text(_body,"ItemName",item["name"],Rect2(1195,474,525,58),34)
			TerminalUI.prose(_body,"ItemDescription",item["description"],Rect2(1195,560,525,180),26)
			if item["id"] == "drink":
				var use := TerminalUI.button(_body,"UseDrink","使用饮品 · 恢复体力",Rect2(1195,770,525,60))
				use.disabled = not PlayerJourney.safe_at_home() or GameState.player_current_hp >= GameState.player_max_hp
				use.pressed.connect(func(): action_requested.emit("use_drink",{}))

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close_requested.emit()
		get_viewport().set_input_as_handled()
