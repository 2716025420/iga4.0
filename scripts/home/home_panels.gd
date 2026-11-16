class_name HomePanels
extends PanelContainer

signal close_requested
signal action_requested(action: String, payload: Dictionary)

const KINDS: Array[String] = ["lounge", "workshop", "records", "quest", "explore"]
const APPROVED_LAYOUTS: Dictionary = {
	"lounge": {"size": Vector2(1360, 810), "position": Vector2(510, 165)},
	"workshop": {"size": Vector2(1370, 960), "position": Vector2(510, 60)},
	"quest": {"size": Vector2(1360, 900), "position": Vector2(510, 100)},
	"records": {"size": Vector2(1040, 900), "position": Vector2(770, 100)},
	"explore": {"size": Vector2(1040, 1000), "position": Vector2(825, 35)}
}
const CLASSMATE_IDS: Array[String] = ["yang_zi_ying", "liu_yu_long", "jiang_zi"]
const ROUTE: Array[Dictionary] = [
	{"id": "n0", "title": "樱林解围", "summary": "替转校生黄秋枫挡下高年级生的刁难。"},
	{"id": "n_gate", "title": "赛前切磋", "summary": "与柳宇龙约好对决，记下秋枫放学后的约定。"},
	{"id": "n_affairs", "title": "旧园名录", "summary": "协助姜梓核对巡回赛名单与异常日志。"},
	{"id": "n_dusk", "title": "黄昏轻吻", "summary": "旧公园分别转瞬，天空骤然响起红月警报。"},
	{"id": "n_guard", "title": "门岗封锁", "summary": "冲破被劫持的超限门禁，追向街角。"},
	{"id": "n_rescue", "title": "灰区奇袭", "summary": "目睹灰区女特工重创秋枫与露出的光纤电路。"},
	{"id": "n_robot", "title": "拦截机械", "summary": "与杨子英联手拦截超限重装机械。"},
	{"id": "n5_boss", "title": "红月超限", "summary": "全员终端协战同步，击退灰区猎杀终端。"},
	{"id": "n_find_yang", "title": "白羊觉醒", "summary": "守住结晶核心，立下六地区巡回赛的约定。"}
]

var panel_kind: String = ""
var context: Dictionary = {}
var refs: Dictionary = {}
var snapshot: Dictionary = {}
var selected_card_id: String = ""
var selected_slot_index: int = -1
var current_tab: String = "today"
var _warehouse_category: String = "all"
var _warehouse_sort: String = "number"
var _warehouse_descending: bool = false
var _inventory_scroll_y: int = 0
var _selected_item_id: String = ""
var _last_focus_name: String = ""
var _library_scroll_y: int = 0

static func create(kind: String, panel_context: Dictionary = {}) -> HomePanels:
	# 未审核的弹窗不会渲染，更不会回退到旧布局。
	if not APPROVED_LAYOUTS.has(kind):
		return null
	var panel := HomePanels.new()
	panel.panel_kind = kind
	panel.context = panel_context.duplicate(true)
	panel.selected_card_id = panel_context.get("selected_card_id", "")
	panel.refresh()
	return panel

static func build(host: Control, kind: String) -> Dictionary:
	var panel := create(kind)
	if panel == null:
		return {"panel": null, "refs": {}, "refresh": Callable()}
	host.add_child(panel)
	return {"panel": panel, "refs": panel.refs, "refresh": panel.refresh}

static func content_snapshot(kind: String, selected_id: String = "") -> Dictionary:
	var exploration: Dictionary = {}
	if GameState.has_method("get_exploration_snapshot"):
		exploration = GameState.call("get_exploration_snapshot")
	var cards: Array[Dictionary] = []
	for cid in GameState.unlocked_card_ids:
		var card := GameState.get_card(cid)
		if card != null:
			cards.append({"id": cid, "name": card.name, "description": card.get_dynamic_description(card.level, false), "cooldown": card.get_current_cooldown(), "level": card.level, "max_level": card.max_level, "type": int(card.card_type), "equipped": GameState.equipped_card_ids.has(cid), "slot": GameState.equipped_card_ids.find(cid), "brief": _card_brief(card), "preview": _upgrade_summary(card), "upgrade_tooltip": card.get_upgrade_preview_text()})
	var selected: Dictionary = {}
	for card in cards:
		if card["id"] == selected_id:
			selected = card
	if selected.is_empty() and not cards.is_empty():
		selected = cards[0]
	var classmates: Array[Dictionary] = []
	for cid in CLASSMATE_IDS:
		var companion: Dictionary = GameState.companions.get(cid, {})
		var actor: Dictionary = PhaseTwoContent.ACTORS.get(cid, {})
		var short_bios := {"yang_zi_ying": "喜欢摄影和橘子汽水。\n每打出3张卡可发动「快门闪光支援」。", "liu_yu_long": "竞技台热血选手，讲究正大光明的切磋。\n每打出3张卡可发动「热血追击重扣」。", "jiang_zi": "学生会干事，把终端安全日志理得一清二楚。\n每打出3张卡可发动「战术统筹屏障」。"}
		classmates.append({"id": cid, "name": actor.get("name", "同学"), "subtitle": actor.get("title", "同班同学"), "bio": short_bios.get(cid, ""), "favor": companion.get("favor", 0), "unlocked": companion.get("unlocked", false), "portrait": DaylightUI.character_path(cid, true), "dialogue_id": {"yang_zi_ying": "chat_yang", "liu_yu_long": "chat_liu", "jiang_zi": "chat_jiang"}.get(cid, "chat_yang")})
	var cast: Array[Dictionary] = []
	for cid in ["ye_zhou", "yang_zi_ying", "liu_yu_long", "jiang_zi"]:
		var actor: Dictionary = PhaseTwoContent.ACTORS[cid]
		cast.append({"id": cid, "name": actor["name"], "subtitle": actor["title"], "portrait": DaylightUI.character_path(cid, true)})
	var completed: bool = GameState.story_flags.get("chapter_1_completed", false)
	var current_step := clampi(GameState.visited_node_ids.size(), 0, ROUTE.size() - 1)
	var steps: Array[Dictionary] = []
	for index in ROUTE.size():
		var step: Dictionary = ROUTE[index].duplicate()
		step["state"] = "done" if GameState.visited_node_ids.has(step["id"]) else ("current" if index == current_step and not completed else "later")
		if step["state"] == "later":
			step["title"] = "待续"
			step["summary"] = ""
		elif step["state"] == "current":
			step["title"] = "现在的目标"
			step["summary"] = PhaseTwoContent.current_objective()
		steps.append(step)
	var upgrade_cost: int = int(selected.get("level", 1)) * 50
	return {
		"exploration": exploration, "dungeons": exploration.get("dungeons", []),
		"kind": kind, "title": {"lounge": "同学交流", "workshop": "卡牌整理", "records": "校园记录", "quest": "模拟训练", "explore": "红月下的旧公园"}.get(kind, "校园生活"),
		"cards": cards, "selected_card": selected, "equipped_ids": GameState.equipped_card_ids.duplicate(), "classmates": classmates, "cast": cast,
		"practice_points": GameState.scrap_metal, "upgrade_cost": upgrade_cost,
		"can_upgrade": not selected.is_empty() and int(selected.get("level", 1)) < int(selected.get("max_level", 3)) and GameState.scrap_metal >= upgrade_cost,
		"steps": steps, "current_step": current_step, "current_title": PhaseTwoContent.current_objective(),
		"completed_count": GameState.visited_node_ids.size(), "total_steps": ROUTE.size(), "completed": completed, "time": GameState.get_formatted_time(),
		"chapter_description": "熟悉的阿瑞忒校园，突如其来的红月异常警报。\n追寻黄秋枫结晶真相，迈向六地区巡回锦标赛。",
		"chapter_action": "重新开始" if completed else ("开始今天的行程" if GameState.visited_node_ids.is_empty() else "继续今天的行程"),
		"chapter_restart": completed,
		"record_headline": "今天，一起站在了红月之下。" if completed else "校园里的小事，也值得记下来。",
		"record_summary": PhaseTwoContent.timeline_summary(),
		"record_anomaly": "反叛组织女特工使用盗取的早期母卡残钥劫持了阿瑞忒门禁并击伤编号04「黄秋枫」。\n创口露出的光纤证明她是月球计算中心派出的高阶拟真伪人。\n唯有赢下六地区巡回锦标赛并集齐十二星座母卡与魔法师钥匙，方能申请唤醒她的深层数据。" if GameState.story_flags.get("principal_stopped", false) else ("校园安全终端侦测到未知外部高权限覆写。\n红月预警亮起，请立即前往旧公园与同伴汇合。" if GameState.visited_node_ids.has("n_dusk") else "收好学生智能终端，准备出发。\n今天的经历会慢慢写进这里。")
	}

func refresh(panel_context: Dictionary = {}) -> void:
	context.merge(panel_context, true)
	selected_card_id = context.get("selected_card_id", selected_card_id)
	snapshot = content_snapshot(panel_kind, selected_card_id)
	if not snapshot["selected_card"].is_empty():
		selected_card_id = snapshot["selected_card"]["id"]
	_render_approved_layout()

func select_card(card_id: String) -> void:
	context["selected_card_id"] = card_id
	selected_card_id = card_id
	refresh()

func request_action(action: String, payload: Dictionary = {}) -> void:
	if action == "close":
		close_requested.emit()
	else:
		action_requested.emit(action, payload)

func _render_approved_layout() -> void:
	if not APPROVED_LAYOUTS.has(panel_kind):
		return
	var preferred: Vector2 = APPROVED_LAYOUTS[panel_kind]["size"]
	set_meta("design_size", preferred)
	set_meta("design_position", APPROVED_LAYOUTS[panel_kind]["position"])
	size = preferred
	custom_minimum_size = preferred
	theme = DaylightUI.get_theme()
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var panel_asset: String = {"lounge": "lounge_panel", "workshop": "workshop_panel", "records": "records_panel", "quest": "exploration_panel", "explore": "story_panel"}.get(panel_kind, "panel_frame")
	add_theme_stylebox_override("panel", SceneSkin.style(panel_asset, Vector4.ZERO))
	var previous_scroll := refs.get("library_scroll") as ScrollContainer
	if previous_scroll != null and is_instance_valid(previous_scroll) and previous_scroll.get_v_scroll_bar().max_value > 0:
		_library_scroll_y = previous_scroll.scroll_vertical
	var inventory_scroll := refs.get("inventory_scroll") as ScrollContainer
	if is_instance_valid(inventory_scroll): _inventory_scroll_y = inventory_scroll.scroll_vertical
	if is_inside_tree() and get_viewport().gui_get_focus_owner() != null and is_ancestor_of(get_viewport().gui_get_focus_owner()):
		_last_focus_name = String(get_viewport().gui_get_focus_owner().name)
	for child in get_children():
		remove_child(child)
		child.queue_free()
	refs.clear()
	var canvas := Control.new()
	canvas.name = "Canvas"
	canvas.custom_minimum_size = preferred
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(canvas)
	refs["canvas"] = canvas
	match panel_kind:
		"lounge": _render_lounge(canvas)
		"workshop": _render_workshop(canvas)
		"quest": _render_quest(canvas)
		"records": _render_records(canvas)
		"explore": _render_explore(canvas)
	if _last_focus_name != "":
		call_deferred("_restore_focus", _last_focus_name)

func _restore_focus(focus_name: String) -> void:
	if not is_inside_tree():
		return
	var restored := find_child(focus_name, true, false) as Control
	if restored != null and restored.visible and not restored.is_queued_for_deletion():
		restored.grab_focus()

static func _card_brief(card: CardData) -> String:
	match card.card_type:
		CardData.CardType.ATTACK:
			return "伤害 %d · 压制 %d 回合" % [card.get_scaled_damage(), card.burn_duration] if card.burn_duration > 0 else "造成 %d 点伤害" % card.get_scaled_damage()
		CardData.CardType.DEFENSE: return "获得 %d 点护盾" % card.get_scaled_shield()
		CardData.CardType.RECOVERY: return "恢复 %d 点体力" % card.get_scaled_heal()
		CardData.CardType.DEBUFF: return "敌方伤害降低 %d%%" % int(card.get_scaled_attack_down() * 100)
		_: return "护盾 %d · 反击 %d" % [card.get_scaled_shield(), card.get_scaled_reflect_damage()]

static func _upgrade_summary(card: CardData) -> String:
	if card.level >= card.max_level:
		return "已达到最高等级"
	var next_level := card.level + 1
	match card.card_type:
		CardData.CardType.ATTACK: return "下一等级：伤害 %d" % card.get_scaled_damage(next_level)
		CardData.CardType.DEFENSE: return "下一等级：护盾 %d" % card.get_scaled_shield(next_level)
		CardData.CardType.RECOVERY: return "下一等级：恢复 %d" % card.get_scaled_heal(next_level)
		CardData.CardType.DEBUFF: return "下一等级：减伤 %d%%" % int(card.get_scaled_attack_down(next_level) * 100)
		_: return "下一等级：反击 %d" % card.get_scaled_reflect_damage(next_level)

func _render_lounge(canvas: Control) -> void:
	_header(canvas, "同学交流", "放学后，慢慢聊。", 1360)
	var motives := {"yang_zi_ying": "想拍下这条路的夕阳。", "liu_yu_long": "想赢一场认真的比赛。", "jiang_zi": "想把今天的事务理清。"}
	var chat_buttons: Dictionary = {}
	for index in snapshot["classmates"].size():
		var mate: Dictionary = snapshot["classmates"][index]
		var card := _paper(canvas, "Classmate_" + mate["id"], Vector2(64 + index * 416, 146), Vector2(400, 620))
		_school_window(card, Vector2(40, 20), Vector2(320, 340))
		var portrait := _portrait(card, mate["portrait"], Vector2(40, 20), Vector2(320, 340))
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_label(card, "Name", mate["name"], 44, Vector2(24, 370), Vector2(352, 60), true)
		_label(card, "Motivation", motives[mate["id"]], 28, Vector2(24, 438), Vector2(352, 44), true, DaylightUI.MUTED)
		_label(card, "Favor", "熟悉度 %d" % mate["favor"] if mate["unlocked"] else "继续行程后可交流", 28, Vector2(24, 478), Vector2(352, 40), true, DaylightUI.ACCENT)
		var chat := _button(card, "Chat_" + mate["id"], {"yang_zi_ying": "聊聊摄影", "liu_yu_long": "聊聊比赛", "jiang_zi": "聊聊近况"}[mate["id"]] if mate["unlocked"] else "尚未交流", Vector2(25, 520), Vector2(350, 80), true)
		chat.disabled = not mate["unlocked"]
		chat.pressed.connect(func(): request_action("chat", {"dialogue_id": mate["dialogue_id"]}))
		chat_buttons[mate["id"]] = chat
	refs["chat_buttons"] = chat_buttons

func _render_records(canvas: Control) -> void:
	_label(canvas, "Title", "校园记录", 64, Vector2(160, 32), Vector2(660, 88))
	_label(canvas, "Subtitle", "那些值得记住的小事。", 28, Vector2(160, 121), Vector2(660, 44), false, DaylightUI.MUTED)
	var close := _button(canvas, "CloseButton", "×", Vector2(926, 42), Vector2(64, 64), false)
	close.add_theme_font_size_override("font_size", 44)
	close.pressed.connect(func(): close_requested.emit())
	refs["close_button"] = close
	var tab_keys := ["today", "classmates", "anomaly", "warehouse"]
	var tab_names := ["今日足迹", "同学小记", "异常记录", "仓库"]
	var tabs: Dictionary = {}
	for index in tab_keys.size():
		var key: String = tab_keys[index]
		var tab := _button(canvas, "RecordsTab_" + key, tab_names[index], Vector2(32, 206 + index * 112), Vector2(220, 88), key == current_tab)
		SchoolObjectUI.set_selected(tab,key == current_tab)
		tab.add_theme_font_size_override("font_size", 28)
		tab.pressed.connect(func(): _select_records_tab(key))
		tabs[key] = tab
	refs["records_tabs"] = tabs
	refs["current_tab"] = current_tab
	var heading: String = {"today": "今天，一起走过这段路。", "classmates": "同学们，各有自己的计划。", "anomaly": "把知道的事，认真记下。", "warehouse": "把收集的物品，妥善收好。"}[current_tab]
	_label(canvas, "RecordHeading", heading, 38, Vector2(288, 194), Vector2(712, 62))
	match current_tab:
		"today": _record_today(canvas)
		"classmates": _record_classmates(canvas)
		"warehouse": _record_warehouse(canvas)
		"anomaly":
			var paper := _paper(canvas, "AnomalyNote", Vector2(288, 274), Vector2(712, 462))
			_label(paper, "AnomalyText", snapshot["record_anomaly"], 32, Vector2(40, 40), Vector2(630, 380), false, DaylightUI.INK, true)
	_label(canvas, "RecordFooter", "慢慢记下今天的小事。", 24, Vector2(288, 810), Vector2(270, 58), false, DaylightUI.MUTED)
	_label(canvas, "PageNumber", "%02d / 04" % (tab_keys.find(current_tab) + 1), 24, Vector2(598, 805), Vector2(100, 58), true, DaylightUI.MUTED)
	var close_book := _button(canvas, "CloseBookButton", "合上手记", Vector2(736, 792), Vector2(240, 80), false)
	close_book.pressed.connect(func(): close_requested.emit())
	refs["close_book_button"] = close_book

func _select_records_tab(tab_key: String) -> void:
	if tab_key not in ["today", "classmates", "anomaly", "warehouse"]:
		return
	current_tab = tab_key
	refresh()

func _record_warehouse(canvas: Control) -> void:
	var inventory: Dictionary = GameState.get_inventory_snapshot()
	var filters := {}
	var keys := ["all", "material", "quest", "item"]
	for index in keys.size():
		var key: String = keys[index]
		var filter := _button(canvas, "InventoryFilter_" + key, str(ItemCatalog.CATEGORIES[key]), Vector2(288 + index * 178, 274), Vector2(166, 56), key == _warehouse_category)
		SchoolObjectUI.set_selected(filter,key == _warehouse_category)
		filter.add_theme_font_size_override("font_size", 26)
		filter.pressed.connect(func(): _warehouse_category = key; refresh())
		filters[key] = filter
	_label(canvas, "SortLabel", "整理方式", 24, Vector2(298, 346), Vector2(130, 50), false, DaylightUI.MUTED)
	var sorting := OptionButton.new()
	sorting.name = "InventorySort"
	for copy in ["物品序号", "拼音首字母", "获得时间"]: sorting.add_item(copy)
	sorting.selected = ["number", "pinyin", "acquired"].find(_warehouse_sort)
	sorting.add_theme_font_size_override("font_size", 25)
	sorting.add_theme_stylebox_override("normal", SceneSkin.style("button_secondary", Vector4(18, 5, 18, 5)))
	canvas.add_child(sorting)
	_place(sorting, Vector2(440, 346), Vector2(290, 50))
	sorting.item_selected.connect(func(index: int):
		_warehouse_sort = ["number", "pinyin", "acquired"][index]
		_warehouse_descending = _warehouse_sort == "acquired"
		refresh()
	)
	var direction := _button(canvas, "InventorySortDirection", ("最新在前" if _warehouse_descending else "最早在前") if _warehouse_sort == "acquired" else ("降序" if _warehouse_descending else "升序"), Vector2(766, 346), Vector2(218, 50), false)
	direction.add_theme_font_size_override("font_size", 24)
	direction.pressed.connect(func(): _warehouse_descending = not _warehouse_descending; refresh())
	var visible_items: Array[Dictionary] = []
	for item in inventory["items"]:
		if _warehouse_category != "all" and item["category"] != _warehouse_category: continue
		visible_items.append(item)
	visible_items.sort_custom(_compare_inventory_items)
	var selected: Dictionary = {}
	for item in visible_items:
		if item["id"] == _selected_item_id: selected = item
	if selected.is_empty() and not visible_items.is_empty(): selected = visible_items[0]
	_selected_item_id = str(selected.get("id", ""))
	var scroll := ScrollContainer.new()
	scroll.name = "InventoryScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	canvas.add_child(scroll)
	_place(scroll, Vector2(288, 419), Vector2(712, 234))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 14)
	scroll.add_child(grid)
	var buttons := {}
	for item in visible_items:
		var item_id: String = str(item["id"])
		var button := Button.new()
		button.name = "InventoryItem_" + item_id
		button.custom_minimum_size = Vector2(338, 128)
		_style_button(button, false)
		if item_id == _selected_item_id: _selected_card_tint(button)
		grid.add_child(button)
		var art := TextureRect.new()
		art.name = "ItemArt"
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var icon: String = str(item["icon"])
		if ResourceLoader.exists(icon): art.texture = SceneSkin.illustration_texture(icon)
		button.add_child(art)
		_place(art, Vector2(12, 35), Vector2(76, 76))
		_label(button, "ItemNumber", "No.%03d" % item["number"], 18, Vector2(16, 14), Vector2(76, 28), false, DaylightUI.MUTED)
		_label(button, "ItemName", str(item["name"]), 24, Vector2(100, 10), Vector2(226, 38)).text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_label(button, "ItemQuantity", "数量 %d" % item["quantity"], 26, Vector2(100, 49), Vector2(226, 36))
		_label(button, "ItemCategory", "%s · %s" % [ItemCatalog.CATEGORIES[item["category"]], item["quality"]], 20, Vector2(100, 89), Vector2(226, 28), false, DaylightUI.MUTED)
		button.pressed.connect(func(): _selected_item_id = item_id; refresh())
		buttons[item_id] = button
	if visible_items.is_empty():
		_label(canvas, "EmptyInventory", "还没有收集到这类物品。\n放学后去训练一下吧。", 28, Vector2(306, 462), Vector2(676, 130), true, DaylightUI.MUTED, true)
	var detail := _paper(canvas, "InventoryDetail", Vector2(288, 675), Vector2(712, 106))
	var acquisition: Dictionary = selected.get("acquired", {})
	var date_copy := "此前已持有 · 时间未记录" if acquisition.is_empty() else "最近获得："+DayCycleService.date_label(int(acquisition["day"]),int(acquisition["hour"]))
	_label(detail, "AcquiredTime", date_copy if not selected.is_empty() else "物品手记", 20, Vector2(24, 14), Vector2(662, 28), false, DaylightUI.ACCENT)
	_label(detail, "SelectedItemDescription", str(selected.get("description", "训练获得的材料和收集的物品会保存在这里。")), 23, Vector2(24, 47), Vector2(662, 54), false, DaylightUI.MUTED, true)
	refs["inventory_filters"] = filters
	refs["inventory_sort"] = sorting
	refs["inventory_sort_direction"] = direction
	refs["inventory_order"] = visible_items.map(func(item: Dictionary): return item["id"])
	refs["inventory_item_buttons"] = buttons
	refs["inventory_scroll"] = scroll
	refs["inventory_selected"] = selected
	refs["inventory_snapshot"] = inventory
	scroll.set_deferred("scroll_vertical", _inventory_scroll_y)

func _compare_inventory_items(a: Dictionary, b: Dictionary) -> bool:
	var comparison: int = 0
	match _warehouse_sort:
		"pinyin": comparison = str(a["pinyin"]).naturalnocasecmp_to(str(b["pinyin"]))
		"acquired":
			var a_order := int(a.get("acquired", {}).get("order", 0))
			var b_order := int(b.get("acquired", {}).get("order", 0))
			# Legacy unknown dates are always kept after known dates.
			if (a_order == 0) != (b_order == 0): return a_order != 0
			comparison = signi(a_order - b_order)
		_: comparison = signi(int(a["number"]) - int(b["number"]))
	if comparison == 0: return int(a["number"]) < int(b["number"])
	return comparison > 0 if _warehouse_descending else comparison < 0


func _known_records() -> Array[Dictionary]:
	var source: Array[Dictionary] = [
		{"node": "n0", "title": "樱林 · 战术刻印解围", "copy": "替转校生黄秋枫挡下高年级生的刁难，两人交换名字。", "scene": "morning_road"},
		{"node": "n_gate", "title": "校门 · 巡回赛与旧园之约", "copy": "与柳宇龙约下赛前切磋；秋枫怯生生约起放学后的旧公园。", "scene": "school_gate"},
		{"node": "n_affairs", "title": "旧园 · 巡回赛名录与暗流", "copy": "协助姜梓核对六地区巡回赛名单，发现外部终端权限异常覆写。", "scene": "school_room"},
		{"node": "n_dusk", "title": "黄昏 · 旧公园轻吻与警报", "copy": "秋枫突发轻吻后转身买汽水，红月警报骤然封锁通道。", "scene": "dusk_road"},
		{"node": "n_guard", "title": "门岗 · 突破超限封锁", "copy": "击退被超限指令锁死的门岗卫兵，抢通前往街角的路。", "scene": "school_gate"},
		{"node": "n_rescue", "title": "街角 · 光纤芯与灰区女特工", "copy": "目睹秋枫肩口露出的蓝色光纤；杨子英挺身护住叶舟。", "scene": "dusk_road"},
		{"node": "n_robot", "title": "路口 · 停下重装拦截机", "copy": "配合战术刻印卡挡下灰区重装机械的火力拦截。", "scene": "dusk_road"},
		{"node": "n5_boss", "title": "红月 · 全员协战共鸣", "copy": "姜梓同步终端防线、柳宇龙赶到支援，合力击败猎杀终端。", "scene": "school_gate"},
		{"node": "n_find_yang", "title": "聚光 · 结晶核心与白羊座", "copy": "秋枫进入结晶休眠，#01 白羊座母卡觉醒，立下巡回赛之誓。", "scene": "dusk_road"}
	]
	var happened: Array[Dictionary] = []
	for entry in source:
		if GameState.visited_node_ids.has(entry["node"]):
			happened.append(entry)
	return happened

func _record_today(canvas: Control) -> void:
	var entries := _known_records()
	if entries.is_empty():
		_label(canvas, "EmptyRecords", "收好书包，准备出发。", 36, Vector2(320, 360), Vector2(640, 110), true, DaylightUI.MUTED)
		return
	var scroll := ScrollContainer.new()
	scroll.name = "RecordScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_place(scroll, Vector2(288, 270), Vector2(712, 510))
	canvas.add_child(scroll)
	var list := Control.new()
	list.name = "RecordList"
	list.custom_minimum_size = Vector2(688, entries.size() * 180)
	scroll.add_child(list)
	for index in entries.size():
		var entry: Dictionary = entries[index]
		var y := index * 180
		_scene_thumbnail(list, "Thumb%d" % index, entry["scene"], Vector2(0, y + 10), Vector2(230, 145), Rect2(140, 100, 1120, 700))
		_label(list, "EntryTitle%d" % index, entry["title"], 28, Vector2(250, y + 14), Vector2(430, 44))
		_label(list, "EntryCopy%d" % index, entry["copy"], 24, Vector2(250, y + 66), Vector2(430, 96), false, DaylightUI.MUTED, true)
	refs["record_scroll"] = scroll
	refs["record_count"] = entries.size()

func _record_classmates(canvas: Control) -> void:
	var motives := {"ye_zhou": "守住与黄秋枫在旧公园的约定，挑战六地区巡回赛。", "yang_zi_ying": "拍下值得记住的风景，关键时刻支援同伴。", "liu_yu_long": "靠战术刻印卡堂堂正正赢下巡回赛。", "jiang_zi": "厘清终端权限异常与巡回赛名录。"}
	var met := {"ye_zhou": true, "yang_zi_ying": GameState.story_flags.get("prologue_completed", false), "liu_yu_long": GameState.story_flags.get("school_gate_done", false), "jiang_zi": GameState.story_flags.get("school_affairs_done", false)}
	var index := 0
	for actor in snapshot["cast"]:
		if not met.get(actor["id"], false):
			continue
		var panel := _paper(canvas, "ActorNote_" + actor["id"], Vector2(288 + (index % 2) * 360, 278 + (index / 2) * 244), Vector2(342, 226))
		var portrait := _portrait(panel, actor["portrait"], Vector2(18, 32), Vector2(118, 164))
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_label(panel, "ActorName", actor["name"], 30, Vector2(152, 38), Vector2(168, 46))
		_label(panel, "ActorMotive", motives[actor["id"]], 24, Vector2(152, 104), Vector2(168, 104), false, DaylightUI.MUTED, true)
		index += 1

func _render_explore(canvas: Control) -> void:
	_label(canvas, "Title", "第一章 · 红月下的旧公园", 64, Vector2(144, 28), Vector2(772, 88), true)
	_label(canvas, "Subtitle", "日常战术刻印切磋与红月异变的起点。", 28, Vector2(90, 124), Vector2(860, 44), true, DaylightUI.MUTED)
	var close := _button(canvas, "CloseButton", "×", Vector2(926, 26), Vector2(64, 64), false)
	close.add_theme_font_size_override("font_size", 44)
	close.pressed.connect(func(): close_requested.emit())
	refs["close_button"] = close
	_scene_thumbnail(canvas, "ChapterWindow", "dusk_road", Vector2(50, 188), Vector2(940, 300))
	_label(canvas, "Synopsis", "黄秋枫的骤然告白与红月封锁交织，\n与三位同伴共同唤醒第一枚星座母卡。", 32, Vector2(64, 506), Vector2(912, 84), true, DaylightUI.INK, true)
	for index in snapshot["cast"].size():
		var actor: Dictionary = snapshot["cast"][index]
		var capsule := _paper(canvas, "ActorCapsule_" + actor["id"], Vector2(64 + index * 232, 602), Vector2(216, 60))
		_portrait(capsule, actor["portrait"], Vector2(14, 7), Vector2(46, 46))
		_label(capsule, "ActorName", actor["name"], 28, Vector2(76, 9), Vector2(124, 42), true)
	_label(canvas, "PreparedHeading", "随身卡牌", 32, Vector2(64, 672), Vector2(680, 42))
	var slots: Array[Button] = []
	for index in 5:
		var card_id: String = snapshot["equipped_ids"][index] if index < snapshot["equipped_ids"].size() else ""
		var info := _find_card(card_id)
		var slot := _button(canvas, "PreparedSlot%d" % index, "", Vector2(63 + index * 186, 720), Vector2(170, 165), false)
		slot.set_meta("card_id", card_id)
		if card_id != "":
			_card_art(slot, card_id, Vector2(35, 12), Vector2(100, 80))
			_label(slot, "CardName", info["name"], 24, Vector2(12, 96), Vector2(146, 36), true)
			_label(slot, "Cooldown", "冷却 %d" % info["cooldown"], 22, Vector2(12, 132), Vector2(146, 30), true, DaylightUI.MUTED)
			slot.pressed.connect(func(): request_action("select_card", {"card_id": card_id}))
		else:
			_label(slot, "EmptyPlus", "+", 64, Vector2(35, 20), Vector2(100, 80), true, DaylightUI.MUTED)
			_label(slot, "EmptyCaption", "空卡槽", 24, Vector2(12, 112), Vector2(146, 36), true, DaylightUI.MUTED)
			slot.disabled = true
		slots.append(slot)
	refs["prepared_slots"] = slots
	var later := _button(canvas, "LaterButton", "稍后", Vector2(64, 900), Vector2(220, 88), false)
	later.pressed.connect(func(): close_requested.emit())
	var start := _button(canvas, "StartButton", snapshot["chapter_action"], Vector2(650, 900), Vector2(330, 88), true)
	start.pressed.connect(func(): request_action("start_chapter", {"restart": snapshot["chapter_restart"]}))
	refs["start_button"] = start
	refs["later_button"] = later

func _scene_thumbnail(parent: Control, node_name: String, scene_key: String, position: Vector2, extent: Vector2, region: Rect2 = Rect2()) -> TextureRect:
	var thumbnail := TextureRect.new()
	thumbnail.name = node_name
	thumbnail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumbnail.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	thumbnail.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	thumbnail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var path := "res://assets/backgrounds/phase_two/" + scene_key + ".png"
	if ResourceLoader.exists(path):
		var texture := load(path) as Texture2D
		if region.size != Vector2.ZERO:
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = region
			atlas.filter_clip = true
			thumbnail.texture = atlas
		else:
			thumbnail.texture = texture
	_place(thumbnail, position, extent)
	parent.add_child(thumbnail)
	return thumbnail

func _card_art(parent: Control, card_id: String, position: Vector2, extent: Vector2) -> TextureRect:
	var art := TextureRect.new()
	art.name = "CardArt"
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var path := SceneSkin.card_illustration_path(card_id)
	var actual_extent := extent
	if ResourceLoader.exists(path):
		art.texture = SceneSkin.illustration_texture(path)
		var native_extent := Vector2(art.texture.get_width(), art.texture.get_height())
		var factor := minf(2.0, minf(extent.x / native_extent.x, extent.y / native_extent.y))
		actual_extent = native_extent * factor
	_place(art, position + (extent - actual_extent) / 2.0, actual_extent)
	parent.add_child(art)
	return art

func _detail_description(card_id: String) -> String:
	var card := GameState.get_card(card_id)
	if card == null:
		return ""
	match card.card_type:
		CardData.CardType.ATTACK:
			if card.burn_duration > 0:
				return "伤害 %d，压制 %d 回合。\n每回合追加 %d 点伤害。" % [card.get_scaled_damage(), card.burn_duration, card.get_scaled_burn_damage()]
			return "对单个目标造成 %d 点伤害。" % card.get_scaled_damage()
		CardData.CardType.DEFENSE: return "获得 %d 点护盾。\n持续 1 回合。" % card.get_scaled_shield()
		CardData.CardType.RECOVERY: return "恢复 %d 点体力。" % card.get_scaled_heal()
		CardData.CardType.DEBUFF: return "敌方全体伤害降低 %d%%。\n持续 %d 回合。" % [int(card.get_scaled_attack_down() * 100), card.debuff_duration]
		_: return "护盾 %d，受击反弹 %d 点。\n持续 1 回合。" % [card.get_scaled_shield(), card.get_scaled_reflect_damage()]

func _render_quest(canvas: Control) -> void:
	_label(canvas, "Title", "模拟训练", 64, Vector2(80, 40), Vector2(1040, 88))
	_label(canvas, "Subtitle", "选一条路线，带上行动卡出发。", 28, Vector2(80, 136), Vector2(1120, 44), false, DaylightUI.MUTED)
	var close := _button(canvas, "CloseButton", "×", Vector2(1232, 42), Vector2(64, 64), false)
	close.add_theme_font_size_override("font_size", 44)
	close.pressed.connect(func(): close_requested.emit())
	refs["close_button"] = close
	var exploration: Dictionary = snapshot.get("exploration", {})
	var materials: Dictionary = exploration.get("materials", {})
	var material_names: Dictionary = exploration.get("material_names", {"common": "普通材料", "fine": "精良材料", "rare": "稀有材料"})
	var dungeons: Array = snapshot.get("dungeons", [])
	var unfinished: bool = bool(exploration.get("active", false)) or bool(exploration.get("resume", false))
	var dungeon_buttons: Dictionary = {}
	var dungeon_cards: Dictionary = {}
	var material_labels: Dictionary = {}
	var state_names := {"ready": "可以出发", "locked": "尚未解锁", "running": "训练进行中", "paused": "训练已暂停", "completed": "上次训练已完成", "retreated": "上次已结束训练", "defeat": "上次挑战未完成"}
	for index in mini(3, dungeons.size()):
		var dungeon: Dictionary = dungeons[index]
		var dungeon_id: String = dungeon.get("id", "")
		var can_resume: bool = bool(dungeon.get("resume", false))
		var unlocked: bool = bool(dungeon.get("unlocked", false))
		var blocked_by_run: bool = unfinished and not can_resume
		var card_x := 72 + index * 416
		var paper := _paper(canvas, "Dungeon_" + dungeon_id, Vector2(card_x, 244), Vector2(384, 456))
		_label(paper, "DungeonTitle", str(dungeon.get("title", "校园路线")), 34, Vector2(24, 14), Vector2(336, 48), true)
		_label(paper, "DungeonDifficulty", str(dungeon.get("difficulty", "初阶")), 24, Vector2(24, 62), Vector2(336, 32), true, DaylightUI.ACCENT)
		_dungeon_preview(paper, index, Vector2(24, 100), Vector2(336, 140))
		_label(paper, "DungeonRewards", str(dungeon.get("reward_range", "")), 22, Vector2(24, 252), Vector2(336, 36), false, DaylightUI.MUTED)
		var status_copy: String = state_names.get(str(dungeon.get("status", "ready")), "可以出发")
		if not unlocked:
			status_copy = str(dungeon.get("lock_reason", "继续校园行程后解锁。"))
		elif blocked_by_run:
			status_copy = "请先继续当前训练，或在路线中结束训练。"
		_label(paper, "DungeonStatus", status_copy, 20, Vector2(24, 292), Vector2(336, 60), false, DaylightUI.ACCENT if can_resume else DaylightUI.MUTED, true)
		var button_copy := "继续训练" if can_resume else ("开始训练" if unlocked else "尚未解锁")
		var start := _button(paper, "DungeonStart_" + dungeon_id, button_copy, Vector2(27, 356), Vector2(330, 80), unlocked and not blocked_by_run)
		start.add_theme_font_size_override("font_size", 30)
		start.disabled = not unlocked or blocked_by_run
		start.pressed.connect(func(): request_action("start_exploration", {"dungeon_id": dungeon_id}))
		dungeon_buttons[dungeon_id] = start
		dungeon_cards[dungeon_id] = paper
		var quality: String = dungeon.get("reward_quality", ["common", "fine", "rare"][index])
		var material_copy := "%s  %d" % [str(material_names.get(quality, "材料")), int(materials.get(quality, 0))]
		material_labels[quality] = _label(canvas, "Material_" + quality, material_copy, 28, Vector2(card_x, 730), Vector2(384, 50), true, DaylightUI.MUTED)
	refs["dungeon_buttons"] = dungeon_buttons
	refs["dungeon_cards"] = dungeon_cards
	refs["material_labels"] = material_labels
	refs["exploration_snapshot"] = exploration
	if dungeons.is_empty():
		_label(canvas, "NoAvailableDungeon", "暂时没有可用路线。", 32, Vector2(80, 340), Vector2(1200, 84), true, DaylightUI.MUTED)
	var message: String = context.get("message", "")
	_label(canvas, "ExplorationFooter", message if message != "" else "训练与主线分别保存进度，随时可以回社团教室。", 24, Vector2(80, 810), Vector2(1200, 44), true, DaylightUI.MUTED)

func _dungeon_preview(parent: Control, index: int, position: Vector2, extent: Vector2) -> TextureRect:
	var preferred := "res://assets/backgrounds/phase_three/exploration_campus.png"
	var fallback := "res://assets/backgrounds/phase_two/%s.png" % ["morning_road", "school_gate", "dusk_road"][index]
	var source := preferred if ResourceLoader.exists(preferred) else fallback
	var preview := TextureRect.new()
	preview.name = "DungeonPreview"
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(source):
		preview.texture = load(source) as Texture2D
	_place(preview, position, extent)
	parent.add_child(preview)
	return preview

func _progress_dot(parent: Control, node_name: String, position: Vector2, diameter: int, fill: Color) -> Panel:
	var dot := Panel.new()
	dot.name = node_name
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shape := StyleBoxFlat.new()
	shape.bg_color = fill
	shape.border_color = Color("#B8ACC7")
	shape.set_border_width_all(1)
	shape.set_corner_radius_all(diameter / 2)
	dot.add_theme_stylebox_override("panel", shape)
	_place(dot, position, Vector2(diameter, diameter))
	parent.add_child(dot)
	return dot

func _campus_atmosphere(parent: Control, position: Vector2, extent: Vector2, opacity: float) -> TextureRect:
	var background := TextureRect.new()
	background.name = "CampusAtmosphere"
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var source_path := "res://assets/backgrounds/phase_two/school_gate.png"
	if ResourceLoader.exists(source_path):
		var atlas := AtlasTexture.new()
		atlas.atlas = load(source_path) as Texture2D
		atlas.region = Rect2(740, 110, 760, 650)
		atlas.filter_clip = true
		background.texture = atlas
	background.modulate = Color(1.0, 0.98, 0.96, opacity)
	_place(background, position, extent)
	parent.add_child(background)
	return background

func _render_workshop(canvas: Control) -> void:
	_header(canvas, "卡牌整理", "练习点 %d" % snapshot["practice_points"], 1370)
	var slot_buttons: Array[Button] = []
	for index in 5:
		var slot := EquipSlot.new()
		slot.name = "EquipSlot%d" % index
		slot.slot_index = index
		var card_id: String = snapshot["equipped_ids"][index] if index < snapshot["equipped_ids"].size() else ""
		slot.card_id = card_id
		var card_info := _find_card(card_id)
		slot.card_name = card_info.get("name", "空卡槽")
		_style_button(slot, false)
		_place(slot, Vector2(72 + index * 244, 132), Vector2(230, 160))
		canvas.add_child(slot)
		_label(slot, "SlotNumber", "%02d" % (index + 1), 26, Vector2(16, 12), Vector2(66, 36), false, DaylightUI.ACCENT)
		if card_id != "":
			_card_art(slot, card_id, Vector2(64, 18), Vector2(100, 80))
		else:
			_label(slot, "EmptyPlus", "+", 64, Vector2(64, 16), Vector2(100, 80), true, DaylightUI.MUTED)
		_label(slot, "CardName", slot.card_name, 28, Vector2(14, 108), Vector2(202, 40), true)
		if card_id != "":
			slot.pressed.connect(func(): request_action("select_card", {"card_id": card_id}))
		slot.move_requested.connect(func(from_index: int, to_index: int): request_action("move_card", {"from_index": from_index, "to_index": to_index}))
		slot_buttons.append(slot)
	refs["slot_buttons"] = slot_buttons
	_label(canvas, "LibraryHeading", "行动卡库", 36, Vector2(72, 310), Vector2(360, 48))
	_label(canvas, "LibraryHint", "选择一张，查看效果", 28, Vector2(410, 318), Vector2(390, 40), false, DaylightUI.MUTED)
	var scroll := ScrollContainer.new()
	scroll.name = "CardLibraryScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_place(scroll, Vector2(72, 362), Vector2(730, 520))
	canvas.add_child(scroll)
	scroll.set_deferred("scroll_vertical", _library_scroll_y)
	var grid := GridContainer.new()
	grid.name = "CardLibrary"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 28)
	grid.add_theme_constant_override("v_separation", 20)
	scroll.add_child(grid)
	var card_buttons: Dictionary = {}
	for info in snapshot["cards"]:
		var card := Button.new()
		card.name = "Library_" + info["id"]
		card.custom_minimum_size = Vector2(340, 245)
		_style_button(card, false)
		card.add_theme_stylebox_override("normal", SceneSkin.card_style())
		card.add_theme_stylebox_override("hover", SceneSkin.card_style(Color(1.015, 1.01, 1.025)))
		card.add_theme_stylebox_override("pressed", SceneSkin.card_style(Color(0.985, 0.975, 0.995)))
		grid.add_child(card)
		_label(card, "CardName", info["name"], 34, Vector2(85, 20), Vector2(220, 50))
		_card_art(card, info["id"], Vector2(50, 76), Vector2(240, 100))
		_label(card, "CardEffect", info["brief"], 24, Vector2(40, 174), Vector2(260, 34), false, DaylightUI.MUTED)
		_label(card, "CardStatus", "等级 %d · 冷却 %d" % [info["level"], info["cooldown"]], 24, Vector2(40, 207), Vector2(260, 30))
		card.pressed.connect(func(): request_action("select_card", {"card_id": info["id"]}))
		if info["id"] == selected_card_id:
			_selected_card_tint(card)
		card_buttons[info["id"]] = card
	refs["card_buttons"] = card_buttons
	refs["library_scroll"] = scroll
	var detail := _paper(canvas, "SelectedCardDetail", Vector2(890, 332), Vector2(410, 540))
	var selected: Dictionary = snapshot["selected_card"]
	if not selected.is_empty():
		_label(detail, "SelectedName", selected["name"], 38, Vector2(100, 16), Vector2(280, 56))
		_card_art(detail, selected["id"], Vector2(90, 80), Vector2(230, 110))
		_label(detail, "SelectedEffect", _detail_description(selected["id"]), 28, Vector2(30, 205), Vector2(350, 80), false, DaylightUI.MUTED, true)
		_label(detail, "SelectedStats", "等级 %d · 冷却 %d 回合" % [selected["level"], selected["cooldown"]], 26, Vector2(30, 286), Vector2(350, 38))
		_label(detail, "UpgradePreview", selected["preview"], 26, Vector2(30, 324), Vector2(350, 34), false, DaylightUI.ACCENT)
		var equip := _button(detail, "EquipButton", "卸下行动卡" if selected["equipped"] else "装备行动卡", Vector2(25, 358), Vector2(360, 74), false)
		equip.pressed.connect(func(): request_action("unequip" if selected["equipped"] else "equip", {"card_id": selected_card_id}))
		var upgrade := _button(detail, "UpgradeButton", "练习 · %d 点" % snapshot["upgrade_cost"] if int(selected["level"]) < int(selected["max_level"]) else "已达到最高等级", Vector2(25, 448), Vector2(360, 74), true)
		upgrade.disabled = not snapshot["can_upgrade"]
		upgrade.pressed.connect(func(): request_action("upgrade", {"card_id": selected_card_id}))
		refs["equip_button"] = equip
		refs["upgrade_button"] = upgrade
	var feedback: String = context.get("message", "")
	if feedback != "":
		_label(canvas, "Feedback", feedback, 28, Vector2(72, 900), Vector2(1230, 42), false, DaylightUI.ACCENT)

func _header(canvas: Control, title: String, subtitle: String, width: float) -> void:
	_label(canvas, "Title", title, 64, Vector2(170, 32), Vector2(440, 88))
	_label(canvas, "Subtitle", subtitle, 28, Vector2(560, 65), Vector2(width - 700, 42), false, DaylightUI.MUTED)
	var close := _button(canvas, "CloseButton", "×", Vector2(width - 128, 42), Vector2(64, 64), false)
	close.add_theme_font_size_override("font_size", 44)
	close.pressed.connect(func(): close_requested.emit())
	refs["close_button"] = close

func _selected_card_tint(card: Button) -> void:
	card.set_meta("selected", true)
	card.add_theme_stylebox_override("normal", SceneSkin.card_style(Color(0.95, 0.925, 0.985)))
	card.add_theme_stylebox_override("hover", SceneSkin.card_style(Color(0.975, 0.955, 1.0)))
	card.add_theme_stylebox_override("pressed", SceneSkin.card_style(Color(0.925, 0.90, 0.975)))
	SchoolObjectUI.set_selected(card,true)

func _find_card(card_id: String) -> Dictionary:
	for card in snapshot["cards"]:
		if card["id"] == card_id:
			return card
	return {}

func _paper(parent: Control, node_name: String, position: Vector2, extent: Vector2) -> Panel:
	var panel := Panel.new()
	panel.name = node_name
	panel.add_theme_stylebox_override("panel", SceneSkin.style("card_frame", Vector4.ZERO))
	_place(panel, position, extent)
	parent.add_child(panel)
	return panel

func _school_window(parent: Control, position: Vector2, extent: Vector2) -> TextureRect:
	var background := TextureRect.new()
	background.name = "SchoolWindow"
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var source_path := "res://assets/backgrounds/phase_two/school_room.png"
	if ResourceLoader.exists(source_path):
		var atlas := AtlasTexture.new()
		atlas.atlas = load(source_path) as Texture2D
		atlas.region = Rect2(60, 90, 520, 560)
		atlas.filter_clip = true
		background.texture = atlas
	background.modulate = Color(1.0, 0.98, 0.95, 0.82)
	_place(background, position, extent)
	parent.add_child(background)
	return background

func _portrait(parent: Control, image_path: String, position: Vector2, extent: Vector2) -> TextureRect:
	var texture := TextureRect.new()
	texture.name = "Portrait"
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if ResourceLoader.exists(image_path):
		texture.texture = load(image_path) as Texture2D
	_place(texture, position, extent)
	parent.add_child(texture)
	return texture

func _label(parent: Control, node_name: String, copy: String, font_size: int, position: Vector2, extent: Vector2, centered: bool = false, color: Color = DaylightUI.INK, wrap: bool = false) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = copy
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf") if font_size >= 38 else theme.default_font)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER if not wrap else VERTICAL_ALIGNMENT_TOP
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	label.clip_text = true
	_place(label, position, extent)
	parent.add_child(label)
	return label

func _button(parent: Control, node_name: String, copy: String, position: Vector2, extent: Vector2, primary: bool) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = copy
	_style_button(button, primary)
	if copy.strip_edges() in ["×","✕","✖","X"]: SchoolObjectUI.style_close_button(button)
	_place(button, position, extent)
	parent.add_child(button)
	return button

func _style_button(button: Button, primary: bool) -> void:
	button.theme_type_variation = &"PrimaryButton" if primary else &"SecondaryButton"
	button.add_theme_font_size_override("font_size", 34)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	DaylightUI.bind_button_feedback(button)
	button.add_theme_stylebox_override("normal", SceneSkin.style("button_primary" if primary else "button_secondary", Vector4(12, 8, 12, 8)))

func _place(control: Control, position: Vector2, extent: Vector2) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	control.position = position
	control.size = extent

class EquipSlot extends Button:
	signal move_requested(from_index: int, to_index: int)
	var slot_index: int = -1
	var card_id: String = ""
	var card_name: String = ""
	var drag_texture: Texture2D
	var drag_enabled: bool = true
	var deck_ids: Array = GameState.equipped_card_ids

	func _get_drag_data(_at_position: Vector2) -> Variant:
		if card_id == "" or disabled or not drag_enabled:
			return null
		var preview := TextureRect.new()
		preview.name = "DraggedCardIcon"
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.texture = drag_texture
		if preview.texture == null:
			var path := SceneSkin.card_illustration_path(card_id)
			if ResourceLoader.exists(path): preview.texture = SceneSkin.illustration_texture(path)
		preview.size = Vector2(104,86)
		preview.position = -preview.size * 0.5
		set_drag_preview(preview)
		return {"home_card_slot": slot_index, "card_id": card_id}

	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		if disabled or not drag_enabled or not data is Dictionary: return false
		var source := int(data.get("home_card_slot",-1))
		return data.has("card_id") and source >= 0 and source < deck_ids.size() and source != slot_index and str(data["card_id"]) == deck_ids[source]

	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		move_requested.emit(int(data["home_card_slot"]), slot_index)
