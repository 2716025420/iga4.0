class_name CampusPlaces
extends RefCounted

const ROOT := "res://assets/ui/campus_life/"
const LEGACY_PLACES := {
 "club": {
  "title": "社团教室",
  "parent": "map",
  "npc": "jiang_zi",
  "description": "熟悉的课桌与等你一起出发的人。",
  "actions": []
 },
 "library": {
  "title": "图书馆 · 阅读区",
  "parent": "map",
  "npc": "lin_zhi_xia",
  "description": "窗边的书页被夕阳照亮，图书委员正在整理归还的书。",
  "actions": [
   {
    "id": "talk",
    "label": "和林知夏聊聊"
   },
   {
    "id": "read",
    "label": "翻阅窗边的书"
   },
   {
    "id": "go",
    "target": "study",
    "label": "前往自习室 →"
   }
  ]
 },
 "study": {
  "title": "图书馆 · 自习室",
  "parent": "library",
  "npc": "",
  "description": "找一个安静的位置，让思绪慢慢落在纸上。",
  "actions": [
   {
    "id": "study",
    "label": "安静自习 · 一次活动"
   },
   {
    "id": "study_note",
    "label": "看看桌边的留言"
   },
   {
    "id": "go",
    "target": "library",
    "label": "← 回阅读区"
   }
  ]
 },
 "shop": {
  "title": "校园商店",
  "parent": "map",
  "npc": "tang_xiao_man",
  "description": "货架间有熟悉的纸张气味。到店选购普通行动卡、练习材料和补给，也可和值班同学聊聊。",
  "actions": [
   {
    "id": "shop",
    "label": "查看商品"
   },
   {
    "id": "delivery",
    "label": "询问今天的送货"
   },
   {
    "id": "go",
    "target": "stockroom",
    "label": "去后面的仓库 →"
   }
  ]
 },
 "stockroom": {
  "title": "校园商店 · 仓库",
  "parent": "shop",
  "npc": "",
  "description": "纸箱按顺序码好，小窗外传来操场上的声音。",
  "actions": [
   {
    "id": "boxes",
    "label": "看看架上的纸箱"
   },
   {
    "id": "stock_note",
    "label": "阅读夹在箱上的便笺"
   },
   {
    "id": "go",
    "target": "shop",
    "label": "← 回商店"
   }
  ]
 },
 "rooftop": {
  "title": "教学楼 · 天台",
  "parent": "club",
  "npc": "liu_yu_long",
  "description": "风从围栏间穿过，楼下的喧闹离这里很远。",
  "actions": [
   {
    "id": "talk",
    "label": "和柳宇龙聊聊"
   },
   {
    "id": "rooftop_note",
    "label": "看看长椅旁的纸条"
   },
   {
    "id": "go",
    "target": "club",
    "label": "← 回社团教室"
   }
  ]
 },
 "dorm": {
  "title": "自己的宿舍",
  "parent": "map",
  "npc": "",
  "description": "一个人的小房间。关上门，今天也可以好好休息了。",
  "background": "dorm_bg.png",
  "actions": [
   {
    "id": "sleep",
    "label": "上床休息 · 推进时段"
   },
   {
    "id": "dorm_note",
    "label": "看看门边的信笺"
   },
   {
    "id": "go",
    "target": "map",
    "label": "返回校园地图"
   }
  ]
 },
 "gym": {
  "title": "体育馆",
  "parent": "map",
  "npc": "",
  "description": "在场边整理行动卡，从这里开始或继续模拟训练。",
  "geometry": true,
  "actions": [
   {
    "id": "training",
    "label": "模拟训练"
   },
   {
    "id": "workshop",
    "label": "整理行动卡"
   },
   {
    "id": "go",
    "target": "map",
    "label": "返回校园地图"
   }
  ]
 },
 "alliance_hq": {
  "title": "联盟指挥所",
  "parent": "map",
  "npc": "",
  "description": "联盟行动的起点。在这里整理卡牌、准备行动与查阅记录。",
  "geometry": true,
  "actions": [
   {
    "id": "workshop",
    "label": "卡牌整理"
   },
   {
    "id": "records",
    "label": "行动记录"
   },
   {
    "id": "go",
    "target": "map",
    "label": "查看地区地图"
   }
  ]
 },
 "alliance_intel": {
  "title": "情报室",
  "parent": "map",
  "npc": "",
  "description": "联络台与情报墙构成剧情区域，后续在这里接入联盟故事。",
  "geometry": true,
  "actions": [
   {
    "id": "preview",
    "label": "查看空间规划"
   },
   {
    "id": "go",
    "target": "map",
    "label": "返回地区地图"
   }
  ]
 },
 "alliance_drill": {
  "title": "演练场",
  "parent": "map",
  "npc": "",
  "description": "预留独立的演练地点。联盟战斗内容尚待设计。",
  "geometry": true,
  "actions": [
   {
    "id": "preview",
    "label": "查看空间规划"
   },
   {
    "id": "go",
    "target": "map",
    "label": "返回地区地图"
   }
  ]
 },
 "alliance_supply": {
  "title": "补给站",
  "parent": "map",
  "npc": "",
  "description": "补给登记与仓储分区，可在这里查看已有物品。",
  "geometry": true,
  "actions": [
   {
    "id": "warehouse",
    "label": "物品收纳"
   },
   {
    "id": "go",
    "target": "map",
    "label": "返回地区地图"
   }
  ]
 },
 "alliance_quarters": {
  "title": "驻地宿舍",
  "parent": "map",
  "npc": "",
  "description": "联盟的生活区域，预留休整与驻地日常。",
  "geometry": true,
  "actions": [
   {
    "id": "preview",
    "label": "查看空间规划"
   },
   {
    "id": "go",
    "target": "map",
    "label": "返回地区地图"
   }
  ]
 },
 "sanctuary_hall": {
  "title": "圣地会所",
  "parent": "map",
  "npc": "",
  "description": "踏上旅途前的会合处。在这里整理卡牌与查阅记录。",
  "geometry": true,
  "actions": [
   {
    "id": "workshop",
    "label": "卡牌整理"
   },
   {
    "id": "records",
    "label": "旅途记录"
   },
   {
    "id": "go",
    "target": "map",
    "label": "查看地区地图"
   }
  ]
 },
 "sanctuary_cathedral": {
  "title": "中央圣堂",
  "parent": "map",
  "npc": "",
  "description": "以中轴与前庭组织的核心剧情空间，仪式与人物内容待接入。",
  "geometry": true,
  "actions": [
   {
    "id": "preview",
    "label": "查看空间规划"
   },
   {
    "id": "go",
    "target": "map",
    "label": "返回地区地图"
   }
  ]
 },
 "sanctuary_archive": {
  "title": "经卷书库",
  "parent": "map",
  "npc": "",
  "description": "阅读台与文献架围绕中央走廊布置，预留文献剧情。",
  "geometry": true,
  "actions": [
   {
    "id": "preview",
    "label": "查看空间规划"
   },
   {
    "id": "go",
    "target": "map",
    "label": "返回地区地图"
   }
  ]
 },
 "sanctuary_garden": {
  "title": "静思庭院",
  "parent": "map",
  "npc": "",
  "description": "环形步道连接水庭与休息区，预留人物交流。",
  "geometry": true,
  "actions": [
   {
    "id": "preview",
    "label": "查看空间规划"
   },
   {
    "id": "go",
    "target": "map",
    "label": "返回地区地图"
   }
  ]
 },
 "sanctuary_lodging": {
  "title": "朝圣者居所",
  "parent": "map",
  "npc": "",
  "description": "圣地的生活空间，预留旅途休憩与日常。",
  "geometry": true,
  "actions": [
   {
    "id": "preview",
    "label": "查看空间规划"
   },
   {
    "id": "go",
    "target": "map",
    "label": "返回地区地图"
   }
  ]
 }
}
static var PLACES: Dictionary = LEGACY_PLACES.merged(WorldRegionContent.PLACES)

const NPCS := {"lin_zhi_xia":{"name":"林知夏","role":"图书委员","texture":"library_actor.png","region":[1170,55,315,886]},"tang_xiao_man":{"name":"唐小满","role":"商店值班同学","texture":"shop_actor.png","region":[1095,52,290,866]},"liu_yu_long":{"name":"柳宇龙","role":"天台的同学","path":"res://assets/sprites/characters/phase_two/fullbody/liu_yu_long.png"},"jiang_zi":{"name":"姜梓","role":"社团教室的同学","path":"res://assets/sprites/characters/phase_two/fullbody/jiang_zi.png"}}
const SNIPPETS := {"read":[["我","随手翻开一本校园随笔，页边留着一行小字：把没说出口的话，留给下一次见面。"],["我","合上书之前，我把这句话记在了心里。"]],"study_note":[["我","桌边的便笺上写着：这里的台灯偶尔接触不良，轻轻转一下就好。落款只有一个“夏”字。"]],"delivery":[["唐小满","今天送来的是社团用的纸和矿泉水。我把送货单夹在后面的纸箱上了。"],["唐小满","想去看看就去吧，小心别碰到门边的手推车。"]],"boxes":[["我","纸箱上的图案标着纸张、文具和饮水。每一箱都已清点好，暂时没有需要带走的东西。"]],"stock_note":[["我","便笺写着：把多出来的空纸箱留给社团。旁边画了一个有点歪的小笑脸。"]],"rooftop_note":[["我","长椅旁压着半张手写谱。风把边角吹得轻轻作响，背面写着“放学以后再试一次”。"]],"dorm_note":[["我","门边的信笺上只有一句话：明天也别忘记，放学后到社团教室来。"],["我","我把信笺夹进书里。这个小房间安静下来，窗外的风声显得格外清楚。"]]}

static func valid_state(value: Variant) -> bool:
 if not value is Dictionary: return false
 if value.get("last_location","") not in PLACES.keys()+["map"]: return false
 if value.has("region_id"):
  if not value["region_id"] is String or not RegionCatalog.owns_place(value["region_id"],value["last_location"]): return false
 if value.has("region_visits"):
  if not value["region_visits"] is Dictionary or value["region_visits"].size() > WorldRegionContent.REGIONS.size(): return false
  for id in value["region_visits"]:
   if not WorldRegionContent.REGIONS.has(id) or value["region_visits"][id] not in ["arrived","completed"]: return false
 if value.has("map_concept") and value["map_concept"] not in ["vermilion","verdant","indigo"]: return false
 if not value.get("visited") is Array or value["visited"].size() > PLACES.size(): return false
 for id in value["visited"]:
  if not id is String or not PLACES.has(id): return false
 if not value.get("notes") is Dictionary or value["notes"].size() > 32: return false
 for id in value["notes"]:
  if not id is String or id not in SNIPPETS.keys()+["first_night"] or not value["notes"][id] is bool or value["notes"][id] != true: return false
 if not value.get("npc_talks") is Dictionary: return false
 for id in value["npc_talks"]:
  if not NPCS.has(id) or not GameState._whole_number(value["npc_talks"][id]) or int(value["npc_talks"][id]) not in range(10000): return false
 for field in ["studied_on_day","last_sleep_day"]:
  if not GameState._whole_number(value.get(field)) or int(value[field]) < 0: return false
 return true
