class_name RegionCatalog
extends RefCounted

## Stable IDs are shared by travel, maps and save validation.
const LEGACY_REGIONS := {
 "campus":{"title":"校园","subtitle":"放学后的日常","home":"club","accent":"#B64E36","ink":"#283B50","paper":"#F5E9D9","places":["club","library","gym","dorm","shop","rooftop"]},
 "resistance":{"title":"反抗联盟","subtitle":"联络 · 集结 · 出发","home":"alliance_hq","accent":"#DC784C","ink":"#EDF1EE","paper":"#202F36","places":["alliance_hq","alliance_intel","alliance_drill","alliance_supply","alliance_quarters"]},
 "sanctuary":{"title":"教会圣地","subtitle":"回廊 · 庭院 · 圣堂","home":"sanctuary_hall","accent":"#9D854C","ink":"#51495E","paper":"#EAE6DB","places":["sanctuary_hall","sanctuary_cathedral","sanctuary_archive","sanctuary_garden","sanctuary_lodging"]}
}
static var REGIONS: Dictionary = LEGACY_REGIONS.merged(WorldRegionContent.REGIONS)

const CONCEPTS := {
 "vermilion":{"title":"晨海绘卷","subtitle":"晴日 / 蔚蓝水彩 / 阿瑞忒全图","path":"res://assets/ui/region_maps/map_arete_day.png","accent":"#C95645","paper":"#FFF9EE","ink":"#24354F"},
 "indigo":{"title":"夜月星图","subtitle":"靛青 / 柔夜水彩 / 阿瑞忒夜图","path":"res://assets/ui/region_maps/map_arete_night.png","accent":"#E29578","paper":"#232E4A","ink":"#FFF7E5"}
}
const MAP_RECTS := {
 "rooftop":Rect2(180,190,330,250),"club":Rect2(460,350,500,315),"library":Rect2(1160,200,390,285),
 "gym":Rect2(1320,570,460,350),"dorm":Rect2(130,690,400,290),"shop":Rect2(820,745,340,250),
 "alliance_hq":Rect2(920,370,450,260),"alliance_intel":Rect2(570,155,320,225),"alliance_drill":Rect2(1460,175,360,240),"alliance_supply":Rect2(550,705,360,230),"alliance_quarters":Rect2(1450,710,360,225),
 "sanctuary_hall":Rect2(980,660,410,260),"sanctuary_cathedral":Rect2(980,140,410,330),"sanctuary_archive":Rect2(550,380,325,245),"sanctuary_garden":Rect2(1485,385,325,245),"sanctuary_lodging":Rect2(540,730,325,230)
}
const ROLES := {"club":"据点 · 整理与主线","library":"阅读 · 自习","gym":"模拟训练","dorm":"生活 · 过夜","shop":"商店 · 物品回收","rooftop":"交流 · 短剧情","alliance_hq":"总部 · 行动准备","alliance_intel":"情报 · 剧情预留","alliance_drill":"演练 · 功能预留","alliance_supply":"补给 · 仓储","alliance_quarters":"休整 · 生活预留","sanctuary_hall":"会所 · 整理与记录","sanctuary_cathedral":"仪式 · 剧情预留","sanctuary_archive":"文献 · 剧情预留","sanctuary_garden":"庭院 · 交流预留","sanctuary_lodging":"休憩 · 生活预留"}
const PLACE_ZONES := {
 "gym": [
  "候场与整理",
  "模拟训练场",
  "训练出入口"
 ],
 "alliance_hq": [
  "联络台",
  "行动桌",
  "档案墙"
 ],
 "alliance_intel": [
  "电台联络",
  "情报墙",
  "交流区"
 ],
 "alliance_drill": [
  "候场区",
  "演练区域",
  "装备整理"
 ],
 "alliance_supply": [
  "补给登记",
  "物品架",
  "储备区"
 ],
 "alliance_quarters": [
  "休息间",
  "生活区",
  "公共客厅"
 ],
 "sanctuary_hall": [
  "会合厅",
  "整理台",
  "记录架"
 ],
 "sanctuary_cathedral": [
  "前庭",
  "中殿",
  "仪式台"
 ],
 "sanctuary_archive": [
  "借阅台",
  "经卷架",
  "阅读区"
 ],
 "sanctuary_garden": [
  "环形回廊",
  "水庭",
  "静思席"
 ],
 "sanctuary_lodging": [
  "客房",
  "起居厅",
  "旅途物品"
 ]
}
const SHORT_NAMES := {"library":"图书馆","rooftop":"教学楼天台","dorm":"学生宿舍","arete_coast_test":"沿海公路","arete_beach_test":"阿瑞忒海滩"}

static func region_for_place(id: String) -> String:
 if id in ["study","stockroom","old_park","arete_coast_test","arete_beach_test"]: return "university_arete"
 for region in REGIONS:
  if owns_place(str(region),id): return str(region)
 return "university_arete"

static func is_home(id: String) -> bool:
 for region in REGIONS.values():
  if id != "" and region["home"] == id: return true
 return false

static func links(region_id: String) -> Array:
 if region_id == "resistance": return [["alliance_hq","alliance_intel"],["alliance_hq","alliance_drill"],["alliance_hq","alliance_supply"],["alliance_hq","alliance_quarters"]]
 return [["sanctuary_hall","sanctuary_cathedral"],["sanctuary_hall","sanctuary_archive"],["sanctuary_hall","sanctuary_garden"],["sanctuary_hall","sanctuary_lodging"]]

const UNLOCK_FLAGS := {"campus":"","resistance":"region_resistance_unlocked","sanctuary":"region_sanctuary_unlocked"}
const CAMPUS_LABELS := {"rooftop":Rect2(205,365,290,70),"club":Rect2(520,580,340,76),"library":Rect2(1160,405,360,70),"gym":Rect2(1400,840,360,70),"dorm":Rect2(150,905,350,72),"shop":Rect2(850,920,300,72)}
const ATLAS_LABELS := {"campus":Rect2(330,425,330,130),"resistance":Rect2(1070,320,390,130),"sanctuary":Rect2(1165,735,390,130)}

static func is_unlocked(id: String, flags: Dictionary = GameState.story_flags) -> bool:
 if not REGIONS.has(id): return false
 var flag := str(REGIONS[id].get("unlock_condition",UNLOCK_FLAGS.get(id,"")))
 return flag == "" or bool(flags.get(flag,false))

static func territory(id: String) -> PackedVector2Array:
 match id:
  "campus": return PackedVector2Array([Vector2(180,300),Vector2(550,170),Vector2(850,320),Vector2(930,570),Vector2(710,810),Vector2(300,860),Vector2(130,620)])
  "resistance": return PackedVector2Array([Vector2(850,320),Vector2(1070,150),Vector2(1470,200),Vector2(1620,430),Vector2(1340,620),Vector2(930,570)])
  "sanctuary": return PackedVector2Array([Vector2(930,570),Vector2(1340,620),Vector2(1620,430),Vector2(1780,660),Vector2(1620,910),Vector2(1200,950),Vector2(710,810)])
 return PackedVector2Array()

const PAINTED_RECTS := {
 "vermilion":{
  "rooftop":Rect2(128,215,425,195),
  "dorm":Rect2(24,465,422,275),
  "club":Rect2(468,335,572,300),
  "library":Rect2(1170,175,540,215),
  "shop":Rect2(492,640,278,205),
  "gym":Rect2(1140,415,555,255),
  "arete_coast_test":Rect2(1585,615,315,325)
 },
 "indigo":{
  "rooftop":Rect2(128,215,425,195),
  "dorm":Rect2(24,465,422,275),
  "club":Rect2(468,335,572,300),
  "library":Rect2(1170,175,540,215),
  "shop":Rect2(492,640,278,205),
  "gym":Rect2(1140,415,555,255),
  "arete_coast_test":Rect2(1585,615,315,325)
 }
}
const PAINTED_LABELS := {
 "vermilion":{
  "rooftop":Rect2(220,398,216,58),
  "dorm":Rect2(118,744,206,58),
  "club":Rect2(675,622,216,58),
  "library":Rect2(1345,146,206,58),
  "shop":Rect2(525,842,206,58),
  "gym":Rect2(1328,674,206,58),
  "arete_coast_test":Rect2(1612,748,220,58)
 },
 "indigo":{
  "rooftop":Rect2(220,398,216,58),
  "dorm":Rect2(118,744,206,58),
  "club":Rect2(675,622,216,58),
  "library":Rect2(1345,146,206,58),
  "shop":Rect2(525,842,206,58),
  "gym":Rect2(1328,674,206,58),
  "arete_coast_test":Rect2(1612,748,220,58)
 }
}


static func is_primary(id: String) -> bool:
 return WorldRegionContent.REGIONS.has(id)

static func owns_place(region_id: String, location_id: String) -> bool:
 if not REGIONS.has(region_id): return false
 if REGIONS[region_id]["places"].has(location_id): return true
 if REGIONS[region_id].get("first_entry_id", "") == location_id: return true
 return region_id in ["campus", "university_arete"] and location_id in ["study", "stockroom", "old_park", "arete_coast_test", "arete_beach_test", "arete_arrival_test"]

static func home_for_region(region_id: String) -> String:
 return str(REGIONS.get(region_id, {}).get("home", ""))
