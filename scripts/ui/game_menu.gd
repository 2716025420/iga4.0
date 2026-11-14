class_name GameMenu
extends Control

signal close_requested

const DESIGN := Vector2(1920.0, 1080.0)
const INK := Color("#24303B")
const MUTED := Color("#49505A")

var page: String = "main"
var stage: Control
var shade: ColorRect
var content: Control
var settings_page: GameSettingsPage
var feedback: String = ""

func _ready() -> void:
	name = "GameMenu"
	theme = DaylightUI.get_theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	shade = ColorRect.new()
	shade.name = "MenuBackdrop"
	shade.color = Color(0.14, 0.16, 0.24, 0.52)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	shade.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			go_back()
	)

	stage = Control.new()
	stage.name = "MenuStage"
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.size = DESIGN
	add_child(stage)

	SchoolObjectUI.art(stage, "PencilTinArtwork", "res://assets/ui/school_objects/menu.png")
	var tin_input := Control.new()
	tin_input.name = "PencilTinInput"
	tin_input.mouse_filter = Control.MOUSE_FILTER_STOP
	stage.add_child(tin_input)
	DaylightUI.place(tin_input, 875, 72, 1015, 965)

	resized.connect(_layout)
	Platform.input_mode_changed.connect(_on_input_mode_changed)
	_layout()
	_render_main()

func _layout() -> void:
	if not is_instance_valid(stage):
		return
	var extent := size
	if extent.x <= 0.0 or extent.y <= 0.0:
		extent = get_viewport_rect().size
	if extent.x <= 0.0 or extent.y <= 0.0:
		extent = DESIGN
	var factor := minf(extent.x / DESIGN.x, extent.y / DESIGN.y)
	stage.scale = Vector2.ONE * factor
	stage.position = (extent - DESIGN * factor) / 2.0

func _on_input_mode_changed(_touch: bool) -> void:
	if page == "help" and is_instance_valid(content) and stage.visible:
		_render_help()

func _clear(next_page: String, heading: String, copy: String) -> void:
	page = next_page
	if is_instance_valid(content):
		stage.remove_child(content)
		content.queue_free()
	content = Control.new()
	content.name = "MenuContent"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(content)
	DaylightUI.place(content, 0, 0, DESIGN.x, DESIGN.y)
	if next_page != "main":
		SchoolObjectUI.slab(content, "PageInterior", Rect2(932, 433, 750, 523), Color("#F2E9DF"))
	SchoolObjectUI.text(content, "Heading", heading, Rect2(1105, 178, 450, 106), 58)
	var caption := SchoolObjectUI.text(content, "Caption", copy, Rect2(1108, 300, 430, 72), 25, SchoolObjectUI.MUTED)
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var close := SchoolObjectUI.hit(content, "CloseButton", Rect2(1755, 133, 66, 66), "×", 46)
	close.pressed.connect(go_back)
	SchoolObjectUI.text(content, "MenuFeedback", feedback, Rect2(1180, 902, 470, 36), 22, SchoolObjectUI.PURPLE, true)
	_apply_borderless_buttons.call_deferred(content)

func _apply_borderless_buttons(target: Control) -> void:
	if not is_instance_valid(target) or target != content:
		return
	for button in target.find_children("*", "Button", true, false):
		SchoolObjectUI.borderless(button)

func _style_pill(button: Button, fill: Color, text_color: Color = INK, border_color: Color = Color("#D4C6B4")) -> void:
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = fill
		if state == "hover":
			box.bg_color = fill.lightened(0.06) if fill.get_luminance() < 0.5 else fill.darkened(0.05)
		elif state in ["pressed", "hover_pressed"]:
			box.bg_color = fill.darkened(0.10)
		elif state == "disabled":
			box.bg_color = Color("#DCD5C7")
		box.border_color = border_color
		box.set_border_width_all(1 if state != "disabled" else 0)
		box.set_corner_radius_all(9)
		button.add_theme_stylebox_override(state, box)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(key, text_color)
	button.add_theme_color_override("font_disabled_color", Color("#707680"))

func _render_main() -> void:
	_clear("main", "片刻休息", "收好今天的进度，\n再慢慢出发。")
	var items := [
		["resume", "继续游戏", "返回放学后的教室"],
		["save", "保存进度", "记录到手动存档"],
		["load", "读取存档", "回到记下的那一刻"],
		["settings", "游戏设置", "声音、显示与阅读"],
		["help", "操作说明", "查看操控与基本规则"],
		["title", "返回标题", "保存自动进度后返回"],
		["quit", "退出游戏", "保存自动进度后退出"]
	]
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
	if SceneManager.is_transitioning:
		return
	match action:
		"resume":
			close_requested.emit()
		"save", "load":
			_render_slots(action)
		"settings":
			_open_settings()
		"help":
			_render_help()
		"title":
			_confirm("返回标题？", "当前进度会先自动保存。手动存档仍可在菜单中读取。", _return_title)
		"quit":
			_confirm("保存并退出？", "下次可以从标题页继续，也可以读取手动存档。", _quit_game)

func _render_slots(mode: String) -> void:
	_clear(mode, "保存进度" if mode == "save" else "读取存档", "手动存档独立保留。\n自动进度不会覆盖它们。" if mode == "save" else "手动存档独立保留。\n含内置全解锁测试存档。")
	var slot_actions: Array[Button] = []
	if mode == "load":
		var test_paper := SchoolObjectUI.slab(content, "Slot_Test", Rect2(951, 398, 707, 104), Color("#F6EED9"))
		var test_style := test_paper.get_theme_stylebox("panel") as StyleBoxFlat
		if test_style != null:
			test_style.border_color = Color("#C8B38E")
			test_style.set_border_width_all(1)
			test_style.set_corner_radius_all(10)
		NotebookUI.icon(test_paper, "load", Vector2(24, 16))
		NotebookUI.label(test_paper, "Title", "常驻测试存档（全解锁）", Vector2(80, 10), Vector2(420, 38), 27)
		NotebookUI.label(test_paper, "Metadata", "第3日 · 六地区 / 全卡组 / 测试星座 / 视差回看", Vector2(28, 50), Vector2(490, 44), 21, NotebookUI.MUTED)
		var test_action := SchoolObjectUI.hit(test_paper, "SlotAction", Rect2(536, 18, 144, 68), "读取", 27)
		_style_pill(test_action, Color("#5C7861"), Color("#FFFDF8"), Color("#4B6450"))
		test_action.pressed.connect(func(): _confirm("读取常驻测试存档？", "当前进度会先自动保存（预览测试存档本身不会覆盖个人进度），然后载入全解锁测试状态。", _load_test_slot))
		slot_actions.append(test_action)
	for slot in range(1, 4):
		var metadata: Dictionary = SaveManager.get_save_metadata(SaveManager.manual_slot_path(slot))
		var card_rect := Rect2(951, 398 + slot * 116, 707, 104) if mode == "load" else Rect2(951, 446 + (slot - 1) * 144, 707, 130)
		var paper := SchoolObjectUI.slab(content, "Slot_%d" % slot, card_rect, Color("#FBF6EC"))
		var card_style := paper.get_theme_stylebox("panel") as StyleBoxFlat
		if card_style != null:
			card_style.border_color = Color("#D6C8B4")
			card_style.set_border_width_all(1)
			card_style.set_corner_radius_all(10)
		NotebookUI.icon(paper, "save" if mode == "save" else "load", Vector2(24, 16 if mode == "load" else 24))
		NotebookUI.label(paper, "Title", "手动存档 %02d" % slot, Vector2(80, 10 if mode == "load" else 12), Vector2(390, 38 if mode == "load" else 44), 27 if mode == "load" else 30)
		NotebookUI.label(paper, "Metadata", NotebookUI.saved_copy(metadata), Vector2(28, 50 if mode == "load" else 58), Vector2(480, 44 if mode == "load" else 64), 21 if mode == "load" else 23, NotebookUI.MUTED)
		var action := SchoolObjectUI.hit(paper, "SlotAction", Rect2(536, 18 if mode == "load" else 31, 144, 68), ("覆盖" if metadata["available"] else "保存") if mode == "save" else "读取", 27 if mode == "load" else 28)
		action.disabled = mode == "load" and not metadata["available"]
		_style_pill(action, Color("#5C7861"), Color("#FFFDF8"), Color("#4B6450"))
		action.pressed.connect(func():
			if mode == "save":
				if metadata["available"]:
					_confirm("覆盖手动存档 %02d？" % slot, "覆盖前会保留一份备份。其他存档不会受到影响。", _save_slot.bind(slot))
				else:
					_save_slot(slot)
			else:
				_confirm("读取手动存档 %02d？" % slot, "当前进度会先自动保存，然后从所选记录继续。", _load_slot.bind(slot))
		)
		slot_actions.append(action)

	var back := SchoolObjectUI.hit(content, "BackToMenu", Rect2(952, 888, 210, 56), "‹  返回菜单", 26)
	_style_pill(back, Color("#EFE6D5"), INK, Color("#D4C6B4"))
	back.pressed.connect(_render_main)

	var enabled_buttons: Array[Button] = []
	for btn in slot_actions:
		if not btn.disabled:
			enabled_buttons.append(btn)
	enabled_buttons.append(back)
	for i in enabled_buttons.size():
		var cur := enabled_buttons[i]
		var prev := enabled_buttons[posmod(i - 1, enabled_buttons.size())]
		var nxt := enabled_buttons[(i + 1) % enabled_buttons.size()]
		cur.focus_neighbor_top = cur.get_path_to(prev)
		cur.focus_neighbor_bottom = cur.get_path_to(nxt)
		cur.focus_previous = cur.get_path_to(prev)
		cur.focus_next = cur.get_path_to(nxt)
	enabled_buttons[0].grab_focus()

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
	if not SaveManager.active_session or SaveManager.save_game():
		get_tree().quit()
	else:
		feedback = SaveManager.last_error
		_render_main()

func _load_test_slot() -> void:
	if not SaveManager.save_game():
		feedback = SaveManager.last_error
		_render_slots("load")
		return
	if SaveManager.load_test_save():
		CampusLife.restore_saved_location()
	else:
		feedback = SaveManager.last_error
		_render_slots("load")

func _open_settings() -> void:
	shade.visible = false
	stage.visible = false
	settings_page = GameSettingsPage.new()
	add_child(settings_page)
	settings_page.close_requested.connect(func():
		remove_child(settings_page)
		settings_page.queue_free()
		settings_page = null
		shade.visible = true
		stage.visible = true
		_render_main()
	)

func _confirm(heading: String, copy: String, callback: Callable) -> void:
	var previous := page
	_clear("confirm_" + previous, heading, "")
	var explanation := SchoolObjectUI.text(content, "ConfirmationCopy", copy, Rect2(972, 490, 668, 240), 30)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var cancel := SchoolObjectUI.hit(content, "CancelAction", Rect2(972, 836, 280, 78), "取消", 30)
	_style_pill(cancel, Color("#EFE6D5"), INK, Color("#D4C6B4"))
	cancel.pressed.connect(go_back)
	var confirm := SchoolObjectUI.hit(content, "ConfirmAction", Rect2(1360, 836, 280, 78), "确认", 30)
	_style_pill(confirm, Color("#D66B5A"), Color("#FFFDF8"), Color("#B95343"))
	confirm.pressed.connect(callback)
	cancel.focus_neighbor_right = cancel.get_path_to(confirm)
	confirm.focus_neighbor_left = confirm.get_path_to(cancel)
	cancel.grab_focus()

func _render_help() -> void:
	_clear("help", "操作说明", "随时停下来，整理好下一步。")
	var pc_help := "Esc   打开菜单 / 返回上一层\nE       在教室打开卡牌整理\n\n行动卡：点击或按键选择可用卡牌执行行动。\n多名对手：先点击要应对的目标。\n结束回合：对手行动，卡牌推进冷却。\n\n进度会在关键行动后自动保存。\n手动存档适合保留重要的分支或阶段。\n训练路线暂离后，可从校园体育馆继续；战斗中选择逃跑会直接判负。"
	var touch_help := "菜单：点击右上「菜单」或使用系统返回键返回\n教室整理：点击桌面蓝皮卡盒整理卡组，橙色幻灯片盒看档案\n\n行动卡：点选卡牌确认效果后打出执行行动。\n多名对手：先点选需要应对的对手目标。\n结束回合：对手开始行动，卡牌推进冷却。\n\n进度会在关键行动后自动保存，手动存档可保留重要分支。\n训练路线暂离后，可从校园体育馆继续；战斗逃跑会直接判负。"
	var copy_box := RichTextLabel.new()
	copy_box.name = "HelpCopy"
	copy_box.bbcode_enabled = false
	copy_box.fit_content = false
	copy_box.scroll_active = true
	copy_box.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy_box.text = Platform.hint(pc_help, touch_help)
	copy_box.add_theme_font_size_override("normal_font_size", 24)
	copy_box.add_theme_color_override("default_color", INK)
	copy_box.add_theme_constant_override("line_separation", 8)
	copy_box.mouse_filter = Control.MOUSE_FILTER_PASS
	content.add_child(copy_box)
	DaylightUI.place(copy_box, 964, 456, 686, 412)
	var back := SchoolObjectUI.hit(content, "BackToMenu", Rect2(952, 888, 210, 56), "‹  返回菜单", 26)
	_style_pill(back, Color("#EFE6D5"), INK, Color("#D4C6B4"))
	back.pressed.connect(_render_main)
	back.grab_focus()

func go_back() -> void:
	if SceneManager.is_transitioning:
		return
	if is_instance_valid(settings_page):
		settings_page.request_close()
	elif page.begins_with("confirm_"):
		var previous := page.trim_prefix("confirm_")
		if previous in ["save", "load"]:
			_render_slots(previous)
		else:
			_render_main()
	elif page == "main":
		close_requested.emit()
	else:
		_render_main()
