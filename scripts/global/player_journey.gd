class_name PlayerJourney
extends RefCounted

const QUALITIES := {"common": "普通", "fine": "精良", "rare": "稀有"}
const COMPANION_ORDER := ["yang_zi_ying", "liu_yu_long", "jiang_zi"]
const COMPANION_ASSISTS := {
 "yang_zi_ying": {"id": "yang_zi_ying", "name": "杨子英", "skill": "快门闪光支援", "summary": "每打出3张卡：恢复10点体力并获得8点护盾", "heal": 10, "shield": 8, "damage": 0},
 "liu_yu_long": {"id": "liu_yu_long", "name": "柳宇龙", "skill": "热血追击重扣", "summary": "每打出3张卡：对主目标追加14点协战伤害", "heal": 0, "shield": 0, "damage": 14},
 "jiang_zi": {"id": "jiang_zi", "name": "姜梓", "skill": "战术统筹屏障", "summary": "每打出3张卡：获得12点护盾并追加6点干扰伤害", "heal": 0, "shield": 12, "damage": 6}
}
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
 {"id":"prepare", "title":"出发前的准备", "condition":"装备至少四张卡，包含进攻手段", "reward":"20练习点 · 普通材料×3", "points":20, "items":{"material_common":3}},
 {"id":"train", "title":"练习一张行动卡", "condition":"任意已解锁行动卡达到2级", "reward":"25练习点 · 普通材料×2", "points":25, "items":{"material_common":2}},
 {"id":"route", "title":"走完一条校园路线", "condition":"击败终点对手，从出口完成训练", "reward":"解锁「默契掩护」 · 精良材料×2", "card":"steel_barricade", "items":{"material_fine":2}},
 {"id":"friends", "title":"结识三位同学", "condition":"在主线认识杨子英、柳宇龙与姜梓", "reward":"30练习点 · 饮品补给×2", "points":30, "items":{"drink":2}},
 {"id":"chapter", "title":"一起走完归途", "condition":"完成第一章的主线行程", "reward":"100零用钱 · 稀有材料×1", "money":100, "items":{"material_rare":1}}
]

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
  if id not in ["prepare","train","route","friends","chapter"] or not profile["milestone_claims"][id] is bool or profile["milestone_claims"][id] != true: return false
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

static func training_quote(card_id: String, quality: String = "common") -> Dictionary:
 var result := {"ok":false,"reason":"请选择已解锁的行动卡", "points":0,"amount":0,"quality":quality}
 var card: CardData = GameState.get_card(card_id)
 if card == null or not GameState.unlocked_card_ids.has(card_id) or not QUALITIES.has(quality): return result
 var level: int = int(GameState.card_levels.get(card_id,1))
 result["level"] = level
 result["points"] = 40 if level == 1 else 90
 result["amount"] = level * 3 if quality == "common" else (level if quality == "fine" else 1)
 result["reason"] = "已达到最高等级" if level >= card.max_level else "练习点不足"
 if not DayCycle.can_act(): result["reason"] = DayCycle.block_reason(); return result
 if level >= card.max_level or GameState.scrap_metal < int(result["points"]): return result
 result["reason"] = "%s材料不足" % QUALITIES[quality]
 if int(GameState.exploration_materials.get(quality,0)) < int(result["amount"]): return result
 result["ok"] = true
 result["reason"] = "练习后提升到等级%d" % (level+1)
 return result

static func train(card_id: String, quality: String = "common") -> bool:
 var quote := training_quote(card_id,quality)
 if not quote["ok"]: return false
 GameState.scrap_metal -= int(quote["points"])
 GameState.exploration_materials[quality] -= int(quote["amount"])
 GameState.card_levels[card_id] = int(quote["level"]) + 1
 DayCycle.spend_action("upgrade")
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
 var trained := false
 for id in GameState.unlocked_card_ids:
  if int(GameState.card_levels.get(id,1)) >= 2: trained = true
 var completed_route: bool = GameState.exploration_state.get("status", "") == "completed"
 for entry in GameState.player_profile["exploration_log"]:
  if entry["status"] == "completed": completed_route = true
 var friends := 0
 for id in ["yang_zi_ying","liu_yu_long","jiang_zi"]:
  if GameState.companions.get(id,{}).get("unlocked",false): friends += 1
 var deck := deck_summary()
 var conditions := [bool(deck["ready"]) and int(deck["count"]) >= 4, trained, completed_route, friends >= 3, bool(GameState.story_flags.get("chapter_1_completed",false))]
 var progress := ["%d/4张" % mini(4,GameState.equipped_card_ids.size()),"已练习" if trained else "尚未练习","已完成" if completed_route else "尚未完成","%d/3位" % friends,"已完成" if conditions[4] else "行程进行中"]
 var result: Array[Dictionary] = []
 for i in MILESTONES.size():
  var item: Dictionary = MILESTONES[i].duplicate(true)
  item["ready"] = conditions[i]
  item["claimed"] = GameState.player_profile["milestone_claims"].has(item["id"])
  item["progress"] = progress[i]
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
  else: GameState.exploration_materials[source] += int(goal["items"][item_id])
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
 var action := "quest"
 if not deck["ready"] and GameState.phase_two_combat_checkpoint.is_empty() and not pending: action = "workshop"
 elif pending and (GameState.player_profile["last_activity"] == "exploration" or complete): action = "resume_route"
 elif not complete: action = "story"
 elif complete: action = "quest"
 var titles := {"story":"今天的行程","workshop":"出发前，准备一下","resume_route":"接着走完这条路","quest":"今天的安排" if DayCycle.has_story() else "日常自由时间"}
 var copy := PhaseTwoContent.current_objective()
 if action == "workshop": copy = deck["reason"]
 elif action == "resume_route": copy = "训练进度已保留，可以从校园地图前往体育馆继续。"
 elif action == "quest": copy = ("今天有重要的安排。" if DayCycle.has_story() else "今天是自由活动日。")+DayCycle.activity_hint()+"，也可以休息推进时段。"
 var goal: Dictionary = {}
 var claims := 0
 for item in milestones():
  if item["ready"] and not item["claimed"]:
   claims += 1
   if goal.is_empty(): goal = item
 if goal.is_empty():
  for item in milestones():
   if not item["claimed"]:
    goal = item
    break
 return {"action":action,"title":titles[action],"body":copy,"button":{"story":"继续行程" if not GameState.visited_node_ids.is_empty() else "出发去学校","workshop":"整理行动卡","resume_route":"打开校园地图","quest":"打开校园地图"}[action],"story_label":DayCycle.rest_label(),"complete":complete,"claim_count":claims,"goal":goal,"deck":deck}

static func companion_assist_spec(companion_id: String) -> Dictionary:
 return COMPANION_ASSISTS.get(companion_id, {}).duplicate(true)

static func zodiac_resonance_spec(zodiac_id: String) -> Dictionary:
 return ZODIAC_RESONANCES.get(zodiac_id, {}).duplicate(true)
