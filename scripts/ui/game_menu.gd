class_name GameMenu
extends Control

signal close_requested
var page: String = "main"
var content: Control
var settings_page: GameSettingsPage
var feedback: String = ""

func _ready() -> void:
	name = "GameMenu"
	theme = DaylightUI.get_theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	DaylightUI.place(self, 0, 0, 1920, 1080)
	var shade := ColorRect.new()
	shade.name = "MenuBackdrop"
	shade.color = Color(0.14, 0.16, 0.24, 0.50)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	DaylightUI.place(shade, 0, 0, 1920, 1080)
	shade.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed: go_back()
	)
	SchoolObjectUI.art(self, "PencilTinArtwork", "res://assets/ui/school_objects/menu.png")
	var tin_input := Control.new()
	tin_input.name = "PencilTinInput"
	tin_input.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(tin_input)
	DaylightUI.place(tin_input, 875, 72, 1015, 965)
	_render_main()

func _clear(next_page: String, heading: String, copy: String) -> void:
	page = next_page
	if is_instance_valid(content):
		remove_child(content)
		content.queue_free()
	content = Control.new()
	content.name = "MenuContent"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)
	DaylightUI.place(content, 0, 0, 1920, 1080)
	if next_page != "main": SchoolObjectUI.slab(content, "PageInterior", Rect2(932, 433, 750, 523), Color("#F2E9DF"))
	SchoolObjectUI.text(content, "Heading", heading, Rect2(1105, 178, 450, 106), 58)
	var caption := SchoolObjectUI.text(content, "Caption", copy, Rect2(1108, 300, 430, 72), 25, SchoolObjectUI.MUTED)
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var close := SchoolObjectUI.hit(content, "CloseButton", Rect2(1755, 133, 66, 66), "×", 46)
	close.pressed.connect(go_back)
	SchoolObjectUI.text(content, "MenuFeedback", feedback, Rect2(1000, 938, 650, 36), 23, SchoolObjectUI.PURPLE, true)
	# Every menu page creates its own buttons. Hide focus outlines on each refresh.
	_apply_borderless_buttons.call_deferred(content)

func _apply_borderless_buttons(target: Control) -> void:
	if not is_instance_valid(target) or target != content: return
	for button in target.find_children("*", "Button", true, false):
		SchoolObjectUI.borderless(button)

func _render_main() -> void:
	_clear("main", "片刻休息", "收好今天的进度，\n再慢慢出发。")
	var items := [["resume", "继续游戏", "返回放学后的教室"], ["save", "保存进度", "记录到手动存档"], ["load", "读取存档", "回到记下的那一刻"], ["settings", "游戏设置", "声音、显示与阅读"], ["help", "操作说明", "查看快捷键与基本规则"], ["title", "返回标题", "保存自动进度后返回"], ["quit", "退出游戏", "保存自动进度后退出"]]
	for index in items.size():
		var item: Array = items[index]
		var rect := Rect2(945, 453, 726, 125) if index == 0 else Rect2(943 + ((index - 1) % 2) * 371, 604 + ((index - 1) / 2) * 112, 351, 96)
		var row := SchoolObjectUI.hit(content, "Menu_" + str(item[0]), rect)
		SchoolObjectUI.borderless(row)
		var hover_wash := StyleBoxFlat.new()
		hover_wash.bg_color = Color(0.34, 0.46, 0.67, 0.35)
		hover_wash.set_corner_radius_all(13)
		row.add_theme_stylebox_override("hover", hover_wash)
		var pressed_wash := hover_wash.duplicate() as StyleBoxFlat
		pressed_wash.bg_color = Color(0.28, 0.38, 0.58, 0.45)
		row.add_theme_stylebox_override("pressed", pressed_wash)
		row.add_theme_stylebox_override("hover_pressed", pressed_wash.duplicate())
		NotebookUI.icon(row, str(item[0]), Vector2(48, 31) if index == 0 else Vector2(24, 25), Vector2(58, 58) if index == 0 else Vector2(42, 42))
		SchoolObjectUI.text(row, "Name", str(item[1]), Rect2(160, 20, 425, 80) if index == 0 else Rect2(87, 16, 232, 64), 46 if index == 0 else 32)
		row.pressed.connect(_activate.bind(str(item[0])))
	_wire_main_focus()
	content.get_node("Menu_resume").grab_focus()
func _wire_main_focus() -> void:
	# Use logical rows: the broad resume button makes spatial guessing ambiguous.
	var graph := {
		"resume": ["resume", "resume", "close", "save"],
		"save": ["save", "load", "resume", "settings"],
		"load": ["save", "load", "resume", "help"],
		"settings": ["settings", "help", "save", "title"],
		"help": ["settings", "help", "load", "quit"],
		"title": ["title", "quit", "settings", "title"],
		"quit": ["title", "quit", "help", "quit"],
		"close": ["resume", "close", "close", "resume"]
	}
	var order := ["resume", "save", "load", "settings", "help", "title", "quit", "close"]
	for index in order.size():
		var key: String = order[index]
		var button := content.get_node("CloseButton" if key == "close" else "Menu_" + key) as Button
		var directions: Array = graph[key]
		var paths: Array[NodePath] = []
		for target in directions:
			paths.append(button.get_path_to(content.get_node("CloseButton" if target == "close" else "Menu_" + target)))
		button.focus_neighbor_left = paths[0]
		button.focus_neighbor_right = paths[1]
		button.focus_neighbor_top = paths[2]
		button.focus_neighbor_bottom = paths[3]
		for pair in [["focus_next", order[(index + 1) % order.size()]], ["focus_previous", order[posmod(index - 1, order.size())]]]:
			button.set(pair[0], button.get_path_to(content.get_node("CloseButton" if pair[1] == "close" else "Menu_" + pair[1])))



func _activate(action: String) -> void:
	if SceneManager.is_transitioning: return
	match action:
		"resume": close_requested.emit()
		"save", "load": _render_slots(action)
		"settings": _open_settings()
		"help": _render_help()
		"title": _confirm("返回标题？", "当前进度会先自动保存。手动存档仍可在菜单中读取。", _return_title)
		"quit": _confirm("保存并退出？", "下次可以从标题页继续，也可以读取手动存档。", _quit_game)

func _render_slots(mode: String) -> void:
	_clear(mode, "保存进度" if mode == "save" else "读取存档", "手动存档独立保留。\n自动进度不会覆盖它们。")
	for slot in range(1, 4):
		var metadata: Dictionary = SaveManager.get_save_metadata(SaveManager.manual_slot_path(slot))
		var paper := SchoolObjectUI.slab(content, "Slot_%d" % slot, Rect2(951, 449 + (slot - 1) * 148, 707, 130), Color("#F9F4EC"))
		NotebookUI.icon(paper, "save" if mode == "save" else "load", Vector2(24, 24))
		NotebookUI.label(paper, "Title", "手动存档 %02d" % slot, Vector2(80, 12), Vector2(390, 44), 30)
		NotebookUI.label(paper, "Metadata", NotebookUI.saved_copy(metadata), Vector2(28, 58), Vector2(480, 64), 23, NotebookUI.MUTED)
		SchoolObjectUI.slab(paper, "ActionColor", Rect2(539, 34, 140, 68), Color("#DDD8ED"))
		var action := SchoolObjectUI.hit(paper, "SlotAction", Rect2(539, 34, 140, 68), ("覆盖" if metadata["available"] else "保存") if mode == "save" else "读取", 30)
		action.disabled = mode == "load" and not metadata["available"]
		action.pressed.connect(func():
			if mode == "save":
				if metadata["available"]: _confirm("覆盖手动存档 %02d？" % slot, "覆盖前会保留一份备份。其他存档不会受到影响。", _save_slot.bind(slot))
				else: _save_slot(slot)
			else: _confirm("读取手动存档 %02d？" % slot, "当前进度会先自动保存，然后从所选记录继续。", _load_slot.bind(slot))
		)
	SchoolObjectUI.hit(content, "BackToMenu", Rect2(960, 900, 260, 54), "返回菜单", 28).pressed.connect(_render_main)

func _save_slot(slot: int) -> void:
	feedback = "手动存档 %02d 已保存。" % slot if SaveManager.save_manual_slot(slot) else SaveManager.last_error
	_render_slots("save")

func _load_slot(slot: int) -> void:
	if not SaveManager.save_game():
		feedback = SaveManager.last_error
		_render_slots("load")
		return
	if SaveManager.load_manual_slot(slot):
		CampusLife.restore_saved_location()
	else:
		feedback = SaveManager.last_error
		_render_slots("load")

func _return_title() -> void:
	# Editor previews have no active save session; returning must still work.
	if SaveManager.active_session and not SaveManager.save_game():
		feedback = SaveManager.last_error
		_render_main()
		return
	SaveManager.active_session = false
	SceneManager.change_scene(SceneManager.TargetScene.TITLE)

func _quit_game() -> void:
	if not SaveManager.active_session or SaveManager.save_game(): get_tree().quit()
	else:
		feedback = SaveManager.last_error
		_render_main()

func _open_settings() -> void:
	content.visible = false
	settings_page = GameSettingsPage.new()
	add_child(settings_page)
	settings_page.close_requested.connect(func():
		remove_child(settings_page)
		settings_page.queue_free()
		settings_page = null
		_render_main()
	)

func _confirm(heading: String, copy: String, callback: Callable) -> void:
	var previous := page
	_clear("confirm_" + previous, heading, "")
	var explanation := SchoolObjectUI.text(content, "ConfirmationCopy", copy, Rect2(985, 500, 640, 250), 32)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	SchoolObjectUI.slab(content, "ConfirmColor", Rect2(1358, 836, 265, 80), Color("#DAD2E9"))
	SchoolObjectUI.hit(content, "ConfirmAction", Rect2(1358, 836, 265, 80), "确认", 32).pressed.connect(callback)
	var cancel := SchoolObjectUI.hit(content, "CancelAction", Rect2(985, 836, 265, 80), "取消", 32)
	cancel.pressed.connect(go_back)
	cancel.grab_focus()

func _render_help() -> void:
	_clear("help", "操作说明", "随时停下来，整理好下一步。")
	var help := "Esc   打开菜单 / 返回上一层\nE      在教室打开卡牌整理\n\n行动卡：点击可用卡牌执行行动。\n多名对手：先点击要应对的目标。\n结束回合：对手行动，卡牌推进冷却。\n\n进度会在关键行动后自动保存。\n手动存档适合保留重要的分支或阶段。\n训练路线暂离后，可以从校园体育馆继续。战斗中选择逃跑会直接判负。"
	SchoolObjectUI.text(content, "HelpCopy", help, Rect2(980, 460, 650, 414), 27)
	SchoolObjectUI.hit(content, "BackToMenu", Rect2(980, 898, 285, 54), "返回菜单", 28).pressed.connect(_render_main)

func go_back() -> void:
	if SceneManager.is_transitioning: return
	if is_instance_valid(settings_page):
		settings_page.request_close()
	elif page.begins_with("confirm_"):
		var previous := page.trim_prefix("confirm_")
		if previous in ["save", "load"]: _render_slots(previous)
		else: _render_main()
	elif page == "main": close_requested.emit()
	else: _render_main()
