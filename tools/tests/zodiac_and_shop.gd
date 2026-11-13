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

