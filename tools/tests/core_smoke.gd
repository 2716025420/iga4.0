extends Node

var state: Node
var life: CampusLifeService
var flow: ProjectSceneFlow
var saves: SaveService
var cycle: DayCycleService
var checks := 0
var failures: Array[String] = []

func _ready() -> void:
	get_tree().current_scene = null
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		printerr("FAIL: " + message)

func _settled() -> void:
	var start := Time.get_ticks_msec()
	while flow.is_transitioning and Time.get_ticks_msec() - start < 20000:
		await get_tree().process_frame
	check(not flow.is_transitioning and flow.last_error == "", "scene transition clean")
	await get_tree().process_frame
	await get_tree().process_frame

func _scan_clean_ui(root: Node, tag: String) -> void:
	var nodes := [root] + root.find_children("*", "", true, false)
	for n in nodes:
		if n is Label or n is Button or n is RichTextLabel:
			var txt := str(n.get("text"))
			check(not txt.contains("TEST"), "%s clean of TEST (%s)" % [tag, txt.left(28)])
			check(not txt.contains("学生智能终端"), "%s de-terminalized (%s)" % [tag, txt.left(28)])

func _run() -> void:
	state = get_tree().root.get_node("GameState")
	life = get_tree().root.get_node("CampusLife")
	flow = get_tree().root.get_node("SceneManager")
	saves = get_tree().root.get_node("SaveManager")
	cycle = get_tree().root.get_node("DayCycle")
	cycle.suspended = true
	saves.save_path = "user://core_smoke/slot_1.json"
	saves.settings["reduced_motion"] = true

	await _test_scenes_and_saves()
	await _test_rules_and_economy()
	await _test_progression_state_machine()
	await _test_ui_cleanliness()

	print("CORE_SMOKE_RESULT " + JSON.stringify({"checks": checks, "failures": failures, "renderer": DisplayServer.get_name()}))
	get_tree().quit(0 if failures.is_empty() else 1)

func _test_scenes_and_saves() -> void:
	for path in [
		"res://scenes/title/title_screen.tscn",
		"res://scenes/home/home_screen.tscn",
		"res://scenes/story/dialogue_screen.tscn",
		"res://scenes/combat/combat_screen.tscn",
		"res://scenes/campus/campus_screen.tscn",
		"res://scenes/campus/local_map_screen.tscn",
		"res://scenes/campus/region_atlas_screen.tscn",
		"res://scenes/exploration/node_map.tscn",
		"res://scenes/exploration/school_route_screen.tscn"
	]:
		var packed := load(path) as PackedScene
		check(packed != null, "scene compiles: " + path)
	check(saves.start_new_game(), "new game saves cleanly")
	var fresh: Dictionary = state.export_progress(false).duplicate(true)
	check(state.validate_progress(fresh), "fresh save validates")
	check(saves.continue_game(), "continue_game loads fresh save")
	# Synthetic legacy save migration check (no activities/reading_notes/chat_periods, old 9 nodes)
	var legacy: Dictionary = fresh.duplicate(true)
	legacy["player_profile"].erase("activities")
	legacy["player_profile"].erase("reading_notes")
	legacy["player_profile"].erase("chat_periods")
	legacy["player_profile"].erase("campus_life")
	legacy["visited_node_ids"] = ["n0", "n_gate", "n_affairs"]
	legacy["story_flags"]["school_affairs_done"] = true
	check(state.import_progress(legacy), "legacy save migrates cleanly")
	check(state.visited_node_ids.has("n_club_intro"), "legacy migration inserts n_club_intro")
	check(bool(state.story_flags.get("prologue_completed", false)), "legacy migration marks prologue_completed")
	check(saves.load_test_save(), "test preset save loads")
	await _settled()

func _test_rules_and_economy() -> void:
	saves.test_session = false
	saves.active_session = false
	check(state.new_game(), "reset to clean game for economy rules")
	await _settled()
	check(ZodiacCatalog.ORDER.size() == 12, "12 zodiac definitions")
	for zid in ZodiacCatalog.ORDER:
		check(CampusShopCatalog.definition(zid).is_empty(), "zodiac absent from shop: " + zid)
	# Deck rules: min 1 attack, max 5
	check(PlayerJourney.deck_summary(["wrench_smash"])["ready"], "single attack card deck valid")
	check(not PlayerJourney.deck_summary(["scrap_shield"])["ready"], "no-attack deck rejected")
	# Shop tiers: Tier 1 has 6 cards initially, locked tiers rejected
	check(CampusShopCatalog.unlocked_card_stock_count() == 6, "initial shop carries 6 tier-1 cards")
	check(not CampusShopCatalog.quote("card_fake_cheque", 1, "buy")["ok"], "tier-2 card locked early")
	# Card upgrade consumes 0 actions
	state.add_scrap(50, false)
	var before_actions := cycle.remaining()
	check(PlayerJourney.train("wrench_smash", "common"), "card upgrade succeeds with 0 action cost")
	check(cycle.remaining() == before_actions, "card upgrade does not spend action")
	check(int(state.card_levels.get("wrench_smash", 1)) == 2, "card upgraded to Lv.2")
	# Familiarity scales Companion Assist values across Lv.1 / Lv.2 / Lv.3
	check(int(PlayerJourney.companion_assist_spec("yang_zi_ying")["tier"]) == 1, "yang assist starts Lv.1")
	state.add_companion_favor("yang_zi_ying", 20)
	check(int(PlayerJourney.companion_assist_spec("yang_zi_ying")["tier"]) == 2, "yang assist scales to Lv.2 at favor>=35")
	state.add_companion_favor("yang_zi_ying", 35)
	check(int(PlayerJourney.companion_assist_spec("yang_zi_ying")["tier"]) == 3, "yang assist scales to Lv.3 at favor>=70")
	# Library study & Shop work economy
	life.current_location = "library"
	var pts_before: int = state.scrap_metal
	var study_res := life.study_in_library()
	check(not study_res.is_empty() and state.scrap_metal == pts_before + 35, "library study awards +35 practice points")
	check(state.player_profile.get("reading_notes", []).size() == 1, "library study unlocks reading note #1")
	check(cycle.remaining() == before_actions - 1, "library study spends 1 action")
	life.current_location = "shop"
	var money_before: int = state.energy_crystals
	life.work_in_shop()
	check(state.energy_crystals == money_before + 100, "shop work awards +100 allowance")
	check(cycle.remaining() == before_actions - 2, "shop work spends 1 action")
	# Atomic shop buy + anti-replay
	var buy1: Dictionary = state.execute_shop_trade("card_desk_vault", 1, "buy", "smoke_req_1")
	check(bool(buy1.get("ok", false)) and state.unlocked_card_ids.has("desk_vault"), "shop purchase succeeds atomically")
	var replay: Dictionary = state.execute_shop_trade("card_desk_vault", 1, "buy", "smoke_req_1")
	check(not bool(replay.get("ok", false)), "duplicate receipt blocked")

func _test_progression_state_machine() -> void:
	saves.test_session = false
	saves.active_session = false
	check(state.new_game(), "reset for progression state machine")
	await _settled()
	check(state.next_phase_two_node() == "n0", "starts at n0")
	check(PlayerJourney.home_snapshot()["action"] == "story", "home points to prologue start")
	# Complete Prologue: n0 -> n_gate -> n_club_intro (stops cleanly at club!)
	check(state.complete_phase_two_step("n0"), "n0 completes")
	await _settled()
	check(state.complete_phase_two_step("n_gate"), "n_gate completes")
	await _settled()
	check(state.complete_phase_two_step("n_club_intro"), "n_club_intro completes")
	await _settled()
	check(bool(state.story_flags.get("prologue_completed", false)), "prologue_completed set")
	check(not bool(state.story_flags.get("chapter_1_completed", false)), "chapter 1 not skipped after prologue")
	check(state.next_phase_two_node() == "n_affairs", "waits at Act 1 n_affairs")
	# Stage 1 Onboarding: equip 4th card -> claim prepare stamp
	check(PlayerJourney.home_snapshot()["action"] == "workshop", "onboarding step 1 guides to workshop")
	check(state.equip_card("overclock_torch", 3), "equip 4th card")
	check(PlayerJourney.home_snapshot()["action"] == "records_growth", "onboarding step 2 guides to projection room")
	var cash_before: int = state.energy_crystals
	check(PlayerJourney.claim_milestone("prepare"), "claim prepare stamp in projection room")
	check(state.energy_crystals == cash_before + 120, "prepare stamp grants +120 allowance")
	# Act 1 Campus Prep -> Library ready
	check(PlayerJourney.home_snapshot()["action"] == "quest", "Act 1 guides to campus map")
	life.study_in_library()
	check(PlayerJourney.act1_story_ready(), "Act 1 ready after 1 activity")
	check(PlayerJourney.home_snapshot()["action"] == "travel_library", "home points to library for Act 1 story")
	# Act 1 story completes cleanly & unlocks tier-2 shop + Act 2
	check(state.complete_phase_two_step("n_affairs"), "n_affairs completes")
	await _settled()
	check(bool(state.story_flags.get("school_affairs_done", false)), "school_affairs_done set")
	check(CampusShopCatalog.unlocked_card_stock_count() == 11, "tier-2 shop opens to 11 cards")
	check(not PlayerJourney.act2_combat_ready(), "Act 2 requires 5-card deck or Lv.2 card")
	check(PlayerJourney.train("wrench_smash", "common"), "upgrade wrench_smash to Lv.2")
	check(PlayerJourney.act2_combat_ready(), "Act 2 ready once upgraded")
	check(PlayerJourney.home_snapshot()["action"] == "travel_old_park", "home points to old_park")
	# Act 3 Climax -> Chapter 1 completed & #01 Aries collected
	for nid in ["n_dusk", "n_guard", "n_rescue", "n_robot", "n5_boss", "n_find_yang"]:
		check(state.complete_phase_two_step(nid), "complete climax step " + nid)
		await _settled()
	check(bool(state.story_flags.get("chapter_1_completed", false)), "chapter_1_completed set")
	check(SpecialCardCollection.collected("hero"), "Aries Mother-Card auto-collected")
	check(state.get_active_zodiac_id() == "hero", "Aries Resonance active")
	check(CampusShopCatalog.unlocked_card_stock_count() == 16, "all 16 shop cards unlocked")
	# Stage 3 Qualifier: points to gym until r1..r3 done
	check(PlayerJourney.home_snapshot()["action"] == "travel_gym", "post-Ch1 points to gym qualifier")
	check(PlayerJourney.qualifier_next_round() == 1, "qualifier starts at round 1")
	state.set_story_flag("qualifier_r1_won", true)
	check(PlayerJourney.qualifier_next_round() == 2, "qualifier advances to round 2")
	state.set_story_flag("qualifier_r2_won", true)
	state.set_story_flag("qualifier_r3_won", true)
	state.set_story_flag("arete_qualifier_completed", true)
	check(PlayerJourney.qualifier_next_round() == 0, "qualifier finished")
	check(PlayerJourney.home_snapshot()["action"] == "quest", "post-qualifier shows representative completion")

func _test_ui_cleanliness() -> void:
	check(saves.load_test_save(), "load test save for UI inspection")
	flow.change_scene(flow.TargetScene.HOME)
	await _settled()
	_scan_clean_ui(get_tree().current_scene, "HomeScreen")
	var home: HomeScreen = get_tree().current_scene
	home._open_panel("records")
	await get_tree().process_frame
	_scan_clean_ui(home._active_modal, "ProjectionRecords")
	home._hide_all_modals()
	home._open_workshop()
	await get_tree().process_frame
	_scan_clean_ui(home._active_modal, "Workshop")
	home._hide_all_modals()

	life.open_map()
	await _settled()
	_scan_clean_ui(get_tree().current_scene, "LocalMap")
	var map_root := get_tree().current_scene
	check(map_root.find_child("ToggleMapStyle", true, false) != null, "local map has ToggleMapStyle button")
	check(map_root.find_child("QuickPeriod", true, false) != null, "local map has QuickPeriod button")
	check(map_root.find_child("MapPreviewLine", true, false) != null, "local map has MapPreviewLine")
	check(map_root.find_child("NameBacking_arete_coast_test", true, false) != null, "campus map renders arete_coast_test pill")
	check(map_root.find_child("NameBacking_old_park", true, false) == null, "campus map delegates old_park entrance into coast hub")
	check(map_root.find_child("NameBacking_arete_beach_test", true, false) == null, "campus map delegates beach entrance into coast hub")
	check(map_root.find_child("WideMapBackground", true, false) != null, "v11 map mounts 2340 wide bleed")
	check(not map_root.find_children("HereBadge_*", "", true, false).is_empty(), "local map marks current location")
	var style_before := life.map_concept()
	check(life.toggle_map_concept() != style_before, "toggle_map_concept flips style cleanly")
	check(CampusPlaces.valid_state(life.snapshot()), "campus_life with map_concept passes validator")
	life.toggle_map_concept()

	life.open_region_atlas()
	await _settled()
	_scan_clean_ui(get_tree().current_scene, "WorldAtlas")
	var atlas_root := get_tree().current_scene
	check(atlas_root.find_child("TourRouteOverlay", true, false) != null, "world atlas draws tour routes")
	check(atlas_root.find_child("AtlasPreviewText", true, false) != null, "world atlas renders AtlasPreviewText")
	check(atlas_root.find_child("RegionCard_university_arete", true, false) != null, "world atlas renders single district card for arete")
	check(atlas_root.find_children("Browse_*", "", true, false).is_empty(), "world atlas removes duplicate Browse buttons")

	for loc in ["library", "shop", "gym", "rooftop", "old_park", "arete_coast_test", "arete_beach_test", "dorm"]:
		check(life.travel_to(loc, "university_arete"), "travel to " + loc)
		await _settled()
		_scan_clean_ui(get_tree().current_scene, "Place_" + loc)
		if loc == "arete_coast_test":
			var coast_root := get_tree().current_scene
			check(coast_root.find_child("Action_enter_old_park", true, false) != null, "coast hub contains old_park entrance")
			check(coast_root.find_child("Action_go", true, false) != null, "coast hub contains beach entrance")
	check(life.travel_to("shop", "university_arete"), "return to shop for counter check")
	await _settled()
	var screen: CampusScreen = get_tree().current_scene
	screen._open_workspace("shop")
	await get_tree().process_frame
	_scan_clean_ui(screen._workspace, "ShopPanel")
	screen._close_workspace()
