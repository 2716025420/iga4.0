class_name SchoolDialoguePresentation
extends Control

var screen: Control
var scene_caption: Label
var cutscene_stage: ParallaxCutsceneStage
var continue_cursor: Label
var _cursor_tween: Tween
var _chapter_banner: Control
var _banner_tween: Tween
var _active_cutscene_id: String = ""
var _staged_bg: SceneStageLayers
var _bg_overlay: TextureRect

func build(owner_screen: Control) -> void:
	screen = owner_screen
	name = "StoryPresentation"
	size = SchoolObjectUI.DESIGN
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = DaylightUI.get_theme()
	var background: TextureRect = screen.get("bg_texture")
	background.reparent(self)
	DaylightUI.place(background, 0, 0, 1920, 1080)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg_overlay = TextureRect.new()
	_bg_overlay.name = "BackdropOverlay"
	_bg_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg_overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg_overlay.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_bg_overlay.visible = false
	add_child(_bg_overlay)
	DaylightUI.place(_bg_overlay, 0, 0, 1920, 1080)
	_staged_bg = SceneStageLayers.new()
	_staged_bg.name = "StagedDialogueBackdrop"
	_staged_bg.visible = false
	add_child(_staged_bg)
	DaylightUI.place(_staged_bg, 0, 0, 1920, 1080)
	cutscene_stage = ParallaxCutsceneStage.create("dusk_corridor", false)
	cutscene_stage.visible = false
	add_child(cutscene_stage)
	DaylightUI.place(cutscene_stage, 0, 0, 1920, 1080)
	for band in [Rect2(-240, 0, 2400, 65), Rect2(-240, 987, 2400, 93)]:
		var wash := ColorRect.new()
		wash.name = "CaptionContrast" if band.position.y == 0 else "ControlsContrast"
		wash.color = Color(0.18, 0.20, 0.28, 0.48 if band.position.y == 0 else 0.65)
		wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(wash)
		DaylightUI.place(wash, band.position.x, band.position.y, band.size.x, band.size.y)
	var actors := Control.new()
	actors.name = "Actors"
	actors.mouse_filter = Control.MOUSE_FILTER_IGNORE
	actors.clip_contents = true
	add_child(actors)
	DaylightUI.place(actors, 0, 0, 1920, 840)
	for index in 2:
		var actor: TextureRect = screen.get("left_char_sprite" if index == 0 else "right_char_sprite")
		actor.reparent(actors)
		actor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		actor.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		actor.mouse_filter = Control.MOUSE_FILTER_IGNORE
		DaylightUI.place(actor, 80 if index == 0 else 1120, 60, 720, 1080)
	SchoolObjectUI.art(self, "StoryChrome", "res://assets/ui/school_objects/story_chrome.png")
	scene_caption = SchoolObjectUI.text(self, "SceneCaption", "校园片段", Rect2(100, 12, 650, 58), 27, Color("#FFF8EC"))
	var speaker: Label = screen.get("nameplate")
	speaker.reparent(self)
	DaylightUI.place(speaker, 265, 717, 240, 62)
	speaker.custom_minimum_size = Vector2.ZERO
	speaker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speaker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	speaker.add_theme_font_size_override("font_size", 34)
	speaker.add_theme_color_override("font_color", Color("#FFF8EC"))
	speaker.add_theme_constant_override("outline_size", 0)
	speaker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var body: RichTextLabel = screen.get("text_label")
	body.reparent(self)
	DaylightUI.place(body, 315, 805, 1415, 155)
	body.add_theme_font_size_override("normal_font_size", 34)
	body.add_theme_font_size_override("bold_font_size", 34)
	body.add_theme_constant_override("line_separation", 12)
	body.add_theme_color_override("default_color", SchoolObjectUI.INK)
	body.scroll_active = true
	body.fit_content = false
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	continue_cursor = SchoolObjectUI.text(self, "ContinueCursor", "点击继续", Rect2(1624, 928, 112, 36), 19, Color("#6D6257"))
	continue_cursor.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	continue_cursor.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	continue_cursor.visible = false
	var choices: PanelContainer = screen.get("choices_panel")
	choices.reparent(self)
	DaylightUI.place(choices, 690, 440, 600, 190)
	choices.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var options: VBoxContainer = screen.get("choices_container")
	options.add_theme_constant_override("separation", 14)
	var controls: HBoxContainer = screen.get_node("ControlBar")
	controls.reparent(self)
	DaylightUI.place(controls, 86, 995, 850, 64)
	var pause: Button = screen.get("pause_button")
	pause.reparent(controls)
	controls.move_child(pause, 0)
	pause.text = "Ⅱ  暂离"
	var skip: Button = screen.get("skip_button")
	skip.text = "▷▷  跳至选项"
	var auto: Button = screen.get("auto_button")
	auto.text = "▷  自动"
	var record: Button = screen.get("record_button")
	record.text = "▤  记录"
	controls.add_theme_constant_override("separation", 26)
	for button in [pause, auto, skip, record]:
		button.custom_minimum_size = Vector2(230 if button == skip else 145, 58)
		button.add_theme_font_size_override("font_size", 27)
		for state in ["normal", "disabled"]: button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		for state in ["hover", "pressed", "hover_pressed"]:
			var wash := StyleBoxFlat.new()
			wash.bg_color = Color(1, 0.94, 0.83, 0.17)
			wash.set_border_width_all(0)
			button.add_theme_stylebox_override(state, wash)
		SchoolObjectUI.borderless(button)
		DaylightUI.bind_button_audio(button)
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]: button.add_theme_color_override(state, Color("#FFF6E8"))
	SchoolObjectUI.text(self, "ReadingHint", "Enter / Space 继续", Rect2(1480, 1005, 340, 45), 25, Color("#FFF6E8"), true)
	var records: Control = screen.get("history_panel")
	records.reparent(self)
	DaylightUI.place(records, 0, 0, 1920, 1080)
	for old_name in ["CharArea", "DialogueBox"]: screen.get_node(old_name).hide()
	update_scene()

func update_scene(override_cutscene_id: String = "") -> void:
	var id := str(screen.get("current_dialogue_id"))
	var key := PhaseTwoContent.background_key(id)
	if bool(screen.get("_exploration_mode")): key = "dusk_road"
	var path := PhaseTwoContent.resolve_background_path(key, true)
	if id == "school_affairs" and ResourceLoader.exists("res://assets/ui/scene_reset/staged/library/library_midground_wide.png"):
		path = "res://assets/ui/scene_reset/staged/library/library_midground_wide.png"
	if path != "" and ResourceLoader.exists(path): screen.get("bg_texture").texture = load(path)
	var location: String = {
		"prologue_sakura_road": "樱林上学路",
		"prologue_sports_field": "操场海选赛",
		"prologue_club_meeting": "阿瑞忒社团教室",
		"ch1_library_path": "清晨海风林荫小路",
		"morning_road": "上学路",
		"school_gate": "运动会场边",
		"school_room": "社团教室",
		"dusk_road": "旧公园夕照"
	}.get(key, "校园片段")
	if id == "school_affairs": location = "阿瑞忒图书馆"
	scene_caption.text = ("回忆片段" if bool(screen.get("_archive_mode")) else ("探索片段" if bool(screen.get("_exploration_mode")) else "剧情放映")) + "   /   " + location
	var calendar_geometry := get_node_or_null("CalendarLocationGeometry")
	if calendar_geometry != null: calendar_geometry.hide()
	var bg_rect := screen.get("bg_texture") as TextureRect
	var cutscene_id := ""
	if not bool(screen.get("_calendar_mode")) and not bool(screen.get("_exploration_mode")):
		if override_cutscene_id != "" and ParallaxCutsceneStage.PRESETS.has(override_cutscene_id):
			cutscene_id = override_cutscene_id
		else:
			cutscene_id = ParallaxCutsceneStage.preset_for_dialogue(id, CampusLife.current_region)
	var use_cutscene := cutscene_id != ""
	if is_instance_valid(cutscene_stage):
		cutscene_stage.visible = use_cutscene
		if use_cutscene:
			if cutscene_stage.preset_id != cutscene_id:
				_active_cutscene_id = id
				cutscene_stage.configure(cutscene_id, true)
			elif _active_cutscene_id != id:
				_active_cutscene_id = id
				cutscene_stage.play(true)
			else:
				cutscene_stage._apply_transforms()
		else:
			_active_cutscene_id = ""
	var staged_place_id := ""
	if id == "school_affairs":
		staged_place_id = "library"
	elif bool(screen.get("_calendar_mode")):
		var cal_place := str(DayCycle.pending_event().get("location", "club"))
		if SceneStageLayers.has_staged_blueprint(cal_place):
			staged_place_id = cal_place
	var use_staged := (not use_cutscene) and staged_place_id != "" and SceneStageLayers.has_staged_blueprint(staged_place_id)
	if is_instance_valid(_staged_bg):
		_staged_bg.visible = use_staged
		if use_staged:
			if _staged_bg.location_id != staged_place_id:
				_staged_bg.configure(staged_place_id, false)
			else:
				_staged_bg.apply_period_lighting()
	if is_instance_valid(bg_rect):
		bg_rect.visible = (not use_cutscene) and (not use_staged)
	if bool(screen.get("_calendar_mode")):
		var place_id := str(DayCycle.pending_event().get("location","club"))
		var place: Dictionary = CampusPlaces.PLACES[place_id]
		var bg_file := str(place.get("background",""))
		var place_path := ("res://assets/backgrounds/phase_two/" + bg_file) if bg_file != "" else ""
		if place_id == "club": place_path = str(HomeScreen.artwork_for_period(DayCycle.period())["room"])
		if SceneDesignCatalog.place_path(place_id) != "" and ResourceLoader.exists(SceneDesignCatalog.place_path(place_id)):
			screen.get("bg_texture").texture = load(SceneDesignCatalog.place_path(place_id))
		elif place.get("geometry",false):
			if calendar_geometry == null:
				calendar_geometry = RegionGeometry.new()
				calendar_geometry.name = "CalendarLocationGeometry"
				add_child(calendar_geometry)
				move_child(calendar_geometry,0)
			calendar_geometry.region_id = RegionCatalog.region_for_place(place_id)
			calendar_geometry.place_id = place_id
			calendar_geometry.show()
			calendar_geometry.queue_redraw()
			screen.get("bg_texture").hide()
		elif ResourceLoader.exists(place_path): screen.get("bg_texture").texture = load(place_path)
		scene_caption.text = GameState.get_detailed_time_string()+" / "+str(place["title"])
	if is_instance_valid(bg_rect):
		bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		if bg_rect.texture != null and bg_rect.texture.get_width() > 2100:
			DaylightUI.place(bg_rect, -210, 0, 2340, 1080)
		else:
			DaylightUI.place(bg_rect, 0, 0, 1920, 1080)
	if is_instance_valid(_bg_overlay):
		var allow_overlay := not bool(screen.get("_calendar_mode")) and not bool(screen.get("_exploration_mode")) and is_instance_valid(bg_rect) and bg_rect.visible
		var bg_is_wide := is_instance_valid(bg_rect) and bg_rect.texture != null and bg_rect.texture.get_width() > 2100
		var overlay_path := PhaseTwoContent.resolve_background_overlay_path(id, key, bg_is_wide) if allow_overlay else ""
		if overlay_path != "" and ResourceLoader.exists(overlay_path):
			_bg_overlay.texture = load(overlay_path) as Texture2D
			_bg_overlay.visible = _bg_overlay.texture != null
			if _bg_overlay.texture != null and _bg_overlay.texture.get_width() > 2100:
				DaylightUI.place(_bg_overlay, -210, 0, 2340, 1080)
			else:
				DaylightUI.place(_bg_overlay, 0, 0, 1920, 1080)
		else:
			_bg_overlay.visible = false
			_bg_overlay.texture = null
	var bg_tex: Texture2D = cutscene_stage.background_texture() if use_cutscene and is_instance_valid(cutscene_stage) else (bg_rect.texture if is_instance_valid(bg_rect) and bg_rect.visible else null)
	Platform.fit_stage(screen, self, Color("#242834"), bg_tex)
	if use_cutscene and is_instance_valid(cutscene_stage):
		cutscene_stage._apply_transforms()

func set_continue_cursor_visible(should_show: bool) -> void:
	if not is_instance_valid(continue_cursor):
		return
	continue_cursor.visible = should_show
	if _cursor_tween != null and _cursor_tween.is_valid():
		_cursor_tween.kill()
		_cursor_tween = null
	if not should_show or bool(SaveManager.settings.get("reduced_motion", false)):
		continue_cursor.modulate.a = 0.85
		continue_cursor.position.x = 1624.0
		return
	continue_cursor.modulate.a = 0.50
	continue_cursor.position.x = 1620.0
	_cursor_tween = create_tween().set_loops()
	_cursor_tween.tween_property(continue_cursor, "modulate:a", 0.95, 0.6).set_trans(Tween.TRANS_SINE)
	_cursor_tween.parallel().tween_property(continue_cursor, "position:x", 1626.0, 0.6).set_trans(Tween.TRANS_SINE)
	_cursor_tween.tween_property(continue_cursor, "modulate:a", 0.50, 0.6).set_trans(Tween.TRANS_SINE)
	_cursor_tween.parallel().tween_property(continue_cursor, "position:x", 1620.0, 0.6).set_trans(Tween.TRANS_SINE)

func show_chapter_banner(title_text: String) -> void:
	var banner_path := "res://assets/ui_core/animations/ui_chapter_banner.png"
	if not ResourceLoader.exists(banner_path) or title_text.strip_edges().is_empty():
		return
	hide_chapter_banner()
	_chapter_banner = Control.new()
	_chapter_banner.name = "ChapterBannerToast"
	_chapter_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chapter_banner.z_index = 25
	add_child(_chapter_banner)
	DaylightUI.place(_chapter_banner, 280, 72, 1360, 226)
	var plate := TextureRect.new()
	plate.name = "BannerPlate"
	plate.texture = load(banner_path) as Texture2D
	plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	plate.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chapter_banner.add_child(plate)
	DaylightUI.place(plate, 0, 0, 1360, 226)
	var lbl := SchoolObjectUI.text(_chapter_banner, "BannerTitle", title_text, Rect2(170, 64, 1020, 98), 35, Color("#FFF3D4"), true)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", load("res://assets/fonts/NotoSerifSC-SemiBold.ttf"))
	if bool(SaveManager.settings.get("reduced_motion", false)):
		_chapter_banner.modulate.a = 0.96
		return
	_chapter_banner.modulate.a = 0.0
	_banner_tween = create_tween()
	_banner_tween.tween_property(_chapter_banner, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_CUBIC)
	_banner_tween.tween_interval(2.0)
	_banner_tween.tween_property(_chapter_banner, "modulate:a", 0.0, 0.45).set_trans(Tween.TRANS_SINE)
	_banner_tween.tween_callback(hide_chapter_banner)

func hide_chapter_banner() -> void:
	if _banner_tween != null and _banner_tween.is_valid():
		_banner_tween.kill()
		_banner_tween = null
	if is_instance_valid(_chapter_banner):
		_chapter_banner.queue_free()
		_chapter_banner = null
