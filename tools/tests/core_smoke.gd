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
	_test_audio_assets()

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
	var theme_paths := [
		DynamicUI.THEME_PAPER_MODAL,
		DynamicUI.THEME_PAPER_CHOICE,
		DynamicUI.THEME_PAPER_CARD,
		DynamicUI.THEME_FABRIC_RIBBON,
	]
	for theme_path in theme_paths:
		check(ResourceLoader.exists(theme_path) and load(theme_path) is Texture2D, "watercolor paper asset loads: " + theme_path)
	check(DynamicUI.v14_texture("buttons/ui_seal_claimed_badge.png") != null, "kept wax seal asset loads")
	for v17_path in [
		DynamicUI.V17_DIAL_MORNING,
		DynamicUI.V17_DIAL_REDMOON,
		DynamicUI.V17_DOCK_STRIP,
		DynamicUI.V17_RESOURCE_CAPSULE,
		DynamicUI.V17_ACTION_BTN,
		DynamicUI.V17_NPC_BUBBLE,
		DynamicUI.V17_STORY_DIALOGUE,
	]:
		check(DynamicUI.v17_texture(v17_path) != null, "v17 Set A UI asset loads: " + v17_path.get_file())
	for icon_key in ["arrow", "bag", "bolt", "book", "card", "chat", "coin", "gem", "map", "rest", "return", "spark", "waves"]:
		check(DynamicUI.v17_icon(icon_key) != null, "v17 Set A icon loads: " + icon_key)
	flow.change_scene(flow.TargetScene.HOME)
	await _settled()
	_scan_clean_ui(get_tree().current_scene, "HomeScreen")
	var home: HomeScreen = get_tree().current_scene
	check(home.find_child("HomePeriodDial", true, false) != null, "home mounts PeriodDial")
	check(home.find_child("RooftopExit", true, false) != null, "home mounts RooftopExit")
	check(home.find_child("QuickMapButton", true, false) == null, "home removes redundant QuickMapButton")
	check(home.find_child("QuickRestButton", true, false) == null, "home removes redundant QuickRestButton")
	for small_icon in ["HealthIcon", "MenuIcon", "BtnIcon", "BubbleIcon"]:
		check(home.find_child(small_icon, true, false) == null, "home has no small HUD icon: " + small_icon)
	var home_menu := home.find_child("MainMenuButton", true, false) as Button
	check(home_menu != null and home_menu.position.x >= 1700.0, "home MainMenuButton aligns rightmost")
	if home_menu != null:
		var menu_norm := home_menu.get_theme_stylebox("normal") as StyleBoxTexture
		var menu_hov := home_menu.get_theme_stylebox("hover") as StyleBoxTexture
		check(menu_norm != null and menu_hov != null and menu_norm.texture == menu_hov.texture, "home MainMenuButton keeps identical texture shape on hover")
	var home_capsule := home.find_child("StatusCapsule", true, false) as Control
	check(home_capsule != null and home_capsule.get_theme_stylebox("panel") is StyleBoxTexture, "home mounts v17 StatusCapsule StyleBoxTexture")
	check(home_capsule != null and home_menu != null and is_equal_approx(home_capsule.size.y, home_menu.size.y), "home StatusCapsule and MainMenuButton share uniform height")
	check(home.find_child("TalkHint", true, false) == null, "home removes overhead JiangZi bubble")
	home._open_panel("records")
	await get_tree().process_frame
	_scan_clean_ui(home._active_modal, "ProjectionRecords")
	var records_panel := home._active_modal as PlayerWorkspace
	if is_instance_valid(records_panel):
		records_panel.current_tab = "growth"
		records_panel.refresh()
		await get_tree().process_frame
		_scan_clean_ui(records_panel, "ProjectionRecordsGrowth")
		var goal_cards := records_panel.find_children("Goal_*", "Panel", true, false)
		check(not goal_cards.is_empty() and (goal_cards[0] as Control).get_theme_stylebox("panel") is StyleBoxTexture, "growth goals mount v14 StyleBoxTexture")
		var claim_btns := records_panel.find_children("Claim_*", "Button", true, false)
		check(not claim_btns.is_empty() and (claim_btns[0] as Button).get_theme_stylebox("normal") is StyleBoxTexture, "growth claim button mounts v14 StyleBoxTexture")
	home._hide_all_modals()
	home._open_workshop()
	await get_tree().process_frame
	_scan_clean_ui(home._active_modal, "Workshop")
	home._hide_all_modals()
	home._open_panel("zodiac")
	await get_tree().process_frame
	_scan_clean_ui(home._active_modal, "ZodiacOverview")
	var zodiac_panel := home._active_modal as ZodiacAlbumPanel
	check(is_instance_valid(zodiac_panel) and zodiac_panel.view_mode == "overview", "zodiac opens in overview mode")
	if is_instance_valid(zodiac_panel):
		check(zodiac_panel.find_children("Badge_*", "", true, false).size() == 12, "zodiac overview shows all 12 cards")
		zodiac_panel._select_badge("hero")
		await get_tree().process_frame
		_scan_clean_ui(zodiac_panel, "ZodiacBookDetail")
		check(zodiac_panel.view_mode == "book_detail", "clicking zodiac badge opens book_detail spread")
		check(zodiac_panel.find_child("BookSpread", true, false) != null, "zodiac detail mounts BookSpread")
		check(zodiac_panel.find_child("CardNiche", true, false) != null, "zodiac detail mounts Left CardNiche")
		check(zodiac_panel.find_child("DetailCardFace", true, false) != null, "zodiac detail mounts Left DetailCardFace")
		check(zodiac_panel.find_child("ResonateButton", true, false) != null, "zodiac detail mounts Right ResonateButton")
		check(zodiac_panel.find_child("ZodiacAbility", true, false) != null, "zodiac detail mounts Right ZodiacAbility")
		var spread_art := zodiac_panel.find_child("BookSpreadArtwork", true, false) as TextureRect
		check(spread_art != null and spread_art.texture != null, "zodiac detail loads real BookSpreadArtwork")
		var ribbon_art := zodiac_panel.find_child("RibbonTexture", true, false) as TextureRect
		check(ribbon_art != null and ribbon_art.texture != null, "zodiac detail loads real RibbonTexture")
		zodiac_panel._turn_page(1)
		await get_tree().process_frame
		check(zodiac_panel.selected_zodiac == "everyperson", "zodiac book turns page to next constellation")
		check(zodiac_panel.cancel_pending(), "zodiac cancel_pending returns true from book_detail")
		check(zodiac_panel.view_mode == "overview", "zodiac cancel_pending restores overview mode")
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
		var place_root := get_tree().current_scene
		_scan_clean_ui(place_root, "Place_" + loc)
		check(place_root.find_child("SceneHUD", true, false) != null, loc + " mounts unified SceneHUD")
		check(place_root.find_child("LeftActionDock", true, false) != null, loc + " mounts LeftActionDock")
		check(place_root.find_child("LocationCapsule", true, false) != null, loc + " mounts v17 LocationCapsule")
		check(place_root.find_child("TopRightHud", true, false) != null, loc + " mounts TopRightHud")
		check(place_root.find_child("PeriodDial", true, false) != null, loc + " mounts PeriodDial")
		check(place_root.find_child("PipCount", true, false) != null, loc + " mounts PipCount")
		var dock_back := place_root.find_child("DockBacking", true, false) as Control
		check(dock_back != null and dock_back.get_theme_stylebox("panel") is StyleBoxTexture, loc + " mounts v17 DockBacking StyleBoxTexture")
		for nav_name in ["OpenMap", "OpenMenu", "BackLocation"]:
			var nav_btn := place_root.find_child(nav_name, true, false) as Button
			if nav_name != "BackLocation":
				check(nav_btn != null, loc + " mounts HUD button: " + nav_name)
			if nav_btn != null:
				var sb_norm := nav_btn.get_theme_stylebox("normal") as StyleBoxTexture
				var sb_hov := nav_btn.get_theme_stylebox("hover") as StyleBoxTexture
				check(sb_norm != null and sb_hov != null and sb_norm.texture == sb_hov.texture, loc + " " + nav_name + " keeps identical texture shape on hover")
		if loc in ["old_park", "arete_beach_test"]:
			check(place_root.find_child("Action_go", true, false) == null, loc + " has no duplicate Action_go return action")
		check(place_root.find_child("StageLayers", true, false) != null, loc + " mounts 5-layer StageLayers")
		check(place_root.find_child("Layer0_Sky", true, false) != null, loc + " mounts Layer0_Sky")
		check(place_root.find_child("Layer1_Midground", true, false) != null, loc + " mounts Layer1_Midground")
		check(place_root.find_child("Layer2_Actors", true, false) != null, loc + " mounts Layer2_Actors")
		check(place_root.find_child("Layer3_Foreground", true, false) != null, loc + " mounts Layer3_Foreground")
		var sky_tr := place_root.find_child("SkyTexture", true, false) as TextureRect
		var mid_tr := place_root.find_child("MidgroundTexture", true, false) as TextureRect
		var fg_tr := place_root.find_child("ForegroundTexture", true, false) as TextureRect
		check(sky_tr != null and sky_tr.visible and sky_tr.texture != null, loc + " loads real v17 SkyTexture")
		check(mid_tr != null and mid_tr.texture != null, loc + " loads real v17 MidgroundTexture")
		check(fg_tr != null and fg_tr.texture != null, loc + " loads real v17 ForegroundTexture")
		var actor_slot_name := "ActorSprite_slot_b" if loc == "old_park" else "ActorSprite_slot_a"
		var actor_tr := place_root.find_child(actor_slot_name, true, false) as TextureRect
		check(actor_tr != null and actor_tr.texture != null, loc + " loads real v17 staged actor sprite")
		check(place_root.find_children("Bubble_*", "", true, false).is_empty(), loc + " has no overhead NPC speech bubble")
		var loc_cap := place_root.find_child("LocationCapsule", true, false) as Control
		var res_cap := place_root.find_child("ResourceCapsule", true, false) as Control
		var map_btn := place_root.find_child("OpenMap", true, false) as Control
		var menu_btn := place_root.find_child("OpenMenu", true, false) as Control
		if loc_cap != null and res_cap != null and map_btn != null and menu_btn != null:
			check(is_equal_approx(loc_cap.size.y, 56.0) and is_equal_approx(res_cap.size.y, 56.0) and is_equal_approx(map_btn.size.y, 56.0) and is_equal_approx(menu_btn.size.y, 56.0), loc + " top bar controls share uniform 56px height")
		if loc == "library":
			var lib_screen: CampusScreen = place_root
			lib_screen._action({"id": "talk", "npc": "lin_zhi_xia"})
			await get_tree().process_frame
			check(is_instance_valid(lib_screen.dialogue), "library dialogue opened")
			if is_instance_valid(lib_screen.dialogue):
				check(lib_screen.dialogue.portrait.visible and lib_screen.dialogue.portrait.texture != null, "CampusDialogueUI displays speaker portrait")
				var chrome_tex := lib_screen.dialogue.find_child("StoryChrome", true, false) as TextureRect
				check(chrome_tex != null and chrome_tex.texture != null, "CampusDialogueUI matches main-story StoryChrome artwork")
				lib_screen.dialogue._close()
				await get_tree().process_frame
		elif loc == "rooftop":
			var roof_screen: CampusScreen = place_root
			var sl := roof_screen.scene_objects.stage_layers if is_instance_valid(roof_screen.scene_objects) else null
			var sky_tex_node := roof_screen.find_child("SkyTexture", true, false) as TextureRect
			if is_instance_valid(sl) and sky_tex_node != null:
				sl.force_sky_mode = "day"
				sl.apply_period_lighting("morning", false)
				var day_path := sky_tex_node.texture.resource_path if sky_tex_node.texture != null else ""
				sl.force_sky_mode = "dusk"
				sl.apply_period_lighting("afternoon", false)
				var dusk_path := sky_tex_node.texture.resource_path if sky_tex_node.texture != null else ""
				sl.force_sky_mode = "redmoon"
				sl.apply_period_lighting("night", true)
				var moon_path := sky_tex_node.texture.resource_path if sky_tex_node.texture != null else ""
				check(day_path != "" and dusk_path != "" and moon_path != "" and day_path != dusk_path and dusk_path != moon_path and day_path != moon_path, "rooftop switches distinct day/dusk/redmoon sky textures")
				sl.force_sky_mode = ""
				sl.apply_period_lighting()
			roof_screen._action({"id": "switch_companion"})
			await get_tree().process_frame
			check(roof_screen.find_child("CompanionSwitcherModal", true, false) != null, "rooftop opens companion switcher modal")
			roof_screen._close_companion_switcher()
			await get_tree().process_frame
		elif loc == "gym":
			var gym_screen: CampusScreen = place_root
			gym_screen._open_qualifier_modal()
			await get_tree().process_frame
			check(gym_screen.find_child("QualifierLeftCol", true, false) != null, "qualifier opens left status col")
			check(gym_screen.find_child("RoundRow_1", true, false) != null and gym_screen.find_child("RoundRow_3", true, false) != null, "qualifier renders 3 round cards")
			check(gym_screen.find_child("GotoWorkshopBtn", true, false) != null, "qualifier provides workshop shortcut")
			gym_screen._close_qualifier_modal()
			await get_tree().process_frame
		elif loc == "arete_coast_test":
			check(place_root.find_child("Action_enter_old_park", true, false) != null, "coast hub contains old_park entrance")
			check(place_root.find_child("Action_go", true, false) != null, "coast hub contains beach entrance")
	check(life.travel_to("shop", "university_arete"), "return to shop for counter check")
	await _settled()
	var screen: CampusScreen = get_tree().current_scene
	check(screen.find_children("Bubble_*", "", true, false).is_empty(), "shop has no overhead Tang Xiaoman bubble")
	screen._open_workspace("shop")
	await get_tree().process_frame
	_scan_clean_ui(screen._workspace, "ShopPanel")
	check(screen._workspace.find_child("ClerkSpeechBubble", true, false) != null, "shop split view renders ClerkSpeechBubble")
	check(screen._workspace.find_child("BalanceIcon", true, false) == null, "shop removes small BalanceIcon")
	check(screen._workspace.find_child("TalkIcon", true, false) == null, "shop removes small TalkIcon")
	var shop_close := screen._workspace.find_child("CloseButton", true, false) as Button
	if shop_close != null:
		var close_norm := shop_close.get_theme_stylebox("normal") as StyleBoxTexture
		var close_hov := shop_close.get_theme_stylebox("hover") as StyleBoxTexture
		check(close_norm != null and close_hov != null and close_norm.texture == close_hov.texture, "shop CloseButton keeps identical texture shape on hover")
	var shop_board := screen._workspace.find_child("ProductsBoard", true, false) as Control
	check(shop_board != null and shop_board.get_theme_stylebox("panel") is StyleBoxTexture, "shop ProductsBoard uses StyleBoxTexture")
	var shop_speech := screen._workspace.find_child("ClerkSpeechBubble", true, false) as Control
	check(shop_speech != null and shop_speech.get_theme_stylebox("panel") is StyleBoxTexture, "shop ClerkSpeechBubble uses StyleBoxTexture")
	var product_tiles := screen._workspace.find_children("Product_*", "Button", true, false)
	check(not product_tiles.is_empty() and (product_tiles[0] as Button).get_theme_stylebox("normal") is StyleBoxTexture, "shop product tiles mount watercolor paper StyleBoxTexture")
	check(screen._workspace.find_child("ConfirmTrade", true, false) != null, "shop split view renders ConfirmTrade")
	check(screen._workspace.find_child("LocalShopBackground", true, false) == null, "shop split view keeps right stage transparent")
	check(not screen.scene_objects.hud_layout.dock_panel.visible, "shop split view hides left action dock")
	screen._close_workspace()
	await get_tree().process_frame
	check(screen.scene_objects.hud_layout.dock_panel.visible, "closing shop restores left action dock")
	screen._open_menu()
	await get_tree().process_frame
	check(screen.scene_objects.hud_layout.menu_button.disabled, "opening system menu disables HUD OpenMenu button")
	screen.system_menu.go_back()
	await get_tree().process_frame
	check(not screen.scene_objects.hud_layout.menu_button.disabled, "closing system menu re-enables HUD OpenMenu button")


func _test_audio_assets() -> void:
	var audio := get_tree().root.get_node_or_null("AudioManager")
	check(audio != null, "AudioManager autoload is available")
	if audio == null:
		return
	var bgm_ids := [
		"bgm_title_serene",
		"bgm_campus_daily",
		"bgm_shop_breeze",
		"bgm_dusk_memory",
		"bgm_duel_practice",
		"bgm_redmoon_overclock",
		"bgm_victory_stinger",
	]
	for track_id in bgm_ids:
		var stream: AudioStream = audio._bgm_stream(track_id)
		check(stream != null, "BGM stream loads: " + track_id)
		if stream != null and "loop" in stream:
			check(bool(stream.get("loop")) == (track_id != "bgm_victory_stinger"), "BGM loop policy matches: " + track_id)
	for key in AudioManager.SFX_KEYS.keys():
		var sfx: AudioStream = audio._sfx_stream(str(key))
		check(sfx != null, "SFX stream loads: " + str(key))
