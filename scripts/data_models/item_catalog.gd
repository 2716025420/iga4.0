class_name ItemCatalog
extends RefCounted

const CATEGORIES := {"all": "全部", "material": "材料", "quest": "任务", "item": "物品"}
const ITEMS := {
	"material_common": {"name": "普通材料", "category": "material", "quality": "普通", "source": "common", "description": "行动卡练习材料。1→2级消耗3份，2→3级消耗6份；还需练习点。", "icon": "res://assets/ui_core/icons/economy/icon_mat_common.png"},
	"material_fine": {"name": "精良材料", "category": "material", "quality": "精良", "source": "fine", "description": "行动卡练习材料。1→2级消耗1份，2→3级消耗2份；还需练习点。", "icon": "res://assets/ui_core/icons/economy/icon_mat_fine.png"},
	"material_rare": {"name": "稀有材料", "category": "material", "quality": "稀有", "source": "rare", "description": "行动卡练习材料。每次提升消耗1份；还需练习点。可替代普通或精良材料。", "icon": "res://assets/ui_core/icons/economy/icon_mat_rare.png"},
	"quest_sample": {"name": "折角借书卡", "category": "quest", "quality": "任务", "description": "夹在阿瑞忒图书馆旧小说里的借书卡，页角留着娟秀的阅读批注。", "icon": "res://assets/ui/scene_reset/icons/home_records.svg"},
	"sealed_note": {"name": "旧公园的汽水拉环", "category": "quest", "quality": "任务", "description": "留在旧公园街角贩卖机旁的橘子汽水拉环，提醒着尚未完成的巡回之约。", "icon": "res://assets/ui_core/icons/economy/icon_quest_sealed_note.png"},
	"practice_token": {"name": "阿瑞忒代表通行章", "category": "quest", "quality": "纪念", "description": "通过阿瑞忒校内代表选拔赛全胜考验后颁发的六地区巡回赛正式代表徽章。", "icon": "res://assets/ui_core/icons/economy/icon_tournament_pass.png"},
	"drink": {"name": "饮品补给", "category": "item", "quality": "普通", "source": "drinks", "description": "在社团教室或地区据点休整时使用，恢复35点体力。满体力不会消耗；可通过打工、领奖或商店获得。", "icon": "res://assets/ui_core/icons/economy/icon_drink_soda.png"}
}

static func definition(item_id: String) -> Dictionary:
	var item: Dictionary = ITEMS.get(item_id, {}).duplicate(true)
	if not item.is_empty():
		item["number"] = ITEMS.keys().find(item_id) + 1
		# Explicit pinyin keys avoid platform-dependent collation of Chinese characters.
		item["pinyin"] = {"material_common": "pu tong cai liao", "material_fine": "jing liang cai liao", "material_rare": "xi you cai liao", "quest_sample": "zhe jiao jie shu ka", "sealed_note": "jiu gong yuan de qi shui la huan", "practice_token": "a rui te dai biao tong xing zhang", "drink": "yin pin bu gei"}.get(item_id, item_id)
	return item
