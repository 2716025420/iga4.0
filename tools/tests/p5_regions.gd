extends Node

## Integration regression using the actual autoloads, scene transitions and save I/O.
## Run with tools/cloud/test_p5.sh. Never writes a normal player save.
var state: Node
var life: CampusLifeService
var flow: ProjectSceneFlow
var saves: SaveService
var cycle: DayCycleService
var checks := 0
var failures: Array[String] = []
var captures := ""

func _ready() -> void:
 # SaveManager applies windowed defaults before this fixture. Override only in QA.
 if "--fullscreen-capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
  get_window().mode = Window.MODE_FULLSCREEN
 # Keep the test driver alive while the production scene flow replaces scenes.
 get_tree().current_scene = null
 _run.call_deferred()

func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures.append(message)
  printerr("FAIL: "+message)

func settled() -> void:
 var start := Time.get_ticks_msec()
 while flow.is_transitioning and Time.get_ticks_msec()-start < 20000:
  await get_tree().process_frame
 check(not flow.is_transitioning and flow.last_error == "","scene transition succeeded")
 await get_tree().process_frame
 await get_tree().process_frame

func capture(label: String) -> void:
 if captures == "" or DisplayServer.get_name() == "headless": return
 await RenderingServer.frame_post_draw
 var output := captures.path_join(label+".png")
 check(get_tree().root.get_texture().get_image().save_png(output) == OK,"render screenshot "+label)

func button_copy(button: BaseButton) -> String:
 return button.text if button is Button else str(button.get_meta("display_label",""))

func click(button: BaseButton) -> void:
 var point := button.get_global_rect().get_center()
 if button is HomeObjectButton:
  var mask: BitMap = button.texture_click_mask
  var pixels := mask.get_size()
  for y in range(pixels.y/4,pixels.y*3/4,4):
   var found := false
   for x in range(pixels.x/4,pixels.x*3/4,4):
    if mask.get_bit(x,y):
     point = button.get_global_transform()*Vector2(float(x)/pixels.x*button.size.x,float(y)/pixels.y*button.size.y)
     found = true
     break
   if found: break
 var motion := InputEventMouseMotion.new()
 motion.position = point
 get_viewport().push_input(motion,true)
 await get_tree().process_frame
 for down in [true,false]:
  var event := InputEventMouseButton.new()
  event.position = point
  event.button_index = MOUSE_BUTTON_LEFT
  event.pressed = down
  get_viewport().push_input(event,true)
  await get_tree().process_frame
 await settled()

func key(code: Key) -> void:
 for down in [true,false]:
  var event := InputEventKey.new()
  event.keycode = code
  event.pressed = down
  get_viewport().push_input(event,true)
  await get_tree().process_frame

func _run() -> void:
 state = get_tree().root.get_node("GameState")
 life = get_tree().root.get_node("CampusLife")
 flow = get_tree().root.get_node("SceneManager")
 saves = get_tree().root.get_node("SaveManager")
 cycle = get_tree().root.get_node("DayCycle")
 cycle.suspended = true
 saves.active_session = false
 saves.save_path = "user://p5_tests/slot_1.json"
 saves.settings["reduced_motion"] = true
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--captures="): captures = arg.trim_prefix("--captures=")
 if captures != "": DirAccess.make_dir_recursive_absolute(captures)
 check(state.new_game(),"new game imports initial progress")
 flow.change_scene(flow.TargetScene.HOME)
 await settled()
 var initial: Dictionary = state.export_progress(false).duplicate(true)
 var calendar: Dictionary = cycle.snapshot()
 check(WorldRegionContent.REGIONS.size() == 6,"six primary regions")
 check(RegionCatalog.LEGACY_REGIONS.size() == 3,"three historical IDs preserved")
 var homes := 0
 for id in WorldRegionContent.REGIONS:
  var spec: Dictionary = RegionCatalog.REGIONS[id]
  check(spec["area_map_id"] == id,"independent area map: "+id)
  check(spec["first_visit_event_id"] == "","no invented story: "+id)
  check(RegionCatalog.owns_place(id,spec["first_entry_id"]),"arrival registered: "+id)
  if spec["home"] != "": homes += 1
  else:
   check(spec["category"] == "story_region_without_home","story has no Home: "+id)
   check(spec["dungeon_difficulties"].size() > 1 and spec["shop_slots"].size() == 1 and spec["special_feature_slots"].size() == 1,"story slots: "+id)
   check(not life.travel_home(id),"no synthetic story Home: "+id)
 check(homes == 4,"exactly four primary Homes")
 check(RegionCatalog.home_for_region("university_arete") == "club","Arete adapts original club ID")
 check(not RegionCatalog.is_home(""),"empty Home is never a Home")
 check(not RegionCatalog.is_unlocked("missing"),"unknown region fails closed")
 check(not life.travel_to("missing"),"unknown place fails closed")
 check(not life.travel_to("club","university_nomos"),"foreign location cannot spoof region")
 check(not life.complete_first_visit(),"cannot complete arrival outside arrival page")
 await capture("arete_original_home")
 check(life.open_region_atlas(),"world map opens")
 await settled()
 var atlas: RegionAtlasView = get_tree().current_scene.view
 check(atlas.refs["regions"].size() == 6,"world UI exposes six primary regions")
 await capture("world_locked")
 for id in WorldRegionContent.REGIONS:
  if id == "university_arete": continue
  var before := life.snapshot()
  check(atlas.refs["regions"][id]["enter"].disabled and atlas.refs["regions"][id]["browse"].disabled,"locked buttons: "+id)
  check(not life.enter_region(id),"locked region denied: "+id)
  check(not life.open_local_map(id),"locked map denied: "+id)
  for loc in RegionCatalog.REGIONS[id]["places"]+[RegionCatalog.REGIONS[id]["first_entry_id"]]:
   check(not life.travel_to(loc,id),"locked direct travel denied: "+loc)
  check(life.snapshot() == before,"denied navigation has no side effects: "+id)
  state.set_story_flag(RegionCatalog.REGIONS[id]["unlock_condition"],true)
  check(not atlas.refs["regions"][id]["enter"].disabled,"live flag unlock refreshes UI: "+id)
 await capture("world_unlocked")
 # Use actual mouse events for the first route, keyboard for completion.
 await click(atlas.refs["regions"]["university_nomos"]["enter"])
 check(life.current_location == "nomos_arrival_test","mouse world entry reaches first arrival")
 check(not life.has_visited_region("university_nomos"),"arrival not auto-completed")
 check(saves.start_new_game(),"isolated test save can start")
 # Restore the just-unlocked test progress after validating the start-new boundary.
 check(state.import_progress(initial),"restore baseline before six-region loop")
 saves.active_session = false
 for id in WorldRegionContent.REGIONS:
  var spec: Dictionary = RegionCatalog.REGIONS[id]
  if spec["unlock_condition"] != "": state.set_story_flag(spec["unlock_condition"],true)
  var origin: Dictionary = life.snapshot()
  check(life.open_local_map(id),"browse unlocked area: "+id)
  await settled()
  check(not life.has_visited_region(id),"browsing does not count as visit: "+id)
  check(life.snapshot() == origin,"browsing keeps location: "+id)
  check(life.travel_to(spec["entry_id"],id),"first direct travel: "+id)
  await settled()
  check(life.current_location == spec["first_entry_id"],"first travel redirects: "+id)
  check(life.snapshot()["region_visits"][id] == "arrived","pending arrival persisted: "+id)
  # Save/read unfinished first arrival using the production validator and JSON I/O.
  saves.active_session = true
  check(saves.save_game(),"save unfinished first arrival: "+id)
  check(saves.continue_game(),"read unfinished first arrival: "+id)
  life.restore_saved_location()
  await settled()
  check(life.current_location == spec["first_entry_id"] and not life.has_visited_region(id),"resume first arrival: "+id)
  var complete: Button = get_tree().current_scene.refs["actions"].values()[0]
  complete.grab_focus()
  await key(KEY_ENTER)
  await settled()
  check(life.has_visited_region(id),"keyboard completes arrival: "+id)
  check(life.current_location == spec["entry_id"],"correct region landing: "+id)
  check(life.current_region == id,"correct explicit region context: "+id)
  check(life.is_home_location() == (spec["home"] != ""),"Home category correct: "+id)
  check(cycle.snapshot() == calendar,"travel does not change time/action budget: "+id)
  await capture(id+"_entry")
  check(saves.save_manual_slot(1),"manual save new region: "+id)
  check(life.travel_to("club","campus"),"return legacy club: "+id)
  await settled()
  check(saves.load_manual_slot(1),"manual read new region: "+id)
  life.restore_saved_location()
  await settled()
  check(life.current_region == id and life.current_location == spec["entry_id"],"restore correct location: "+id)
  check(life.enter_region(id),"revisit region: "+id)
  await settled()
  check(life.current_location == spec["entry_id"],"revisit skips first arrival: "+id)
  check(life.open_map(),"map from new region: "+id)
  await settled()
  await capture(id+"_map")
  check(life.open_region_atlas(),"atlas from area: "+id)
  await settled()
  await key(KEY_ESCAPE)
  await settled()
  check(flow.current_scene_type == flow.TargetScene.LOCAL_MAP and life.map_region_id == id,"Esc atlas returns area: "+id)
  await key(KEY_ESCAPE)
  await settled()
  check(life.current_location == spec["entry_id"] and life.current_region == id,"Esc area returns actual origin: "+id)
  if spec["home"] != "club" and spec["home"] != "":
   get_tree().current_scene._open_workspace("workshop")
   check(get_tree().current_scene.get_meta("region_modal_open",false),"shared card workspace: "+id)
   check(not life.enter_region("university_arete"),"workspace blocks travel: "+id)
   get_tree().current_scene._close_workspace()
   get_tree().current_scene._open_workspace("records")
   check(get_tree().current_scene.get_meta("region_modal_open",false),"shared records workspace: "+id)
   get_tree().current_scene._close_workspace()
  if spec["home"] == "":
   for loc in spec["places"]:
    check(life.travel_to(loc,id),"story feature test entrance: "+loc)
    await settled()
    check(not life.is_home_location(),"feature is not Home: "+loc)
    if loc.ends_with("dungeon_test"):
     var before_progress: Dictionary = state.export_progress(false)
     get_tree().current_scene._action(CampusPlaces.PLACES[loc]["actions"][0])
     check(not state.exploration_active and cycle.snapshot() == calendar,"TEST difficulty does not start dungeon or spend action")
     check(state.export_progress(false) == before_progress,"TEST difficulty has no economic/story effects")
     get_tree().current_scene.dialogue.queue_free()
     get_tree().current_scene.dialogue = null
     get_tree().current_scene.set_meta("campus_dialogue_open",false)
    check(life.open_map(),"story feature can return map: "+loc)
    await settled()
 # Cross-region browsing and revoked permissions retain a safe, explicit origin.
 check(life.enter_region("university_nomos"),"return Nomos for origin checks")
 await settled()
 var nomos_origin: Dictionary = life.snapshot()
 check(life.open_map(),"open Nomos map before browsing")
 await settled()
 check(life.open_local_map("region_iga_church"),"browse another unlocked region")
 await settled()
 check(life.snapshot() == nomos_origin and life.current_region == "university_nomos","cross-region browsing keeps actual location/context")
 life.close_map()
 await settled()
 check(life.current_region == "university_nomos","closing foreign map returns actual region")
 check(life.open_region_atlas(),"atlas before permission revocation")
 await settled()
 state.set_story_flag("region_nomos_unlocked",false)
 check(get_tree().current_scene.view.refs["regions"]["university_nomos"]["enter"].disabled,"live revocation disables fast travel")
 check(not life.travel_home("university_nomos"),"revoked Home denied")
 life.restore_saved_location()
 await settled()
 check(life.current_location == "club" and life.current_region == "campus","locked saved location safely falls back and commits")
 state.set_story_flag("region_nomos_unlocked",true)
 # New Homes offer free partner conversation instead of a time-advancing rest.
 for id in ["university_nomos","university_agora","university_techne"]:
  check(life.travel_home(id),"new Home before partner conversation: "+id)
  await settled()
  var home: CampusScreen = get_tree().current_scene
  var place: Dictionary = CampusPlaces.PLACES[life.current_location]
  var partner: BaseButton
  for action in place["actions"]:
   check(action["id"] != "rest_test" and not str(action["label"]).contains("休息"),"new Home has no rest action: "+id)
   check(str(action.get("object_label", "")) != "","local representative object configured: "+id)
   if action["id"] == "partner_test": partner = home.refs["actions"]["partner_test2"]
  check(is_instance_valid(partner) and button_copy(partner).ends_with("伙伴交流"),"partner label uses local object: "+id)
  check(button_copy(home.refs["map_button"]).begins_with(place["map_object_label"]),"map label uses local object: "+id)
  var before_chat: Dictionary = state.export_progress(false)
  await click(partner)
  check(is_instance_valid(home.dialogue) and home.get_meta("campus_dialogue_open",false),"mouse opens partner conversation: "+id)
  check(home.dialogue.portrait.texture == null,"partner identity and portrait are not invented: "+id)
  check(not life.open_map(),"partner dialogue blocks travel: "+id)
  await key(KEY_ESCAPE)
  await get_tree().process_frame
  check(not is_instance_valid(home.dialogue) and partner.visible,"Esc closes conversation and restores actions: "+id)
  check(get_viewport().gui_get_focus_owner() == partner,"conversation returns keyboard focus: "+id)
  await key(KEY_ENTER)
  check(is_instance_valid(home.dialogue),"keyboard reopens partner conversation: "+id)
  if is_instance_valid(home.dialogue):
   await click(home.dialogue.get_node("CloseDialogue"))
  check(state.export_progress(false) == before_chat,"partner conversation has no time/action/reward/save effects: "+id)
  await capture(id+"_partner_home")
 check(cycle.snapshot() == calendar,"partner conversation preserves calendar and remaining actions")
 # All new state can be validated after the complete round trip.
 check(state.validate_progress(state.export_progress(false)),"new full progress validates")
 var malformed: Dictionary = life.snapshot()
 malformed["region_visits"] = {"not_a_region":"completed"}
 check(not CampusPlaces.valid_state(malformed),"unknown visit region rejected")
 malformed = life.snapshot()
 malformed["region_visits"] = {"university_nomos":true}
 check(not CampusPlaces.valid_state(malformed),"invalid visit status rejected")
 malformed = life.snapshot()
 malformed["region_id"] = "university_nomos"
 check(not CampusPlaces.valid_state(malformed),"inconsistent region/location rejected")
 # Old unlocked regions still use their original maps and Homes.
 for id in ["resistance","sanctuary"]:
  state.set_story_flag(RegionCatalog.UNLOCK_FLAGS[id],true)
  check(life.enter_region(id),"legacy unlocked region travels: "+id)
  await settled()
  check(life.current_region == id and life.is_home_location(),"legacy Home preserved: "+id)
  check(life.open_map(),"legacy area map opens: "+id)
  await settled()
  await capture("legacy_"+id+"_map")
 # Legacy snapshots have no new optional fields, including the map fallback.
 for loc in ["club","library","gym","study","stockroom","map","alliance_hq","sanctuary_hall"]:
  var old: Dictionary = initial.duplicate(true)
  var legacy: Dictionary = life.DEFAULT_STATE.duplicate(true)
  legacy["last_location"] = loc
  old["player_profile"]["campus_life"] = legacy
  check(state.import_progress(old),"legacy save accepted: "+loc)
  life.restore_saved_location()
  await settled()
  check(life.current_location == (loc if loc not in ["map","alliance_hq","sanctuary_hall"] else "club"),"legacy safe landing: "+loc)
 check(state.import_progress(initial),"reset before training regression")
 check(life.travel_to("gym","campus"),"legacy gym reachable")
 await settled()
 var actions_before := cycle.remaining()
 check(state.start_exploration("campus_basic",451),"existing training starts")
 await settled()
 check(cycle.remaining() == actions_before-1,"new training spends one action")
 check(not life.enter_region("university_arete"),"active training blocks region travel")
 var route: Dictionary = state.exploration_state.duplicate(true)
 check(state.pause_exploration(),"existing training pauses")
 await settled()
 check(life.current_location == "gym","paused training returns gym")
 check(saves.save_game() and saves.continue_game(),"paused training save/read")
 check(state.start_exploration("campus_basic",451),"existing training resumes")
 await settled()
 check(cycle.remaining() == actions_before-1,"training resume spends no action")
 var resumed_deck: Array = state.exploration_state["deck"]
 check(resumed_deck.size() == route["deck"].size(),"training deck length preserved")
 for i in resumed_deck.size():
  check(str(resumed_deck[i]["id"]) == str(route["deck"][i]["id"]) and int(resumed_deck[i]["level"]) == int(route["deck"][i]["level"]),"training deck card/order/level preserved")
 check(state.finish_exploration("retreated"),"training can end")
 await settled()
 check(life.current_location == "gym" and not state.exploration_active,"training ends at gym")
 check(PlayerJourney.deck_summary()["ready"],"equipped deck still valid")
 # Exercise actual combat screens and production victory/defeat/escape settlement.
 for outcome in ["victory","defeat","escape"]:
  check(state.import_progress(initial),"reset combat fixture: "+outcome)
  check(life.travel_to("gym","campus"),"gym before combat: "+outcome)
  await settled()
  check(state.start_exploration("campus_basic",451),"training before combat: "+outcome)
  await settled()
  var battle_id := ""
  for id in SchoolExplorationFlow.available_nodes():
   if not state.get_exploration_node(id).get("enemy_keys",[]).is_empty(): battle_id = id; break
  check(battle_id != "" and SchoolExplorationFlow.choose_node(battle_id),"choose existing battle: "+outcome)
  await settled()
  var combat: CombatScreen = get_tree().current_scene
  var start := Time.get_ticks_msec()
  while combat.is_animating and Time.get_ticks_msec()-start < 5000: await get_tree().process_frame
  check(combat.card_ui_nodes.size() == state.equipped_card_ids.size(),"combat uses equipped cards: "+outcome)
  check(saves.save_game(),"save live combat: "+outcome)
  check(saves.continue_game(),"load live combat: "+outcome)
  check(not state.exploration_checkpoint.is_empty(),"combat snapshot retained: "+outcome)
  check(state.start_exploration("campus_basic",451),"resume saved combat through production training service: "+outcome)
  await settled()
  combat = get_tree().current_scene
  check(state.exploration_state["current_node_id"] == battle_id,"combat resumes same node: "+outcome)
  var points_before: int = state.scrap_metal
  if outcome == "victory": combat._trigger_victory()
  elif outcome == "defeat": combat._trigger_defeat()
  else:
   start = Time.get_ticks_msec()
   while combat.is_animating and Time.get_ticks_msec()-start < 5000: await get_tree().process_frame
   combat._on_escape_pressed()
  check(combat.result_modal.visible,"combat shows result: "+outcome)
  if outcome != "victory":
   check(not state.exploration_active and state.exploration_checkpoint.is_empty(),"defeat clears route snapshot: "+outcome)
   check(state.scrap_metal == points_before,"no victory reward on defeat: "+outcome)
   check(saves.save_game(),"defeat result can be saved: "+outcome)
  combat._on_result_button_pressed()
  await settled()
  if outcome == "victory":
   check(state.exploration_state["settled"].has(battle_id),"victory settles existing node")
   check(state.finish_exploration("retreated"),"leave successful training node")
   await settled()
  check(life.current_location == "gym","combat result preserves gym return: "+outcome)
 check(CalendarContent.STORY_DATES.is_empty(),"formal story calendar remains empty")
 saves.active_session = false
 print("P5_RESULT "+JSON.stringify({"checks":checks,"failures":failures,"renderer":DisplayServer.get_name(),"captures":captures}))
 get_tree().quit(0 if failures.is_empty() else 1)
