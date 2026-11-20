class_name SceneHUDLayout
extends Control

## Unified v17 Set A functional scene HUD (clear washi paper + sage-teal ink):
## - Top-left PeriodDial (real v17 dial art + activity arc) overlapping LocationCapsule
## - Floating left vertical action dock (auto-sized washi card with v17 pill buttons & icons)
## - Top-right ResourceCapsule (stamina/practice/allowance with v17 icons) + Map + Menu
## - Bottom hover hint strip

signal map_requested
signal menu_requested
signal back_requested

const DESIGN := Vector2(1920.0, 1080.0)
const DOCK_X := 26.0
const DOCK_Y := 142.0
const DOCK_WIDTH := 312.0
const INK := Color("#213D3A")
const MUTED := Color("#45645F")
const TEAL := Color("#35897A")
const CORAL := Color("#C95543")
const AMBER := Color("#C8822B")
const SLATE_BLUE := Color("#4C75A6")
const NIGHT_MOD := Color(0.24, 0.30, 0.42, 0.96)
const NIGHT_INK := Color("#F1F6FC")
const NIGHT_MUTED := Color("#B8CAE4")

var location_id := ""
var location_title := ""
var back_copy_text := "返回地图"
var dock_panel: Control
var dock_backing: Panel
var location_capsule: Panel
var period_dial: PeriodDial
var title_label: Label
var time_label: Label
var dock_heading_label: Label
var pip_label: Label
var pip_count_label: Label
var dock_divider: ColorRect
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
var status_backing: Panel
var status_label: Label

var _default_hint := ""
var _action_buttons: Array[Button] = []
var _dock_visible := true
var _res_icons: Array[TextureRect] = []


func configure(target_location_id: String, title_copy: String, back_copy: String = "返回地图") -> void:
	location_id = target_location_id
	location_title = title_copy
	back_copy_text = back_copy.replace("← ", "").strip_edges()
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
	# 1. Left Action Dock container (includes top-left dial + location capsule + floating action card)
	dock_panel = Control.new()
	dock_panel.name = "LeftActionDock"
	dock_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dock_panel)
	DaylightUI.place(dock_panel, 0.0, 0.0, 440.0, DESIGN.y)

	# Top-left Location Capsule (uniform 56px height matching top-right bar)
	location_capsule = Panel.new()
	location_capsule.name = "LocationCapsule"
	location_capsule.mouse_filter = Control.MOUSE_FILTER_STOP
	dock_panel.add_child(location_capsule)
	DaylightUI.place(location_capsule, 74.0, 26.0, 344.0, 56.0)

	title_label = SchoolObjectUI.text(location_capsule, "LocationTitle", location_title, Rect2(44.0, 3.0, 282.0, 29.0), 22, INK)
	title_label.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.clip_text = true

	time_label = SchoolObjectUI.text(location_capsule, "DayTime", "", Rect2(44.0, 31.0, 282.0, 22.0), 14, MUTED)
	time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	time_label.clip_text = true

	# PeriodDial centered vertically with the 56px top bar (center y = 54)
	period_dial = PeriodDial.new()
	period_dial.name = "PeriodDial"
	dock_panel.add_child(period_dial)
	DaylightUI.place(period_dial, 18.0, 14.0, 80.0, 80.0)

	# Floating washi Action Card (auto-resized as rows are added)
	dock_backing = Panel.new()
	dock_backing.name = "DockBacking"
	dock_backing.mouse_filter = Control.MOUSE_FILTER_STOP
	dock_panel.add_child(dock_backing)
	DaylightUI.place(dock_backing, DOCK_X, DOCK_Y, DOCK_WIDTH, 320.0)

	dock_heading_label = SchoolObjectUI.text(dock_panel, "DockHeading", "行动", Rect2(DOCK_X + 24.0, DOCK_Y + 20.0, 96.0, 32.0), 21, INK)
	dock_heading_label.add_theme_font_override("font", DaylightUI.bold_font())
	dock_heading_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var pips_bar := Control.new()
	pips_bar.name = "ActivityPips"
	pips_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dock_panel.add_child(pips_bar)
	DaylightUI.place(pips_bar, DOCK_X + 124.0, DOCK_Y + 20.0, 150.0, 32.0)
	pip_label = SchoolObjectUI.text(pips_bar, "PipText", "剩余活动", Rect2(0.0, 0.0, 86.0, 32.0), 16, MUTED)
	pip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pip_count_label = SchoolObjectUI.text(pips_bar, "PipCount", "3 / 3", Rect2(90.0, 0.0, 60.0, 32.0), 18, TEAL)
	pip_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pip_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pip_count_label.add_theme_font_override("font", DaylightUI.bold_font())

	dock_divider = ColorRect.new()
	dock_divider.name = "DockDivider"
	dock_divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dock_divider.color = Color("#6D9B8F", 0.55)
	dock_panel.add_child(dock_divider)
	DaylightUI.place(dock_divider, DOCK_X + 22.0, DOCK_Y + 58.0, DOCK_WIDTH - 44.0, 2.0)

	action_list = VBoxContainer.new()
	action_list.name = "ActionList"
	action_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action_list.add_theme_constant_override("separation", 12)
	dock_panel.add_child(action_list)
	DaylightUI.place(action_list, DOCK_X + 20.0, DOCK_Y + 74.0, DOCK_WIDTH - 40.0, 520.0)

	back_button = Button.new()
	back_button.name = "BackLocation"
	back_button.text = "返回地图"
	back_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	back_button.custom_minimum_size = Vector2(DOCK_WIDTH - 40.0, 52.0)
	dock_panel.add_child(back_button)
	DaylightUI.place(back_button, DOCK_X + 20.0, DOCK_Y + 240.0, DOCK_WIDTH - 40.0, 52.0)
	DynamicUI.make_v17_button(back_button, Color(0.97, 0.99, 0.99, 0.98), INK, 19, 52.0, Vector4(48, 4, 16, 4))
	_attach_v17_icon(back_button, "BackIcon", "return", Rect2(18.0, 15.0, 22.0, 22.0))
	DaylightUI.bind_button_audio(back_button)
	back_button.pressed.connect(func(): back_requested.emit())

	# 3. Top-Right Single-Line Resource Capsule + Map + Menu (uniform height 56px, y=26, right edge x=1894)
	top_right_hud = Control.new()
	top_right_hud.name = "TopRightHud"
	top_right_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_right_hud)
	DaylightUI.place(top_right_hud, 1002.0, 26.0, 892.0, 56.0)

	resource_capsule = Panel.new()
	resource_capsule.name = "ResourceCapsule"
	resource_capsule.mouse_filter = Control.MOUSE_FILTER_STOP
	top_right_hud.add_child(resource_capsule)
	DaylightUI.place(resource_capsule, 0.0, 0.0, 580.0, 56.0)

	_res_icons.clear()
	_res_icons.append(_attach_v17_icon(resource_capsule, "ResIconStamina", "bolt", Rect2(22.0, 17.0, 22.0, 22.0)))
	hp_caption = SchoolObjectUI.text(resource_capsule, "HpCaption", "体力", Rect2(48.0, 8.0, 40.0, 40.0), 16, MUTED)
	hp_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_value = SchoolObjectUI.text(resource_capsule, "HpValue", "100/100", Rect2(90.0, 8.0, 114.0, 40.0), 21, INK)
	hp_value.add_theme_font_override("font", DaylightUI.bold_font())
	hp_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	SchoolObjectUI.rule(resource_capsule, "ResDiv1", Rect2(208.0, 15.0, 1.0, 26.0))
	_res_icons.append(_attach_v17_icon(resource_capsule, "ResIconPoints", "gem", Rect2(220.0, 17.0, 22.0, 22.0)))
	points_caption = SchoolObjectUI.text(resource_capsule, "PointsCaption", "练习点", Rect2(246.0, 8.0, 54.0, 40.0), 16, MUTED)
	points_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	points_value = SchoolObjectUI.text(resource_capsule, "PointsValue", "0", Rect2(302.0, 8.0, 82.0, 40.0), 21, INK)
	points_value.add_theme_font_override("font", DaylightUI.bold_font())
	points_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	SchoolObjectUI.rule(resource_capsule, "ResDiv2", Rect2(390.0, 15.0, 1.0, 26.0))
	_res_icons.append(_attach_v17_icon(resource_capsule, "ResIconMoney", "coin", Rect2(402.0, 17.0, 22.0, 22.0)))
	money_caption = SchoolObjectUI.text(resource_capsule, "MoneyCaption", "零用钱", Rect2(428.0, 8.0, 54.0, 40.0), 16, MUTED)
	money_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	money_value = SchoolObjectUI.text(resource_capsule, "MoneyValue", "0", Rect2(484.0, 8.0, 82.0, 40.0), 21, INK)
	money_value.add_theme_font_override("font", DaylightUI.bold_font())
	money_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	map_button = Button.new()
	map_button.name = "OpenMap"
	map_button.text = "校园地图"
	map_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	top_right_hud.add_child(map_button)
	DaylightUI.place(map_button, 594.0, 0.0, 174.0, 56.0)
	DynamicUI.make_v17_button(map_button, Color.WHITE, INK, 19, 56.0, Vector4(48, 4, 16, 4))
	_attach_v17_icon(map_button, "OpenMapGlyph", "map", Rect2(18.0, 17.0, 22.0, 22.0))
	DaylightUI.bind_button_audio(map_button)
	map_button.pressed.connect(func(): map_requested.emit())

	menu_button = Button.new()
	menu_button.name = "OpenMenu"
	menu_button.text = "菜单"
	top_right_hud.add_child(menu_button)
	DaylightUI.place(menu_button, 782.0, 0.0, 110.0, 56.0)
	DynamicUI.make_v17_button(menu_button, Color(0.97, 0.99, 0.99, 0.98), INK, 20, 56.0, Vector4(16, 4, 16, 4))
	DaylightUI.bind_button_audio(menu_button)
	menu_button.pressed.connect(func(): menu_requested.emit())

	# 4. Bottom subtle washi hint strip (fits cleanly under the floating dock or along bottom)
	status_backing = Panel.new()
	status_backing.name = "ConceptStatusBacking"
	status_backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(status_backing)
	DaylightUI.place(status_backing, 354.0, 1020.0, 1540.0, 42.0)

	status_label = SchoolObjectUI.text(self, "ConceptStatus", "", Rect2(384.0, 1022.0, 1480.0, 38.0), 19, INK)
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.clip_text = true
	_relayout_dock()


func _attach_v17_icon(parent: Control, node_name: String, icon_key: String, rect: Rect2, tint: Color = Color.WHITE) -> TextureRect:
	var tex := DynamicUI.v17_icon(icon_key)
	var icon := parent.get_node_or_null(node_name) as TextureRect
	if tex == null:
		return icon
	if icon == null:
		icon = TextureRect.new()
		icon.name = node_name
		parent.add_child(icon)
	icon.texture = tex
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.modulate = tint
	DaylightUI.place(icon, rect.position.x, rect.position.y, rect.size.x, rect.size.y)
	return icon


func _icon_key_for_action(action_id: String, kind: String) -> String:
	match action_id:
		"shop", "rooftop_vending", "park_vending":
			return "bag"
		"shop_work":
			return "coin"
		"library_study", "study", "read_notes", "dorm_note":
			return "book"
		"workshop", "training", "dorm_desk":
			return "card"
		"talk":
			return "chat"
		"sleep", "park_reflect":
			return "rest"
		"rooftop_review", "coast_walk", "coast_observe", "beach_observe":
			return "waves"
		"beach_rest":
			return "gem"
		"qualifier", "switch_companion", "story_act1", "story_act3":
			return "spark"
		"enter_old_park", "go":
			return "map"
	if kind == "story":
		return "spark"
	if kind == "move":
		return "map"
	return "arrow"


func _relayout_dock() -> void:
	if not is_instance_valid(dock_backing) or not is_instance_valid(back_button):
		return
	var row_count := _action_buttons.size()
	var rows_h := float(row_count) * 56.0 + float(maxi(0, row_count - 1)) * 12.0
	if is_instance_valid(action_list):
		DaylightUI.place(action_list, DOCK_X + 20.0, DOCK_Y + 74.0, DOCK_WIDTH - 40.0, maxf(64.0, rows_h + 8.0))
	var back_y := DOCK_Y + 74.0 + rows_h + (16.0 if row_count > 0 else 8.0)
	DaylightUI.place(back_button, DOCK_X + 20.0, back_y, DOCK_WIDTH - 40.0, 52.0)
	var total_h := (back_y - DOCK_Y) + 52.0 + 24.0
	DaylightUI.place(dock_backing, DOCK_X, DOCK_Y, DOCK_WIDTH, total_h)


func _apply_header_copy(back_copy: String) -> void:
	if is_instance_valid(title_label):
		title_label.text = location_title
		var fsize := 19 if location_title.length() >= 6 else 22
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
	btn.custom_minimum_size = Vector2(DOCK_WIDTH - 40.0, 56.0)
	btn.clip_text = true
	btn.set_meta("action_kind", kind)
	action_list.add_child(btn)

	var tint := Color.WHITE
	var ink := INK
	var badge_fill := Color("#E5F1EC")
	var badge_border := Color("#88B4A7")
	var badge_ink := Color("#235A4E")
	var show_badge := cost_badge != "" and cost_badge != "免费"
	match kind:
		"story":
			tint = Color(1.0, 0.94, 0.92, 1.0)
			ink = Color("#7E271C")
			badge_fill = Color("#C95543")
			badge_border = Color("#9F3B2D")
			badge_ink = Color("#FFFBF4")
			show_badge = cost_badge != ""
		"activity":
			tint = Color(1.0, 0.98, 0.92, 1.0)
			badge_fill = Color("#F5E4C8")
			badge_border = Color("#C9A06B")
			badge_ink = Color("#7A4916")
		"move":
			tint = Color(0.96, 0.99, 1.0, 1.0)
			badge_fill = Color("#E1EFF7")
			badge_border = Color("#89B0CB")
			badge_ink = Color("#275077")
		"locked":
			tint = Color(0.91, 0.93, 0.95, 0.85)
			ink = Color("#6A7786")
			badge_fill = Color("#E6E9EE")
			badge_border = Color("#B6BFC9")
			badge_ink = Color("#616D7A")

	var right_pad := 78.0 if show_badge else 16.0
	DynamicUI.make_v17_button(btn, tint, ink, 19, 56.0, Vector4(48.0, 4.0, right_pad, 4.0))

	var icon_key := str(item.get("icon", _icon_key_for_action(action_id, kind)))
	var icon_tint := Color("#B94737") if kind == "story" else (Color(0.55, 0.60, 0.66, 0.8) if kind == "locked" else Color.WHITE)
	_attach_v17_icon(btn, "RowGlyph", icon_key, Rect2(18.0, 17.0, 22.0, 22.0), icon_tint)

	if show_badge:
		var badge := Label.new()
		badge.name = "CostBadge"
		badge.text = cost_badge
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.add_theme_font_override("font", DaylightUI.bold_font())
		badge.add_theme_font_size_override("font_size", 13)
		badge.add_theme_color_override("font_color", badge_ink)
		badge.add_theme_stylebox_override("normal", DynamicUI.make_paper_tag(badge_fill, badge_border, 6, 4.0, 1.0))
		btn.add_child(badge)
		DaylightUI.place(badge, DOCK_WIDTH - 40.0 - 72.0, 15.0, 60.0, 26.0)
	if kind == "story":
		DynamicUI.attach_sheen(btn, Color(1.0, 0.88, 0.72, 0.32), 18)
	DaylightUI.bind_button_audio(btn)
	btn.pressed.connect(callback)
	_wire_preview(btn, preview_text)
	_action_buttons.append(btn)
	_relayout_dock()
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
	if is_instance_valid(back_button):
		back_button.disabled = not enabled
	if is_instance_valid(map_button):
		map_button.disabled = not enabled
	if is_instance_valid(menu_button):
		menu_button.disabled = not enabled
	if _dock_visible:
		if is_instance_valid(status_backing):
			status_backing.visible = enabled
		if is_instance_valid(status_label):
			status_label.visible = enabled


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
	return order


func refresh_status() -> void:
	var night := DayCycle.period() == "night"
	if is_inside_tree() and get_tree().current_scene != null:
		var sl := get_tree().current_scene.find_child("StageLayers", true, false)
		if sl != null and str(sl.get("force_sky_mode")) == "redmoon":
			night = true
	var rem := DayCycle.remaining()
	var date := DayCycleService.calendar_date(GameState.game_day)
	var ink_col := NIGHT_INK if night else INK
	var muted_col := NIGHT_MUTED if night else MUTED
	var panel_mod := NIGHT_MOD if night else Color(1.0, 1.0, 1.0, 0.96)

	if is_instance_valid(time_label):
		time_label.text = "%d月%d日 · %s · %s" % [int(date["month"]), int(date["day"]), DayCycleService.weekday_for_day(GameState.game_day), DayCycleService.PERIOD_NAMES[DayCycle.period()]]
		time_label.add_theme_color_override("font_color", muted_col)
	if is_instance_valid(title_label):
		title_label.add_theme_color_override("font_color", ink_col)
	if is_instance_valid(location_capsule):
		var loc_box := DynamicUI.v17_capsule_box(DynamicUI.V17_RESOURCE_CAPSULE, 56.0, panel_mod)
		if loc_box != null:
			location_capsule.add_theme_stylebox_override("panel", loc_box)
	if is_instance_valid(dock_backing):
		var dock_box := DynamicUI.v17_panel_box(DynamicUI.V17_DOCK_STRIP, Vector4(113, 154, 102, 174), Vector4(49, 63, 48, 63), 0.56, panel_mod)
		if dock_box != null:
			dock_backing.add_theme_stylebox_override("panel", dock_box)
	if is_instance_valid(dock_heading_label):
		dock_heading_label.add_theme_color_override("font_color", ink_col)
	if is_instance_valid(dock_divider):
		dock_divider.color = Color("#86B2D8", 0.45) if night else Color("#6D9B8F", 0.55)
	if is_instance_valid(pip_label):
		pip_label.text = "剩余活动"
		pip_label.add_theme_color_override("font_color", muted_col)
	if is_instance_valid(pip_count_label):
		pip_count_label.text = "%d / %d" % [rem, DayCycleService.ACTIONS_PER_PERIOD]
		pip_count_label.add_theme_color_override("font_color", Color("#93C8FF") if night else TEAL)
	for btn in _action_buttons:
		if is_instance_valid(btn) and str(btn.get_meta("action_kind", "")) == "activity":
			var badge := btn.get_node_or_null("CostBadge") as Control
			if is_instance_valid(badge):
				badge.modulate.a = 0.45 if rem <= 0 else 1.0
	if is_instance_valid(period_dial):
		period_dial.redmoon_active = bool(GameState.story_flags.get("prologue_redmoon", false)) or (night and GameState.next_phase_two_node() in ["n_dusk", "n_guard", "n_rescue", "n_robot", "n5_boss"])
		period_dial.sync_dial()
	if is_instance_valid(resource_capsule):
		var res_box := DynamicUI.v17_capsule_box(DynamicUI.V17_RESOURCE_CAPSULE, 56.0, panel_mod)
		if res_box != null:
			resource_capsule.add_theme_stylebox_override("panel", res_box)
	for icon in _res_icons:
		if is_instance_valid(icon):
			icon.modulate = Color(0.84, 0.93, 1.0, 0.95) if night else Color.WHITE
	for cap in [hp_caption, points_caption, money_caption]:
		if is_instance_valid(cap):
			cap.add_theme_color_override("font_color", muted_col)
	if is_instance_valid(hp_value):
		hp_value.text = "%d/%d" % [GameState.player_current_hp, GameState.player_max_hp]
		hp_value.add_theme_color_override("font_color", ink_col)
	if is_instance_valid(points_value):
		points_value.text = str(GameState.scrap_metal)
		points_value.add_theme_color_override("font_color", ink_col)
	if is_instance_valid(money_value):
		money_value.text = str(GameState.energy_crystals)
		money_value.add_theme_color_override("font_color", ink_col)
	if is_instance_valid(status_backing):
		var st_box := DynamicUI.v17_capsule_box(DynamicUI.V17_RESOURCE_CAPSULE, 42.0, Color(0.18, 0.23, 0.34, 0.90) if night else Color(1.0, 1.0, 1.0, 0.92))
		if st_box != null:
			status_backing.add_theme_stylebox_override("panel", st_box)
	_default_hint = "%s · 左侧选择行动或点击人物互动 · Esc 返回" % DayCycle.activity_hint()
	if is_instance_valid(status_label):
		status_label.text = _default_hint
		status_label.add_theme_color_override("font_color", ink_col)


class PeriodDial:
	extends Control
	var redmoon_active: bool = false
	var _art: TextureRect
	var _arc_overlay: _DialArcOverlay

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(_layout_children)

	func _ready() -> void:
		_art = TextureRect.new()
		_art.name = "DialArt"
		_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		add_child(_art)
		_arc_overlay = _DialArcOverlay.new()
		_arc_overlay.name = "DialArcOverlay"
		_arc_overlay.dial = self
		add_child(_arc_overlay)
		_layout_children()
		sync_dial()

	func _layout_children() -> void:
		if is_instance_valid(_art):
			DaylightUI.place(_art, -6.0, -6.0, size.x + 12.0, size.y + 12.0)
		if is_instance_valid(_arc_overlay):
			DaylightUI.place(_arc_overlay, 0.0, 0.0, size.x, size.y)
			_arc_overlay.queue_redraw()

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
		var eff := _effective_state()
		var p := str(eff[0])
		var is_redmoon := bool(eff[1])
		if is_instance_valid(_art):
			var tex_path := DynamicUI.V17_DIAL_REDMOON if is_redmoon else DynamicUI.V17_DIAL_MORNING
			_art.texture = DynamicUI.v17_texture(tex_path)
			if is_redmoon:
				_art.modulate = Color.WHITE
			elif p == "afternoon":
				_art.modulate = Color(1.0, 0.93, 0.84, 1.0)
			elif p == "night":
				_art.modulate = Color(0.76, 0.80, 0.95, 1.0)
			else:
				_art.modulate = Color.WHITE
		if is_instance_valid(_arc_overlay):
			_arc_overlay.queue_redraw()


class _DialArcOverlay:
	extends Control
	var dial: PeriodDial

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if not is_instance_valid(dial):
			return
		var eff := dial._effective_state()
		var p := str(eff[0])
		var is_redmoon := bool(eff[1])
		var rem := DayCycle.remaining()
		var total := DayCycleService.ACTIONS_PER_PERIOD
		var c := size * 0.5 + Vector2(0.0, 2.0)
		var r := minf(size.x, size.y) * 0.44
		var seg_color := Color("#D15447") if is_redmoon else (Color("#3C927F") if p == "morning" else (Color("#D68945") if p == "afternoon" else Color("#6C95D4")))
		var empty_color := Color(0.55, 0.62, 0.65, 0.28)
		var gap := 0.24
		var span := (TAU - gap * float(total)) / float(total)
		for i in total:
			var a0 := -PI * 0.5 + float(i) * (span + gap) + gap * 0.5
			var a1 := a0 + span
			draw_arc(c, r, a0, a1, 20, seg_color if i < rem else empty_color, 3.2, true)
