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
	check(CalendarContent.STORY_DATES.is_empty(),"test concepts do not fill formal story dates")
	print("SCENE_RESET_RESULT "+JSON.stringify({"checks":checks,"failures":failures,"renderer":DisplayServer.get_name()}))
	get_tree().quit(0 if failures.is_empty() else 1)

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
			check(Rect2(Vector2.ZERO,Vector2(1920,1080)).encloses(button.get_global_rect()),"object caption remains on canvas: "+id)
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
			check(Rect2(Vector2.ZERO,Vector2(1920,1080)).encloses(button.get_global_rect()),"map caption stays in canvas: "+id)
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
