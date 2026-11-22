class_name PlayerJourney
extends RefCounted

const QUALITIES := {"common": "普通", "fine": "精良", "rare": "稀有"}
const COMPANION_ORDER := ["yang_zi_ying", "liu_yu_long", "jiang_zi"]
const COMPANION_ASSISTS := {
 "yang_zi_ying": {"id": "yang_zi_ying", "name": "杨子英", "skill": "快门闪光支援", "heal": 10, "shield": 8, "damage": 0},
 "liu_yu_long": {"id": "liu_yu_long", "name": "柳宇龙", "skill": "热血追击重扣", "heal": 0, "shield": 0, "damage": 14},
 "jiang_zi": {"id": "jiang_zi", "name": "姜梓", "skill": "战术统筹屏障", "heal": 0, "shield": 12, "damage": 6}
}
const QUALIFIER_ROUNDS: Array[Dictionary] = [
 {"round": 1, "flag": "qualifier_r1_won", "title": "第1战 · 新锐资格战", "subtitle": "迎战学园预选代表，检验基础攻防与冷却轮转。", "enemies": ["duel_student_ace"], "money": 150, "points": 45, "items": {"material_fine": 2}},
 {"round": 2, "flag": "qualifier_r2_won", "title": "第2战 · 双人战术演武", "subtitle": "双人编队夹击！善用同伴3卡协战与群体减攻破局。", "enemies": ["arena_tactician", "duel_student_ace"], "money": 200, "points": 60, "items": {"material_rare": 1}},
 {"round": 3, "flag": "qualifier_r3_won", "title": "第3战 · 阿瑞忒首席代表战", "subtitle": "决战巡回赛种子代表！赢下阿瑞忒正式代表通行章。", "enemies": ["national_finalist"], "money": 300, "points": 90, "items": {"material_rare": 2, "practice_token": 1}}
]
const ZODIAC_RESONANCES := {
 "hero": {"id": "hero", "title": "白羊共鸣·肉体强化", "summary": "开局获得12点护盾，进攻卡伤害+2", "start_shield": 12, "attack_bonus": 2},
 "everyperson": {"id": "everyperson", "title": "金牛共鸣·同频洞察", "summary": "开局恢复6点体力，护盾收益+2", "start_heal": 6, "shield_bonus": 2},
 "jester": {"id": "jester", "title": "双子共鸣·灵巧换位", "summary": "开局获得8点护盾，攻击+1且护盾+1", "start_shield": 8, "attack_bonus": 1, "shield_bonus": 1},
 "caregiver": {"id": "caregiver", "title": "巨蟹共鸣·温柔庇护", "summary": "每回合开始恢复4点体力", "turn_heal": 4},
 "ruler": {"id": "ruler", "title": "狮子共鸣·秩序权威", "summary": "开局获得16点护盾", "start_shield": 16},
 "creator": {"id": "creator", "title": "处女共鸣·精工重构", "summary": "护盾卡与反制卡护盾额外+3", "shield_bonus": 3},
 "innocent": {"id": "innocent", "title": "天秤共鸣·均衡裁决", "summary": "敌方全体首回合伤害降低15%", "start_enemy_weak": 0.15},
 "rebel": {"id": "rebel", "title": "天蝎共鸣·超限破局", "summary": "进攻卡伤害额外+3", "attack_bonus": 3},
 "explorer": {"id": "explorer", "title": "射手共鸣·轻装疾行", "summary": "开局获得10点护盾并恢复4点体力", "start_shield": 10, "start_heal": 4},
 "sage": {"id": "sage", "title": "摩羯共鸣·先机推演", "summary": "敌方全体首回合附加4点压制灼烧", "start_enemy_burn": 4},
 "magician": {"id": "magician", "title": "水瓶共鸣·密钥增幅", "summary": "攻击+2 · 护盾+2 · 每回合恢复3点体力", "attack_bonus": 2, "shield_bonus": 2, "turn_heal": 3},
 "lover": {"id": "lover", "title": "双鱼共鸣·心弦守望", "summary": "开局获得8点护盾，每回合恢复3点体力", "start_shield": 8, "turn_heal": 3}
}
const MILESTONES := [
 {"id":"prepare", "title":"正式入部整备", "condition":"在卡牌整理编入至少4张卡（含进攻卡）", "reward":"120零用钱 · 25练习点 · 普通材料×3", "money":120, "points":25, "items":{"material_common":3}},
 {"id":"campus_step", "title":"阿瑞忒日常初探", "condition":"在校园完成任意1次场景活动、兼职或训练", "reward":"80零用钱 · 20练习点 · 饮品补给×1", "money":80, "points":20, "items":{"drink":1}},
 {"id":"work_first", "title":"小店盘点帮手", "condition":"到校园商店帮助唐小满完成1次兼职盘点", "reward":"60零用钱 · 普通材料×3", "money":60, "items":{"material_common":3}},
 {"id":"study_first", "title":"窗边牌理笔记", "condition":"在图书馆阅读区完成1次牌理研习", "reward":"35练习点 · 精良材料×1", "points":35, "items":{"material_fine":1}},
 {"id":"full_deck", "title":"满编战术卡匣", "condition":"同时装备满5张战术刻印卡", "reward":"100零用钱 · 解锁「双人协防印」", "money":100, "card":"tag_assist"},
 {"id":"train", "title":"刻印精进·初阶", "condition":"任意已解锁行动卡强化至2级", "reward":"40练习点 · 普通材料×3", "points":40, "items":{"material_common":3}},
 {"id":"route", "title":"体育馆路线通关", "condition":"在体育馆完成任意1条模拟训练路线", "reward":"解锁「默契反制壁」 · 精良材料×2", "card":"steel_barricade", "items":{"material_fine":2}},
 {"id":"friends", "title":"社团默契升温", "condition":"结识三位同伴且任一位熟悉度达到35（默契Lv.2）", "reward":"80零用钱 · 30练习点 · 饮品补给×2", "money":80, "points":30, "items":{"drink":2}},
 {"id":"chapter", "title":"红月与白羊星火", "condition":"完成第一章旧公园高潮并唤醒白羊座母卡", "reward":"180零用钱 · 稀有材料×1", "money":180, "items":{"material_rare":1}},
 {"id":"qualifier_debut", "title":"选拔赛初阵告捷", "condition":"赢下体育馆《阿瑞忒代表选拔赛》第1战", "reward":"120零用钱 · 精良材料×2", "money":120, "items":{"material_fine":2}},
 {"id":"qualifier_champ", "title":"阿瑞忒首席代表", "condition":"全胜通关《阿瑞忒代表选拔赛》全部3战", "reward":"260零用钱 · 稀有材料×2", "money":260, "items":{"material_rare":2}}
]

static func qualifier_round_spec(round_index: int) -> Dictionary:
 for entry in QUALIFIER_ROUNDS:
  if int(entry["round"]) == round_index:
   return entry.duplicate(true)
 return {}

static func qualifier_next_round() -> int:
 for entry in QUALIFIER_ROUNDS:
  if not bool(GameState.story_flags.get(str(entry["flag"]), false)):
   return int(entry["round"])
 return 0

static func validate_profile(profile: Dictionary) -> bool:
 if not profile.get("loadouts") is Array or profile["loadouts"].size() > 3: return false
 for entry in profile["loadouts"]:
  if not entry is Dictionary or not entry.get("name") is String or str(entry["name"]).length() > 24 or not entry.get("card_ids") is Array or entry["card_ids"].size() > 5: return false
  var seen := {}
  for id in entry["card_ids"]:
   if not id is String or not GameState.all_cards.has(id) or seen.has(id): return false
   seen[id] = true
 if profile.has("active_loadout_index"):
  var index: Variant = profile["active_loadout_index"]
  if not GameState._whole_number(index) or int(index) < -1 or int(index) >= profile["loadouts"].size(): return false
 if not profile.get("milestone_claims") is Dictionary: return false
 for id in profile["milestone_claims"]:
  if not id is String or str(id).length() > 64 or not profile["milestone_claims"][id] is bool or profile["milestone_claims"][id] != true: return false
 if profile.has("activities"):
  if not profile["activities"] is Dictionary or profile["activities"].size() > 32: return false
  for key in profile["activities"]:
   if not key is String or not GameState._whole_number(profile["activities"][key]) or int(profile["activities"][key]) < 0 or int(profile["activities"][key]) > 999999: return false
 if profile.has("reading_notes"):
  if not profile["reading_notes"] is Array or profile["reading_notes"].size() > 32: return false
  for note_id in profile["reading_notes"]:
   if not note_id is String or str(note_id).length() > 64: return false
 if profile.has("chat_periods"):
  if not profile["chat_periods"] is Dictionary or profile["chat_periods"].size() > 256: return false
  for key in profile["chat_periods"]:
   if not key is String or not profile["chat_periods"][key] is bool: return false
 if profile.has("campus_life") and not CampusPlaces.valid_state(profile["campus_life"]): return false
 if profile.has("calendar") and not DayCycleService.valid_calendar(profile["calendar"]): return false
 if profile.has("zodiac_collection") and not SpecialCardCollection.valid_state(profile["zodiac_collection"]): return false
 if profile.has("shop_receipts") and not CampusShopCatalog.valid_receipts(profile["shop_receipts"]): return false
 if profile.has("active_companion") and (not profile["active_companion"] is String or (profile["active_companion"] != "" and not COMPANION_ASSISTS.has(profile["active_companion"]))): return false
 if profile.has("active_zodiac") and (not profile["active_zodiac"] is String or (profile["active_zodiac"] != "" and not ZodiacCatalog.known(profile["active_zodiac"]))): return false
 if profile.get("last_activity") not in ["story","exploration"]: return false
 if not profile.get("exploration_log") is Array or profile["exploration_log"].size() > 20: return false
 var runs := {}
 for entry in profile["exploration_log"]:
  if not entry is Dictionary: return false
  for key in ["run_id","visited","day","hour","minute","spent_points"]:
   if not GameState._whole_number(entry.get(key)) or int(entry[key]) < 0 or int(entry[key]) > 999999: return false
  if int(entry["run_id"]) < 1 or int(entry["day"]) < 1 or int(entry["hour"]) > 23 or int(entry["minute"]) > 59 or runs.has(int(entry["run_id"])): return false
  runs[int(entry["run_id"])] = true
  if not entry.get("dungeon_id") is String or ExplorationContent.dungeon_definition(entry["dungeon_id"]).is_empty() or entry.get("status") not in ["completed","defeat","retreated"]: return false
  if not entry.get("earned") is Dictionary or not GameState._whole_number(entry["earned"].get("scrap_metal")) or (int(entry["earned"]["scrap_metal"]) < 0 or int(entry["earned"]["scrap_metal"]) > 999999) or not entry["earned"].get("materials") is Dictionary: return false
  for quality in QUALITIES:
   var amount: Variant = entry["earned"]["materials"].get(quality)
   if not GameState._whole_number(amount) or int(amount) < 0 or int(amount) > 999999: return false
 return true

static func deck_summary(ids: Array = GameState.equipped_card_ids) -> Dictionary:
 var roles := {"attack":0,"guard":0,"heal":0,"support":0}
 var valid := not ids.is_empty() and ids.size() <= 5
 var seen := {}
 for id in ids:
  var card: CardData = GameState.get_card(str(id))
  if card == null or not GameState.unlocked_card_ids.has(id) or seen.has(id):
   valid = false
   continue
  seen[id] = true
  if card.card_type == CardData.CardType.ATTACK: roles["attack"] += 1
  if card.shield > 0: roles["guard"] += 1
  if card.heal > 0: roles["heal"] += 1
  if card.attack_down_percent > 0: roles["support"] += 1
 var ready: bool = valid and int(roles["attack"]) > 0
 var reason := "可以出发" if ready else GameState.DECK_RULE_MESSAGE
 return {"ready":ready,"count":ids.size(),"roles":roles,"reason":reason,"text":"进攻%d  防护%d  恢复%d  支援%d" % [roles["attack"],roles["guard"],roles["heal"],roles["support"]]}

static func has_upgraded_card() -> bool:
 for id in GameState.unlocked_card_ids:
  if int(GameState.card_levels.get(id, 1)) >= 2:
   return true
 return false

static func campus_activities_done() -> int:
 var activities: Dictionary = GameState.player_profile.get("activities", {})
 var total := 0
 for key in ["study_count", "work_count", "rooftop_count", "coast_count", "beach_count", "park_count"]:
  total += int(activities.get(key, 0))
 total += GameState.exploration_run_counter
 total += maxi(0, GameState.unlocked_card_ids.size() - 4)
 if int(CampusLife.snapshot().get("studied_on_day", 0)) > 0 and int(activities.get("study_count", 0)) == 0:
  total += 1
 return total

static func act1_story_ready() -> bool:
 return bool(GameState.story_flags.get("prologue_completed", false)) and GameState.equipped_card_ids.size() >= 4 and campus_activities_done() >= 1

static func act2_combat_ready() -> bool:
 var act1_done: bool = GameState.visited_node_ids.has("n_affairs") or bool(GameState.story_flags.get("school_affairs_done", false))
 return act1_done and (GameState.equipped_card_ids.size() >= 5 or has_upgraded_card())

static func training_quote(card_id: String, quality: String = "common") -> Dictionary:
 var result := {"ok":false,"reason":"请选择已解锁的行动卡", "points":0,"amount":0,"quality":quality}
 var card: CardData = GameState.get_card(card_id)
 if card == null or not GameState.unlocked_card_ids.has(card_id) or not QUALITIES.has(quality): return result
 var level: int = int(GameState.card_levels.get(card_id,1))
 result["level"] = level
 result["points"] = 40 if level == 1 else 90
 result["amount"] = level * 3 if quality == "common" else (level if quality == "fine" else 1)
 result["reason"] = "已达到最高等级" if level >= card.max_level else "练习点不足"
 if SceneManager.is_transitioning or GameState.exploration_active:
  result["reason"] = "训练或转场中暂不可强化"
  return result
 if level >= card.max_level or GameState.scrap_metal < int(result["points"]): return result
 result["reason"] = "%s材料不足" % QUALITIES[quality]
 if int(GameState.exploration_materials.get(quality,0)) < int(result["amount"]): return result
 result["ok"] = true
 result["reason"] = "强化至 Lv.%d（不消耗活动次数）" % (level+1)
 return result

static func train(card_id: String, quality: String = "common") -> bool:
 var quote := training_quote(card_id,quality)
 if not quote["ok"]: return false
 GameState.scrap_metal -= int(quote["points"])
 GameState.exploration_materials[quality] -= int(quote["amount"])
 GameState.card_levels[card_id] = int(quote["level"]) + 1
 GameState.materials_changed.emit()
 GameState.inventory_changed.emit()
 GameState.deck_changed.emit()
 return true

static func active_loadout_index() -> int:
 var index := int(GameState.player_profile.get("active_loadout_index",-1))
 var entries: Array = GameState.player_profile["loadouts"]
 if index < 0 or index >= entries.size(): return -1
 return index if entries[index]["card_ids"] == GameState.equipped_card_ids else -1

static func save_loadout(index: int, ids: Array = GameState.equipped_card_ids) -> bool:
 if index not in range(3) or not deck_summary(ids)["ready"]: return false
 var seen := {}
 for id in ids:
  if not id is String or not GameState.all_cards.has(id) or not GameState.unlocked_card_ids.has(id) or seen.has(id): return false
  seen[id] = true
 var profile: Dictionary = GameState.player_profile
 while profile["loadouts"].size() <= index: profile["loadouts"].append({"name":"方案%d" % (profile["loadouts"].size()+1),"card_ids":[]})
 # Overwriting an applied preset does not overwrite the deck already equipped.
 if int(profile.get("active_loadout_index",-1)) == index and ids != GameState.equipped_card_ids:
  profile["active_loadout_index"] = -1
 profile["loadouts"][index] = {"name":"方案%d" % (index+1),"card_ids":ids.duplicate()}
 GameState.profile_changed.emit()
 return true

static func apply_loadout(index: int) -> bool:
 var entries: Array = GameState.player_profile["loadouts"]
 if index < 0 or index >= entries.size(): return false
 var ids: Array = entries[index]["card_ids"]
 if ids.is_empty() or ids.size() > 5: return false
 var seen := {}
 for id in ids:
  if not GameState.all_cards.has(id) or not GameState.unlocked_card_ids.has(id) or seen.has(id): return false
  seen[id] = true
 return GameState.apply_equipped_deck(ids,index)

static func milestones() -> Array[Dictionary]:
 var trained := has_upgraded_card()
 var completed_route: bool = GameState.exploration_state.get("status", "") == "completed"
 for entry in GameState.player_profile["exploration_log"]:
  if entry["status"] == "completed": completed_route = true
 var friends := 0
 var max_favor := 0
 for id in COMPANION_ORDER:
  var comp: Dictionary = GameState.companions.get(id, {})
  if comp.get("unlocked", false):
   friends += 1
   max_favor = maxi(max_favor, int(comp.get("favor", 0)))
 var activities: Dictionary = GameState.player_profile.get("activities", {})
 var work_count := int(activities.get("work_count", 0))
 var study_count := int(activities.get("study_count", 0))
 var total_acts := campus_activities_done()
 var deck := deck_summary()
 var r1 := bool(GameState.story_flags.get("qualifier_r1_won", false))
 var r3 := bool(GameState.story_flags.get("arete_qualifier_completed", false))
 var ch1 := bool(GameState.story_flags.get("chapter_1_completed", false))
 var state_by_id := {
  "prepare": {"ready": bool(deck["ready"]) and int(deck["count"]) >= 4, "progress": "%d/4张" % mini(4, GameState.equipped_card_ids.size())},
  "campus_step": {"ready": total_acts >= 1, "progress": "%d/1次" % mini(1, total_acts)},
  "work_first": {"ready": work_count >= 1, "progress": "%d/1次" % mini(1, work_count)},
  "study_first": {"ready": study_count >= 1, "progress": "%d/1次" % mini(1, study_count)},
  "full_deck": {"ready": bool(deck["ready"]) and int(deck["count"]) >= 5, "progress": "%d/5张" % mini(5, GameState.equipped_card_ids.size())},
  "train": {"ready": trained, "progress": "Lv.2+" if trained else "未强化"},
  "route": {"ready": completed_route, "progress": "已完成" if completed_route else "未完成"},
  "friends": {"ready": friends >= 3 and max_favor >= 35, "progress": "%d/3位 · 最高%d" % [friends, max_favor]},
  "chapter": {"ready": ch1, "progress": "已觉醒" if ch1 else "进行中"},
  "qualifier_debut": {"ready": r1, "progress": "已首胜" if r1 else "未出战"},
  "qualifier_champ": {"ready": r3, "progress": "全胜通关" if r3 else "%d/3战" % maxi(0, qualifier_next_round() - 1 if qualifier_next_round() > 0 else 3)}
 }
 var result: Array[Dictionary] = []
 for raw_item in MILESTONES:
  var item: Dictionary = raw_item.duplicate(true)
  var st: Dictionary = state_by_id[item["id"]]
  item["ready"] = bool(st["ready"])
  item["claimed"] = GameState.player_profile["milestone_claims"].has(item["id"])
  item["progress"] = str(st["progress"])
  result.append(item)
 return result

static func claim_milestone(id: String) -> bool:
 var goal: Dictionary = {}
 for item in milestones():
  if item["id"] == id: goal = item
 if goal.is_empty() or not goal["ready"] or goal["claimed"]: return false
 if GameState.scrap_metal > 999999-int(goal.get("points",0)) or GameState.energy_crystals > 999999-int(goal.get("money",0)): return false
 for item_id in goal.get("items",{}):
  if GameState.get_inventory_quantity(item_id) > 999999-int(goal["items"][item_id]): return false
 # Commit the complete reward before signals schedule a save or rebuild a panel.
 var received: Dictionary = goal.get("items",{}).duplicate()
 received["practice_points"] = int(goal.get("points",0))
 received["allowance"] = int(goal.get("money",0))
 GameState.player_profile["milestone_claims"][id] = true
 GameState.scrap_metal += int(goal.get("points",0))
 GameState.energy_crystals += int(goal.get("money",0))
 for item_id in goal.get("items",{}):
  var definition := ItemCatalog.definition(item_id)
  var source: String = str(definition.get("source",""))
  if source == "drinks": GameState.energy_drinks += int(goal["items"][item_id])
  elif source != "": GameState.exploration_materials[source] += int(goal["items"][item_id])
  else: GameState.inventory_items[item_id] = GameState.get_inventory_quantity(item_id) + int(goal["items"][item_id])
  GameState._record_inventory_acquisition(item_id)
 if goal.has("card") and not GameState.unlocked_card_ids.has(goal["card"]):
  GameState.unlocked_card_ids.append(goal["card"])
  received["card:" + str(goal["card"])] = 1
 GameState.notify_rewards(received)
 GameState.profile_changed.emit()
 GameState.materials_changed.emit()
 GameState.inventory_changed.emit()
 GameState.deck_changed.emit()
 return true

static func safe_at_home() -> bool:
 return CampusLife.is_home_location() and not SceneManager.is_transitioning and not GameState.exploration_active and GameState.archive_dialogue_id == ""

static func use_drink() -> bool:
 if not safe_at_home() or GameState.energy_drinks < 1 or GameState.player_current_hp >= GameState.player_max_hp: return false
 GameState.energy_drinks -= 1
 GameState.heal_player(35)
 GameState.inventory_changed.emit()
 return true

static func record_exploration() -> void:
 var state: Dictionary = GameState.exploration_state
 if state.get("status", "") not in ["completed","defeat","retreated"]: return
 var log_entries: Array = GameState.player_profile["exploration_log"]
 for entry in log_entries:
  if int(entry["run_id"]) == int(state.get("run_id",0)): return
 log_entries.push_front({"run_id":int(state["run_id"]),"dungeon_id":str(state["dungeon_id"]),"status":str(state["status"]),"visited":state.get("visited",[]).size(),"earned":state.get("earned",{}).duplicate(true),"spent_points":int(state.get("spent_points",0)),"day":GameState.game_day,"hour":GameState.game_hour,"minute":GameState.game_minute})
 while log_entries.size() > 20: log_entries.pop_back()
 GameState.profile_changed.emit()

static func memories() -> Array[Dictionary]:
 var entries: Array[Dictionary] = []
 for step in PhaseTwoContent.FLOW_STEPS:
  if GameState.visited_node_ids.has(step["node"]) and step.has("dialogue"):
   entries.append({"dialogue_id":step["dialogue"],"title":step["title"],"node":step["node"]})
  if GameState.visited_node_ids.has(step["node"]) and step.has("post_dialogue"):
   entries.append({"dialogue_id":step["post_dialogue"],"title":str(step["title"]) + " · 战后","node":step["node"]})
 return entries

static func open_memory(dialogue_id: String) -> bool:
 if not safe_at_home(): return false
 var allowed := false
 for entry in memories():
  if entry["dialogue_id"] == dialogue_id: allowed = true
 if not allowed: return false
 GameState.archive_dialogue_id = dialogue_id
 SceneManager.change_scene(SceneManager.TargetScene.STORY)
 return true

static func home_snapshot() -> Dictionary:
 var deck := deck_summary()
 var pending: bool = GameState.get_exploration_snapshot().get("resume",false)
 var complete: bool = GameState.story_flags.get("chapter_1_completed",false)
 var qualifier_done: bool = GameState.story_flags.get("arete_qualifier_completed",false)
 var claims := 0
 var goal: Dictionary = {}
 for item in milestones():
  if item["ready"] and not item["claimed"]:
   claims += 1
   if goal.is_empty(): goal = item
 if goal.is_empty():
  for item in milestones():
   if not item["claimed"]:
    goal = item
    break
 var action := "quest"
 var title := "今天的安排"
 var copy := PhaseTwoContent.current_objective()
 var button := "打开校园地图"
 var next_node: String = GameState.next_phase_two_node()
 var prologue_done: bool = bool(GameState.story_flags.get("prologue_completed", false))
 if not deck["ready"] and GameState.phase_two_combat_checkpoint.is_empty() and not pending:
  action = "workshop"
  title = "出发前，准备一下"
  copy = deck["reason"]
  button = "整理行动卡"
 elif pending:
  action = "resume_route"
  title = "接着走完训练路线"
  copy = "训练进度已保留，可以从校园地图前往体育馆继续。"
  button = "前往体育馆"
 elif not prologue_done and not complete and next_node in ["n0", "n_gate", "n_club_intro"]:
  action = "story"
  title = "序章 · 初遇与入部"
  button = "继续序章" if not GameState.visited_node_ids.is_empty() else "开始序章"
 elif not complete and GameState.equipped_card_ids.size() < 4:
  action = "workshop"
  title = "入部引导 · 第1步"
  copy = "先点击下方【卡牌整理】，把第4张储备卡编入卡匣并保存应用。"
  button = "整理行动卡"
 elif not complete and not GameState.player_profile["milestone_claims"].has("prepare"):
  action = "records_growth"
  title = "入部引导 · 第2步"
  copy = "点击右下【放映档案室】，为「正式入部整备」盖章领取 120 零用钱与材料！"
  button = "去放映室领奖"
 elif not complete and next_node == "n_affairs":
  if act1_story_ready():
   action = "travel_library"
   title = "第一幕 · 图书馆的午后约见"
   copy = "黄秋枫正在「图书馆」窗边等你。随时可点右侧直达图书馆触发剧情。"
   button = "前往图书馆"
  else:
   action = "quest"
   title = "第一幕 · 熟悉阿瑞忒校园"
   copy = "打开「校园地图」体验日常活动（图书馆研习/商店打工/体育馆训练），完成1次后去找黄秋枫。"
   button = "打开校园地图"
 elif not complete and next_node == "n_dusk":
  if act2_combat_ready():
   action = "travel_old_park"
   title = "第二幕 · 旧公园的黄昏之约"
   copy = "卡匣已整备就绪！前往校外「旧公园」长椅赴黄秋枫的放学之约。"
   button = "前往旧公园"
  else:
   action = "workshop"
   title = "第二幕 · 赴约前的卡匣整备"
   copy = "街区外围限幅器出现异常。请先编满 5 张行动卡（商店可购新卡）或将任意卡强化至 Lv.2。"
   button = "整理行动卡"
 elif not complete:
  action = "story"
  title = "红月超限 · 旧公园突围"
  button = "继续主线"
 elif not qualifier_done:
  action = "travel_gym"
  var done_rounds := maxi(0, qualifier_next_round() - 1) if qualifier_next_round() > 0 else 3
  title = "终幕挑战 · 代表选拔赛"
  copy = "前往「体育馆」迎战 3 轮校内选拔赛（已胜 %d/3 战），赢得巡回代表通行章！" % done_rounds
  button = "前往体育馆"
 else:
  action = "quest"
  var unlocked_cards := GameState.unlocked_card_ids.size()
  var notes_cnt: int = GameState.player_profile.get("reading_notes", []).size()
  title = "阿瑞忒代表 · 诺莫斯行前整备"
  if claims > 0:
   copy = "已赢下「阿瑞忒代表通行章」！放映档案室尚有 %d 项委托印章可盖章领奖，也可回巡回总图预览第 2 站《诺莫斯》。" % claims
  elif unlocked_cards < 16 or notes_cnt < CampusPlaces.LIBRARY_NOTES.size():
   copy = "已达成阿瑞忒代表资格！行前可继续收录全 16 张刻印卡（%d/16）与风物纪要（%d/%d），或前往「巡回总图」预览下一站《诺莫斯》。" % [unlocked_cards, notes_cnt, CampusPlaces.LIBRARY_NOTES.size()]
  else:
   copy = "已收集齐阿瑞忒全部刻印卡与风物纪要，巡回代表准备万全！第二章《诺莫斯》筹备中，可自由切磋与重温胶片。"
  button = "打开校园地图"
 return {"action":action,"title":title,"body":copy,"button":button,"story_label":DayCycle.rest_label(),"complete":complete,"claim_count":claims,"goal":goal,"deck":deck}

static func companion_favor_tier(companion_id: String) -> int:
 var favor: int = int(GameState.companions.get(companion_id, {}).get("favor", 0))
 if favor >= 70: return 3
 if favor >= 35: return 2
 return 1

static func companion_assist_spec(companion_id: String) -> Dictionary:
 if not COMPANION_ASSISTS.has(companion_id): return {}
 var spec: Dictionary = COMPANION_ASSISTS[companion_id].duplicate(true)
 var tier := companion_favor_tier(companion_id)
 spec["tier"] = tier
 match companion_id:
  "yang_zi_ying":
   spec["heal"] = [10, 13, 16][tier - 1]
   spec["shield"] = [8, 11, 14][tier - 1]
   spec["summary"] = "默契Lv.%d · 每打出3张卡：恢复%d点体力并获得%d点护盾" % [tier, int(spec["heal"]), int(spec["shield"])]
  "liu_yu_long":
   spec["damage"] = [14, 18, 22][tier - 1]
   spec["summary"] = "默契Lv.%d · 每打出3张卡：对主目标追加%d点协战伤害" % [tier, int(spec["damage"])]
  "jiang_zi":
   spec["shield"] = [12, 15, 19][tier - 1]
   spec["damage"] = [6, 8, 11][tier - 1]
   spec["summary"] = "默契Lv.%d · 每打出3张卡：获得%d点护盾并追加%d点干扰伤害" % [tier, int(spec["shield"]), int(spec["damage"])]
 return spec

static func zodiac_resonance_spec(zodiac_id: String) -> Dictionary:
 return ZODIAC_RESONANCES.get(zodiac_id, {}).duplicate(true)
