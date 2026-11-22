extends Node

var state: Node
var life: CampusLifeService
var flow: ProjectSceneFlow
var saves: SaveService
var cycle: DayCycleService
var captures := ""
var captured_count := 0
var failures: Array[String] = []

func _ready() -> void:
	if "--fullscreen-capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		get_window().mode = Window.MODE_FULLSCREEN
	get_tree().current_scene = null
	_run.call_deferred()

func _fail(msg: String) -> void:
	failures.append(msg)
	printerr("FAIL: " + msg)

func _settled() -> void:
	var start := Time.get_ticks_msec()
	while flow.is_transitioning and Time.get_ticks_msec() - start < 20000:
		await get_tree().process_frame
	if flow.is_transitioning or flow.last_error != "":
		_fail("scene transition failed: " + flow.last_error)
	await get_tree().process_frame
	await get_tree().process_frame

func _capture(label: String) -> void:
	if captures == "" or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var out := captures.path_join(label + ".png")
	if get_tree().root.get_texture().get_image().save_png(out) != OK:
		_fail("save screenshot " + label)
	else:
		captured_count += 1

func _run() -> void:
	state = get_tree().root.get_node("GameState")
	life = get_tree().root.get_node("CampusLife")
	flow = get_tree().root.get_node("SceneManager")
	saves = get_tree().root.get_node("SaveManager")
	cycle = get_tree().root.get_node("DayCycle")
	cycle.suspended = true
	saves.save_path = "user://capture_tests/slot_1.json"
	saves.settings["reduced_motion"] = true
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--captures="):
			captures = arg.trim_prefix("--captures=")
	if captures != "":
		DirAccess.make_dir_recursive_absolute(captures)

	# 1. Title Screen
	flow.change_scene(flow.TargetScene.TITLE)
	await _settled()
	await _capture("01_title")

	# 2. Test Save Home, Projection Room (Records), Workshop & Lounge
	if not saves.load_test_save():
		_fail("load_test_save failed")
	flow.change_scene(flow.TargetScene.HOME)
	await _settled()
	await _capture("02_home_club")

	var home: HomeScreen = get_tree().current_scene
	home._open_panel("records")
	await get_tree().process_frame
	await _capture("03_projection_records")
	home._hide_all_modals()

	home._open_workshop()
	await get_tree().process_frame
	await _capture("04_workshop")
	home._hide_all_modals()

	home._open_panel("zodiac")
	await get_tree().process_frame
	await _capture("19_zodiac_overview")
	var zodiac_panel := home._active_modal as ZodiacAlbumPanel
	if is_instance_valid(zodiac_panel):
		zodiac_panel._select_badge("hero")
		await get_tree().process_frame
		await get_tree().process_frame
		await _capture("20_zodiac_book_detail")
	home._hide_all_modals()

	# 3. Local Map (with Qualifier badge) & World Atlas
	life.open_map()
	await _settled()
	await _capture("05_campus_map")
	life.open_region_atlas()
	await _settled()
	await _capture("06_world_atlas")

	# 4. Key Campus Scenes with Resident NPCs + Shop Counter + Gym Qualifier + Old Park
	life.travel_to("library", "university_arete")
	await _settled()
	await _capture("07_library_npc")
	var lib_screen: CampusScreen = get_tree().current_scene
	lib_screen._action({"id": "talk", "npc": "lin_zhi_xia"})
	await get_tree().process_frame
	if is_instance_valid(lib_screen.dialogue):
		lib_screen.dialogue.advance()
		await get_tree().process_frame
	await _capture("15_campus_dialogue")
	if is_instance_valid(lib_screen.dialogue):
		lib_screen.dialogue._close()
		await get_tree().process_frame

	life.travel_to("shop", "university_arete")
	await _settled()
	await _capture("08_shop_npc")
	var shop_screen: CampusScreen = get_tree().current_scene
	shop_screen._open_workspace("shop")
	await get_tree().process_frame
	await _capture("09_shop_counter")
	shop_screen._close_workspace()

	life.travel_to("gym", "university_arete")
	await _settled()
	await _capture("16_gym_stage")
	var gym_screen: CampusScreen = get_tree().current_scene
	gym_screen._open_qualifier_modal()
	await get_tree().process_frame
	await _capture("10_gym_qualifier")
	gym_screen._close_qualifier_modal()

	life.travel_to("old_park", "university_arete")
	await _settled()
	await _capture("11_old_park")

	life.travel_to("arete_coast_test", "university_arete")
	await _settled()
	await _capture("12_coast")

	life.travel_to("rooftop", "university_arete")
	await _settled()
	await _capture("13_rooftop")
	var roof_screen: CampusScreen = get_tree().current_scene
	if is_instance_valid(roof_screen.scene_objects) and is_instance_valid(roof_screen.scene_objects.stage_layers):
		var sl: SceneStageLayers = roof_screen.scene_objects.stage_layers
		sl.force_sky_mode = "dusk"
		sl.apply_period_lighting("afternoon", false)
		await get_tree().process_frame
		await _capture("17_rooftop_dusk")
		sl.force_sky_mode = "redmoon"
		sl.apply_period_lighting("night", true)
		await get_tree().process_frame
		await _capture("18_rooftop_redmoon")
		sl.force_sky_mode = ""
		sl.apply_period_lighting()

	life.travel_to("arete_beach_test", "university_arete")
	await _settled()
	await _capture("14_beach")

	life.travel_to("dorm", "university_arete")
	await _settled()
	await _capture("21_dorm")

	# 5. New Prologue Scenes (Sakura Road, Sports Field Dialogue, 2v2 Duel, Club Meeting)
	saves.test_session = false
	saves.active_session = false
	if not state.new_game():
		_fail("new_game failed before prologue captures")
	await _settled()
	state.start_story_from_home()
	await _settled()
	var dlg := get_tree().current_scene as DialogueScreen
	if is_instance_valid(dlg):
		if is_instance_valid(dlg.story_presentation):
			dlg.story_presentation.hide_chapter_banner()
		dlg.line_index = 1
		dlg._show_next_line()
		if dlg.tween_typing and dlg.tween_typing.is_valid():
			dlg.tween_typing.kill()
		dlg._reveal_current_line()
		await get_tree().process_frame
		await get_tree().process_frame
		await _capture("22_prologue_sakura")
		dlg.line_index = 17
		dlg._show_next_line()
		if dlg.tween_typing and dlg.tween_typing.is_valid():
			dlg.tween_typing.kill()
		dlg.line_index = 18
		dlg._show_next_line()
		if dlg.tween_typing and dlg.tween_typing.is_valid():
			dlg.tween_typing.kill()
		dlg._reveal_current_line()
		await get_tree().process_frame
		await get_tree().process_frame
		await _capture("26_prologue_thugs")
		dlg._finish_dialogue()
		await _settled()

	var gate_dlg := get_tree().current_scene as DialogueScreen
	if is_instance_valid(gate_dlg):
		gate_dlg.line_index = 25
		gate_dlg._show_next_line()
		if gate_dlg.tween_typing and gate_dlg.tween_typing.is_valid():
			gate_dlg.tween_typing.kill()
		gate_dlg.line_index = 26
		gate_dlg._show_next_line()
		if gate_dlg.tween_typing and gate_dlg.tween_typing.is_valid():
			gate_dlg.tween_typing.kill()
		gate_dlg._reveal_current_line()
		await get_tree().process_frame
		await get_tree().process_frame
		await _capture("23_prologue_sports_field")
		gate_dlg._finish_dialogue()
		await _settled()

	await get_tree().process_frame
	await get_tree().process_frame
	await _capture("24_prologue_duel_2v2")

	state.complete_phase_two_step("n_gate")
	await _settled()
	var club_dlg := get_tree().current_scene as DialogueScreen
	if is_instance_valid(club_dlg):
		club_dlg.line_index = 0
		club_dlg._show_next_line()
		if club_dlg.tween_typing and club_dlg.tween_typing.is_valid():
			club_dlg.tween_typing.kill()
		club_dlg.line_index = 3
		club_dlg._show_next_line()
		if club_dlg.tween_typing and club_dlg.tween_typing.is_valid():
			club_dlg.tween_typing.kill()
		club_dlg._reveal_current_line()
		await get_tree().process_frame
		await get_tree().process_frame
		await _capture("25_prologue_club_meeting")

	# 6. Nighttime Auto-Switched Campus Map & 1v1 Overclock Combat Symmetry
	if not saves.load_test_save():
		_fail("load_test_save failed before night map capture")
	state.game_hour = 20
	flow.change_scene(flow.TargetScene.HOME)
	await _settled()
	life.open_map()
	await _settled()
	await _capture("27_campus_map_night")

	saves.test_session = false
	saves.active_session = false
	if not state.new_game():
		_fail("new_game failed before 1v1 overclock capture")
	await _settled()
	state.current_node_id = "n_guard"
	state.pending_combat_data = {"enemies": ["security_guard"], "overclock": true}
	flow.change_scene(flow.TargetScene.COMBAT)
	await _settled()
	await _capture("28_combat_1v1_overclock")

	print("CAPTURE_SCENES_RESULT " + JSON.stringify({"captures": captured_count, "failures": failures, "renderer": DisplayServer.get_name()}))
	get_tree().quit(0 if failures.is_empty() else 1)
