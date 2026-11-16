extends "res://tools/tests/p5_regions.gd"

func _run() -> void:
	state = get_tree().root.get_node("GameState")
	life = get_tree().root.get_node("CampusLife")
	flow = get_tree().root.get_node("SceneManager")
	saves = get_tree().root.get_node("SaveManager")
	cycle = get_tree().root.get_node("DayCycle")
	cycle.suspended = true
	saves.active_session = false
	saves.save_path = "user://zodiac_shop_tests/slot_1.json"
	saves.settings["reduced_motion"] = true
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--captures="): captures = arg.trim_prefix("--captures=")
	if captures != "": DirAccess.make_dir_recursive_absolute(captures)
	check(state.new_game(), "new game starts")
	saves.active_session = true
	flow.change_scene(flow.TargetScene.HOME)
	await settled()
	_collection_rules()
	await _shops()
	await _records_and_zodiac()
	await _v6_systems()
	print("ZODIAC_RESULT " + JSON.stringify({"checks": checks, "failures": failures, "renderer": DisplayServer.get_name()}))
	get_tree().quit(0 if failures.is_empty() else 1)

func _collection_rules() -> void:
	check(SpecialCardCollection.snapshot()["collected"].is_empty(), "new game grants no zodiac story badges")
	check(ZodiacCatalog.ORDER.size() == 12 and ZodiacCatalog.ENTRIES.size() == 12, "twelve independent zodiac definitions")
	check(not SpecialCardCollection.acquire_from_story("unknown", "bad"), "unknown zodiac rejected")
	check(not SpecialCardCollection.acquire_from_story("hero", ""), "empty story event rejected")
	var before: Dictionary = state.export_progress(false)
	for id in ZodiacCatalog.ORDER:
		var card := ZodiacCatalog.definition(id)
		for field in ["zodiac", "name", "archetype", "power", "ability", "limits", "interactions"]:
			check(str(card[field]) != "", "zodiac has canon description " + id + "/" + field)
		check(ItemCatalog.definition(id).is_empty() and state.get_card(id) == null, "story badge separate from inventory and deck " + id)
		check(CampusShopCatalog.definition(id).is_empty(), "story badge absent from shop " + id)
	check(SpecialCardCollection.acquire_from_story("magician", "story_key"), "story awards key")
	check(not SpecialCardCollection.key_progress()["ready"], "key alone cannot unlock wish")
	check(SpecialCardCollection.acquire_from_story("hero", "story_hero"), "story award adds permanent badge")
	var once := SpecialCardCollection.snapshot()
	check(not SpecialCardCollection.acquire_from_story("hero", "story_other"), "duplicate card rejected")
	check(not SpecialCardCollection.acquire_from_story("sage", "story_hero"), "duplicate event rejected")
	check(once == SpecialCardCollection.snapshot(), "duplicate award cannot modify collection")
	for id in ZodiacCatalog.ORDER:
		if id not in ["hero", "magician"]:
			check(SpecialCardCollection.acquire_from_story(id, "story_" + id), "collect " + id)
	check(SpecialCardCollection.key_progress()["ready"], "key requires all other eleven")
	check(state.unlocked_card_ids == before["unlocked_card_ids"] and state.inventory_items == before["inventory_items"], "zodiac never enters equippable cards or generic items")
	var progress: Dictionary = state.export_progress(false)
	check(state.validate_progress(progress), "collected story state validates")
	var invalid: Dictionary = progress.duplicate(true)
	invalid["player_profile"]["zodiac_collection"]["collected"].append("hero")
	check(not state.validate_progress(invalid), "duplicate saved badge rejected")
	invalid = progress.duplicate(true)
	invalid["player_profile"]["zodiac_collection"]["events"]["malformed"] = "unknown"
	check(not state.validate_progress(invalid), "forged saved story id rejected")
	check(saves.save_game(), "permanent collection saves")
	check(state.import_progress(before), "clean collection fixture restores")
	check(saves.continue_game(), "collection loads through production save service")
	check(SpecialCardCollection.snapshot()["collected"].size() == 12, "collected badges survive reload")
	var old: Dictionary = progress.duplicate(true)
	old["player_profile"].erase("zodiac_collection")
	old["player_profile"].erase("shop_receipts")
	check(state.import_progress(old), "legacy save migrates cleanly")
	check(SpecialCardCollection.snapshot()["collected"].is_empty(), "legacy save migrates to empty collection")

func _shops() -> void:
	for region in CampusShopCatalog.REGION_SHOPS:
		var shop: String = CampusShopCatalog.REGION_SHOPS[region]
		if region != "university_arete":
			var flag := str(RegionCatalog.REGIONS[region]["unlock_condition"])
			state.set_story_flag(flag, false)
			check(not life.enter_region(region), "locked shop region cannot travel " + region)
			state.set_story_flag(flag, true)
		check(life.enter_region(region), "unlocked region entered " + region)
		await settled()
		if not life.has_visited_region(region):
			check(life.complete_first_visit(), "first arrival gate remains " + region)
			await settled()
		check(not CampusShopCatalog.quote("material_common", 1, "buy")["ok"], "cannot buy from regional Home/gateway " + region)
		life.open_map()
		await settled()
		var map: RegionMapView = get_tree().current_scene.view
		check(map.refs["locations"].has(shop), "shop is a registered map location " + region)
		await click(map.refs["locations"][shop])
		check(life.current_location == shop, "map travels to local merchant " + region)
		var screen: CampusScreen = get_tree().current_scene
		var shop_button: Button
		for action in screen.refs["actions"].values():
			if action.text == "查看商品":
				shop_button = action
		check(shop_button != null, "merchant has visible action " + region)
		if shop_button == null:
			continue
		await click(shop_button)
		check(screen._workspace is CampusShopPanel, "local action opens independent shop counter " + region)
		var counter: CampusShopPanel = screen._workspace
		var calendar := cycle.snapshot()
		state.energy_crystals = 320
		var amount: int = state.get_inventory_quantity("material_common")
		var result: Dictionary = state.execute_shop_trade("material_common", 2, "buy", "buy_" + region)
		check(result["ok"] and state.energy_crystals == 296 and state.get_inventory_quantity("material_common") == amount + 2, "purchase debits exact amount atomically " + region)
		check(not state.execute_shop_trade("material_common", 2, "buy", "buy_" + region)["ok"], "replayed request rejected " + region)
		check(state.execute_shop_trade("material_common", 2, "sell", "sell_" + region)["ok"] and state.energy_crystals == 308 and state.get_inventory_quantity("material_common") == amount, "recycle owned allowed materials " + region)
		check(cycle.snapshot() == calendar, "transactions consume no time or actions " + region)
		counter.refresh()
		if region == "university_arete":
			var all_count: int = counter.refs["products"].size()
			var filter_btn := counter.find_child("FilterUnowned", true, false) as Button
			check(filter_btn != null, "shop displays FilterUnowned toggle on cards tab")
			if filter_btn != null:
				await click(filter_btn)
				check(counter.refs["products"].size() < all_count, "FilterUnowned hides owned starter cards")
				await click(counter.find_child("FilterUnowned", true, false) as Button)
		await click(counter.find_child("Category_materials", true, false))
		await click(counter.refs["products"]["material_common"])
		var confirm: Button = counter.refs["confirm"]
		var money: int = state.energy_crystals
		confirm.pressed.emit()
		confirm.pressed.emit()
		await get_tree().process_frame
		check(state.energy_crystals == money - 12, "same confirm callback is consumed once " + region)
		check(counter.find_child("LocalShopBackground", true, false).texture.resource_path.ends_with("shop_counter_plate.png"), "counter uses migrated concept plate " + region)
		await click(counter.find_child("Category_cards", true, false))
		await capture("shop_" + region)
		await key(KEY_ESCAPE)
		check(not is_instance_valid(screen._workspace), "merchant closes with Escape " + region)
	var before: Dictionary = state.export_progress(false)
	for quantity in [0, -1, 1.5, 100, NAN, INF, true]:
		check(not state.execute_shop_trade("material_common", quantity, "buy", "invalid")["ok"], "invalid quantity rejected " + str(quantity))
	for id in ["hero", "magician", "quest_sample", "sealed_note", "unknown"]:
		check(not state.execute_shop_trade(id, 1, "buy", "invalid")["ok"], "non-commodity cannot be purchased " + id)
		check(not state.execute_shop_trade(id, 1, "sell", "invalid")["ok"], "story item cannot be recycled " + id)
	check(before == state.export_progress(false), "rejected transactions change no progress")
	state.energy_crystals = 0
	check(not state.execute_shop_trade("drink", 1, "buy", "poor")["ok"], "insufficient money rejected")
	state.energy_crystals = 999999
	check(not state.execute_shop_trade("drink", 1, "sell", "overflow")["ok"], "money overflow rejected")
	state.energy_crystals = 320
	check(not CampusShopCatalog.quote("card_wrench_smash", 1, "buy")["ok"], "owned action card cannot be bought twice")
	check(state.execute_shop_trade("card_fake_cheque", 1, "buy", "first_card")["ok"], "ordinary new action card can be purchased")
	check(state.unlocked_card_ids.has("fake_cheque"), "bought ordinary card enters existing collection")
	check(not state.execute_shop_trade("card_fake_cheque", 1, "buy", "second_card")["ok"], "second callback cannot duplicate owned card")
	check(not CampusShopCatalog.quote("card_fake_cheque", 1, "sell")["ok"], "ordinary unique card not recycled")
	check(saves.save_game() and saves.continue_game(), "trade state persists and reloads")
	check(not state.execute_shop_trade("material_common", 1, "buy", "buy_region_iga_church")["ok"], "receipt ledger survives reload")

func _records_and_zodiac() -> void:
	check(life.enter_region("university_arete"), "return to campus")
	await settled()
	check(life.travel_to("club"), "campus Home reached")
	await settled()
	var home: HomeScreen = get_tree().current_scene
	var before := cycle.snapshot()
	var shortcut := home.find_child("ZodiacShortcut", true, false) as Button
	check(shortcut != null and shortcut.text == "星座图鉴", "blank blackboard button is labeled zodiac")
	check(home.btn_records.get_node("EntryTitle").text == "放映档案", "records entry uses projector title")

	# Opening records opens the revived film projector PlayerWorkspace
	await click(home.btn_records)
	check(home.records_panel is PlayerWorkspace and home.records_panel.panel_kind == "records", "records tray opens film projector PlayerWorkspace")
	check(cycle.snapshot() == before, "projector viewing is free")
	var open_zodiac := home.records_panel.find_child("OpenZodiac", true, false) as Button
	check(open_zodiac != null, "projector bar has Zodiac shortcut")
	await click(open_zodiac)
	check(home.records_panel is ZodiacAlbumPanel, "projector shortcut switches to 2D Zodiac album")
	await key(KEY_ESCAPE)
	check(not is_instance_valid(home._active_modal), "Escape closes modal from Home")

	# Blackboard opens Zodiac album directly
	await click(shortcut)
	check(home.records_panel is ZodiacAlbumPanel, "blackboard opens 2D Zodiac album directly")
	var album: ZodiacAlbumPanel = home.records_panel
	for id in ZodiacCatalog.ORDER:
		check(album.refs["badges"].has(id), "badge button available " + id)
		var btn: Button = album.refs["badges"][id]
		check(btn.get_theme_stylebox("focus") is StyleBoxEmpty, "zodiac tile has zero focus border " + id)
	check(SpecialCardCollection.acquire_from_story("hero", "ui_hero"), "UI story acquisition fixture")
	await settled()
	await capture("zodiac_partial")
	check(album.refs["badges"]["hero"].get_node("BadgeIcon").material == null, "collected badge has original color")
	check(album.refs["badges"]["everyperson"].get_node("BadgeIcon").material is ShaderMaterial, "uncollected badge is grayscale")
	await click(album.refs["badges"]["magician"])
	check(album.find_child("ZodiacName", true, false).text == "水瓶座", "uncollected badge can inspect ability")
	check(not SpecialCardCollection.collected("magician"), "viewing never grants story badge")
	await click(album.refs["open_records"])
	check(home.records_panel is PlayerWorkspace and home.records_panel.panel_kind == "records", "album button switches back to projector records")
	await key(KEY_ESCAPE)
	check(not is_instance_valid(home._active_modal), "Escape closes projector modal")
	check(get_viewport().gui_get_focus_owner() == shortcut or is_instance_valid(get_viewport().gui_get_focus_owner()), "closing restores focus on Home")

	# Verify PlatformService API & zero-focus-border fix
	check(Platform.hint("PC", "TOUCH") == ("TOUCH" if Platform.is_touch() else "PC"), "Platform hint adapts to input mode")
	var test_hit := SchoolObjectUI.hit(home, "TempHit", Rect2(0, 0, 10, 10), "", 20)
	check(test_hit.get_theme_stylebox("focus") is StyleBoxEmpty, "SchoolObjectUI.hit uses StyleBoxEmpty focus by default")
	test_hit.queue_free()

	# Verify blackboard pill geometry and permanent unlocked TEST save isolation
	check(shortcut.position == Vector2(1480, 441) and shortcut.size == Vector2(240, 54), "zodiac shortcut aligns to painted blackboard pill")
	var test_progress := SaveService.build_test_progress()
	check(state.validate_progress(test_progress), "permanent test save progress validates")
	check(saves.load_test_save() and saves.test_session, "load_test_save enters test session")
	var loaded: Dictionary = state.export_progress(false)
	var visits: Dictionary = loaded.get("player_profile", {}).get("campus_life", {}).get("region_visits", {})
	for region_id in WorldRegionContent.REGIONS.keys():
		check(RegionCatalog.REGIONS.has(region_id) and RegionCatalog.is_unlocked(region_id) and life.has_visited_region(region_id) and str(visits.get(region_id, "")) == "completed", "test save unlocks region " + str(region_id))
	check(SpecialCardCollection.snapshot()["collected"].size() == 6, "test save seeds 6 preview zodiac cards")
	check(loaded.get("visited_node_ids", []).has("n_dusk"), "test save unlocks dusk corridor cutscene replay")
	var before_save_path := saves.save_path
	var probe_path := "user://zodiac_shop_tests/test_session_probe.json"
	if FileAccess.file_exists(probe_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(probe_path))
	saves.save_path = probe_path
	check(saves.save_game() and not FileAccess.file_exists(probe_path), "test session save_game preserves disk slots")
	saves.save_path = before_save_path
	check(test_progress["unlocked_card_ids"].size() == 16, "test save unlocks all 16 duel cards")
	var has_test_loadout := false
	for loadout_item in test_progress["player_profile"]["loadouts"]:
		if str(loadout_item.get("name", "")) == "决斗包·TEST":
			has_test_loadout = true
	check(has_test_loadout, "test save provides Wave 5 duel test loadout")
	var trump_path := SceneSkin.card_illustration_path("final_trump")
	var raw_trump := load(trump_path) as Texture2D
	var cropped_trump := SceneSkin.illustration_texture(trump_path)
	check(raw_trump != null and cropped_trump != null and cropped_trump.get_height() == raw_trump.get_height() - 28, "final_trump art crops 28px bottom border cleanly")
	check(SceneSkin.illustration_texture(SceneSkin.card_illustration_path("silent_library")) != null, "silent_library card art loads")
	check(CombatSkin.card_back_texture() != null, "duel card back texture loads")
	check(CombatSkin.character_combat_path("liu_yu_long") != "" and CombatSkin.character_combat_path("jiang_zi") != "" and CombatSkin.character_combat_path("yang_zi_ying") != "", "companion combat idle sprites exist")
	for enemy_id in ["duel_student_ace", "national_finalist", "alliance_operative", "church_guardian"]:
		check(ResourceLoader.exists(CombatSkin.enemy_combat_path(enemy_id)), "Wave 5 enemy texture exists for " + enemy_id)
	check(saves.start_new_game() and not saves.test_session, "start_new_game exits test session cleanly")
	check(SpecialCardCollection.snapshot()["collected"].is_empty(), "new game after test save starts with 0 zodiacs")
	check(state.unlocked_card_ids.size() == 4, "new game baseline preserves 4 starter cards")

func _v6_systems() -> void:
	check(PhaseTwoContent.ACTORS.has("huang_qiufeng"), "PhaseTwoContent registers huang_qiufeng actor")
	check(ResourceLoader.exists(PhaseTwoContent.dialogue_character_path("huang_qiufeng", "shy")), "huang_qiufeng shy dialogue sprite exists")
	check(PhaseTwoContent.dialogue_character_path("huang_qiufeng", "damaged_fiber").ends_with("damaged_fiber.png"), "huang_qiufeng damaged_fiber sprite resolves")
	check(PhaseTwoContent.dialogue_character_path("huang_qiufeng", "crystal_stasis").ends_with("crystal_stasis.png"), "huang_qiufeng crystal_stasis sprite resolves")
	check(PhaseTwoContent.dialogue_character_path("alliance_operative").ends_with("rebel_operative_masked.png"), "alliance_operative resolves masked dialogue portrait")
	check(PhaseTwoContent.dialogue_character_path("alliance_operative", "unmasked").ends_with("rebel_operative_unmasked.png"), "alliance_operative unmasked portrait resolves")
	for rep_id in ["nomos_arbiter", "agora_broker", "techne_researcher"]:
		check(ResourceLoader.exists(PhaseTwoContent.character_path(rep_id)), "regional rep portrait loads: " + rep_id)
	for cutin_id in ["ye_zhou", "yang_zi_ying", "liu_yu_long", "jiang_zi"]:
		check(CombatSkin.character_cutin_path(cutin_id).ends_with("_cutin.png"), "squad cutin portrait loads: " + cutin_id)
	for v6_fx in ["debuff", "companion_assist", "overclock_redmoon", "counter_reflect", "pack_tear", "crystal_shimmer"]:
		check(CombatVFX.frames_for(v6_fx).size() == 8, "CombatVFX v6 4x2 sheet loads 8 frames: " + v6_fx)
	check(CombatSkin.character_combat_path("huang_qiufeng") != "", "huang_qiufeng combat idle sprite exists")
	var shop_cards: Array = CampusShopCatalog.PRODUCTS.keys().filter(func(id: String): return str(CampusShopCatalog.PRODUCTS[id].get("category", "")) == "cards")
	check(shop_cards.size() == 16, "CampusShopCatalog offers all 16 tactical imprint cards")

	check(saves.load_test_save() and saves.test_session, "v6_systems enters test save")
	flow.change_scene(flow.TargetScene.HOME)
	var home_guard := 0
	while flow.is_transitioning and home_guard < 300:
		home_guard += 1
		await get_tree().process_frame
	await settled()

	var home := get_tree().current_scene as HomeScreen
	check(home != null, "v6_systems reaches HomeScreen")
	if home == null:
		return

	await click(home.btn_workshop)
	await settled()
	var comp_btn := home.find_child("CompanionButton", true, false) as Button
	check(comp_btn != null, "workshop displays CompanionButton")
	if comp_btn != null:
		var prev_comp: String = str(state.get_active_companion_id())
		await click(comp_btn)
		await settled()
		check(state.get_active_companion_id() != prev_comp, "CompanionButton cycles active combat companion")
		await capture("v6_workshop_companion")
	await key(KEY_ESCAPE)
	await settled()

	var shortcut := home.find_child("ZodiacShortcut", true, false) as Button
	check(shortcut != null, "HomeScreen exposes ZodiacShortcut for v6 check")
	if shortcut != null:
		await click(shortcut)
		await settled()
		var album := home.records_panel as ZodiacAlbumPanel
		check(album != null, "ZodiacShortcut opens ZodiacAlbumPanel for resonance test")
		if album != null:
			if not SpecialCardCollection.collected("hero"):
				SpecialCardCollection.acquire_from_story("hero", "v6_test_hero")
				album.refresh()
				await settled()
			await click(album.refs["badges"]["hero"])
			await settled()
			var res_btn := album.refs.get("resonate_button") as Button
			check(res_btn != null and not res_btn.disabled, "collected zodiac badge enables ResonateButton")
			if res_btn != null:
				await click(res_btn)
				await settled()
				check(state.get_active_zodiac_id() == "hero", "ResonateButton sets active zodiac resonance to hero")
				res_btn = album.refs.get("resonate_button") as Button
				var desc_node := album.refs.get("detail") as Control
				check(desc_node != null and res_btn != null and desc_node.position.y + desc_node.size.y <= res_btn.position.y, "ZodiacDescription does not overlap ResonateButton vertically")
				check(res_btn != null and res_btn.position.x + res_btn.size.x <= 775.0, "ResonateButton stays inside ZodiacDetail MatRule border")
				var album_halo := album.find_child("DetailResonanceHalo", true, false) as CanvasItem
				check(album_halo != null and album_halo.visible, "ZodiacAlbumPanel shows DetailResonanceHalo when active")
				await capture("v6_zodiac_resonance")
		await key(KEY_ESCAPE)
		await settled()

	state.set_active_companion_id("liu_yu_long")
	var duel_loadout: Dictionary = state.player_profile["loadouts"][2]
	check(state.apply_equipped_deck(duel_loadout["card_ids"], 2), "v6_systems equips duel loadout")
	state.pending_combat_data = {"enemies": ["duel_student_ace", "church_guardian"], "companion_id": "liu_yu_long"}
	flow.change_scene(flow.TargetScene.COMBAT)
	var combat_guard := 0
	while flow.is_transitioning and combat_guard < 300:
		combat_guard += 1
		await get_tree().process_frame
	await settled()

	var combat := get_tree().current_scene
	var turn_guard := 0
	while combat != null and (combat.get("is_animating") == true or combat.get("is_player_turn") != true) and turn_guard < 180:
		turn_guard += 1
		await get_tree().process_frame

	check(int(combat.get("player_shield")) >= 12, "Aries zodiac resonance grants >=12 start shield")
	check(str(combat.get("_companion_id")) == "liu_yu_long", "combat resolves active companion liu_yu_long")
	var comp_badge := combat.find_child("CompanionAssistBadge", true, false) as Label
	var zod_badge := combat.find_child("ZodiacResonanceBadge", true, false) as Label
	var redmoon_hud := combat.find_child("RedMoonHudPulse", true, false) as CanvasItem
	var halo_emblem := combat.find_child("ZodiacHaloEmblem", true, false) as CanvasItem
	check(comp_badge != null and comp_badge.text.contains("0/3"), "CompanionAssistBadge initializes at 0/3")
	check(zod_badge != null and zod_badge.text.contains("白羊共鸣"), "ZodiacResonanceBadge displays active Aries resonance")
	check(redmoon_hud != null and redmoon_hud.visible, "RedMoonHudPulse displays on Overclock combat encounter")
	check(halo_emblem != null and halo_emblem.visible, "ZodiacHaloEmblem displays for active Aries resonance")

	var preview_cards := combat.get("card_ui_nodes") as Array
	if not preview_cards.is_empty():
		var hover_card := preview_cards[0] as CombatCardUI
		hover_card._arm_touch()
		var glow := hover_card.find_child("HoverGlowFrame", true, false) as CanvasItem
		check(glow != null and glow.visible, "CombatCardUI HoverGlowFrame lights up on arm/hover")
		hover_card.disarm_touch()

	var first_target = combat.get("selected_enemy")
	var first_reticle := (first_target as Node).find_child("LoopVFX_target_reticle", true, false) as CanvasItem if is_instance_valid(first_target) else null
	check(CombatVFX.frames_for("target_reticle").size() == 8, "v7 target_reticle 4x2 frames load 8 frames")
	check(first_reticle != null and first_reticle.visible, "selected enemy renders LoopVFX_target_reticle at feet")
	await key(KEY_TAB)
	await settled()
	var next_target = combat.get("selected_enemy")
	check(next_target != first_target, "Combat KEY_TAB switches living enemy target")
	var next_reticle := (next_target as Node).find_child("LoopVFX_target_reticle", true, false) as CanvasItem if is_instance_valid(next_target) else null
	check(first_reticle == null or not first_reticle.visible, "previous target hides LoopVFX_target_reticle after Tab switch")
	check(next_reticle != null and next_reticle.visible, "new target displays LoopVFX_target_reticle after Tab switch")
	await key(KEY_TAB)
	await settled()
	await key(KEY_H)
	await settled()
	check(combat.get("is_log_expanded") == true, "Combat KEY_H toggles combat history open")
	await key(KEY_H)
	await settled()
	check(combat.get("is_log_expanded") == false, "Combat KEY_H closes combat history")

	state.player_current_hp = maxi(10, state.player_max_hp - 30)
	var played_count := 0
	for _step in 3:
		var cards := combat.get("card_ui_nodes") as Array
		var chosen: Control = null
		for card_node in cards:
			if card_node.get("is_available") == true and card_node.get("card_data") != null:
				chosen = card_node as Control
				break
		if chosen == null:
			break
		chosen.card_clicked.emit(chosen.get("card_data"))
		await get_tree().process_frame
		if played_count == 2:
			await get_tree().process_frame
			var cutin := combat.get_node_or_null("CompanionCutinOverlay") as CanvasItem
			var anchor := combat.get("floating_anchor") as Control
			var assist_vfx := anchor.get_node_or_null("VFX_companion_assist") if anchor != null else null
			check(cutin != null and cutin.visible, "3rd card spawns CompanionCutinOverlay banner and portrait")
			check(assist_vfx != null, "3rd card spawns VFX_companion_assist burst")
			await capture("v6_cutin_assist")
		var anim_wait := 0
		while combat != null and combat.get("is_animating") == true and anim_wait < 180:
			anim_wait += 1
			await get_tree().process_frame
		played_count += 1
	check(played_count == 3 and int(combat.get("_cards_played_total")) == 3, "playing 3 cards advances companion assist counter to 3")
	comp_badge = combat.find_child("CompanionAssistBadge", true, false) as Label
	check(comp_badge != null and comp_badge.text.contains("0/3"), "CompanionAssistBadge resets counter to 0/3 after assist")
	var log_rtl := combat.get("log_text") as RichTextLabel
	check(log_rtl != null and (log_rtl.get_parsed_text().contains("同伴协战") or log_rtl.text.contains("同伴协战")), "3rd card logs companion assist strike")
	var cutin_wait := 0
	while combat != null and combat.get_node_or_null("CompanionCutinOverlay") != null and cutin_wait < 90:
		cutin_wait += 1
		await get_tree().process_frame
	check(combat.get_node_or_null("CompanionCutinOverlay") == null, "CompanionCutinOverlay cleanly dismisses after assist")
	await capture("v6_combat_assist")

	var audio_mgr := get_node_or_null("/root/AudioManager")
	check(audio_mgr != null, "AudioManager autoload exists")
	if audio_mgr != null:
		for sfx_key in audio_mgr.SFX_KEYS.keys():
			check(audio_mgr.call("_sfx_stream", sfx_key) != null, "SFX stream loads cleanly: " + str(sfx_key))

	state.pending_combat_data.clear()
	check(saves.start_new_game() and not saves.test_session, "v6_systems cleanup exits test session cleanly")
	check(state.equipped_card_ids.size() == 3, "new game equips 3 starter cards (attack/shield/heal)")
	check(PlayerJourney.home_snapshot()["action"] == "story", "new game Home primary action is story (Ch1 unblocked)")
	check(not str(ZodiacCatalog.ENTRIES["explorer"]["interactions"]).contains("死亡程序"), "ZodiacCatalog explorer removes obsolete 35yo death copy")
	var gate_step := PhaseTwoContent.step_for("n_gate")
	var boss_step := PhaseTwoContent.step_for("n5_boss")
	check(str(gate_step.get("enemy", "")) == "liu_yu_long_duel" and str(gate_step.get("briefing_flag", "")) == "school_gate_duel_briefed", "n_gate configures Liu Yu Long duel tutorial")
	check(str(boss_step.get("enemy", "")) == "ch1_hunter_mech", "n5_boss updates enemy from principal to ch1_hunter_mech")
	check(CombatSkin.enemy_combat_path("liu_yu_long_duel") != "" and CombatSkin.enemy_combat_path("ch1_hunter_mech") != "", "enemy combat sprites resolve for liu_yu_long_duel and ch1_hunter_mech")
	check(CombatSkin.enemy_combat_path("ch1_hunter_mech").ends_with("enemy_ch1_hunter_mech.png"), "v7 enemy_ch1_hunter_mech.png resolves cleanly")
	for v7_path in [
		"res://assets/backgrounds/phase_two/battle_red_moon_lockdown.png",
		"res://assets/backgrounds/phase_two/battle_red_moon_lockdown_wide.png",
		"res://assets/ui/scene_reset/places/beach.png",
		"res://assets/ui/scene_reset/places/beach_wide.png",
		"res://assets/ui_core/vfx/vfx_target_reticle_4x2.png",
		"res://assets/ui_core/animations/ui_chapter_banner.png",
		"res://assets/ui_core/theme/ui_tutorial_callout_9slice.png"
	]:
		check(ResourceLoader.exists(v7_path), "v7 delivered resource exists: " + v7_path)
	for avatar_file in [
		"ye_zhou_neutral", "ye_zhou_happy", "ye_zhou_worried",
		"huang_qiufeng_neutral", "huang_qiufeng_happy", "huang_qiufeng_shy", "huang_qiufeng_worried", "huang_qiufeng_damaged_fiber",
		"yang_zi_ying_neutral", "yang_zi_ying_happy", "yang_zi_ying_worried",
		"liu_yu_long_neutral", "liu_yu_long_happy", "liu_yu_long_angry",
		"jiang_zi_neutral", "jiang_zi_happy", "jiang_zi_worried",
		"rebel_operative_masked_neutral"
	]:
		check(ResourceLoader.exists("res://assets/sprites/characters/phase_two/avatars/%s.png" % avatar_file), "v7 avatar exists: " + avatar_file)
	for npc_emotion in ["neutral", "happy"]:
		check(PhaseTwoContent.dialogue_character_path("lin_zhi_xia", npc_emotion).ends_with("lin_zhi_xia_%s.png" % npc_emotion), "lin_zhi_xia sprite resolves: " + npc_emotion)
		check(PhaseTwoContent.dialogue_character_path("tang_xiao_man", npc_emotion).ends_with("tang_xiao_man_%s.png" % npc_emotion), "tang_xiao_man sprite resolves: " + npc_emotion)
	var note_d0 := SchoolExplorationRoutes.dialogue_lines({"id": "r2_9_0_0", "layer": 0})
	var note_d1 := SchoolExplorationRoutes.dialogue_lines({"id": "r2_9_1_2", "layer": 1})
	check(not note_d0.is_empty() and str(note_d0[0].get("text", "")).contains("路牌下面") and not note_d1.is_empty() and str(note_d1[0].get("text", "")) != str(note_d0[0].get("text", "")), "SchoolExplorationRoutes serves deterministic note variants")

	var saved_hour: int = state.game_hour
	state.current_node_id = "n_gate"
	state.game_hour = 10
	state.pending_combat_data = {"enemies": ["liu_yu_long_duel"], "companion_id": "yang_zi_ying", "overclock": false}
	flow.change_scene(flow.TargetScene.COMBAT)
	var gate_guard := 0
	while flow.is_transitioning and gate_guard < 300:
		gate_guard += 1
		await get_tree().process_frame
	await settled()
	var gate_combat := get_tree().current_scene
	if gate_combat != null:
		var day_plat := gate_combat.find_child("CombatStagePlatformArt", true, false) as TextureRect
		check(day_plat != null and day_plat.visible and day_plat.texture != null and day_plat.texture.resource_path.ends_with("combat_stage_platform_day.png"), "Daytime combat displays v8 combat_stage_platform_day")
		await capture("v8_combat_day_platform")
	state.game_hour = saved_hour

	state.current_node_id = "n_guard"
	state.pending_combat_data = {"enemies": ["security_guard"], "is_boss": false}
	flow.change_scene(flow.TargetScene.COMBAT)
	var guard_wait := 0
	while flow.is_transitioning and guard_wait < 300:
		guard_wait += 1
		await get_tree().process_frame
	await settled()
	var guard_combat := get_tree().current_scene
	if guard_combat != null:
		var red_plat := guard_combat.find_child("CombatStagePlatformArt", true, false) as TextureRect
		check(red_plat != null and red_plat.visible and red_plat.texture != null and red_plat.texture.resource_path.ends_with("combat_stage_platform_redmoon.png"), "Overclock combat displays v8 combat_stage_platform_redmoon")
		var guard_enemies := guard_combat.get("enemy_nodes") as Array
		check(guard_enemies != null and guard_enemies.size() == 1 and not guard_enemies[0].sprite.flip_h, "v8 native left-facing security_guard renders without flip_h")
		var hint_wash := guard_combat.get_node_or_null("FirstBattleHintWash") as Panel
		var wash_style := hint_wash.get_theme_stylebox("panel") as StyleBoxTexture if hint_wash != null else null
		check(hint_wash != null and hint_wash.visible and wash_style != null and wash_style.texture != null and wash_style.texture.resource_path.ends_with("ui_tutorial_callout_9slice.png"), "FirstBattleHintWash uses v7 ui_tutorial_callout_9slice")
		await capture("v7_n_guard_hint")

	state.current_node_id = "n5_boss"
	state.pending_combat_data = {"enemies": ["ch1_hunter_mech"], "is_boss": true, "overclock": true}
	flow.change_scene(flow.TargetScene.COMBAT)
	var boss_guard := 0
	while flow.is_transitioning and boss_guard < 300:
		boss_guard += 1
		await get_tree().process_frame
	await settled()
	var boss_combat := get_tree().current_scene
	if boss_combat != null:
		var boss_bg := boss_combat.get_node_or_null("Background") as TextureRect
		check(boss_bg != null and boss_bg.texture != null and boss_bg.texture.resource_path.contains("battle_red_moon_lockdown"), "Overclock combat switches background to battle_red_moon_lockdown")
		var boss_reticle := boss_combat.find_child("LoopVFX_target_reticle", true, false) as CanvasItem
		check(boss_reticle != null and boss_reticle.visible, "Overclock boss spawns LoopVFX_target_reticle")
		await capture("v7_overclock_boss_reticle")

	state.current_node_id = "ch1_trio_test"
	state.pending_combat_data = {"enemies": ["duel_student_ace", "alliance_operative", "church_guardian", "security_guard"], "companion_id": "yang_zi_ying", "overclock": false}
	flow.change_scene(flow.TargetScene.COMBAT)
	var trio_guard := 0
	while flow.is_transitioning and trio_guard < 300:
		trio_guard += 1
		await get_tree().process_frame
	await settled()
	var trio_combat := get_tree().current_scene
	if trio_combat != null:
		var trio_enemies := trio_combat.get("enemy_nodes") as Array
		check(trio_enemies != null and trio_enemies.size() == 3, "CombatScreen caps simultaneous enemies at 3 max")
		if trio_enemies != null and trio_enemies.size() == 3:
			var first_unit := trio_enemies[0] as EnemyUnitUI
			var second_unit := trio_enemies[1] as EnemyUnitUI
			var third_unit := trio_enemies[2] as EnemyUnitUI
			check(absf(first_unit.size.x - CombatPresentation.ENEMY_SLOT_SIZE.x) < 1.0 and absf(third_unit.size.x - CombatPresentation.ENEMY_SLOT_SIZE.x) < 1.0, "3-enemy slots keep constant fixed width without shrinking")
			first_unit.shield = 12
			first_unit.apply_burn(6, 2)
			second_unit.apply_debuff(0.25, 2)
			third_unit.shield = 8
			trio_combat.set("player_shield", 14)
			trio_combat.set("player_reflect_turns", 2)
			trio_combat.set("player_reflect_damage", 12)
			trio_combat.set("player_reflect_hits", 2)
			trio_combat.call("_update_player_ui")
			await get_tree().process_frame
			var p_icons := trio_combat.find_child("PlayerStatusIcons", true, false) as HBoxContainer
			var p_plaque := trio_combat.find_child("PlayerIdentity", true, false) as Control
			var p_sprite := trio_combat.find_child("ProtagonistSprite", true, false) as Control
			var c_sprite := trio_combat.find_child("CompanionSprite", true, false) as Control
			var e_plaque := first_unit.find_child("IdentityPaper", true, false) as Control
			var e_icons := first_unit.find_child("EnemyStatusIcons", true, false) as Control
			var weak_chip := second_unit.find_child("EnemyWeakChip", true, false) as CanvasItem
			var weak_status_icon := second_unit.find_child("StatusIcon", true, false) as CanvasItem
			check(p_icons != null and p_plaque != null and p_icons.position.y > p_plaque.position.y and p_icons.position.y + p_icons.size.y <= p_sprite.position.y, "Player status icon bar sits cleanly below Info Bar and above head")
			check(e_icons != null and e_plaque != null and e_icons.position.y > e_plaque.position.y, "Enemy status icon bar sits cleanly below Enemy Info Bar")
			check(c_sprite != null and c_sprite.visible and c_sprite.position.x + c_sprite.size.x * 0.5 < p_plaque.position.x, "Companion has fixed left slot with zero overhead Info/Status HUD")
			check(weak_chip != null and weak_chip.visible and weak_status_icon != null and weak_status_icon.visible, "Enemy weak chip exposes visible StatusIcon without burn active")
			check(not second_unit.sprite.flip_h and not CombatSkin.enemy_needs_flip_h("campus_robot") and CombatSkin.enemy_combat_path("campus_robot").ends_with("enemy_campus_robot.png"), "v8 left-facing alliance_operative and campus_robot load without flip_h")
			await capture("v8_combat_three_enemies")
	for av_path in [
		"res://assets/sprites/characters/phase_two/avatars/huang_qiufeng_surprised.png",
		"res://assets/sprites/characters/phase_two/avatars/huang_qiufeng_crystal_stasis.png",
		"res://assets/sprites/characters/phase_two/avatars/rebel_operative_unmasked_neutral.png",
	]:
		check(ResourceLoader.exists(av_path), "v8 avatar resource imported: " + av_path.get_file())
	state.current_node_id = ""
	state.pending_combat_data.clear()

	state.pending_dialogue_id = "campus_morning"
	flow.change_scene(flow.TargetScene.STORY)
	var dlg_guard := 0
	while flow.is_transitioning and dlg_guard < 300:
		dlg_guard += 1
		await get_tree().process_frame
	await settled()
	var story_dlg := get_tree().current_scene as DialogueScreen
	check(story_dlg != null, "Ch1 dialogue loads DialogueScreen")
	if story_dlg != null:
		var chapter_banner := story_dlg.story_presentation.get_node_or_null("ChapterBannerToast") as CanvasItem if is_instance_valid(story_dlg.story_presentation) else null
		check(chapter_banner != null and chapter_banner.visible, "DialogueScreen renders ui_chapter_banner at campus_morning line 0")
		await capture("v7_chapter_banner")
		story_dlg.line_index = 5
		story_dlg._show_next_line()
		await settled()
		await key(KEY_SPACE)
		await settled()
		var portrait := story_dlg.nameplate.get_node_or_null("SpeakerPortrait") as TextureRect
		var cursor := story_dlg.story_presentation.get("continue_cursor") as CanvasItem if is_instance_valid(story_dlg.story_presentation) else null
		check(portrait != null and portrait.visible and portrait.texture != null and portrait.texture.resource_path.contains("/avatars/huang_qiufeng_"), "DialogueScreen loads unified v7 avatar for Huang Qiufeng")
		check(cursor != null and cursor.visible, "DialogueScreen ContinueCursor appears after line reveal")
		await capture("v7_dialogue_qiufeng_cursor")

	flow.change_scene(flow.TargetScene.HOME)
	var exit_guard := 0
	while flow.is_transitioning and exit_guard < 300:
		exit_guard += 1
		await get_tree().process_frame
	await settled()
	var clean_home := get_tree().current_scene as HomeScreen
	check(clean_home != null, "returns to clean HomeScreen for Ch1 start verification")
	if clean_home != null:
		clean_home._start_chapter()
		var start_guard := 0
		while flow.is_transitioning and start_guard < 300:
			start_guard += 1
			await get_tree().process_frame
		await settled()
		check(get_tree().current_scene is DialogueScreen, "HomeScreen._start_chapter launches Ch1 DialogueScreen directly")
		flow.change_scene(flow.TargetScene.HOME)
		var back_guard := 0
		while flow.is_transitioning and back_guard < 300:
			back_guard += 1
			await get_tree().process_frame
		await settled()

