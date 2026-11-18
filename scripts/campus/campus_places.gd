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
  "title": "图书馆",
  "parent": "map",
  "npc": "lin_zhi_xia",
  "description": "阳光与书页气息交织的明亮阅读区。可以研习牌理赚取练习点，并翻阅《阿瑞忒风物纪要》。",
  "actions": [
   {
    "id": "library_study",
    "label": "牌理研习 · 1活动"
   },
   {
    "id": "read_notes",
    "label": "翻阅风物纪要"
   },
   {
    "id": "talk",
    "label": "和林知夏聊聊"
   }
  ]
 },
 "study": {
  "title": "图书馆 · 自习席",
  "parent": "library",
  "npc": "lin_zhi_xia",
  "description": "窗边安静的自习位置。",
  "actions": [
   {
    "id": "library_study",
    "label": "牌理研习 · 1活动"
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
  "description": "木质货架与冷饮柜台之间总是香气扑鼻。到店选购行动卡、材料与饮品，也能帮唐小满打工赚零用钱。",
  "actions": [
   {
    "id": "shop",
    "label": "查看商品"
   },
   {
    "id": "shop_work",
    "label": "店务兼职 · 1活动"
   },
   {
    "id": "talk",
    "label": "和唐小满聊聊"
   }
  ]
 },
 "stockroom": {
  "title": "校园商店 · 货仓角",
  "parent": "shop",
  "npc": "tang_xiao_man",
  "description": "纸箱按顺序码好，小窗外传来操场上的声音。",
  "actions": [
   {
    "id": "shop_work",
    "label": "店务兼职 · 1活动"
   },
   {
    "id": "go",
    "target": "shop",
    "label": "← 回商店"
   }
  ]
 },
 "rooftop": {
  "title": "教学楼天台",
  "parent": "club",
  "npc": "liu_yu_long",
  "description": "海风从护栏间拂过，楼下的喧闹离这里很远。适合休息恢复体力并与同伴复盘战术。",
  "actions": [
   {
    "id": "rooftop_review",
    "label": "午后复盘 · 1活动"
   },
   {
    "id": "talk",
    "label": "和同伴聊聊"
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
  "description": "一个人的小房间。关上门，整理今日见闻，也可以安心休息推进时段。",
  "background": "dorm_bg.png",
  "actions": [
   {
    "id": "sleep",
    "label": "上床休息 · 推进时段"
   },
   {
    "id": "dorm_desk",
    "label": "书桌整理 · 今日小结"
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
  "npc": "liu_yu_long",
  "description": "阳光透过高窗照在木质场地上。这里不仅能刷材料与模拟训练，也是《阿瑞忒代表选拔赛》的擂台。",
  "geometry": false,
  "actions": [
   {
    "id": "training",
    "label": "模拟训练"
   },
   {
    "id": "qualifier",
    "label": "代表选拔赛"
   },
   {
    "id": "workshop",
    "label": "整理行动卡"
   }
  ]
 },
 "old_park": {
  "title": "旧公园",
  "parent": "arete_coast_test",
  "npc": "",
  "description": "红枫与梧桐掩映的校外旧公园，黄昏的长椅正对着街角自动贩卖机。",
  "actions": [
   {
    "id": "park_reflect",
    "label": "长椅追忆 · 1活动"
   },
   {
    "id": "park_vending",
    "label": "查看街角贩卖机"
   },
   {
    "id": "go",
    "target": "arete_coast_test",
    "label": "返回沿海公路"
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

const NPCS := {
 "lin_zhi_xia":{"name":"林知夏","role":"图书委员","texture":"library_actor.png","halfbody":"res://assets/sprites/characters/phase_two/halfbody/lin_zhi_xia_neutral.png","region":[1170,55,315,886]},
 "tang_xiao_man":{"name":"唐小满","role":"商店值班同学","texture":"shop_actor.png","halfbody":"res://assets/sprites/characters/phase_two/halfbody/tang_xiao_man_neutral.png","region":[1095,52,290,866]},
 "liu_yu_long":{"name":"柳宇龙","role":"竞技社同学","path":"res://assets/sprites/characters/phase_two/fullbody/liu_yu_long.png"},
 "jiang_zi":{"name":"姜梓","role":"社团教室干事","path":"res://assets/sprites/characters/phase_two/fullbody/jiang_zi.png"},
 "yang_zi_ying":{"name":"杨子英","role":"摄影社同伴","path":"res://assets/sprites/characters/phase_two/fullbody/yang_zi_ying.png"},
 "huang_qiufeng":{"name":"黄秋枫","role":"转校插班生","path":"res://assets/sprites/characters/phase_two/halfbody/huang_qiufeng.png"}
}
const LIBRARY_NOTES := [
 {"id":"note_arbitration","title":"纪要 01 · 学园护盾裁决公约","body":"四所独立大学之间通行「非致命护盾裁决」规约：日常切磋以投影偏折盾消减作为胜负判定，不得伤及学生实体。"},
 {"id":"note_four_academies","title":"纪要 02 · 四大大学巡回概览","body":"诺莫斯崇尚自然松弛与公众议政，阿瑞忒留存盛夏海风与青春社团，阿戈拉以高度自由的商贸闻名，忒克捏则追求极致技艺。"},
 {"id":"note_red_moon","title":"纪要 03 · 红月预警与超限模式","body":"每当城市上空出现异常红月频段或街区限幅器遭外部覆写时，护盾投影保护将失效并强行切入实战模式，务必保持卡匣满编。"},
 {"id":"note_card_case","title":"纪要 04 · 战术刻印卡匣的演进","body":"早期的笨重运算装置已被学生们改造成随身折叠卡匣；平时可存放于社团整理台或商店柜台随时添置强化，不消耗日常活动次数。"},
 {"id":"note_coast_tram","title":"纪要 05 · 沿海公路与电车旧闻","body":"阿瑞忒东侧临海，沿着长堤与沙滩一直走到尽头，就是全区最受欢迎的放学散步道——不少巡回赛选手习惯在海风里复盘卡序。"},
 {"id":"note_zodiac_myth","title":"纪要 06 · 十二星座母卡传闻","body":"不同于商店流通的普通战术刻印卡，传说中唯有极少数人持有的十二星座母卡各自铭刻着无可复制的法则，也是开启月球档案库的钥匙。"},
 {"id":"note_nomos_tree","title":"纪要 07 · 诺莫斯的巨树聚落","body":"校刊上记载，第二站诺莫斯学园的核心据点建在一棵环绕全城的巨大古木中空腔室内，旅人们常在树根下的小酒馆交换情报。"},
 {"id":"note_borrowed_novel","title":"纪要 08 · 折角借书卡背面的字迹","body":"林知夏在窗边旧小说里发现了一张被人反复借阅却工整誊写着批注的借书卡：『人类在分别时会先买两瓶汽水——或许因为那样，下次见面就有了理由。』"}
]
const SNIPPETS := {
 "read":[["我","随手翻开一本校园随笔，页边留着一行小字：把没说出口的话，留给下一次见面。"],["我","合上书之前，我把这句话记在了心里。"]],
 "study_note":[["我","桌边的便笺上写着：这里的台灯偶尔接触不良，轻轻转一下就好。落款只有一个“夏”字。"]],
 "delivery":[["唐小满","今天送来的是社团用的纸和饮品补给。需要赚点零用钱买新卡的话，随时来柜台帮我盘点哦！"]],
 "boxes":[["我","纸箱上的图案标着纸张、文具和饮水。每一箱都已清点好，暂时没有需要带走的东西。"]],
 "stock_note":[["我","便笺写着：把多出来的空纸箱留给社团。旁边画了一个有点歪的小笑脸。"]],
 "rooftop_note":[["我","长椅旁压着半张手写谱。风把边角吹得轻轻作响，背面写着“放学以后再试一次”。"]],
 "dorm_note":[["我","门边的信笺上只有一句话：明天也别忘记，放学后到社团教室来。"],["我","我把信笺夹进书里。这个小房间安静下来，窗外的风声显得格外清楚。"]],
 "park_vending":[["我","街角的自动贩卖机还亮着温暖的橙色灯箱。玻璃橱窗里依然摆着那款熟悉的冰镇橘子汽水。"]],
 "coast_observe":[["我","沿着沿海公路的石阶向下望去，阳光碎在湛蓝的海面上，远处的白色灯塔正迎着海风旋转。"]],
 "beach_observe":[["我","细软的沙岸边拍打着透明的海浪。把脚步放慢下来，整个人都轻松了许多。"]]
}

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
 if not value.get("notes") is Dictionary or value["notes"].size() > 64: return false
 for id in value["notes"]:
  if not id is String or str(id).length() > 64 or not value["notes"][id] is bool or value["notes"][id] != true: return false
 if not value.get("npc_talks") is Dictionary: return false
 for id in value["npc_talks"]:
  if not NPCS.has(id) or not GameState._whole_number(value["npc_talks"][id]) or int(value["npc_talks"][id]) not in range(10000): return false
 for field in ["studied_on_day","last_sleep_day"]:
  if not GameState._whole_number(value.get(field)) or int(value[field]) < 0: return false
 return true
