class_name CampusLifeService
extends Node

signal location_changed(location_id: String)
signal first_visit_started(region_id: String, event_id: String)
var current_location := "map"
var current_region: String:
 get:
  var data := snapshot()
  var id := current_location if current_location != "map" else str(data.get("last_location","club"))
  var region := str(data.get("region_id",""))
  return region if RegionCatalog.owns_place(region,id) else RegionCatalog.region_for_place(id)
var map_region_id := "campus"
var map_return_location := "club"
var map_return_region := "campus"
const DEFAULT_STATE := {"last_location":"club","visited":[],"notes":{},"npc_talks":{},"studied_on_day":0,"last_sleep_day":0}

func snapshot() -> Dictionary:
 var data: Dictionary = GameState.player_profile.get("campus_life",DEFAULT_STATE)
 return data.duplicate(true)

func _commit(data: Dictionary) -> void:
 GameState.player_profile["campus_life"] = data
 GameState.profile_changed.emit()

func map_concept() -> String:
 return "indigo" if DayCycle.period() == "night" else "vermilion"

func travel_to(location_id: String, region_id: String = "") -> bool:
 if not _can_travel() or (location_id != "map" and not CampusPlaces.PLACES.has(location_id)): return false
 if location_id == "map": return open_map()
 var region := region_id
 if region == "": region = current_region if RegionCatalog.owns_place(current_region,location_id) else RegionCatalog.region_for_place(location_id)
 if not RegionCatalog.owns_place(region,location_id) or not RegionCatalog.is_unlocked(region): return false
 # A direct place or Home call cannot bypass the first-arrival checkpoint.
 if RegionCatalog.is_primary(region) and not has_visited_region(region):
  location_id = str(RegionCatalog.REGIONS[region]["first_entry_id"])
 var host := get_tree().current_scene
 var same_place: bool = (location_id == "club" and host is HomeScreen) or (host is CampusScreen and host.location_id == location_id)
 current_location = location_id
 _remember_location(location_id,region)
 if not same_place:
  SceneManager.change_scene(SceneManager.TargetScene.HOME if location_id == "club" else SceneManager.TargetScene.CAMPUS_LIFE)
 location_changed.emit(location_id)
 return true

func _can_travel() -> bool:
 if SceneManager.is_transitioning or GameState.exploration_active: return false
 var host := get_tree().current_scene
 if not is_instance_valid(host): return false
 if host is CombatScreen and str(host.get("_combat_outcome")) == "": return false
 return not host.get_meta("campus_dialogue_open",false) and not host.get_meta("region_modal_open",false)

func has_visited_region(region_id: String) -> bool:
 return snapshot().get("region_visits",{}).get(region_id,"") == "completed"

func enter_region(region_id: String) -> bool:
 if not RegionCatalog.is_unlocked(region_id): return false
 var spec: Dictionary = RegionCatalog.REGIONS[region_id]
 return travel_to(str(spec.get("entry_id",spec["home"])),region_id)

func travel_home(region_id: String) -> bool:
 var id := RegionCatalog.home_for_region(region_id)
 return id != "" and travel_to(id,region_id)

func complete_first_visit() -> bool:
 var region := current_region
 if not _can_travel() or not RegionCatalog.is_primary(region) or not RegionCatalog.is_unlocked(region): return false
 if current_location != RegionCatalog.REGIONS[region]["first_entry_id"]: return false
 var data := snapshot()
 var visits: Dictionary = data.get("region_visits",{})
 visits[region] = "completed"
 data["region_visits"] = visits
 _commit(data)
 return enter_region(region)

func _remember_location(id: String, region: String = "") -> void:
 var data := snapshot()
 data["last_location"] = id
 data["region_id"] = region if region != "" else RegionCatalog.region_for_place(id)
 if not data["visited"].has(id): data["visited"].append(id)
 var started := false
 if RegionCatalog.is_primary(data["region_id"]):
  var visits: Dictionary = data.get("region_visits",{})
  if not visits.has(data["region_id"]):
   visits[data["region_id"]] = "arrived"
   started = true
  data["region_visits"] = visits
 _commit(data)
 if started: first_visit_started.emit(data["region_id"],str(RegionCatalog.REGIONS[data["region_id"]]["first_visit_event_id"]))

func arrive_at_club() -> void:
 var region := current_region if RegionCatalog.owns_place(current_region,"club") else "campus"
 current_location = "club"
 if snapshot().get("last_location","club") != "club": _remember_location("club",region)

func restore_saved_location() -> void:
 var data := snapshot()
 var id := str(data.get("last_location","club"))
 var region := str(data.get("region_id",RegionCatalog.region_for_place(id)))
 if not CampusPlaces.PLACES.has(id) or not RegionCatalog.owns_place(region,id) or not RegionCatalog.is_unlocked(region):
  id = "club"
  region = "campus"
 if RegionCatalog.is_primary(region) and not has_visited_region(region): id = str(RegionCatalog.REGIONS[region]["first_entry_id"])
 current_location = id
 _remember_location(id,region)
 SceneManager.change_scene(SceneManager.TargetScene.HOME if id == "club" else SceneManager.TargetScene.CAMPUS_LIFE)

func return_from_training() -> void:
 travel_to("gym")

func is_home_location() -> bool:
 if SceneManager.current_scene_type == SceneManager.TargetScene.HOME: return current_location == "club"
 return SceneManager.current_scene_type == SceneManager.TargetScene.CAMPUS_LIFE and RegionCatalog.is_home(current_location)

func npc_lines(npc_id: String) -> Array:
 if not CampusPlaces.NPCS.has(npc_id): return []
 if not DayCycle.pending_event().is_empty(): return [["我",DayCycle.block_reason()]]
 var data := snapshot()
 var count := int(data["npc_talks"].get(npc_id,0))
 data["npc_talks"][npc_id] = mini(9999,count+1)
 _commit(data)
 match npc_id:
  "lin_zhi_xia":
   return [["林知夏","你好，我是图书委员林知夏。这里有安静的阅读位置，窗边的书可以直接翻阅。"],["林知夏","窗边的书可以随手翻阅。等你读到喜欢的句子，下次也讲给我听吧。"]] if count == 0 else [["林知夏","又见面了。刚才的风把书签吹到了下一页，像是在催我继续读。"],["林知夏","今天想看哪一本书？"]]
  "tang_xiao_man":
   return [["唐小满","我是今天值班的唐小满。这里还在整理，先陪我聊聊天吧。"],["唐小满","送货单夹在箱子边，社团要用的东西都分箱放好了。"]] if count == 0 else [["唐小满","你来得正好，我终于把送货单核对完了。"],["唐小满","忙完这些小事，放学后剩下的时间就都是自己的啦。"]]
  "liu_yu_long": return [["柳宇龙","这里风大，但比楼下清静。偶尔来坐一会儿，也算给脑袋放个假。"],["柳宇龙","社团教室就在下面。等风小一点，我们再回去。"]]
  "jiang_zi": return [["姜梓","今天想去哪里走走？地图已经放在桌上了。"],["姜梓","整理卡牌和校园记录还是在这里。走累了，也随时可以回来。"]]
 return []

func inspect(action_id: String) -> Array:
 if not CampusPlaces.SNIPPETS.has(action_id): return []
 if not DayCycle.pending_event().is_empty(): return [["我",DayCycle.block_reason()]]
 var data := snapshot()
 data["notes"][action_id] = true
 _commit(data)
 return CampusPlaces.SNIPPETS[action_id].duplicate(true)

func study() -> Array:
 if current_location != "study" or SceneManager.is_transitioning: return []
 var data := snapshot()
 if int(data["studied_on_day"]) == GameState.game_day:
  return [["我","今天的自习已经完成了。再坐一会儿，或者去别的地方走走吧。"]]
 if not DayCycle.can_act(): return [["我",DayCycle.block_reason()]]
 data["studied_on_day"] = GameState.game_day
 _commit(data)
 DayCycle.spend_action("study")
 return [["我","把注意力放回纸页上，认真完成了一次自习。今天的思路清楚了一些。"]]

func sleep_to_morning() -> Array:
 if current_location != "dorm": return []
 var overnight: bool = DayCycle.period() == "night"
 if not DayCycle.rest(): return [["我",DayCycle.block_reason()]]
 var data := snapshot()
 if overnight: data["last_sleep_day"] = GameState.game_day; data["notes"]["first_night"] = true
 _commit(data)
 var copy := "休息过后，已经是新的一天了。去看看今天会遇见谁吧。" if overnight else ("歇过一会儿，已经是下午了。接下来想做些什么？" if DayCycle.period() == "afternoon" else "歇过一会儿，窗外已经入夜了。今晚还可以安排自己的时间。")
 return [["我",copy]]

func _can_open_map() -> bool:
 if SceneManager.is_transitioning or GameState.exploration_active: return false
 var host := get_tree().current_scene
 return is_instance_valid(host) and not host is CombatScreen and not host.get_meta("campus_dialogue_open",false) and not host.get_meta("region_modal_open",false)

func _remember_map_origin() -> void:
 var host := get_tree().current_scene
 if not host.get_meta("map_page",false):
  map_return_location = current_location if CampusPlaces.PLACES.has(current_location) else str(snapshot().get("last_location","club"))
  map_return_region = current_region

func open_map() -> bool:
 return open_local_map(current_region)

func open_local_map(id: String = "") -> bool:
 if id == "": id = current_region
 if not _can_open_map() or not RegionCatalog.is_unlocked(id): return false
 _remember_map_origin()
 map_region_id = id
 SceneManager.change_scene(SceneManager.TargetScene.LOCAL_MAP)
 return true

func open_region_atlas() -> bool:
 if not _can_open_map(): return false
 _remember_map_origin()
 SceneManager.change_scene(SceneManager.TargetScene.REGION_ATLAS)
 return true

func close_map(_return_focus: bool = true) -> void:
 var host := get_tree().current_scene
 if SceneManager.is_transitioning or not is_instance_valid(host) or not host.get_meta("map_page",false): return
 var id := map_return_location
 var region := map_return_region
 if not CampusPlaces.PLACES.has(id) or not RegionCatalog.owns_place(region,id) or not RegionCatalog.is_unlocked(region):
  id = "club"
  region = "campus"
 current_location = id
 _remember_location(id,region)
 SceneManager.change_scene(SceneManager.TargetScene.HOME if id == "club" else SceneManager.TargetScene.CAMPUS_LIFE)
