class_name WorldRegionContent
extends RefCounted

## P5 configuration only. TEST pages are not approved scene artwork.
## Empty first_visit_event_id reserves the script hook without inventing a story.
const REGIONS := {
 "university_nomos": {
  "title": "诺莫斯",
  "category": "university_with_home",
  "subtitle": "安稳自由 · 公共生活 · 鼠尾草灰",
  "theme_tokens": [
   "sage_gray",
   "nature",
   "public_space"
  ],
  "home": "nomos_home_test",
  "home_id": "nomos_home_test",
  "home_scene": "res://scenes/campus/campus_screen.tscn",
  "area_map_id": "university_nomos",
  "unlock_condition": "region_nomos_unlocked",
  "first_visit_event_id": "",
  "first_entry_id": "nomos_arrival_test",
  "entry_id": "nomos_home_test",
  "accent": "#88948A",
  "ink": "#E7EBED",
  "paper": "#20262D",
  "places": [
   "nomos_home_test",
   "nomos_shop_test"
  ],
  "dungeon_difficulties": [],
  "shop_slots": [
   {
    "id": "nomos_shop_test",
    "content_status": "TEST",
    "service": "local_shop"
   }
  ],
  "special_feature_slots": [],
  "features": [],
  "guide_characters": [],
  "interactions": [],
  "events": []
 },
 "university_arete": {
  "title": "阿瑞忒",
  "category": "university_with_home",
  "subtitle": "盛夏青春 · 海风 · 夕照",
  "theme_tokens": [
   "sky_blue",
   "ocean_blue",
   "sand",
   "summer_green",
   "sunset_orange"
  ],
  "home": "club",
  "home_id": "club",
  "home_scene": "res://scenes/home/home_screen.tscn",
  "area_map_id": "university_arete",
  "unlock_condition": "",
  "first_visit_event_id": "",
  "first_entry_id": "arete_arrival_test",
  "entry_id": "club",
  "accent": "#88948A",
  "ink": "#E7EBED",
  "paper": "#20262D",
  "places": [
   "club",
   "library",
   "gym",
   "dorm",
   "shop",
   "rooftop",
   "arete_coast_test",
   "arete_beach_test"
  ],
  "dungeon_difficulties": [],
  "shop_slots": [
   {
    "id": "shop",
    "content_status": "TEST",
    "service": "local_shop"
   }
  ],
  "special_feature_slots": [],
  "features": [],
  "guide_characters": [],
  "interactions": [],
  "events": []
 },
 "university_agora": {
  "title": "阿戈拉",
  "category": "university_with_home",
  "subtitle": "商业消费 · 极端自由 · 耀金",
  "theme_tokens": [
   "gold",
   "consumption",
   "welfare_distribution"
  ],
  "home": "agora_home_test",
  "home_id": "agora_home_test",
  "home_scene": "res://scenes/campus/campus_screen.tscn",
  "area_map_id": "university_agora",
  "unlock_condition": "region_agora_unlocked",
  "first_visit_event_id": "",
  "first_entry_id": "agora_arrival_test",
  "entry_id": "agora_home_test",
  "accent": "#88948A",
  "ink": "#E7EBED",
  "paper": "#20262D",
  "places": [
   "agora_home_test",
   "agora_shop_test"
  ],
  "dungeon_difficulties": [],
  "shop_slots": [
   {
    "id": "agora_shop_test",
    "content_status": "TEST",
    "service": "local_shop"
   }
  ],
  "special_feature_slots": [],
  "features": [
   "welfare_distribution_unimplemented"
  ],
  "guide_characters": [],
  "interactions": [],
  "events": []
 },
 "university_techne": {
  "title": "忒克捏",
  "category": "university_with_home",
  "subtitle": "技艺精进 · 完善作品 · 黑白红绿",
  "theme_tokens": [
   "black",
   "white",
   "red",
   "green"
  ],
  "home": "techne_home_test",
  "home_id": "techne_home_test",
  "home_scene": "res://scenes/campus/campus_screen.tscn",
  "area_map_id": "university_techne",
  "unlock_condition": "region_techne_unlocked",
  "first_visit_event_id": "",
  "first_entry_id": "techne_arrival_test",
  "entry_id": "techne_home_test",
  "accent": "#88948A",
  "ink": "#E7EBED",
  "paper": "#20262D",
  "places": [
   "techne_home_test",
   "techne_shop_test"
  ],
  "dungeon_difficulties": [],
  "shop_slots": [
   {
    "id": "techne_shop_test",
    "content_status": "TEST",
    "service": "local_shop"
   }
  ],
  "special_feature_slots": [],
  "features": [],
  "guide_characters": [],
  "interactions": [],
  "events": []
 },
 "region_failed_alliance": {
  "title": "失败者同盟",
  "category": "story_region_without_home",
  "subtitle": "剧情探索 · 无 Home · 内容待定",
  "theme_tokens": [],
  "home": "",
  "home_id": "",
  "home_scene": "",
  "area_map_id": "region_failed_alliance",
  "unlock_condition": "region_failed_alliance_unlocked",
  "first_visit_event_id": "",
  "first_entry_id": "region_failed_alliance_arrival_test",
  "entry_id": "region_failed_alliance_gateway_test",
  "accent": "#88948A",
  "ink": "#E7EBED",
  "paper": "#20262D",
  "places": [
   "region_failed_alliance_gateway_test",
   "region_failed_alliance_dungeon_test",
   "region_failed_alliance_shop_test",
   "region_failed_alliance_feature_test"
  ],
  "dungeon_difficulties": [
   {
    "id": "test_a",
    "label": "TEST · 难度 A（未定）"
   },
   {
    "id": "test_b",
    "label": "TEST · 难度 B（未定）"
   }
  ],
  "shop_slots": [
   {
    "id": "region_failed_alliance_shop_test",
    "content_status": "TEST",
    "service": "local_shop"
   }
  ],
  "special_feature_slots": [
   {
    "id": "region_failed_alliance_feature_test",
    "content_status": "TEST"
   }
  ],
  "features": [],
  "guide_characters": [],
  "interactions": [],
  "events": []
 },
 "region_iga_church": {
  "title": "IGA信仰教团",
  "category": "story_region_without_home",
  "subtitle": "剧情探索 · 无 Home · 内容待定",
  "theme_tokens": [],
  "home": "",
  "home_id": "",
  "home_scene": "",
  "area_map_id": "region_iga_church",
  "unlock_condition": "region_iga_church_unlocked",
  "first_visit_event_id": "",
  "first_entry_id": "region_iga_church_arrival_test",
  "entry_id": "region_iga_church_gateway_test",
  "accent": "#88948A",
  "ink": "#E7EBED",
  "paper": "#20262D",
  "places": [
   "region_iga_church_gateway_test",
   "region_iga_church_dungeon_test",
   "region_iga_church_shop_test",
   "region_iga_church_feature_test"
  ],
  "dungeon_difficulties": [
   {
    "id": "test_a",
    "label": "TEST · 难度 A（未定）"
   },
   {
    "id": "test_b",
    "label": "TEST · 难度 B（未定）"
   }
  ],
  "shop_slots": [
   {
    "id": "region_iga_church_shop_test",
    "content_status": "TEST",
    "service": "local_shop"
   }
  ],
  "special_feature_slots": [
   {
    "id": "region_iga_church_feature_test",
    "content_status": "TEST"
   }
  ],
  "features": [],
  "guide_characters": [],
  "interactions": [],
  "events": []
 }
}
const PLACES := {
 "nomos_arrival_test": {
  "title": "TEST · 诺莫斯首次到达",
  "parent": "map",
  "npc": "",
  "test": true,
  "arrival": true,
  "description": "TEST 首次到达入口。正式解锁剧情、人物与全页美术尚待主创确认。",
  "actions": [
   {
    "id": "complete_visit",
    "label": "TEST · 完成首次到达"
   }
  ]
 },
 "nomos_home_test": {
  "title": "TEST · 巨树内部小酒馆",
  "parent": "map",
  "npc": "",
  "test": true,
  "description": "小型政治集团活动据点；正式人物、空间与互动待审核。",
  "actions": [
   {
    "id": "workshop",
    "label": "卡牌整理",
    "object_label": "随行木匣"
   },
   {
    "id": "records",
    "label": "随身档案",
    "object_label": "档案手账"
   },
   {
    "id": "partner_test",
    "label": "伙伴交流",
    "object_label": "围桌席"
   }
  ],
  "map_object_label": "门边导览图"
 },
 "arete_arrival_test": {
  "title": "TEST · 阿瑞忒首次到达",
  "parent": "map",
  "npc": "",
  "test": true,
  "arrival": true,
  "description": "TEST 首次到达入口。正式解锁剧情、人物与全页美术尚待主创确认。",
  "actions": [
   {
    "id": "complete_visit",
    "label": "TEST · 完成首次到达"
   }
  ]
 },
 "arete_coast_test": {
  "title": "TEST · 出校城区 / 沿海道路",
  "parent": "map",
  "npc": "",
  "test": true,
  "description": "校园与海滩之间的地区内生活空间。正式地图与玩法待审核。",
  "actions": []
 },
 "arete_beach_test": {
  "title": "TEST · 海滩",
  "parent": "map",
  "npc": "",
  "test": true,
  "description": "阿瑞忒地区内的海滩，非独立世界地区。正式地图与玩法待审核。",
  "actions": []
 },
 "agora_arrival_test": {
  "title": "TEST · 阿戈拉首次到达",
  "parent": "map",
  "npc": "",
  "test": true,
  "arrival": true,
  "description": "TEST 首次到达入口。正式解锁剧情、人物与全页美术尚待主创确认。",
  "actions": [
   {
    "id": "complete_visit",
    "label": "TEST · 完成首次到达"
   }
  ]
 },
 "agora_home_test": {
  "title": "TEST · 集中营集体宿舍",
  "parent": "map",
  "npc": "",
  "test": true,
  "description": "强制劳动集中营中主角与伙伴合住的宿舍；不实现劳动、博彩或福利经济规则。",
  "actions": [
   {
    "id": "workshop",
    "label": "卡牌整理",
    "object_label": "床边布包"
   },
   {
    "id": "records",
    "label": "随身档案",
    "object_label": "档案手账"
   },
   {
    "id": "partner_test",
    "label": "伙伴交流",
    "object_label": "床沿坐席"
   }
  ],
  "map_object_label": "墙上路线图"
 },
 "techne_arrival_test": {
  "title": "TEST · 忒克捏首次到达",
  "parent": "map",
  "npc": "",
  "test": true,
  "arrival": true,
  "description": "TEST 首次到达入口。正式解锁剧情、人物与全页美术尚待主创确认。",
  "actions": [
   {
    "id": "complete_visit",
    "label": "TEST · 完成首次到达"
   }
  ]
 },
 "techne_home_test": {
  "title": "TEST · 黑白研究制造室",
  "parent": "map",
  "npc": "",
  "test": true,
  "description": "黑白强对比的共同研究制造空间；红绿比例、人物及互动待审核。",
  "actions": [
   {
    "id": "workshop",
    "label": "卡牌整理",
    "object_label": "工作台卡架"
   },
   {
    "id": "records",
    "label": "随身档案",
    "object_label": "档案手账"
   },
   {
    "id": "partner_test",
    "label": "伙伴交流",
    "object_label": "协作台"
   }
  ],
  "map_object_label": "墙上索引图"
 },
 "region_failed_alliance_arrival_test": {
  "title": "TEST · 失败者同盟 · 首次到达",
  "parent": "map",
  "npc": "",
  "test": true,
  "arrival": true,
  "description": "正式首次剧情待主创编写。",
  "actions": [
   {
    "id": "complete_visit",
    "label": "TEST · 完成首次到达"
   }
  ]
 },
 "region_failed_alliance_gateway_test": {
  "title": "TEST · 失败者同盟 · 剧情探索入口",
  "parent": "map",
  "npc": "",
  "test": true,
  "arrival": false,
  "description": "本地区没有 Home。副本、商店、特殊功能仅提供测试入口。",
  "actions": []
 },
 "region_failed_alliance_dungeon_test": {
  "title": "TEST · 失败者同盟 · 多难度副本入口",
  "parent": "map",
  "npc": "",
  "test": true,
  "arrival": false,
  "description": "难度数值、关卡、奖励及行动消费均未设定。",
  "actions": [
   {
    "id": "test_difficulty",
    "label": "TEST · 难度 A（未定）"
   },
   {
    "id": "test_difficulty",
    "label": "TEST · 难度 B（未定）"
   }
  ]
 },
 "region_failed_alliance_shop_test": {
  "title": "TEST · 失败者同盟 · 商店",
  "parent": "map",
  "npc": "",
  "test": true,
  "description": "到店购买普通行动卡、练习材料与饮品，也可回收允许交易的物品。专属货源与店主待完善。",
  "actions": [
   {
    "id": "shop",
    "label": "查看商品",
    "object_label": "商品柜台"
   },
   {
    "id": "records",
    "label": "随身档案",
    "object_label": "档案手账"
   }
  ]
 },
 "region_failed_alliance_feature_test": {
  "title": "TEST · 失败者同盟 · 特殊功能区",
  "parent": "map",
  "npc": "",
  "test": true,
  "arrival": false,
  "description": "具体功能、人物、素材待定。",
  "actions": []
 },
 "region_iga_church_arrival_test": {
  "title": "TEST · IGA信仰教团 · 首次到达",
  "parent": "map",
  "npc": "",
  "test": true,
  "arrival": true,
  "description": "正式首次剧情待主创编写。",
  "actions": [
   {
    "id": "complete_visit",
    "label": "TEST · 完成首次到达"
   }
  ]
 },
 "region_iga_church_gateway_test": {
  "title": "TEST · IGA信仰教团 · 剧情探索入口",
  "parent": "map",
  "npc": "",
  "test": true,
  "arrival": false,
  "description": "本地区没有 Home。副本、商店、特殊功能仅提供测试入口。",
  "actions": []
 },
 "region_iga_church_dungeon_test": {
  "title": "TEST · IGA信仰教团 · 多难度副本入口",
  "parent": "map",
  "npc": "",
  "test": true,
  "arrival": false,
  "description": "难度数值、关卡、奖励及行动消费均未设定。",
  "actions": [
   {
    "id": "test_difficulty",
    "label": "TEST · 难度 A（未定）"
   },
   {
    "id": "test_difficulty",
    "label": "TEST · 难度 B（未定）"
   }
  ]
 },
 "region_iga_church_shop_test": {
  "title": "TEST · IGA信仰教团 · 商店",
  "parent": "map",
  "npc": "",
  "test": true,
  "description": "到店购买普通行动卡、练习材料与饮品，也可回收允许交易的物品。专属货源与店主待完善。",
  "actions": [
   {
    "id": "shop",
    "label": "查看商品",
    "object_label": "商品柜台"
   },
   {
    "id": "records",
    "label": "随身档案",
    "object_label": "档案手账"
   }
  ]
 },
 "region_iga_church_feature_test": {
  "title": "TEST · IGA信仰教团 · 特殊功能区",
  "parent": "map",
  "npc": "",
  "test": true,
  "arrival": false,
  "description": "具体功能、人物、素材待定。",
  "actions": []
 },
 "nomos_shop_test": {
  "title": "TEST · 诺莫斯 · 社区商店",
  "parent": "map",
  "npc": "",
  "test": true,
  "description": "到店购买普通行动卡、练习材料与饮品，也可回收允许交易的物品。专属货源与店主待完善。",
  "actions": [
   {
    "id": "shop",
    "label": "查看商品",
    "object_label": "商品柜台"
   },
   {
    "id": "records",
    "label": "随身档案",
    "object_label": "档案手账"
   }
  ]
 },
 "agora_shop_test": {
  "title": "TEST · 阿戈拉 · 地区商店",
  "parent": "map",
  "npc": "",
  "test": true,
  "description": "到店购买普通行动卡、练习材料与饮品，也可回收允许交易的物品。专属货源与店主待完善。",
  "actions": [
   {
    "id": "shop",
    "label": "查看商品",
    "object_label": "商品柜台"
   },
   {
    "id": "records",
    "label": "随身档案",
    "object_label": "档案手账"
   }
  ]
 },
 "techne_shop_test": {
  "title": "TEST · 忒克捏 · 工坊用品店",
  "parent": "map",
  "npc": "",
  "test": true,
  "description": "到店购买普通行动卡、练习材料与饮品，也可回收允许交易的物品。专属货源与店主待完善。",
  "actions": [
   {
    "id": "shop",
    "label": "查看商品",
    "object_label": "商品柜台"
   },
   {
    "id": "records",
    "label": "随身档案",
    "object_label": "档案手账"
   }
  ]
 }
}
