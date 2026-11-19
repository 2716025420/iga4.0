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
var map_region_id := "university_arete"
var map_return_location := "club"
var map_return_region := "university_arete"
const DEFAULT_STATE := {"last_location":"club","region_id":"university_arete","visited":["club"],"notes":{},"npc_talks":{},"studied_on_day":0,"last_sleep_day":0,"region_visits":{"university_arete":"completed"}}

func snapshot() -> Dictionary:
 var data: Dictionary = GameState.player_profile.get("campus_life",DEFAULT_STATE)
 return data.duplicate(true)

func _commit(data: Dictionary) -> void:
 GameState.player_profile["campus_life"] = data
 GameState.profile_changed.emit()

func map_concept() -> String:
 var preferred := str(snapshot().get("map_concept", ""))
 if preferred in ["vermilion", "indigo"]:
  return preferred
 return "indigo" if DayCycle.period() == "night" else "vermilion"

func toggle_map_concept() -> String:
 var next := "indigo" if map_concept() == "vermilion" else "vermilion"
 var data := snapshot()
 data["map_concept"] = next
 _commit(data)
 return next

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
  if data["region_id"] == "university_arete":
   visits["university_arete"] = "completed"
  elif not visits.has(data["region_id"]):
   visits[data["region_id"]] = "arrived"
   started = true
  data["region_visits"] = visits
 _commit(data)
 if started: first_visit_started.emit(data["region_id"],str(RegionCatalog.REGIONS[data["region_id"]]["first_visit_event_id"]))

func arrive_at_club() -> void:
 var region := current_region if RegionCatalog.owns_place(current_region,"club") else "university_arete"
 current_location = "club"
 if snapshot().get("last_location","club") != "club" or snapshot().get("region_visits",{}).get("university_arete","") != "completed":
  _remember_location("club",region)

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
   if count == 0:
    return [["林知夏","你好，我是图书委员林知夏。窗边的座位很亮堂，适合静下心来研习战术牌理。"],["林知夏","桌上的《阿瑞忒风物纪要》都可以随时翻阅。常来研习的话，我会帮你把新抄录好的手记留在这里。"]]
   return [["林知夏","欢迎回来。刚才又整理出几页关于四大学院规约的剪报，有空一起看看吧？"]]
  "tang_xiao_man":
   if count == 0:
    return [["唐小满","嗨！我是店员唐小满。随着校内赛事推进，柜台会陆续进货一共 16 张各色刻印卡哦！"],["唐小满","要是零用钱紧了，随时接一次店务盘点兼职，一次稳拿 100 零用钱呢！"]]
   return [["唐小满","今天货架刚补充完新卡与补给。逛累了记得顺便喝瓶汽水！"]]
  "liu_yu_long":
   if bool(GameState.story_flags.get("arete_qualifier_completed", false)):
    return [["柳宇龙","阿瑞忒代表选拔赛三连胜真解气！以后也别忘了每天保持卡匣手感和默契配合！"]]
   return [["柳宇龙","天台或者体育馆的风都很适合活动筋骨！想试验新配的 5 卡卡序，随时去擂台找我！"]]
  "yang_zi_ying":
   return [["杨子英","清晨天台的海风真舒服，取景框里连远处的白色灯塔都看得一清二楚！"],["杨子英","要在这里一起做一次战术复盘吗？平时去图书馆、商店、海边转转也很不错哦。"]]
  "jiang_zi":
   return [["姜梓","今天想去哪里走走？手绘校园地图就在旁边，放映档案室也能随时加盖委托印章。"],["姜梓","强化行动卡与找同伴交流都不占白天活动次数，先把节奏理顺再出门吧。"]]
 return []

func _record_activity(key: String) -> int:
 var activities: Dictionary = GameState.player_profile.get("activities", {}).duplicate()
 var next := int(activities.get(key, 0)) + 1
 activities[key] = next
 GameState.player_profile["activities"] = activities
 GameState.profile_changed.emit()
 return next

func active_walk_companion() -> String:
 var cid := GameState.get_active_companion_id()
 if cid != "" and bool(GameState.companions.get(cid, {}).get("unlocked", false)):
  return cid
 for candidate in PlayerJourney.COMPANION_ORDER:
  if bool(GameState.companions.get(candidate, {}).get("unlocked", false)):
   return candidate
 return "yang_zi_ying"

func _active_walk_companion() -> String:
 return active_walk_companion()

func study_in_library() -> Array:
 if SceneManager.is_transitioning: return []
 if not DayCycle.can_act(): return [["我",DayCycle.block_reason()]]
 if not DayCycle.spend_action("study"): return [["我",DayCycle.block_reason()]]
 var data := snapshot()
 data["studied_on_day"] = GameState.game_day
 _commit(data)
 var count := _record_activity("study_count")
 GameState.add_scrap(35, false)
 var notes: Array = GameState.player_profile.get("reading_notes", []).duplicate()
 var unlocked_title := ""
 for note in CampusPlaces.LIBRARY_NOTES:
  var nid := str(note["id"])
  if not notes.has(nid):
   notes.append(nid)
   unlocked_title = str(note["title"])
   GameState.player_profile["reading_notes"] = notes
   GameState.profile_changed.emit()
   break
 if unlocked_title != "":
  return [["林知夏","认真做完了一次牌理推演呢（练习点 +35）。另外，这份新抄录的【%s】我也夹进你的放映室档案里啦。" % unlocked_title]]
 return [["我","在窗边静心梳理了卡组冷却与防线联动，思路清楚了不少（练习点 +35，已累计研习 %d 次）。" % count]]

func read_library_notes() -> Array:
 var notes: Array = GameState.player_profile.get("reading_notes", []).duplicate()
 if notes.is_empty():
  notes.append(str(CampusPlaces.LIBRARY_NOTES[0]["id"]))
  GameState.player_profile["reading_notes"] = notes
  GameState.profile_changed.emit()
 var latest_id := str(notes[-1])
 var latest := {}
 for note in CampusPlaces.LIBRARY_NOTES:
  if str(note["id"]) == latest_id:
   latest = note
   break
 return [
  ["林知夏","目前你已收录《阿瑞忒与红月风物纪要》共 %d / %d 篇（随时可在社团【放映档案室】重读全篇）。" % [notes.size(), CampusPlaces.LIBRARY_NOTES.size()]],
  [str(latest.get("title", "风物纪要")), str(latest.get("body", ""))]
 ]

func work_in_shop() -> Array:
 if SceneManager.is_transitioning: return []
 if not DayCycle.can_act(): return [["我",DayCycle.block_reason()]]
 if not DayCycle.spend_action("work"): return [["我",DayCycle.block_reason()]]
 var count := _record_activity("work_count")
 GameState.add_crystals(100)
 var drink_bonus := ""
 if count % 2 == 0:
  GameState.add_inventory_item("drink", 1, false)
  drink_bonus = "，唐小满还多塞了一瓶「饮品补给」给你"
 return [["唐小满","货架和快递单都核对得整整齐齐！辛苦啦——这是今天的兼职零用钱 +100%s！" % drink_bonus]]

func rooftop_active_npc() -> String:
 var period := DayCycle.period()
 if period == "morning":
  return "yang_zi_ying"
 if period == "afternoon":
  if bool(GameState.companions.get("liu_yu_long", {}).get("unlocked", false)) or SaveManager.test_session:
   return "liu_yu_long"
  return "yang_zi_ying"
 if bool(GameState.companions.get("jiang_zi", {}).get("unlocked", false)) or SaveManager.test_session:
  return "jiang_zi"
 return "yang_zi_ying"

func rooftop_review() -> Array:
 if SceneManager.is_transitioning: return []
 if not DayCycle.can_act(): return [["我",DayCycle.block_reason()]]
 if not DayCycle.spend_action("rooftop"): return [["我",DayCycle.block_reason()]]
 _record_activity("rooftop_count")
 var cid := rooftop_active_npc()
 var cname := str(PhaseTwoContent.ACTORS.get(cid, {}).get("name", "同伴"))
 GameState.heal_player(40)
 GameState.add_scrap(20, false)
 GameState.add_companion_favor(cid, 12)
 return [[cname,"吹着天台的海风复盘上几场出牌顺序，疲劳一下子散掉了！（体力 +40 · 练习点 +20 · %s熟悉度 +12）" % cname]]

func coast_walk() -> Array:
 if SceneManager.is_transitioning: return []
 if not DayCycle.can_act(): return [["我",DayCycle.block_reason()]]
 if not DayCycle.spend_action("coast"): return [["我",DayCycle.block_reason()]]
 _record_activity("coast_count")
 var cid := _active_walk_companion()
 var cname := str(PhaseTwoContent.ACTORS.get(cid, {}).get("name", "同伴"))
 GameState.add_scrap(15, false)
 GameState.add_companion_favor(cid, 15)
 return [[cname,"沿着阿瑞忒的沿海步道慢慢走了好远，海风里连平时紧绷的心情也跟着放松下来了。（练习点 +15 · %s熟悉度 +15）" % cname]]

func beach_rest() -> Array:
 if SceneManager.is_transitioning: return []
 if not DayCycle.can_act(): return [["我",DayCycle.block_reason()]]
 if not DayCycle.spend_action("beach"): return [["我",DayCycle.block_reason()]]
 _record_activity("beach_count")
 var cid := _active_walk_companion()
 var cname := str(PhaseTwoContent.ACTORS.get(cid, {}).get("name", "同伴"))
 GameState.heal_player(35)
 GameState.add_inventory_item("material_common", 2, false)
 GameState.add_companion_favor(cid, 10)
 return [["我","在海滩边坐了会儿，顺手捡起两块适合刻制护盾卡的海岩素材。（体力 +35 · 普通材料 +2 · %s熟悉度 +10）" % cname]]

func park_reflect() -> Array:
 if SceneManager.is_transitioning: return []
 if not DayCycle.can_act(): return [["我",DayCycle.block_reason()]]
 if not DayCycle.spend_action("park"): return [["我",DayCycle.block_reason()]]
 _record_activity("park_count")
 GameState.heal_player(30)
 GameState.add_scrap(30, false)
 var ring_note := ""
 if GameState.grant_inventory_reward("old_park_soda_ring", {"sealed_note": 1}, false):
  ring_note = "在长椅旁拾起一枚「旧公园的汽水拉环」，妥善收进了社团收纳箱。"
 return [["我","看着夕照把长椅与街角贩卖机镀上一层暖金色，暗自记下了再次踏上旅途的决心。（体力 +30 · 练习点 +30）" + ("\n" + ring_note if ring_note != "" else "")]]

func inspect(action_id: String) -> Array:
 if not CampusPlaces.SNIPPETS.has(action_id): return []
 if not DayCycle.pending_event().is_empty(): return [["我",DayCycle.block_reason()]]
 var data := snapshot()
 data["notes"][action_id] = true
 _commit(data)
 return CampusPlaces.SNIPPETS[action_id].duplicate(true)

func study() -> Array:
 return study_in_library()

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
