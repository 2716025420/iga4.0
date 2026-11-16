extends "res://tools/tests/p5_regions.gd"

## Scene-level regression: real Viewport input, registered artwork and production navigation.
func _run() -> void:
	state = get_tree().root.get_node("GameState")
	life = get_tree().root.get_node("CampusLife")
	flow = get_tree().root.get_node("SceneManager")
	saves = get_tree().root.get_node("SaveManager")
	cycle = get_tree().root.get_node("DayCycle")
	cycle.suspended = true
	saves.active_session = false
	saves.save_path = "user://scene_reset_tests/slot_1.json"
	saves.settings["reduced_motion"] = true
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--captures="): captures = arg.trim_prefix("--captures=")
	if captures != "": DirAccess.make_dir_recursive_absolute(captures)
	check(state.new_game(),"scene-reset fixture starts normally")
	flow.change_scene(flow.TargetScene.HOME)
	await settled()
	await _campus_interactions()
	await _registered_homes()
	await _map_and_compatibility_pages()
	await _wave5_visual_checks()
	await _dialogue_and_script_checks()
	check(CalendarContent.STORY_DATES.is_empty(),"test concepts do not fill formal story dates")
	print("SCENE_RESET_RESULT "+JSON.stringify({"checks":checks,"failures":failures,"renderer":DisplayServer.get_name()}))
	get_tree().quit(0 if failures.is_empty() else 1)

func _wave5_visual_checks() -> void:
	var prev_reduced := bool(saves.settings.get("reduced_motion", false))
	saves.settings["reduced_motion"] = false
	var presets := ParallaxCutsceneStage.available_presets()
	for pid in ["dusk_corridor", "red_moon_street", "arena_spotlight", "old_park_dusk", "rebel_warning", "qiufeng_crystal", "red_moon_finale"]:
		check(presets.has(pid), "cutscene preset registered: " + pid)
	check(ParallaxCutsceneStage.preset_status("old_park_dusk") == "story_concept_review", "old_park_dusk stays marked story_concept_review")
	check(ParallaxCutsceneStage.preset_status("rebel_warning") == "story_concept_review", "rebel_warning stays marked story_concept_review")
	check(ParallaxCutsceneStage.preset_for_dialogue("after_school", "campus") == "dusk_corridor", "after_school keeps dusk_corridor preset")

	var cut_layer := CanvasLayer.new()
	cut_layer.layer = 95
	var cut_host := Control.new()
	cut_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var cut_stage := Control.new()
	cut_stage.size = Vector2(1920, 1080)
	var cutscene := ParallaxCutsceneStage.create("red_moon_street", false)
	cut_stage.add_child(cutscene)
	DaylightUI.place(cutscene, 0, 0, 1920, 1080)
	cut_host.add_child(cut_stage)
	cut_layer.add_child(cut_host)
	get_tree().root.add_child(cut_layer)
	await settled()
	check(is_instance_valid(cutscene.bg_layer) and cutscene.bg_layer.texture != null and is_instance_valid(cutscene.fg_layer) and cutscene.fg_layer.texture != null, "red_moon_street cutscene layers load textures")
	Platform.fit_stage(cut_host, cut_stage, Color("#242834"), cutscene.background_texture())
	cutscene.set_progress(0.45)
	await settled()
	await capture("wave5_cutscene_red_moon")
	cutscene.configure("arena_spotlight", false)
	check(is_instance_valid(cutscene.bg_layer) and cutscene.bg_layer.texture != null and is_instance_valid(cutscene.fg_layer) and cutscene.fg_layer.texture != null, "arena_spotlight cutscene layers load textures")
	Platform.fit_stage(cut_host, cut_stage, Color("#242834"), cutscene.background_texture())
	cutscene.set_progress(0.45)
	await settled()
	await capture("wave5_cutscene_arena")
	cutscene.configure("qiufeng_crystal", false)
	check(is_instance_valid(cutscene.bg_layer) and cutscene.bg_layer.texture != null and is_instance_valid(cutscene.fg_layer) and cutscene.fg_layer.texture != null, "qiufeng_crystal cutscene layers load textures")
	check(cutscene.fg_layer.get_node_or_null("LoopVFX_crystal_shimmer") != null, "qiufeng_crystal mounts crystal_shimmer loop")
	Platform.fit_stage(cut_host, cut_stage, Color("#242834"), cutscene.background_texture())
	cutscene.set_progress(0.5)
	await settled()
	await capture("v6_cutscene_qiufeng_crystal")
	cutscene.configure("red_moon_finale", false)
	check(is_instance_valid(cutscene.bg_layer) and cutscene.bg_layer.texture != null and is_instance_valid(cutscene.fg_layer) and cutscene.fg_layer.texture != null, "red_moon_finale cutscene layers load textures")
	Platform.fit_stage(cut_host, cut_stage, Color("#242834"), cutscene.background_texture())
	cutscene.set_progress(0.5)
	await settled()
	await capture("v6_cutscene_red_moon_finale")
	cut_layer.queue_free()
	await settled()

	var loader := SceneLoadingScreen.new()
	get_tree().root.add_child(loader)
	await get_tree().process_frame
	for theme_key in ["after_school", "red_moon", "nomos", "agora", "techne", "tournament"]:
		check(SceneLoadingScreen.THEMES.has(theme_key), "loading theme registered: " + theme_key)
		loader.apply_theme(theme_key)
		var backdrop := loader.find_child("DuskCorridor", true, false) as TextureRect
		check(backdrop != null and backdrop.texture != null, "loading theme texture loads: " + theme_key)
	loader.queue_free()

	for vfx_key in ["slash", "shield", "heal", "pack"]:
		check(CombatVFX.frames_for(vfx_key).size() == 8, "CombatVFX 4x2 sheet loads 8 frames: " + vfx_key)
	for svg_path in [CombatVFX.SVG_CORNER_BRACKET, CombatVFX.SVG_ARROW_SWEEP, CombatVFX.SVG_DUEL_CREST_VS, CombatVFX.SVG_RED_MOON_RETICLE]:
		check(ResourceLoader.exists(svg_path), "CombatVFX SVG asset exists: " + svg_path)

	check(saves.load_test_save() and saves.test_session, "wave5 combat enters test save")
	var duel_loadout: Dictionary = state.player_profile["loadouts"][2]
	check(str(duel_loadout.get("name", "")) == "决斗包·TEST" and state.apply_equipped_deck(duel_loadout["card_ids"], 2), "wave5 equips 决斗包·TEST loadout")
	state.pending_combat_data = {"enemies": ["duel_student_ace", "church_guardian"], "companion_id": "liu_yu_long"}
	flow.change_scene(flow.TargetScene.COMBAT)
	var transition_guard := 0
	while flow.is_transitioning and transition_guard < 300:
		transition_guard += 1
		await get_tree().process_frame
	await settled()

	var combat := get_tree().current_scene
	var anim_guard := 0
	while combat != null and (bool(combat.get("is_animating")) or not bool(combat.get("is_player_turn"))) and anim_guard < 180:
		anim_guard += 1
		await get_tree().process_frame
	var enemies := combat.get("enemy_nodes") as Array
	var cards := combat.get("card_ui_nodes") as Array
	var companion_sprite := combat.find_child("CompanionSprite", true, false) as TextureRect
	var duel_deck_back := combat.find_child("DuelDeckBack", true, false) as TextureRect
	var stage_zones := combat.find_child("ArenaStageZones", true, false)
	var stage_platform_art := combat.find_child("CombatStagePlatformArt", true, false) as TextureRect
	var stage_platform := stage_platform_art if (stage_platform_art != null and stage_platform_art.visible) else combat.find_child("CombatStagePlatform", true, false)
	check(enemies != null and enemies.size() == 2, "wave5 combat spawns 2 TEST duel enemies")
	check(cards != null and cards.size() == 5, "wave5 combat deals 5 cards from 决斗包·TEST")
	check(companion_sprite != null and companion_sprite.visible and companion_sprite.texture != null, "wave5 combat displays companion sprite")
	check(duel_deck_back != null and duel_deck_back.visible and duel_deck_back.texture != null, "wave5 combat displays DuelDeckBack")
	check(stage_zones != null and stage_platform != null and combat.find_child("ArenaEmblems", true, false) == null, "combat separates upper HUD band & unified platform without floating center SVGs")
	check(not enemies[0].sprite.flip_h and not enemies[1].sprite.flip_h and not CombatSkin.enemy_needs_flip_h("alliance_operative") and not CombatSkin.enemy_needs_flip_h("security_guard") and not CombatSkin.enemy_needs_flip_h("campus_robot") and not CombatSkin.enemy_needs_flip_h("ch1_hunter_mech") and CombatSkin.enemy_needs_flip_h("liu_yu_long_duel"), "combat enemies face left cleanly toward player")
	await capture("wave5_combat_duel")

	var target_card: Control = null
	for card_node in cards:
		var cdata := card_node.get("card_data") as CardData
		if cdata != null and cdata.id == "crimson_pulse":
			target_card = card_node as Control
			break
	check(target_card != null, "crimson_pulse present in Wave 5 combat hand")
	if target_card != null:
		await get_tree().process_frame
		target_card.card_clicked.emit(target_card.get("card_data"))
		await get_tree().process_frame
		await get_tree().process_frame
		var anchor := combat.get("floating_anchor") as Control
		var vfx_slash := anchor.get_node_or_null("VFX_slash") if anchor != null else null
		check(vfx_slash != null, "crimson_pulse spawns active VFX_slash burst")
		var status_icon := (enemies[0] as Node).find_child("StatusIcon", true, false) as CanvasItem
		check(status_icon != null and status_icon.visible, "crimson_pulse burn status displays debuff.svg StatusIcon")
		for _f in 7:
			await get_tree().process_frame
		await capture("wave5_combat_vfx")
		var post_guard := 0
		while combat != null and bool(combat.get("is_animating")) and post_guard < 180:
			post_guard += 1
			await get_tree().process_frame

	var reward_popup := get_tree().root.find_child("RewardCards", true, false)
	if reward_popup != null:
		await get_tree().process_frame
		reward_popup.call("enqueue", {"card:duel_draw": 1})
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
		var pack_pres := reward_popup.get("presentation") as Control
		var pack_vfx := pack_pres.get_node_or_null("VFX_pack") as TextureRect if pack_pres != null else null
		var pack_tear := pack_pres.get_node_or_null("VFX_pack_tear") as TextureRect if pack_pres != null else null
		check(pack_vfx != null, "RewardCardPopup spawns VFX_pack burst on card reward")
		check(pack_tear != null, "RewardCardPopup spawns VFX_pack_tear burst on card reward")
		if pack_vfx != null:
			var center_delta := (pack_vfx.position + pack_vfx.size * 0.5 - Vector2(960, 540)).length()
			check(center_delta < 2.0, "RewardCardPopup VFX_pack centers on presentation stage")
		for _f in 8:
			await get_tree().process_frame
		await capture("wave5_reward_pack")
		reward_popup.call("dismiss")
		await get_tree().process_frame

	saves.settings["reduced_motion"] = prev_reduced
	state.pending_combat_data.clear()
	check(saves.start_new_game() and not saves.test_session, "wave5 cleanup exits test session cleanly")
	flow.change_scene(flow.TargetScene.HOME)
	await settled()

func _campus_interactions() -> void:
	for id in ["rooftop","library","gym","shop"]:
		check(life.travel_to(id),"campus location reachable: "+id)
		await settled()
		var screen: CampusScreen = get_tree().current_scene
		check(is_instance_valid(screen.scene_objects),"location uses concept object flow: "+id)
		check(screen.scene_objects.refs["actions"].size() == 2,"exactly two useful location actions: "+id)
		check(not screen.presentation.has_node("ResidentNPC"),"unconfirmed character art is not imposed: "+id)
		var background: TextureRect = screen.scene_objects.get_node("PlaceBackground")
		check(background.texture != null and background.texture.resource_path == SceneDesignCatalog.place_path(id),"new environment actually loaded: "+id)
		for button in screen.refs["actions"].values():
			check(button.get_theme_stylebox("focus") is StyleBoxEmpty,"no focus frame: "+id)
			check(Rect2(Vector2.ZERO,get_viewport().get_visible_rect().size).encloses(button.get_global_rect()),"object caption remains on canvas: "+id)
		await capture("place_"+id)
		if id == "gym":
			await click(screen.refs["actions"]["training"])
			check(is_instance_valid(screen._workspace),"training object opens production route selector")
			await capture("gym_training")
			await key(KEY_ESCAPE)
			await get_tree().process_frame
			check(not is_instance_valid(screen._workspace),"training selector closes with keyboard")
			await click(screen.refs["actions"]["workshop"])
			check(is_instance_valid(screen._workspace),"gym bag opens shared card workspace")
			await capture("gym_workshop")
			await key(KEY_ESCAPE)
			await get_tree().process_frame
			check(screen.scene_objects.selected_id == "","workspace clears scene selection")
		elif id == "shop":
			var before: Dictionary = cycle.snapshot()
			await click(screen.refs["actions"]["shop"])
			check(screen._workspace is CampusShopPanel,"shop object opens local trade counter")
			await capture("shop_counter")
			await click(screen._workspace.find_child("Talk",true,false))
			check(is_instance_valid(screen.dialogue),"counter retains conversation entry")
			await key(KEY_ESCAPE)
			await get_tree().process_frame
			await click(screen.refs["actions"]["delivery"])
			check(is_instance_valid(screen.dialogue),"delivery note retains ordinary dialogue")
			await key(KEY_ESCAPE)
			await get_tree().process_frame
			await click(screen.scene_objects.objects["shop"])
			check(screen._workspace is CampusShopPanel,"physical shop object opens same counter")
			await key(KEY_ESCAPE)
			await get_tree().process_frame
			check(cycle.snapshot() == before,"viewing shop and conversation remain free")
			check(screen.scene_objects.selected_id == "","counter close clears scene selection")
		else:
			var progress: Dictionary = state.export_progress(false)
			progress["player_profile"]["calendar"] = cycle.snapshot()
			progress["player_profile"]["calendar"]["remaining"] = 0
			check(state.import_progress(progress),"zero-action interaction fixture imports")
			var before: Dictionary = cycle.snapshot()
			for action in screen.refs["actions"].keys():
				await click(screen.refs["actions"][action])
				check(is_instance_valid(screen.dialogue),"ordinary object interaction works at zero actions: "+id+"/"+action)
				if action == screen.refs["actions"].keys()[0] and is_instance_valid(screen.dialogue):
					if screen.dialogue.body.visible_characters >= 0 and screen.dialogue.body.visible_characters < screen.dialogue.body.get_total_character_count(): await key(KEY_SPACE)
					await capture("dialogue_"+id)
				if is_instance_valid(screen.dialogue):
					check(screen.dialogue.has_node("NextLine") and screen.dialogue.has_node("CloseDialogue"),"dialogue keeps mouse controls")
					for control in ["NextLine","CloseDialogue"]:
						check(screen.dialogue.get_node("DialogueSurface").get_global_rect().encloses(screen.dialogue.get_node(control).get_global_rect()),"mouse dialogue buttons fit inside paper panel")
					await click(screen.dialogue.get_node("CloseDialogue"))
					await get_tree().process_frame
				check(cycle.snapshot() == before,"ordinary viewing/conversation is free: "+id+"/"+action)
				check(screen.scene_objects.selected_id == "","dialogue clears selected object: "+id)
				await click(screen.scene_objects.objects[action])
				check(is_instance_valid(screen.dialogue),"physical object opens same interaction: "+id+"/"+action)
				await key(KEY_ESCAPE)
				await get_tree().process_frame
				check(cycle.snapshot() == before,"physical object interaction is also free: "+id+"/"+action)
		var keyboard_entry: Button = screen.refs["actions"].values()[0]
		keyboard_entry.grab_focus()
		await key(KEY_ENTER)
		await get_tree().process_frame
		check(is_instance_valid(screen._workspace) if id in ["gym","shop"] else is_instance_valid(screen.dialogue),"keyboard activates object entry: "+id)
		await key(KEY_ESCAPE)
		await get_tree().process_frame
		check(get_viewport().gui_get_focus_owner() == keyboard_entry,"modal closing restores keyboard entry focus: "+id)
		var original := life.current_location
		await click(screen.refs["map_button"])
		check(flow.current_scene_type == flow.TargetScene.LOCAL_MAP,"scene map button opens local map: "+id)
		await key(KEY_ESCAPE)
		await settled()
		check(life.current_location == original,"map back returns to actual scene: "+id)

func _registered_homes() -> void:
	for slug in ["nomos","agora","techne"]:
		state.set_story_flag("region_"+slug+"_unlocked",true)
		check(life.enter_region("university_"+slug),"Home region entered: "+slug)
		await settled()
		if not life.has_visited_region("university_"+slug):
			check(life.complete_first_visit(),"Home first arrival completed: "+slug)
			await settled()
		var screen: CampusScreen = get_tree().current_scene
		var view: RegionHomeView = screen.object_home
		check(is_instance_valid(view),"new registered Home view loaded: "+slug)
		var source: Texture2D = view.get_node("RoomBackground").texture
		var factor := Vector2(1920,1080)/source.get_size()
		for object in view.objects.values():
			check(object.get_meta("source_registered",false),"furniture has source registration: "+slug)
			var region: Rect2 = object.get_meta("source_rect")
			check(object.position.is_equal_approx(region.position*factor) and object.size.is_equal_approx(region.size*factor),"furniture never independently fit-scaled: "+slug)
			check(object.texture_click_mask.get_true_bit_count() > 0,"furniture has live alpha input mask")
		await capture("home_"+slug)

func _map_and_compatibility_pages() -> void:
	for id in WorldRegionContent.REGIONS:
		var flag := str(WorldRegionContent.REGIONS[id]["unlock_condition"])
		if flag != "": state.set_story_flag(flag,true)
	state.set_story_flag("region_resistance_unlocked",true)
	state.set_story_flag("region_sanctuary_unlocked",true)
	for id in SceneDesignCatalog.MAPS:
		var previous := life.current_location
		var before: Dictionary = cycle.snapshot()
		check(life.open_local_map(id),"illustrated map opens: "+id)
		await settled()
		var map: RegionMapView = get_tree().current_scene.view
		check(map.has_node("ConceptMother"),"map has actual mother image: "+id)
		check(map.refs["locations"].size() == SceneDesignCatalog.MAPS[id]["locations"].size(),"map exposes implemented destinations only: "+id)
		check(life.current_location == previous and cycle.snapshot() == before,"map browsing preserves location/time: "+id)
		for button in map.refs["locations"].values():
			check(Rect2(Vector2.ZERO,get_viewport().get_visible_rect().size).encloses(button.get_global_rect()),"map caption stays in canvas: "+id)
		await capture("map_"+id)
		await key(KEY_ESCAPE)
		await settled()
		check(life.current_location == previous,"map Esc returns to actual origin: "+id)
	check(life.open_region_atlas(),"new world travel picture opens")
	await settled()
	check(get_tree().current_scene.view.refs["regions"].size() == 6,"world exposes six independent regions")
	await capture("world_open")
	var atlas: RegionAtlasView = get_tree().current_scene.view
	for pair in atlas.refs["regions"].values():
		check(pair["landmark"].z_index < atlas.get_node("DayTime").z_index,"world objects cannot repaint date/title")
		check(pair["enter"].get_index() > pair["landmark"].get_index(),"world captions take input above physical objects")
	state.set_story_flag("region_nomos_unlocked",false)
	check(atlas.refs["regions"]["university_nomos"]["enter"].disabled and atlas.refs["regions"]["university_nomos"]["landmark"].disabled,"world label and environmental hotspot lock together")
	await capture("world_locked")
	state.set_story_flag("region_nomos_unlocked",true)
	await key(KEY_ESCAPE)
	await settled()
	# Exercise the real first-arrival route once before visiting all story/compat pages.
	for id in WorldRegionContent.REGIONS:
		check(life.enter_region(id),"region remains navigable after redesign: "+id)
		await settled()
		if not life.has_visited_region(id):
			await capture("arrival_"+str(id))
			check(life.complete_first_visit(),"first-arrival still completes: "+id)
			await settled()
	var places: Array = ["arete_coast_test","arete_beach_test","study","stockroom"]
	for id in ["region_failed_alliance","region_iga_church","resistance","sanctuary"]:
		places.append_array(RegionCatalog.REGIONS[id]["places"])
	for id in places:
		check(life.travel_to(id),"test/compat location remains reachable: "+str(id))
		await settled()
		var screen: CampusScreen = get_tree().current_scene
		check(is_instance_valid(screen.scene_objects),"test/compat location has concept rendering: "+str(id))
		check(screen.scene_objects.get_node("PlaceBackground").texture != null,"test/compat image loaded: "+str(id))
		await capture("scene_"+str(id))

func _collect_res_files(folder: String, suffix: String, out: Array[String]) -> void:
	var dir := DirAccess.open(folder)
	if dir == null: return
	dir.list_dir_begin()
	var item := dir.get_next()
	while item != "":
		if not item.begins_with("."):
			var full := folder.path_join(item)
			if dir.current_is_dir(): _collect_res_files(full, suffix, out)
			elif item.ends_with(suffix): out.append(full)
		item = dir.get_next()
	dir.list_dir_end()

func _dialogue_and_script_checks() -> void:
	var gd_files: Array[String] = []
	var tscn_files: Array[String] = []
	_collect_res_files("res://scripts", ".gd", gd_files)
	_collect_res_files("res://scenes", ".tscn", tscn_files)
	check(gd_files.size() > 20 and tscn_files.size() >= 10, "enumerated project scripts and scenes for compile check")
	for path in gd_files:
		var scr := load(path) as GDScript
		check(scr != null and scr.can_instantiate(), "project script loads cleanly: " + path)
	for path in tscn_files:
		var packed := load(path) as PackedScene
		check(packed != null, "project scene loads cleanly: " + path)

	check(state.new_game(), "story-node check resets cleanly to new game")
	state.exploration_state.clear()
	state.exploration_active = false
	check(state.start_exploration("campus_basic", 12345), "starts campus_basic exploration route")
	await settled()
	var route_screen := get_tree().current_scene as SchoolRouteScreen
	check(route_screen != null, "exploration enters SchoolRouteScreen")
	var story_id := ""
	for raw_id in state.get_exploration_available_nodes():
		var node_id := str(raw_id)
		var node: Dictionary = state.get_exploration_node(node_id)
		if SchoolExplorationRoutes.kind_for(node) == "story":
			story_id = node_id
			break
	check(story_id != "", "depth 0 offers 拾到的留言 story node")
	if story_id != "":
		var story_btn := route_screen.refs["card_buttons"].get(story_id) as BaseButton
		check(story_btn != null, "拾到的留言 route card button exists")
		await click(story_btn)
		await settled()
		var dlg := get_tree().current_scene as DialogueScreen
		check(dlg != null and dlg.has_node("StoryPresentation"), "拾到的留言 opens functional DialogueScreen")
		if dlg != null:
			check(dlg.text_label.text != "故事马上开始。" and dlg.text_label.text.contains("路牌下面压着一张纸条"), "DialogueScreen loads 拾到的留言 line 1")
			check(is_instance_valid(dlg.pause_button) and not dlg.pause_button.disabled, "DialogueScreen pause button ready")
			await key(KEY_SPACE)
			await settled()
			await capture("story_exploration_note")
			await click(dlg.skip_button)
			await settled()
		check(get_tree().current_scene is SchoolRouteScreen, "completing 拾到的留言 returns cleanly to SchoolRouteScreen")
		check(int(state.exploration_state.get("depth", 0)) == 1, "拾到的留言 completion advances exploration depth")
	if bool(state.exploration_active):
		state.retreat_exploration()
		await settled()

	state.pending_dialogue_id = "find_yang"
	flow.change_scene(flow.TargetScene.STORY)
	await settled()
	var find_dlg := get_tree().current_scene as DialogueScreen
	check(find_dlg != null and is_instance_valid(find_dlg.story_presentation), "find_yang enters DialogueScreen with presentation")
	if find_dlg != null:
		check(find_dlg.story_presentation.cutscene_stage.preset_id == "qiufeng_crystal", "find_yang opens qiufeng_crystal cutscene")
		await key(KEY_ESCAPE)
		await settled()
	check(flow.current_scene_type == flow.TargetScene.HOME, "Esc pauses DialogueScreen cleanly back to Home")
