class_name SceneHUDLayout
extends Control

## Unified 03-style functional scene HUD:
## - Left vertical action dock with PeriodDial + remaining action pips + layered action buttons
## - Top-right resource capsule (HP / Practice Points / Allowance) + Map + Menu
## - Stage minimal NPC bubbles + bottom single-line hover preview strip

signal map_requested
signal menu_requested
signal back_requested

const DESIGN := Vector2(1920.0, 1080.0)
const DOCK_WIDTH := 356.0
const TEAL := Color("#359686")
const CORAL := Color("#D45B49")
const AMBER := Color("#D48A30")
const SLATE_BLUE := Color("#4C75A6")
const NAVY_INK := Color("#1E314D")
const IVORY := Color("#FFFDF8")
const NIGHT_PANEL := Color(0.11, 0.15, 0.25, 0.92)
const NIGHT_CARD := Color(0.17, 0.22, 0.35, 0.95)
const NIGHT_INK := Color("#F2F6FD")

var location_id := ""
var location_title := ""
var back_copy_text := "← 返回地图"
var dock_panel: Control
var dock_backing: Panel
var period_dial: PeriodDial
var title_label: Label
var time_label: Label
var pip_label: Label
var pip_count_label: Label
var action_list: VBoxContainer
var back_button: Button
var top_right_hud: Control
var resource_capsule: Panel
var hp_caption: Label
var hp_value: Label
var points_caption: Label
var points_value: Label
var money_caption: Label
var money_value: Label
var map_button: Button
var menu_button: Button
var bubbles_layer: Control
var status_backing: Panel
var status_label: Label

var _default_hint := ""
var _action_buttons: Array[Button] = []
var _bubble_buttons: Array[Button] = []
var _dock_visible := true


func configure(target_location_id: String, title_copy: String, back_copy: String = "← 返回地图") -> void:
	location_id = target_location_id
	location_title = title_copy
	back_copy_text = back_copy
	if is_inside_tree():
		_apply_header_copy(back_copy_text)


func _ready() -> void:
	size = DESIGN
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_hud()
	_apply_header_copy(back_copy_text)
	_connect_signals()
	refresh_status()


func _exit_tree() -> void:
	if DayCycle.changed.is_connected(refresh_status):
		DayCycle.changed.disconnect(refresh_status)
	if GameState.materials_changed.is_connected(refresh_status):
		GameState.materials_changed.disconnect(refresh_status)
	if GameState.player_stats_changed.is_connected(refresh_status):
		GameState.player_stats_changed.disconnect(refresh_status)


func _connect_signals() -> void:
	if not DayCycle.changed.is_connected(refresh_status):
		DayCycle.changed.connect(refresh_status)
	if not GameState.materials_changed.is_connected(refresh_status):
		GameState.materials_changed.connect(refresh_status)
	if not GameState.player_stats_changed.is_connected(refresh_status):
		GameState.player_stats_changed.connect(refresh_status)


func _build_hud() -> void:
	# 1. Stage minimal NPC bubbles layer (behind dock/modals, over actors/foreground)
	bubbles_layer = Control.new()
	bubbles_layer.name = "StageBubbles"
	bubbles_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bubbles_layer)
	DaylightUI.place(bubbles_layer, 0.0, 0.0, DESIGN.x, DESIGN.y)

	# 2. Left Action Dock (03 style)
	dock_panel = Control.new()
	dock_panel.name = "LeftActionDock"
	dock_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dock_panel)
	DaylightUI.place(dock_panel, 0.0, 0.0, DOCK_WIDTH, DESIGN.y)

	# Backdrop extends to x=-260 so 20:9 widescreen never reveals an exposed seam on the left
	dock_backing = Panel.new()
	dock_backing.name = "DockBacking"
	dock_backing.mouse_filter = Control.MOUSE_FILTER_STOP
	dock_panel.add_child(dock_backing)
	DaylightUI.place(dock_backing, -260.0, 0.0, DOCK_WIDTH + 260.0, DESIGN.y)

	period_dial = PeriodDial.new()
	period_dial.name = "PeriodDial"
	dock_panel.add_child(period_dial)
	DaylightUI.place(period_dial, 20.0, 28.0, 76.0, 76.0)

	title_label = SchoolObjectUI.text(dock_panel, "LocationTitle", location_title, Rect2(108.0, 26.0, 230.0, 44.0), 30, NAVY_INK)
	title_label.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.clip_text = true

	time_label = SchoolObjectUI.text(dock_panel, "DayTime", "", Rect2(108.0, 72.0, 230.0, 30.0), 19, Color("#4A5D78"))
	time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	time_label.clip_text = true

	var pips_bar := SchoolObjectUI.slab(dock_panel, "ActivityPips", Rect2(20.0, 122.0, 316.0, 44.0), Color("#F0F6F2"))
	pips_bar.add_theme_stylebox_override("panel", DynamicUI.make_paper_tag(Color("#F0F6F2"), Color("#89AC9E"), 6))
	pip_label = SchoolObjectUI.text(pips_bar, "PipText", "剩余活动", Rect2(16.0, 2.0, 160.0, 40.0), 19, NAVY_INK)
	pip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pip_count_label = SchoolObjectUI.text(pips_bar, "PipCount", "3 / 3", Rect2(196.0, 2.0, 102.0, 40.0), 21, Color("#24685B"))
	pip_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pip_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pip_count_label.add_theme_font_override("font", DaylightUI.bold_font())

	SchoolObjectUI.rule(dock_panel, "DockDivider", Rect2(20.0, 182.0, 316.0, 2.0))

	action_list = VBoxContainer.new()
	action_list.name = "ActionList"
	action_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action_list.add_theme_constant_override("separation", 12)
	dock_panel.add_child(action_list)
	DaylightUI.place(action_list, 20.0, 200.0, 316.0, 728.0)

	back_button = Button.new()
	back_button.name = "BackLocation"
	back_button.text = "返回地图"
	back_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	back_button.custom_minimum_size = Vector2(316.0, 58.0)
	dock_panel.add_child(back_button)
	DaylightUI.place(back_button, 20.0, 964.0, 316.0, 58.0)
	DynamicUI.make_cel_button(back_button, Color("#F3F6FA"), NAVY_INK, SLATE_BLUE, 21, 8)
	DaylightUI.bind_button_audio(back_button)
	back_button.pressed.connect(func(): back_requested.emit())

	# 3. Top-Right Unified Resource Note + Map + Menu (fixed Menu at rightmost x=1884)
	top_right_hud = Control.new()
	top_right_hud.name = "TopRightHud"
	top_right_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_right_hud)
	DaylightUI.place(top_right_hud, 1044.0, 24.0, 840.0, 56.0)

	resource_capsule = Panel.new()
	resource_capsule.name = "ResourceCapsule"
	resource_capsule.mouse_filter = Control.MOUSE_FILTER_STOP
	top_right_hud.add_child(resource_capsule)
	DaylightUI.place(resource_capsule, 0.0, 0.0, 500.0, 54.0)

	hp_caption = SchoolObjectUI.text(resource_capsule, "HpCaption", "体力", Rect2(20.0, 8.0, 48.0, 38.0), 17, Color("#5A6B82"))
	hp_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_value = SchoolObjectUI.text(resource_capsule, "HpValue", "100/100", Rect2(68.0, 7.0, 108.0, 40.0), 21, NAVY_INK, true)
	hp_value.add_theme_font_override("font", DaylightUI.bold_font())
	hp_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	SchoolObjectUI.rule(resource_capsule, "ResDiv1", Rect2(184.0, 13.0, 1.0, 28.0))

	points_caption = SchoolObjectUI.text(resource_capsule, "PointsCaption", "练习点", Rect2(198.0, 8.0, 62.0, 38.0), 17, Color("#5A6B82"))
	points_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	points_value = SchoolObjectUI.text(resource_capsule, "PointsValue", "0", Rect2(262.0, 7.0, 74.0, 40.0), 21, NAVY_INK, true)
	points_value.add_theme_font_override("font", DaylightUI.bold_font())
	points_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	SchoolObjectUI.rule(resource_capsule, "ResDiv2", Rect2(342.0, 13.0, 1.0, 28.0))

	money_caption = SchoolObjectUI.text(resource_capsule, "MoneyCaption", "零用钱", Rect2(356.0, 8.0, 62.0, 38.0), 17, Color("#5A6B82"))
	money_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	money_value = SchoolObjectUI.text(resource_capsule, "MoneyValue", "0", Rect2(420.0, 7.0, 68.0, 40.0), 21, NAVY_INK, true)
	money_value.add_theme_font_override("font", DaylightUI.bold_font())
	money_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	map_button = Button.new()
	map_button.name = "OpenMap"
	map_button.text = "地区地图 (M)"
	top_right_hud.add_child(map_button)
	DaylightUI.place(map_button, 514.0, 0.0, 188.0, 54.0)
	DynamicUI.make_cel_button(map_button, IVORY, NAVY_INK, TEAL, 19, 8)
	DaylightUI.bind_button_audio(map_button)
	map_button.pressed.connect(func(): map_requested.emit())

	menu_button = Button.new()
	menu_button.name = "OpenMenu"
	menu_button.text = "菜单"
	top_right_hud.add_child(menu_button)
	DaylightUI.place(menu_button, 716.0, 0.0, 124.0, 54.0)
	DynamicUI.make_cel_button(menu_button, Color("#F3F6FA"), NAVY_INK, SLATE_BLUE, 20, 8)
	DaylightUI.bind_button_audio(menu_button)
	menu_button.pressed.connect(func(): menu_requested.emit())

	# 4. Bottom stitched indigo fabric ribbon hint strip (avoid brass rivets at both ends)
	status_backing = SchoolObjectUI.slab(self, "ConceptStatusBacking", Rect2(384.0, 1016.0, 1496.0, 44.0), Color(0.18, 0.24, 0.37, 0.90))
	if not DynamicUI.apply_nine_slice_panel(status_backing, DynamicUI.THEME_FABRIC_RIBBON, Vector4(56, 26, 56, 26)):
		var sb := status_backing.get_theme_stylebox("panel") as StyleBoxFlat
		sb.set_corner_radius_all(8)
		sb.border_color = Color(1.0, 1.0, 1.0, 0.18)
	status_backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_label = SchoolObjectUI.text(self, "ConceptStatus", "", Rect2(432.0, 1020.0, 1400.0, 36.0), 20, Color("#FFF8EC"))
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.clip_text = true


func _apply_header_copy(back_copy: String) -> void:
	if is_instance_valid(title_label):
		title_label.text = location_title
		var fsize := 25 if location_title.length() >= 6 else 30
		title_label.add_theme_font_size_override("font_size", fsize)
	if is_instance_valid(back_button):
		back_button.text = back_copy


func add_action_row(item: Dictionary, kind: String, cost_badge: String, preview_text: String, callback: Callable) -> Button:
	var action_id := str(item.get("id", "act"))
	var copy := str(item.get("label", action_id))
	var btn := Button.new()
	btn.name = "Action_" + action_id
	btn.text = copy
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(316.0, 66.0)
	btn.clip_text = true
	btn.set_meta("action_kind", kind)
	action_list.add_child(btn)

	var fill := IVORY
	var ink := NAVY_INK
	var accent := TEAL
	var badge_fill := Color("#E2EFE7")
	var badge_border := Color("#94B9A5")
	var badge_ink := Color("#265E4D")
	match kind:
		"story":
			fill = Color("#FFF4F1")
			ink = Color("#7A2318")
			accent = CORAL
			badge_fill = Color("#C85242")
			badge_border = Color("#9E3B2E")
			badge_ink = Color("#FFFBF2")
		"activity":
			fill = Color("#FFFBF0")
			ink = NAVY_INK
			accent = AMBER
			badge_fill = Color("#F5DFC2")
			badge_border = Color("#C99E67")
			badge_ink = Color("#7D4A14")
		"move":
			fill = Color("#F4F8FD")
			ink = NAVY_INK
			accent = SLATE_BLUE
			badge_fill = Color("#DFECF6")
			badge_border = Color("#8EB0CC")
			badge_ink = Color("#2A517B")
		"locked":
			fill = Color("#ECEFF4")
			ink = Color("#6B778C")
			accent = Color("#98A5B8")
			badge_fill = Color("#E4E6EA")
			badge_border = Color("#B8BFC9")
			badge_ink = Color("#616B7A")

	DynamicUI.make_cel_button(btn, fill, ink, accent, 20, 8)
	var right_pad := 96 if cost_badge != "" else 18
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		var st := btn.get_theme_stylebox(state)
		if st != null:
			st.content_margin_left = 26
			st.content_margin_right = right_pad
	if cost_badge != "":
		var badge := Label.new()
		badge.name = "CostBadge"
		badge.text = cost_badge
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.add_theme_font_override("font", DaylightUI.bold_font())
		badge.add_theme_font_size_override("font_size", 14)
		badge.add_theme_color_override("font_color", badge_ink)
		badge.add_theme_stylebox_override("normal", DynamicUI.make_paper_tag(badge_fill, badge_border, 4, 6.0, 2.0))
		btn.add_child(badge)
		DaylightUI.place(badge, 224.0, 19.0, 74.0, 28.0)
	if kind == "story":
		DynamicUI.attach_sheen(btn, Color(1.0, 0.90, 0.72, 0.34), 8)
	DaylightUI.bind_button_audio(btn)
	btn.pressed.connect(callback)
	_wire_preview(btn, preview_text)
	_action_buttons.append(btn)
	return btn


func add_npc_bubble(node_name: String, anchor: Vector2, label_text: String, is_story: bool, preview_text: String, callback: Callable) -> Button:
	var clean_label := label_text.replace("💬 ", "").replace("✦ ", "").strip_edges()
	var w := clampf(float(clean_label.length()) * 22.0 + 44.0, 118.0, 240.0)
	var h := 44.0
	var bx := clampf(anchor.x - w * 0.5, DOCK_WIDTH + 20.0, DESIGN.x - w - 24.0)
	var by := clampf(anchor.y - h - 10.0, 96.0, 620.0)

	var wrap := Control.new()
	wrap.name = node_name + "_Wrap"
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubbles_layer.add_child(wrap)
	DaylightUI.place(wrap, bx, by, w, h + 12.0)

	var fill := CORAL if is_story else IVORY
	var ink := Color("#FFFBF2") if is_story else NAVY_INK
	var accent := Color("#FFF3D4") if is_story else Color("#89AC9E")

	var tail := _BubbleTail.new()
	tail.name = "Tail"
	tail.fill_color = Color(0.84, 0.40, 0.33) if is_story else Color(1.0, 0.99, 0.95)
	tail.border_color = Color("#9E3B2E") if is_story else Color("#95A49B")
	wrap.add_child(tail)
	DaylightUI.place(tail, w * 0.5 - 8.0, h - 2.0, 16.0, 10.0)

	var btn := Button.new()
	btn.name = node_name
	btn.text = clean_label
	btn.custom_minimum_size = Vector2(w, h)
	wrap.add_child(btn)
	DaylightUI.place(btn, 0.0, 0.0, w, h)

	DynamicUI.make_cel_button(btn, fill, ink, accent, 19, 8)
	var bnorm_mod := Color(0.84, 0.40, 0.33, 1.0) if is_story else Color(1.0, 0.99, 0.96, 1.0)
	var bhov_mod := Color(0.90, 0.45, 0.37, 1.0) if is_story else Color(0.95, 0.92, 0.85, 1.0)
	var bprs_mod := Color(0.75, 0.34, 0.27, 1.0) if is_story else Color(0.90, 0.86, 0.78, 1.0)
	var card_margins := Vector4(44, 36, 32, 32)
	var card_pad := Vector4(14, 4, 14, 6)
	var bnorm := DynamicUI.nine_slice_box(DynamicUI.THEME_PAPER_CARD, card_margins, card_pad, bnorm_mod, Vector4(-1, -1, -1, -1), h)
	if bnorm != null:
		var bhover := DynamicUI.nine_slice_box(DynamicUI.THEME_PAPER_CARD, card_margins, card_pad, bhov_mod, Vector4(-1, -1, -1, -1), h)
		var bpress := DynamicUI.nine_slice_box(DynamicUI.THEME_PAPER_CARD, card_margins, card_pad, bprs_mod, Vector4(-1, -1, -1, -1), h)
		btn.add_theme_stylebox_override("normal", bnorm)
		btn.add_theme_stylebox_override("focus", bnorm)
		btn.add_theme_stylebox_override("hover", bhover if bhover != null else bnorm)
		btn.add_theme_stylebox_override("pressed", bpress if bpress != null else bnorm)
		btn.add_theme_stylebox_override("hover_pressed", bpress if bpress != null else bnorm)
	if is_story:
		DynamicUI.attach_sheen(btn, Color(1.0, 0.94, 0.78, 0.36), 8)

	DynamicUI.attach_float_bob(wrap, 3.0, 2.4)
	DaylightUI.bind_button_audio(btn)
	btn.pressed.connect(callback)
	_wire_preview(btn, preview_text)
	_bubble_buttons.append(btn)
	return btn


func _wire_preview(control: Control, copy: String) -> void:
	if not is_instance_valid(control) or copy == "":
		return
	var show_tip := func():
		if is_instance_valid(status_label):
			status_label.text = copy
	var reset_tip := func():
		if is_instance_valid(status_label):
			status_label.text = _default_hint
	control.mouse_entered.connect(show_tip)
	control.focus_entered.connect(show_tip)
	control.mouse_exited.connect(reset_tip)
	control.focus_exited.connect(reset_tip)


func set_dock_visible(visible_state: bool) -> void:
	_dock_visible = visible_state
	if is_instance_valid(dock_panel):
		dock_panel.visible = visible_state
	if is_instance_valid(bubbles_layer):
		bubbles_layer.visible = visible_state
	if is_instance_valid(status_backing):
		status_backing.visible = visible_state
	if is_instance_valid(status_label):
		status_label.visible = visible_state
	if is_instance_valid(top_right_hud):
		top_right_hud.visible = visible_state


func set_interactions_enabled(enabled: bool) -> void:
	for btn in _action_buttons:
		if is_instance_valid(btn):
			btn.disabled = not enabled
	for bbtn in _bubble_buttons:
		if is_instance_valid(bbtn):
			bbtn.disabled = not enabled
	if is_instance_valid(back_button):
		back_button.disabled = not enabled
		back_button.visible = enabled
	if is_instance_valid(map_button):
		map_button.disabled = not enabled
	if is_instance_valid(menu_button):
		menu_button.disabled = not enabled
	if _dock_visible:
		if is_instance_valid(status_backing):
			status_backing.visible = enabled
		if is_instance_valid(status_label):
			status_label.visible = enabled
		if is_instance_valid(bubbles_layer):
			bubbles_layer.visible = enabled


func focus_order() -> Array[BaseButton]:
	var order: Array[BaseButton] = []
	for btn in _action_buttons:
		if is_instance_valid(btn) and btn.visible:
			order.append(btn)
	if is_instance_valid(back_button) and back_button.visible:
		order.append(back_button)
	if is_instance_valid(map_button) and map_button.visible:
		order.append(map_button)
	if is_instance_valid(menu_button) and menu_button.visible:
		order.append(menu_button)
	for bbtn in _bubble_buttons:
		if is_instance_valid(bbtn) and bbtn.visible:
			order.append(bbtn)
	return order


func refresh_status() -> void:
	var night := DayCycle.period() == "night"
	var rem := DayCycle.remaining()
	var date := DayCycleService.calendar_date(GameState.game_day)
	if is_instance_valid(time_label):
		time_label.text = "%d月%d日 · %s · %s" % [int(date["month"]), int(date["day"]), DayCycleService.weekday_for_day(GameState.game_day), DayCycleService.PERIOD_NAMES[DayCycle.period()]]
		time_label.add_theme_color_override("font_color", Color("#B9CAE6") if night else Color("#4A5D78"))
	if is_instance_valid(title_label):
		title_label.add_theme_color_override("font_color", NIGHT_INK if night else NAVY_INK)
	if is_instance_valid(dock_backing):
		if not DynamicUI.apply_nine_slice_panel(dock_backing, DynamicUI.THEME_PAPER_MODAL, Vector4(72, 56, 44, 44), Color(0.24, 0.29, 0.40, 0.96) if night else Color(1.0, 0.99, 0.96, 0.97)):
			var dstyle := StyleBoxFlat.new()
			dstyle.bg_color = NIGHT_PANEL if night else Color(0.99, 0.98, 0.95, 0.93)
			dstyle.border_color = Color("#6AA5EA", 0.85) if night else Color(TEAL, 0.82)
			dstyle.border_width_right = 4
			dock_backing.add_theme_stylebox_override("panel", dstyle)
	if is_instance_valid(pip_label):
		pip_label.text = "剩余活动"
		pip_label.add_theme_color_override("font_color", NIGHT_INK if night else NAVY_INK)
	if is_instance_valid(pip_count_label):
		pip_count_label.text = "%d / %d" % [rem, DayCycleService.ACTIONS_PER_PERIOD]
		pip_count_label.add_theme_color_override("font_color", Color("#87BAFF") if night else Color("#24685B"))
	var pips_bar := dock_panel.get_node_or_null("ActivityPips") as Panel
	if is_instance_valid(pips_bar):
		pips_bar.add_theme_stylebox_override("panel", DynamicUI.make_paper_tag(NIGHT_CARD if night else Color("#F0F6F2"), Color("#6AA5EA", 0.65) if night else Color("#89AC9E"), 6))
	for btn in _action_buttons:
		if is_instance_valid(btn) and str(btn.get_meta("action_kind", "")) == "activity":
			var badge := btn.get_node_or_null("CostBadge") as Control
			if is_instance_valid(badge):
				badge.modulate.a = 0.45 if rem <= 0 else 1.0
	if is_instance_valid(period_dial):
		period_dial.redmoon_active = bool(GameState.story_flags.get("prologue_redmoon", false)) or (night and GameState.next_phase_two_node() in ["n_dusk", "n_guard", "n_rescue", "n_robot", "n5_boss"])
		period_dial.sync_dial()
	if is_instance_valid(resource_capsule):
		if not DynamicUI.apply_nine_slice_panel(resource_capsule, DynamicUI.THEME_PAPER_CARD, Vector4(44, 36, 32, 32), Color(0.24, 0.29, 0.40, 0.96) if night else Color(1.0, 0.99, 0.96, 0.98)):
			var rstyle := StyleBoxFlat.new()
			rstyle.bg_color = NIGHT_PANEL if night else Color(1.0, 0.99, 0.97, 0.95)
			rstyle.border_color = Color("#6AA5EA", 0.82) if night else Color(TEAL, 0.82)
			rstyle.set_border_width_all(2)
			rstyle.set_corner_radius_all(8)
			resource_capsule.add_theme_stylebox_override("panel", rstyle)
	var cap_ink := Color("#A6B7D4") if night else Color("#5A6B82")
	for cap in [hp_caption, points_caption, money_caption]:
		if is_instance_valid(cap):
			cap.add_theme_color_override("font_color", cap_ink)
	var res_ink := NIGHT_INK if night else NAVY_INK
	if is_instance_valid(hp_value):
		hp_value.text = "%d/%d" % [GameState.player_current_hp, GameState.player_max_hp]
		hp_value.add_theme_color_override("font_color", res_ink)
	if is_instance_valid(points_value):
		points_value.text = str(GameState.scrap_metal)
		points_value.add_theme_color_override("font_color", res_ink)
	if is_instance_valid(money_value):
		money_value.text = str(GameState.energy_crystals)
		money_value.add_theme_color_override("font_color", res_ink)
	if is_instance_valid(status_backing):
		DynamicUI.apply_nine_slice_panel(status_backing, DynamicUI.THEME_FABRIC_RIBBON, Vector4(56, 26, 56, 26), Color(0.84, 0.88, 0.96, 0.96) if night else Color.WHITE)
	_default_hint = "%s · 左侧选择行动或点击场景气泡 · Esc 返回" % DayCycle.activity_hint()
	if is_instance_valid(status_label):
		status_label.text = _default_hint


class _BubbleTail:
	extends Control
	var fill_color := Color.WHITE
	var border_color := Color("#359686")

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var pts := PackedVector2Array([Vector2(0.0, 0.0), Vector2(16.0, 0.0), Vector2(8.0, 9.0)])
		draw_polygon(pts, PackedColorArray([fill_color]))
		draw_line(Vector2(0.0, 0.0), Vector2(8.0, 9.0), border_color, 2.0, true)
		draw_line(Vector2(16.0, 0.0), Vector2(8.0, 9.0), border_color, 2.0, true)


class PeriodDial:
	extends Control
	var redmoon_active: bool = false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _ready() -> void:
		queue_redraw()

	func _effective_state() -> Array:
		var p := DayCycle.period()
		var is_redmoon := redmoon_active or (p == "night" and GameState.next_phase_two_node() in ["n_dusk", "n_guard", "n_rescue", "n_robot", "n5_boss"])
		if is_inside_tree() and get_tree().current_scene != null:
			var sl := get_tree().current_scene.find_child("StageLayers", true, false)
			if sl != null:
				var forced: String = str(sl.get("force_sky_mode"))
				if forced == "redmoon":
					is_redmoon = true
					p = "night"
				elif forced == "dusk":
					is_redmoon = false
					p = "afternoon"
				elif forced == "day":
					is_redmoon = false
					p = "morning"
		return [p, is_redmoon]

	func sync_dial() -> void:
		queue_redraw()

	func _draw() -> void:
		var c := size * 0.5
		var outer_r := minf(size.x, size.y) * 0.45
		var inner_r := outer_r * 0.72
		var eff := _effective_state()
		var p := str(eff[0])
		var is_redmoon := bool(eff[1])
		var rem := DayCycle.remaining()
		var total := DayCycleService.ACTIONS_PER_PERIOD

		# Matte watercolor cotton-paper stamp backing
		var paper_bg := Color("#FAF4E6", 0.96) if p != "night" else Color("#242E46", 0.96)
		var rim_col := Color("#8B7E6E", 0.65) if p != "night" else Color("#728CB8", 0.75)
		draw_circle(c, outer_r + 2.0, paper_bg)
		draw_arc(c, outer_r + 2.0, 0.0, TAU, 44, rim_col, 1.6, true)

		# Subtle ink gauge segments around perimeter
		var seg_color := Color("#B84A42") if is_redmoon else (Color("#4D8F7F") if p == "morning" else (Color("#D28246") if p == "afternoon" else Color("#5E88C7")))
		var empty_color := Color(0.62, 0.66, 0.72, 0.30)
		var gap := 0.24
		var span := (TAU - gap * float(total)) / float(total)
		for i in total:
			var a0 := -PI * 0.5 + float(i) * (span + gap) + gap * 0.5
			var a1 := a0 + span
			draw_arc(c, outer_r - 2.5, a0, a1, 20, seg_color if i < rem else empty_color, 3.6, true)

		# Inner flat watercolor wash sky & minimalist celestial ink mark
		if is_redmoon:
			draw_circle(c, inner_r, Color("#4D2B42"))
			draw_arc(c, inner_r - 1.5, 0.0, TAU, 36, Color("#D66C66", 0.75), 1.4, true)
			draw_circle(c + Vector2(1.0, -2.0), inner_r * 0.44, Color("#D95353"))
			draw_arc(c + Vector2(1.0, -2.0), inner_r * 0.58, -0.35, 2.75, 20, Color("#F6BDB2", 0.65), 1.5, true)
		elif p == "morning":
			draw_circle(c, inner_r, Color("#DCEEF7"))
			draw_arc(c, inner_r - 1.5, 0.0, TAU, 36, Color("#7CB2CF", 0.65), 1.4, true)
			draw_circle(c + Vector2(3.0, -3.0), inner_r * 0.36, Color("#F2C864"))
			draw_arc(c, inner_r * 0.85, 0.3, 2.8, 16, Color("#9BC6B8", 0.7), 2.5, true)
		elif p == "afternoon":
			draw_circle(c, inner_r, Color("#F8E1CE"))
			draw_arc(c, inner_r - 1.5, 0.0, TAU, 36, Color("#CE8A5F", 0.65), 1.4, true)
			draw_circle(c + Vector2(0.0, 2.0), inner_r * 0.38, Color("#E59654"))
			draw_line(c + Vector2(-inner_r * 0.58, 5.0), c + Vector2(inner_r * 0.58, 5.0), Color("#C9754D", 0.85), 2.0, true)
		else:
			draw_circle(c, inner_r, Color("#2E3D63"))
			draw_arc(c, inner_r - 1.5, 0.0, TAU, 36, Color("#728FC4", 0.65), 1.4, true)
			draw_circle(c + Vector2(-2.0, -1.0), inner_r * 0.40, Color("#F3DFA2"))
			draw_circle(c + Vector2(4.0, -4.0), inner_r * 0.34, Color("#2E3D63"))
			draw_circle(c + Vector2(7.0, 5.0), 1.6, Color("#FAF2D8"))
