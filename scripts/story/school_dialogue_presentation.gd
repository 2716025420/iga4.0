class_name SchoolDialoguePresentation
extends Control

var screen: Control
var scene_caption: Label
var cutscene_stage: ParallaxCutsceneStage
var _active_cutscene_id: String = ""

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
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]: button.add_theme_color_override(state, Color("#FFF6E8"))
	SchoolObjectUI.text(self, "ReadingHint", "Enter / Space 继续", Rect2(1480, 1005, 340, 45), 25, Color("#FFF6E8"), true)
	var records: Control = screen.get("history_panel")
	records.reparent(self)
	DaylightUI.place(records, 0, 0, 1920, 1080)
	for old_name in ["CharArea", "DialogueBox"]: screen.get_node(old_name).hide()
	update_scene()

func update_scene() -> void:
	var id := str(screen.get("current_dialogue_id"))
	var key := PhaseTwoContent.background_key(id)
	if bool(screen.get("_exploration_mode")): key = "dusk_road"
	var path := "res://assets/backgrounds/phase_two/%s_wide.png" % key
	if not ResourceLoader.exists(path): path = "res://assets/backgrounds/phase_two/%s.png" % key
	if ResourceLoader.exists(path): screen.get("bg_texture").texture = load(path)
	var location: String = {"morning_road":"上学路", "school_gate":"校门前", "school_room":"课间", "dusk_road":"放学以后"}.get(key, "校园片段")
	scene_caption.text = ("回忆片段" if bool(screen.get("_archive_mode")) else ("探索片段" if bool(screen.get("_exploration_mode")) else "校园片段")) + "   /   " + location
	var calendar_geometry := get_node_or_null("CalendarLocationGeometry")
	if calendar_geometry != null: calendar_geometry.hide()
	var bg_rect := screen.get("bg_texture") as TextureRect
	var use_cutscene := not bool(screen.get("_calendar_mode")) and not bool(screen.get("_exploration_mode")) and id == "after_school"
	if is_instance_valid(cutscene_stage):
		cutscene_stage.visible = use_cutscene
		if use_cutscene:
			if _active_cutscene_id != id:
				_active_cutscene_id = id
				cutscene_stage.play(true)
			else:
				cutscene_stage._apply_transforms()
		else:
			_active_cutscene_id = ""
	if is_instance_valid(bg_rect):
		bg_rect.visible = not use_cutscene
	if bool(screen.get("_calendar_mode")):
		var place_id := str(DayCycle.pending_event().get("location","club"))
		var place: Dictionary = CampusPlaces.PLACES[place_id]
		var place_path := CampusPlaces.ROOT+str(place.get("background",""))
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
	var bg_tex: Texture2D = cutscene_stage.background_texture() if use_cutscene and is_instance_valid(cutscene_stage) else (bg_rect.texture if is_instance_valid(bg_rect) and bg_rect.visible else null)
	Platform.fit_stage(screen, self, Color("#242834"), bg_tex)
	if use_cutscene and is_instance_valid(cutscene_stage):
		cutscene_stage._apply_transforms()
