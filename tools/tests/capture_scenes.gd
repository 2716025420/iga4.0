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

	print("CAPTURE_SCENES_RESULT " + JSON.stringify({"captures": captured_count, "failures": failures, "renderer": DisplayServer.get_name()}))
	get_tree().quit(0 if failures.is_empty() else 1)
