class_name CampusGuidePanel
extends Control

signal close_requested
signal action_requested(action: String, payload: Dictionary)
const TINTS: Array[Color] = [Color("#DFB2A1"), Color("#C5CDB8"), Color("#BCD0D8")]
var context: Dictionary = {}
var snapshot: Dictionary = {}
var refs: Dictionary = {}
var selected_dungeon_id := ""

static func create(kind: String, panel_context: Dictionary = {}) -> CampusGuidePanel:
	if kind != "quest": return null
	var panel := CampusGuidePanel.new()
	panel.refresh(panel_context)
	return panel

func refresh(panel_context: Dictionary = {}) -> void:
	context.merge(panel_context, true)
	snapshot = HomePanels.content_snapshot("quest")
	var exploration: Dictionary = snapshot["exploration"]
	var dungeons: Array = snapshot["dungeons"]
	if selected_dungeon_id == "":
		selected_dungeon_id = str(exploration.get("state", {}).get("dungeon_id", "")) if exploration.get("resume", false) else ""
	if not dungeons.any(func(item: Dictionary): return item["id"] == selected_dungeon_id):
		selected_dungeon_id = str(dungeons[0]["id"]) if not dungeons.is_empty() else ""
	for child in get_children():
		remove_child(child)
		child.queue_free()
	refs.clear()
	size = SchoolObjectUI.DESIGN
	theme = DaylightUI.get_theme()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_meta("full_scene_overlay", true)
	set_meta("design_size", SchoolObjectUI.DESIGN)
	var ticket_well := ColorRect.new()
	ticket_well.name = "TicketWellBacking"
	ticket_well.color = Color("#DDD3BE")
	ticket_well.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ticket_well)
	DaylightUI.place(ticket_well, 1172, 256, 704, 592)
	SchoolObjectUI.art(self, "GuideBacking", "res://assets/ui/school_objects/campus_guide_warm.png")
	for label in [["TeachingBlock", "教学楼", Rect2(690, 447, 135, 42)], ["Library", "图书馆", Rect2(1000, 504, 125, 42)], ["Field", "操场", Rect2(950, 331, 120, 42)], ["Gate", "校门", Rect2(864, 674, 120, 42)]]:
		SchoolPaperSurface.create(self, str(label[0]) + "Slip", label[2], Color("#F9F3E5"))
		SchoolObjectUI.text(self, str(label[0]), str(label[1]), label[2], 25, SchoolObjectUI.INK, true)
	var catcher := Control.new()
	catcher.name = "GuideInput"
	catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(catcher)
	DaylightUI.place(catcher, 420, 65, 1485, 970)
	SchoolObjectUI.text(self, "Title", "模拟训练", Rect2(506, 120, 270, 72), 50)
	SchoolObjectUI.text(self, "Subtitle", "体育馆 · 选一条路线，带上行动卡出发。", Rect2(506, 194, 650, 40), 25, SchoolObjectUI.MUTED)
	var close := SchoolObjectUI.hit(self, "CloseButton", Rect2(1782, 150, 92, 50), "×", 34)
	SchoolObjectUI.borderless(close)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]: close.add_theme_color_override(state, SchoolObjectUI.INK)
	close.pressed.connect(func(): close_requested.emit())
	refs["close_button"] = close
	var tickets: Dictionary = {}
	var selected: Dictionary = {}
	for index in dungeons.size():
		var dungeon: Dictionary = dungeons[index]
		var id: String = dungeon["id"]
		if id == selected_dungeon_id: selected = dungeon
		var ticket := Control.new()
		ticket.name = "Ticket_" + id
		ticket.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(ticket)
		DaylightUI.place(ticket, 1185, 268 + index * 190, 675, 180)
		SchoolObjectUI.art(ticket, "TicketBase", "res://assets/ui/school_objects/campus_ticket_warm.png", Rect2(-15, -42, 705, 264))
		var tint: Color = TINTS[index % TINTS.size()]
		SchoolPaperSurface.create(ticket, "TierTab", Rect2(24, 20, 72, 137), tint)
		SchoolObjectUI.text(ticket, "Tier", str(dungeon["difficulty"]), Rect2(25, 56, 70, 46), 23, SchoolObjectUI.INK, true)
		SchoolObjectUI.text(ticket, "Name", str(dungeon["title"]), Rect2(130, 20, 510, 56), 36)
		SchoolObjectUI.text(ticket, "Reward", str(dungeon["reward_range"]), Rect2(130, 80, 510, 35), 24, SchoolObjectUI.MUTED)
		var status := "可以出发" if dungeon["unlocked"] else str(dungeon["lock_reason"])
		if dungeon.get("resume", false): status = "上次暂离的路线 · 可以继续"
		elif exploration.get("resume", false) and dungeon["unlocked"]: status = "请先继续或结束当前训练"
		SchoolObjectUI.text(ticket, "Status", status, Rect2(130, 122, 510, 33), 22, Color("#8F4A3B"))
		var choose := SchoolObjectUI.hit(ticket, "Choose", Rect2(4, 4, 664, 168))
		SchoolObjectUI.borderless(choose)
		if id == selected_dungeon_id:
			var sel := StyleBoxFlat.new()
			sel.bg_color = Color(0.73, 0.42, 0.35, 0.08)
			sel.border_color = Color("#BA6A58")
			sel.set_border_width_all(2)
			sel.set_corner_radius_all(8)
			choose.add_theme_stylebox_override("normal", sel)
		SchoolObjectUI.set_selected(choose,id == selected_dungeon_id)
		choose.pressed.connect(_select.bind(id))
		tickets[id] = choose
	refs["dungeon_buttons"] = tickets
	var names: Dictionary = exploration.get("material_names", {})
	var materials: Dictionary = exploration.get("materials", {})
	var counters: Dictionary = {}
	for index in 3:
		var quality: String = ["common", "fine", "rare"][index]
		counters[quality] = SchoolObjectUI.text(self, "Material_" + quality, "%s  %d" % [str(names.get(quality, quality)).trim_suffix("材料"), int(materials.get(quality, 0))], Rect2(485 + index * 210, 822, 195, 42), 24, SchoolObjectUI.MUTED, true)
	refs["material_labels"] = counters
	var resume: bool = bool(selected.get("resume", false))
	var blocked: bool = exploration.get("resume", false) and not resume
	var ready: bool = selected.get("unlocked", false) and not blocked and (resume or bool(PlayerJourney.deck_summary()["ready"])) and (resume or DayCycle.can_act()) and not DayCycle.has_story()
	var description: String = str(selected.get("description", "选择一张通行票，看看这条路。"))
	if resume: description = "接着上次的脚步出发，已完成 %d 段路线。" % exploration.get("state", {}).get("visited", []).size()
	elif blocked: description = "先继续当前训练，或在路线中选择结束训练。"
	elif not selected.get("unlocked", false): description = str(selected.get("lock_reason", "继续行程后开放。"))
	elif not PlayerJourney.deck_summary()["ready"]: description = str(PlayerJourney.deck_summary()["reason"])
	elif not DayCycle.can_act(): description = DayCycle.block_reason()
	var detail := SchoolObjectUI.text(self, "RouteDescription", description, Rect2(485, 872, 740, 74), 25)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var message := str(context.get("message", ""))
	SchoolObjectUI.text(self, "GuideFooter", message if message != "" else "新训练消耗一次活动，继续不重复消耗；战斗逃跑判负。", Rect2(485, 952, 740, 38), 21, SchoolObjectUI.MUTED)
	var start := SchoolObjectUI.hit(self, "DepartureButton", Rect2(1280, 865, 550, 130), "继续训练" if resume else "开始训练", 42)
	SchoolObjectUI.borderless(start)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]: start.add_theme_color_override(state, Color("#FFF9EC"))
	start.disabled = not ready
	start.pressed.connect(func():
		if not SceneManager.is_transitioning: action_requested.emit("start_exploration", {"dungeon_id": selected_dungeon_id})
	)
	refs["start_button"] = start
	refs["exploration_snapshot"] = exploration
	var choices: Array = tickets.values()
	for index in choices.size():
		var choice: Button = choices[index]
		choice.focus_neighbor_top = choice.get_path_to(close if index == 0 else choices[index - 1])
		choice.focus_neighbor_bottom = choice.get_path_to(start if index == choices.size() - 1 and ready else choices[mini(index + 1, choices.size() - 1)])
		choice.focus_neighbor_right = choice.get_path_to(start if ready else choice)
	close.focus_neighbor_bottom = close.get_path_to(tickets[selected_dungeon_id]) if tickets.has(selected_dungeon_id) else NodePath(".")
	if tickets.has(selected_dungeon_id):
		start.focus_neighbor_top = start.get_path_to(tickets[selected_dungeon_id])
		start.focus_neighbor_left = start.focus_neighbor_top

func _select(dungeon_id: String) -> void:
	if SceneManager.is_transitioning: return
	selected_dungeon_id = dungeon_id
	refresh()
	var selected := refs["dungeon_buttons"].get(dungeon_id) as Button
	if is_instance_valid(selected): selected.grab_focus.call_deferred()
