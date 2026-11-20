class_name HomeScreen
extends Control

## A 1920x1080 composition reconstructed from the approved full-scene artwork.
## Old serialized UI is retired at runtime; original scene files remain recoverable.
const DESIGN_SIZE := Vector2(1920, 1080)
const ROOM_PATH := "res://assets/ui/player_experience/home_room_v3.png"
const FOREGROUND_PATH := "res://assets/ui/player_experience/home_foreground_desk_v3.png"
const GIRL_PATH := "res://assets/ui/player_experience/home_midground_seated_v3.png"
const OBJECTS_PATH := "res://assets/ui/player_experience/home_objects_v3.png"
const TITLE_INK := Color("#263059")
const SUBTITLE_INK := Color("#3B466B")
const ENTRY_ORDER := ["lounge", "workshop", "records", "quest", "explore", "zodiac"]
const ENTRY_TITLES := {
	"lounge": "同学交流", "workshop": "卡牌整理",
	"records": "放映档案室", "quest": "校园地图", "explore": "进入第一章"
}

var presentation: Control
var top_bar: Control
var hotspots_layer: Control
var modals_layer: Control
var modal_backdrop: ColorRect
var room_art: TextureRect
var midground: Control
var girl_actor: TextureRect
var foreground_art: TextureRect
var title_label: Label
var subtitle_label: Label
var hp_label: Label
var scrap_label: Label
var crystal_label: Label
var btn_lounge: Button
var btn_workshop: Button
var btn_records: Button
var btn_quest: Button
var btn_explore: Button
var lounge_panel: Control
var workshop_panel: Control
var records_panel: Control
var quest_panel: Control
var explore_panel: Control
var selected_card_id_for_upgrade: String = ""

var _entries: Dictionary = {}
var _active_modal: Control
var _active_kind: String = ""
var _return_focus: Control
var _modal_tween: Tween
var _body_font: Font
var _title_font: Font
var _feedback: String = ""
var system_menu: GameMenu
var menu_button: Button
var activity_title: Label
var activity_body: Label
var story_button: Button
var period_dial: SceneHUDLayout.PeriodDial
var activity_pip_badge: Label
var rooftop_button: Button
var _records_open_tab := ""
var _panel_refresh_pending := false

func _ready() -> void:
	SceneManager.current_scene_type = SceneManager.TargetScene.HOME
	CampusLife.arrive_at_club()
	AudioManager.play_bgm_for_scene(SceneManager.TargetScene.HOME)
	_body_font = DaylightUI.body_font()
	_title_font = load("res://assets/fonts/NotoSerifSC-SemiBold.ttf") as Font
	theme = DaylightUI.get_theme().duplicate() as Theme



	clip_contents = true
	_build_home_scene()
	_refresh_artwork()
	_update_top_bar()
	_layout_home_scene()
	resized.connect(_layout_home_scene)
	DayCycle.changed.connect(_calendar_changed)
	GameState.profile_changed.connect(_refresh_journey_ui)
	GameState.materials_changed.connect(_update_top_bar)
	GameState.materials_changed.connect(_refresh_inventory_ui)
	GameState.inventory_changed.connect(_refresh_inventory_ui)
	GameState.player_stats_changed.connect(_update_top_bar)
	GameState.deck_changed.connect(_refresh_workshop_ui)
	GameState.companion_favor_changed.connect(_on_companion_changed)
	GameState.story_flag_updated.connect(_on_story_flag_changed)
	if GameState.archive_return_tab != "":
		_records_open_tab = GameState.archive_return_tab
		GameState.archive_return_tab = ""
		_restore_records_after_transition.call_deferred()

func _restore_records_after_transition() -> void:
	if SceneManager.is_transitioning:
		await SceneManager.scene_transition_completed
	if is_inside_tree() and not is_queued_for_deletion():
		_open_records()

func _build_home_scene() -> void:
	presentation = Control.new()
	presentation.name = "HomePresentation"
	presentation.mouse_filter = Control.MOUSE_FILTER_IGNORE
	presentation.clip_contents = true
	presentation.size = DESIGN_SIZE
	add_child(presentation)
	room_art = TextureRect.new()
	room_art.name = "RoomArt"
	room_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	room_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	room_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	presentation.add_child(room_art)
	_place(room_art, Vector2.ZERO, DESIGN_SIZE)
	midground = Control.new()
	midground.name = "CharacterMidground"
	midground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	presentation.add_child(midground)
	_place(midground, Vector2.ZERO, DESIGN_SIZE)
	# Registered animated portrait stays behind the original foreground desk.
	midground.set_meta("role", "seated_character_and_chair")
	girl_actor = HomePortraitActor.new()
	girl_actor.name = "JiangZiHomeActor"
	girl_actor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	girl_actor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	girl_actor.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	girl_actor.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	midground.add_child(girl_actor)
	# A complete seated pose and chair; the foreground desk supplies natural occlusion.
	_place(girl_actor, Vector2(80, 222), DESIGN_SIZE * 0.8)
	foreground_art = TextureRect.new()
	foreground_art.name = "ForegroundArt"
	foreground_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	foreground_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	foreground_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	foreground_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	presentation.add_child(foreground_art)
	_place(foreground_art, Vector2.ZERO, DESIGN_SIZE)
	var title_wash := Panel.new()
	title_wash.name = "TitleHeaderWash"
	title_wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_wash.z_index = 1
	var wash_style := CombatSkin.flat(Color(0.99, 0.96, 0.90, 0.92), Vector4.ZERO)
	wash_style.border_color = Color(0.84, 0.77, 0.68, 0.65)
	wash_style.set_corner_radius_all(22)
	title_wash.add_theme_stylebox_override("panel", wash_style)
	presentation.add_child(title_wash)
	_place(title_wash, Vector2(56, 16), Vector2(618, 206))
	period_dial = SceneHUDLayout.PeriodDial.new()
	period_dial.name = "HomePeriodDial"
	period_dial.z_index = 2
	presentation.add_child(period_dial)
	_place(period_dial, Vector2(76, 36), Vector2(76, 76))
	title_label = _label("MainTitle", "社团教室", 72, _title_font, TITLE_INK)
	title_label.z_index = 2
	presentation.add_child(title_label)
	_place(title_label, Vector2(168, 22), Vector2(490, 102))
	subtitle_label = _label("Subtitle", "", 24, _body_font, SUBTITLE_INK)
	subtitle_label.z_index = 2
	subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	subtitle_label.add_theme_constant_override("line_spacing", 6)
	presentation.add_child(subtitle_label)
	_place(subtitle_label, Vector2(170, 134), Vector2(485, 76))
	activity_pip_badge = SchoolObjectUI.text(presentation, "ActivityPipBadge", "", Rect2(66, 134, 96, 32), 17, Color("#FFFBF2"), true)
	activity_pip_badge.z_index = 2
	activity_pip_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	activity_pip_badge.add_theme_stylebox_override("normal", DynamicUI.make_paper_tag(Color("#367D6D"), Color("#24594D"), 6, 8.0, 2.0))
	_build_top_bar()
	_build_navigation()
	_build_modals_layer()
	for button in presentation.find_children("*","Button",true,false):
		SchoolObjectUI.borderless(button)

func _build_top_bar() -> void:
	top_bar = Control.new()
	top_bar.name = "TopBar"
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	presentation.add_child(top_bar)
	_place(top_bar, Vector2(1188, 26), Vector2(580, 56))
	var rail := Panel.new()
	rail.name = "StatusCapsule"
	rail.mouse_filter = Control.MOUSE_FILTER_STOP
	var rail_box := DynamicUI.v17_capsule_box(DynamicUI.V17_RESOURCE_CAPSULE, 56.0, Color(1.0, 1.0, 1.0, 0.96))
	if rail_box != null:
		rail.add_theme_stylebox_override("panel", rail_box)
	else:
		var fb := StyleBoxFlat.new()
		fb.bg_color = Color("#FAF6EB", 0.96)
		fb.border_color = Color("#6D9B8F")
		fb.set_border_width_all(2)
		fb.set_corner_radius_all(28)
		rail.add_theme_stylebox_override("panel", fb)
	top_bar.add_child(rail)
	_place(rail, Vector2.ZERO, Vector2(580, 56))
	var specs := [
		["ResIconStamina", "bolt", "体力", 0.0, 22.0, 48.0, 40.0, 90.0, 114.0],
		["ResIconPoints", "gem", "练习点", 208.0, 220.0, 246.0, 54.0, 302.0, 82.0],
		["ResIconMoney", "coin", "零用钱", 390.0, 402.0, 428.0, 54.0, 484.0, 82.0]
	]
	var values: Array[Label] = []
	for spec in specs:
		var div_x := float(spec[3])
		if div_x > 20.0:
			SchoolObjectUI.rule(rail, "Divider" + str(int(div_x)), Rect2(div_x, 15.0, 1.0, 26.0))
		var icon_tex := DynamicUI.v17_icon(str(spec[1]))
		if icon_tex != null:
			var icon := TextureRect.new()
			icon.name = str(spec[0])
			icon.texture = icon_tex
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			rail.add_child(icon)
			DaylightUI.place(icon, float(spec[4]), 17.0, 22.0, 22.0)
		var cap := SchoolObjectUI.text(rail, "Caption" + str(int(div_x)), str(spec[2]), Rect2(float(spec[5]), 8.0, float(spec[6]), 40.0), 16, DynamicUI.V17_MUTED)
		cap.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var value := SchoolObjectUI.text(rail, "Value" + str(int(div_x)), "", Rect2(float(spec[7]), 8.0, float(spec[8]), 40.0), 21, DynamicUI.V17_INK)
		value.add_theme_font_override("font", DaylightUI.bold_font())
		value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		values.append(value)
	hp_label = values[0]
	scrap_label = values[1]
	crystal_label = values[2]

	menu_button = Button.new()
	menu_button.name = "MainMenuButton"
	menu_button.text = "菜单"
	presentation.add_child(menu_button)
	_place(menu_button, Vector2(1782, 26), Vector2(112, 56))
	DynamicUI.make_v17_button(menu_button, Color(0.97, 0.99, 0.99, 0.98), DynamicUI.V17_INK, 20, 56.0, Vector4(16, 4, 16, 4))
	menu_button.pressed.connect(_open_system_menu)

func _build_navigation() -> void:
	hotspots_layer = Control.new()
	hotspots_layer.name = "Navigation"
	hotspots_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	presentation.add_child(hotspots_layer)
	_place(hotspots_layer,Vector2.ZERO,DESIGN_SIZE)
	var objects := SchoolObjectUI.art(hotspots_layer,"StudentObjects",OBJECTS_PATH,Rect2(0,30,1920,1080))
	objects.set_meta("role","desk_objects_without_itinerary")
	room_art.set_meta("role","room_with_pinned_itinerary")
	activity_title = SchoolObjectUI.text(hotspots_layer,"ActivityTitle","",Rect2(1080,145,580,62),34,TITLE_INK)
	activity_body = SchoolObjectUI.text(hotspots_layer,"ActivityBody","",Rect2(1030,394,430,122),22,SUBTITLE_INK)
	activity_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	activity_body.clip_text = true
	btn_explore = SchoolObjectUI.hit(hotspots_layer,"PrimaryActivity",Rect2(1480,304,240,67),"",28)
	for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		btn_explore.add_theme_color_override(key, Color.WHITE)
	for state in ["hover","pressed","hover_pressed"]:
		var primary_wash := StyleBoxFlat.new()
		primary_wash.bg_color = Color(1.0,1.0,1.0,0.14) if state == "hover" else Color(0.18,0.08,0.12,0.18)
		primary_wash.set_corner_radius_all(12)
		btn_explore.add_theme_stylebox_override(state,primary_wash)
	SchoolObjectUI.borderless(btn_explore)
	DaylightUI.bind_button_audio(btn_explore)
	btn_explore.pressed.connect(_activate_primary)
	_entries["explore"] = btn_explore
	story_button = SchoolObjectUI.hit(hotspots_layer,"StoryShortcut",Rect2(1480,381,240,54),"",24)
	_style_journey_shortcut(story_button)
	DaylightUI.bind_button_audio(story_button)
	story_button.pressed.connect(_activate_story)
	var zodiac := SchoolObjectUI.hit(hotspots_layer,"ZodiacShortcut",Rect2(1480,441,240,54),"星座图鉴",24)
	_style_journey_shortcut(zodiac)
	DaylightUI.bind_button_audio(zodiac)
	zodiac.pressed.connect(_open_panel.bind("zodiac"))
	_entries["zodiac"] = zodiac
	var positions := {"workshop":Rect2(562,741,591,280),"lounge":Rect2(861,534,400,225),"quest":Rect2(1178,587,742,284),"records":Rect2(1145,835,695,212)}
	var labels := {"workshop":Rect2(662,916,285,65),"lounge":Rect2(1020,545,215,65),"quest":Rect2(1620,740,270,75),"records":Rect2(1512,941,286,73)}
	for kind in ["workshop","lounge","quest","records"]:
		var button := SchoolObjectUI.hit(hotspots_layer,"Entry"+kind.capitalize(),positions[kind])
		var label_rect: Rect2 = labels[kind]
		var label := SchoolObjectUI.text(button,"EntryTitle",ENTRY_TITLES[kind],Rect2(label_rect.position-positions[kind].position,label_rect.size),30,TITLE_INK,true)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		DaylightUI.bind_button_audio(button)
		button.pressed.connect(_open_panel.bind(kind))
		_entries[kind] = button
	btn_lounge = _entries["lounge"]
	btn_workshop = _entries["workshop"]
	btn_records = _entries["records"]
	btn_quest = _entries["quest"]
	var badge_pos := Vector2(labels["records"].position - positions["records"].position) + Vector2(20, -40)
	var badge := SchoolObjectUI.text(btn_records, "ClaimBadge", "", Rect2(badge_pos, Vector2(180, 32)), 17, Color("#FFFBF2"), true)
	badge.add_theme_stylebox_override("normal", DynamicUI.make_paper_tag(Color("#C85242"), Color("#9E3B2E"), 6, 8.0, 2.0))
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.visible = false
	rooftop_button = SchoolObjectUI.hit(hotspots_layer,"RooftopExit",Rect2(62,232,168,50),"去天台",20)
	DaylightUI.bind_button_audio(rooftop_button)
	rooftop_button.pressed.connect(func(): CampusLife.travel_to("rooftop"))
	var talk := SchoolObjectUI.hit(hotspots_layer,"TalkJiangZi",Rect2(345,320,430,380))
	for state in ["normal","hover","pressed","hover_pressed","focus"]: talk.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	DaylightUI.bind_button_audio(talk)
	talk.pressed.connect(_talk_to_jiang)

func _style_journey_shortcut(button: Button) -> void:
	# A dark wash stays visible over the pale illustrated paper, unlike white.
	for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		button.add_theme_color_override(key, TITLE_INK)
	for state in ["hover","pressed","hover_pressed"]:
		var wash := StyleBoxFlat.new()
		wash.bg_color = Color(0.23,0.37,0.53,0.16 if state == "hover" else 0.28)
		wash.set_corner_radius_all(16)
		button.add_theme_stylebox_override(state,wash)
	SchoolObjectUI.borderless(button)

func _activate_primary() -> void:
	var data := PlayerJourney.home_snapshot()
	match data["action"]:
		"story": _start_chapter()
		"workshop": _open_workshop()
		"records_growth":
			_records_open_tab = "growth"
			_open_records()
		"travel_library": CampusLife.travel_to("library")
		"travel_old_park": CampusLife.travel_to("old_park")
		"travel_gym": CampusLife.travel_to("gym")
		"resume_route": _open_training()
		"quest": _open_training()

func _activate_story() -> void:
	_hide_all_modals()
	if not DayCycle.rest(): _set_feedback(DayCycle.block_reason())

func _calendar_changed() -> void:
	_refresh_artwork()
	_update_top_bar()

func _refresh_journey_ui() -> void:
	_update_top_bar()
	if _active_kind in ["workshop","records","zodiac"]: _refresh_active_panel()

func _build_modals_layer() -> void:
	modals_layer = Control.new()
	modals_layer.name = "Modals"
	modals_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	presentation.add_child(modals_layer)
	_place(modals_layer, Vector2.ZERO, DESIGN_SIZE)
	modal_backdrop = ColorRect.new()
	modal_backdrop.name = "ModalBackdrop"
	modal_backdrop.color = Color(0.22, 0.20, 0.29, 0.40)
	modal_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	modals_layer.add_child(modal_backdrop)
	_place(modal_backdrop, Vector2(-600, -300), Vector2(3120, 1680))
	modal_backdrop.gui_input.connect(_on_backdrop_gui_input)
	modals_layer.visible = false

func _label(node_name: String, text: String, font_size: int, font: Font, color: Color) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 0)
	return label

func _place(node: Control, position: Vector2, extent: Vector2) -> void:
	node.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	node.position = position
	node.size = extent

static func artwork_for_period(phase: String) -> Dictionary:
	var suffix := str({"morning":"morning_v1","afternoon":"v3","night":"night_v1"}.get(phase,"v3"))
	var root := "res://assets/ui/player_experience/"
	return {"room":root+"home_room_"+suffix+".png","girl":root+"home_midground_seated_"+suffix+".png","desk":root+"home_foreground_desk_"+suffix+".png","objects":root+"home_objects_"+suffix+".png"}

func _refresh_artwork() -> void:
	var art := artwork_for_period(DayCycle.period())
	var night: bool = DayCycle.period() == "night"
	title_label.add_theme_color_override("font_color",Color("#FFF2D6") if night else TITLE_INK)
	subtitle_label.add_theme_color_override("font_color",Color("#DBE2EA") if night else SUBTITLE_INK)
	var title_wash := presentation.get_node_or_null("TitleHeaderWash") as Panel
	if title_wash != null:
		var wash_style := CombatSkin.flat(Color(0.13, 0.16, 0.26, 0.76) if night else Color(0.98, 0.95, 0.89, 0.82), Vector4.ZERO)
		wash_style.border_color = Color(0.32, 0.37, 0.50, 0.65) if night else Color(0.84, 0.77, 0.68, 0.65)
		wash_style.set_corner_radius_all(22)
		title_wash.add_theme_stylebox_override("panel", wash_style)
	if is_instance_valid(rooftop_button):
		DynamicUI.make_v17_button(rooftop_button, Color(0.24, 0.30, 0.42, 0.96) if night else Color(1.0, 1.0, 1.0, 0.96), Color("#F1F6FC") if night else DynamicUI.V17_INK, 19, 50.0, Vector4(18, 4, 18, 4))
	var rail := top_bar.get_node_or_null("StatusCapsule") as Control if is_instance_valid(top_bar) else null
	if is_instance_valid(rail):
		var rail_box := DynamicUI.v17_capsule_box(DynamicUI.V17_RESOURCE_CAPSULE, 56.0, Color(0.24, 0.30, 0.42, 0.96) if night else Color(1.0, 1.0, 1.0, 0.96))
		if rail_box != null:
			rail.add_theme_stylebox_override("panel", rail_box)
		var cap_col := Color("#B8CAE4") if night else DynamicUI.V17_MUTED
		var val_col := Color("#F1F6FC") if night else DynamicUI.V17_INK
		for child in rail.get_children():
			if child is Label:
				var lbl := child as Label
				lbl.add_theme_color_override("font_color", cap_col if lbl.name.begins_with("Caption") else val_col)
			elif child is TextureRect:
				(child as TextureRect).modulate = Color(0.84, 0.93, 1.0, 0.95) if night else Color.WHITE
	if is_instance_valid(period_dial):
		period_dial.sync_dial()
	room_art.texture = load(art["room"])
	girl_actor.texture = load(art["girl"])
	foreground_art.texture = load(art["desk"])
	var objects := hotspots_layer.get_node("StudentObjects") as TextureRect
	objects.texture = load(art["objects"])

func _layout_home_scene(_extent: Vector2 = Vector2.ZERO) -> void:
	if not is_instance_valid(presentation):
		return
	var bg_tex: Texture2D = room_art.texture if is_instance_valid(room_art) else null
	Platform.fit_stage(self, presentation, Color("#EAE1CE"), bg_tex)
	_layout_modal()

func _update_top_bar() -> void:
	if not is_instance_valid(hp_label):
		return
	hp_label.text = "%d/%d" % [GameState.player_current_hp, GameState.player_max_hp]
	scrap_label.text = str(GameState.scrap_metal)
	crystal_label.text = str(GameState.energy_crystals)
	subtitle_label.text = GameState.get_formatted_time()+"\n在这里歇一会，再一起出发。"
	if is_instance_valid(activity_pip_badge):
		activity_pip_badge.text = "活动 %d/%d" % [DayCycle.remaining(), DayCycleService.ACTIONS_PER_PERIOD]
	if is_instance_valid(period_dial):
		period_dial.sync_dial()
	var activity := PlayerJourney.home_snapshot()
	activity_title.text = activity["title"]
	activity_body.text = activity["body"]
	btn_explore.text = activity["button"]
	story_button.text = activity["story_label"]
	var claim_badge := btn_records.get_node_or_null("ClaimBadge") as Label if is_instance_valid(btn_records) else null
	if is_instance_valid(claim_badge):
		var count: int = int(activity.get("claim_count", 0))
		claim_badge.visible = count > 0
		claim_badge.text = "%d项可盖章" % count


func _panel_context() -> Dictionary:
	return {"selected_card_id": selected_card_id_for_upgrade, "message": _feedback}

func _open_workshop() -> void:
	_open_panel("workshop")

func _open_records() -> void:
	_open_panel("records")

func _open_quest() -> void:
	_hide_all_modals()
	CampusLife.open_map()

func _open_training() -> void:
	_open_quest()

func _open_panel(kind: String) -> void:
	if kind == "training":
		_open_training()
		return
	if kind == "quest":
		_open_quest()
		return
	if SceneManager.is_transitioning or not _entries.has(kind):
		return
	var factory_path := ""
	match kind:
		"lounge": factory_path = "res://scripts/home/school_object_panels.gd"
		"workshop", "records": factory_path = "res://scripts/home/player_workspace.gd"
		"zodiac": factory_path = "res://scripts/home/zodiac_album_panel.gd"
		_: return
	if selected_card_id_for_upgrade == "" and not GameState.unlocked_card_ids.is_empty():
		selected_card_id_for_upgrade = GameState.unlocked_card_ids[0]
	var factory: Variant = load(factory_path)
	_set_feedback("")
	var panel_context := _panel_context()
	if kind == "records" and _records_open_tab != "":
		panel_context["tab"] = _records_open_tab
		_records_open_tab = ""
	var candidate: Variant = factory.create(kind, panel_context)
	if not candidate is Control:
		push_warning("入口弹窗仍在等待对应概念图审核：" + kind)
		return
	_hide_all_modals()
	AudioManager.play_sfx_modal_open()
	_return_focus = _entries[kind]
	_active_kind = kind
	_active_modal = candidate as Control
	_active_modal.name = kind.capitalize() + "Modal"
	if _active_modal is PlayerWorkspace or _active_modal.get_meta("full_scene_overlay", false):
		add_child(_active_modal)
		move_child(_active_modal, presentation.get_index() + 1)
	else:
		modals_layer.add_child(_active_modal)
	_active_modal.connect("close_requested", _hide_all_modals)
	_active_modal.connect("action_requested", _on_panel_action)
	match kind:
		"lounge": lounge_panel = _active_modal
		"workshop": workshop_panel = _active_modal
		"records", "zodiac": records_panel = _active_modal
		"quest", "training": quest_panel = _active_modal
		"explore": explore_panel = _active_modal
	_layout_modal()
	modals_layer.visible = true
	modal_backdrop.visible = true
	_set_hotspots_enabled(false)
	_active_modal.modulate.a = 0.0
	_modal_tween = create_tween()
	_modal_tween.tween_property(_active_modal, "modulate:a", 1.0, SaveManager.motion_duration(0.16))
	_focus_modal.call_deferred()

func _layout_modal() -> void:
	if not is_instance_valid(_active_modal):
		return
	if _active_modal is PlayerWorkspace and _active_modal.get_parent() == self:
		_active_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		return
	if _active_modal.get_meta("full_scene_overlay", false):
		if _active_modal.get_parent() == self:
			_active_modal.position = presentation.position
			_active_modal.scale = presentation.scale
			_active_modal.size = DESIGN_SIZE
		else:
			_place(_active_modal, Vector2.ZERO, DESIGN_SIZE)
		return
	var preferred: Vector2 = _active_modal.get_meta("design_size", _active_modal.custom_minimum_size)
	if preferred.x < 100 or preferred.y < 100:
		preferred = Vector2(1480, 900)
	preferred.x = minf(preferred.x, DESIGN_SIZE.x - 100)
	preferred.y = minf(preferred.y, DESIGN_SIZE.y - 90)
	var design_position := (DESIGN_SIZE - preferred) / 2.0
	if _active_modal.has_meta("design_position"):
		var requested: Variant = _active_modal.get_meta("design_position")
		if requested is Vector2:
			design_position = requested
	_place(_active_modal, design_position, preferred)

func _focus_modal() -> void:
	if not is_instance_valid(_active_modal):
		return
	var close := _active_modal.find_child("CloseButton", true, false) as Button
	if close and close.is_inside_tree():
		close.grab_focus()
	else:
		var focusable := _active_modal.find_children("*", "Button", true, false)
		for candidate in focusable:
			if not candidate.disabled and candidate.is_inside_tree():
				candidate.grab_focus()
				break

func _hide_all_modals() -> void:
	if _modal_tween and _modal_tween.is_valid():
		_modal_tween.kill()
	if is_instance_valid(_active_modal):
		var modal_parent := _active_modal.get_parent()
		if modal_parent != null:
			modal_parent.remove_child(_active_modal)
		_active_modal.queue_free()
	_active_modal = null
	_active_kind = ""
	lounge_panel = null
	workshop_panel = null
	records_panel = null
	quest_panel = null
	explore_panel = null
	if is_instance_valid(modals_layer):
		modals_layer.visible = false
	_set_hotspots_enabled(true)
	if is_instance_valid(_return_focus) and _return_focus.is_inside_tree():
		_return_focus.grab_focus()
	_return_focus = null

func _set_hotspots_enabled(enabled: bool) -> void:
	var title_wash := presentation.get_node_or_null("TitleHeaderWash") as CanvasItem
	if title_wash != null: title_wash.visible = enabled
	if is_instance_valid(period_dial): period_dial.visible = enabled
	if is_instance_valid(activity_pip_badge): activity_pip_badge.visible = enabled
	if is_instance_valid(title_label): title_label.visible = enabled
	if is_instance_valid(subtitle_label): subtitle_label.visible = enabled
	if is_instance_valid(menu_button): menu_button.visible = enabled
	if is_instance_valid(top_bar): top_bar.visible = enabled
	if is_instance_valid(rooftop_button): rooftop_button.visible = enabled
	if is_instance_valid(story_button): story_button.disabled = not enabled
	for button in hotspots_layer.find_children("*","Button",true,false):
		button.disabled = not enabled
		var entry_title := button.get_node_or_null("EntryTitle") as CanvasItem
		if entry_title != null: entry_title.visible = enabled

func _on_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_hide_all_modals()
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if get_meta("campus_dialogue_open",false) or get_meta("campus_map_open",false): return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if is_instance_valid(system_menu): system_menu.go_back()
		elif is_instance_valid(_active_modal):
			if not _active_modal.has_method("cancel_pending") or not _active_modal.call("cancel_pending"): _hide_all_modals()
		else: _open_system_menu()
		get_viewport().set_input_as_handled()

func _open_system_menu() -> void:
	if SceneManager.is_transitioning or is_instance_valid(system_menu): return
	_hide_all_modals()
	system_menu = GameMenu.new()
	add_child(system_menu)
	_set_hotspots_enabled(false)
	menu_button.disabled = true
	system_menu.close_requested.connect(func():
		remove_child(system_menu)
		system_menu.queue_free()
		system_menu = null
		_set_hotspots_enabled(true)
		menu_button.disabled = false
		menu_button.grab_focus()
	)

func _unhandled_input(event: InputEvent) -> void:
	if get_meta("campus_dialogue_open",false) or get_meta("campus_map_open",false): return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_E and not is_instance_valid(_active_modal) and not is_instance_valid(system_menu):
		_open_workshop()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_M and not is_instance_valid(_active_modal) and not is_instance_valid(system_menu):
		_open_quest()
		get_viewport().set_input_as_handled()

func _refresh_inventory_ui() -> void:
	if _active_kind in ["records","zodiac","workshop"] and is_instance_valid(_active_modal):
		_refresh_active_panel()

func _refresh_active_panel() -> void:
	if _panel_refresh_pending: return
	_panel_refresh_pending = true
	_flush_panel_refresh.call_deferred()

func _flush_panel_refresh() -> void:
	_panel_refresh_pending = false
	if is_instance_valid(_active_modal) and _active_modal.has_method("refresh"):
		_active_modal.call("refresh", _panel_context())

func _refresh_workshop_ui() -> void:
	_update_top_bar()
	if _active_kind == "workshop":
		_refresh_active_panel()

func _on_companion_changed(_companion_id: String, _favor: int) -> void:
	if _active_kind in ["lounge","records","zodiac"]:
		_refresh_active_panel()

func _on_story_flag_changed(_flag_name: String, _value: Variant) -> void:
	_update_top_bar()
	_refresh_active_panel()

func _select_card_for_details(card_id: String) -> void:
	if GameState.unlocked_card_ids.has(card_id):
		selected_card_id_for_upgrade = card_id
		_set_feedback("")
		_refresh_workshop_ui()

func _on_equip_toggle_pressed() -> void:
	var card_id := selected_card_id_for_upgrade
	if card_id == "":
		return
	if GameState.equipped_card_ids.has(card_id):
		_set_feedback("已卸下行动卡" if GameState.unequip_card(card_id) else GameState.DECK_RULE_MESSAGE)
	else:
		if GameState.equipped_card_ids.size() >= 5:
			_set_feedback("卡组已满，请在下方选择要替换的卡槽。")
			_refresh_workshop_ui()
			return
		var slot := GameState.equipped_card_ids.size()
		_set_feedback("已装备行动卡" if GameState.equip_card(card_id, slot) else GameState.DECK_RULE_MESSAGE)
	_refresh_workshop_ui()

func _on_panel_action(action: String, payload: Dictionary) -> void:
	var card_id: String = payload.get("card_id", selected_card_id_for_upgrade)
	match action:
		"open_workshop":
			_hide_all_modals()
			_open_workshop()
			return
		"open_records":
			_hide_all_modals()
			_open_panel("records")
			return
		"open_zodiac":
			_hide_all_modals()
			_open_panel("zodiac")
			return
		"close": _hide_all_modals()
		"select_card": _select_card_for_details(card_id)
		"toggle_equip":
			selected_card_id_for_upgrade = card_id
			_on_equip_toggle_pressed()
		"equip", "equip_card":
			selected_card_id_for_upgrade = card_id
			var default_slot := GameState.equipped_card_ids.size()
			if default_slot >= 5 and not payload.has("slot_index"):
				_set_feedback("请选择要替换的卡槽。")
				_refresh_workshop_ui()
				return
			_set_feedback("已装备行动卡" if GameState.equip_card(card_id, int(payload.get("slot_index", default_slot))) else GameState.DECK_RULE_MESSAGE)
			_refresh_workshop_ui()
		"unequip", "unequip_card":
			_set_feedback("已卸下行动卡" if GameState.unequip_card(card_id) else GameState.DECK_RULE_MESSAGE)
			_refresh_workshop_ui()
		"upgrade", "upgrade_card":
			selected_card_id_for_upgrade = card_id
			var quality := str(payload.get("quality","common"))
			var quote := PlayerJourney.training_quote(card_id,quality)
			_set_feedback("练习完成，行动卡已经提升" if GameState.upgrade_card(card_id,quality) else str(quote["reason"]))
			_refresh_workshop_ui()
		"move_card": _move_equipped_card(int(payload.get("from_index", -1)), int(payload.get("to_index", -1)))
		"chat":
			var dialogue_id: String = payload.get("dialogue_id", "")
			var legacy_companion: String = {"chat_yang": "yang_zi_ying", "chat_liu": "liu_yu_long", "chat_jiang": "jiang_zi"}.get(dialogue_id, "")
			var companion_id: String = str(payload.get("companion_id", legacy_companion))
			if companion_id != "" and PhaseTwoContent.SCRIPTS.has(dialogue_id) and GameState.companions.get(companion_id, {}).get("unlocked", false):
				var chat_periods: Dictionary = GameState.player_profile.get("chat_periods", {}).duplicate()
				var period_key := "%s_%d_%s" % [companion_id, GameState.game_day, DayCycle.period()]
				if not chat_periods.has(period_key):
					chat_periods[period_key] = true
					GameState.player_profile["chat_periods"] = chat_periods
					GameState.add_companion_favor(companion_id, 8)
					GameState.profile_changed.emit()
				GameState.pending_dialogue_id = dialogue_id
				_hide_all_modals()
				SceneManager.change_scene(SceneManager.TargetScene.STORY)
		"save_loadout", "apply_loadout":
			var index := int(payload.get("index",0))
			var ok := PlayerJourney.save_loadout(index,payload.get("card_ids",GameState.equipped_card_ids)) if action == "save_loadout" else PlayerJourney.apply_loadout(index)
			_set_feedback(("已保存当前卡组到方案%d" if action == "save_loadout" else "已应用方案%d") % (index+1) if ok else "方案不可用，卡组至少保留一张攻击卡。")
			_refresh_active_panel()
		"claim_milestone":
			_set_feedback("成长奖励已放入仓库" if PlayerJourney.claim_milestone(str(payload.get("id",""))) else "尚未达成、已经领取，或资源已达上限。")
			_refresh_active_panel()
		"use_drink":
			var ok := PlayerJourney.use_drink()
			_set_feedback("已恢复体力" if ok else "体力已满、补给不足，或目前无法操作。")
			_refresh_active_panel()
		"replay_memory": PlayerJourney.open_memory(str(payload.get("dialogue_id","")))
		"open_quest": _open_training()
		"start_exploration": _start_exploration(str(payload.get("dungeon_id", "")))
		"start_chapter": _start_chapter(bool(payload.get("restart", false)))

func _move_equipped_card(from_index: int, to_index: int) -> void:
	var next: Array = GameState.equipped_card_ids.duplicate()
	var count := next.size()
	if from_index < 0 or from_index >= count or to_index < 0 or to_index >= 5:
		return
	if to_index < count:
		var target: String = next[to_index]
		next[to_index] = next[from_index]
		next[from_index] = target
	else:
		var moved: String = next[from_index]
		next.remove_at(from_index)
		next.append(moved)
	GameState.apply_equipped_deck(next)

func _start_exploration(_dungeon_id: String) -> void:
	_open_training()

func _start_chapter(restart: bool = false) -> void:
	if DayCycle.dispatch_due_event():
		return
	if GameState.story_flags.get("chapter_1_completed", false):
		_set_feedback("关键故事会随日期自动到来，今天可以自由安排。")
		return
	if GameState.phase_two_combat_checkpoint.is_empty() and not PlayerJourney.deck_summary()["ready"]:
		_set_feedback(PlayerJourney.deck_summary()["reason"])
		_open_workshop()
		return
	if not GameState.has_method("start_story_from_home"):
		push_error("连续章节流程接口尚未接入")
		return
	_hide_all_modals()
	GameState.call("start_story_from_home", restart)

func _get_home_layout_metrics() -> Dictionary:
	return {
		"design_size": DESIGN_SIZE, "presentation_scale": presentation.scale,
		"title_rect": title_label.get_rect(), "title_font_size": title_label.get_theme_font_size("font_size"),
		"entry_rect": btn_lounge.get_rect(), "entry_font_size": btn_lounge.get_node("EntryTitle").get_theme_font_size("font_size"),
		"actor_rect": girl_actor.get_rect(), "actor_source": girl_actor.texture.resource_path if girl_actor.texture else "",
		"background_source": room_art.texture.resource_path if room_art.texture else "",
		"modal_kind": _active_kind, "modal_input_blocked": modals_layer.visible and modal_backdrop.mouse_filter == Control.MOUSE_FILTER_STOP
	}

var _feedback_serial := 0

func _set_feedback(message: String) -> void:
	_feedback = message
	_feedback_serial += 1
	if message == "" or not is_inside_tree(): return
	var serial := _feedback_serial
	get_tree().create_timer(2.8).timeout.connect(func():
		if serial != _feedback_serial: return
		_feedback = ""
		if is_instance_valid(_active_modal): _refresh_active_panel()
	)

func _talk_to_jiang() -> void:
	if is_instance_valid(_active_modal) or is_instance_valid(system_menu) or get_meta("campus_dialogue_open",false): return
	set_meta("campus_dialogue_open",true)
	_set_hotspots_enabled(false)
	menu_button.disabled = true
	var conversation := CampusDialogueUI.new()
	conversation.lines = CampusLife.npc_lines("jiang_zi")
	presentation.add_child(conversation)
	if conversation.portrait.texture == null:
		conversation.portrait.texture = load("res://assets/sprites/characters/phase_two/portraits/jiang_zi.png")
		conversation.portrait.visible = true
	conversation.closed.connect(func():
		set_meta("campus_dialogue_open",false)
		_set_hotspots_enabled(true)
		menu_button.disabled = false
	)
