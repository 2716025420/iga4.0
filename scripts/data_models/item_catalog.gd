class_name ItemCatalog
extends RefCounted

const CATEGORIES := {"all": "全部", "material": "材料", "quest": "任务", "item": "物品"}
const ITEMS := {
	"material_common": {"name": "普通材料", "category": "material", "quality": "普通", "source": "common", "description": "行动卡练习材料。1→2级消耗3份，2→3级消耗6份；还需练习点。", "icon": "res://assets/ui_core/icons/economy/icon_mat_common.png"},
	"material_fine": {"name": "精良材料", "category": "material", "quality": "精良", "source": "fine", "description": "行动卡练习材料。1→2级消耗1份，2→3级消耗2份；还需练习点。", "icon": "res://assets/ui_core/icons/economy/icon_mat_fine.png"},
	"material_rare": {"name": "稀有材料", "category": "material", "quality": "稀有", "source": "rare", "description": "行动卡练习材料。每次提升消耗1份；还需练习点。可替代普通或精良材料。", "icon": "res://assets/ui_core/icons/economy/icon_mat_rare.png"},
	"quest_sample": {"name": "任务样件（测试）", "category": "quest", "quality": "任务", "description": "用于验证任务道具的存放与展示。名称和用途均为临时测试文本。", "icon": "res://assets/ui/scene_reset/icons/home_records.svg"},
	"sealed_note": {"name": "封存记录（测试）", "category": "quest", "quality": "任务", "description": "用于验证任务记录的收集。后续由正式剧情数据替换。", "icon": "res://assets/ui_core/icons/economy/icon_quest_sealed_note.png"},
	"practice_token": {"name": "特殊材料（测试）", "category": "material", "quality": "特殊", "description": "用于验证独立特殊材料的堆叠。不会在新游戏时自动发放。", "icon": "res://assets/ui_core/icons/economy/icon_tournament_pass.png"},
	"drink": {"name": "饮品补给", "category": "item", "quality": "普通", "source": "drinks", "description": "在Home休息时使用，恢复35点主线体力。满体力不会消耗；可由成长目标等事件获得。", "icon": "res://assets/ui_core/icons/economy/icon_drink_soda.png"}
}

static func definition(item_id: String) -> Dictionary:
	var item: Dictionary = ITEMS.get(item_id, {}).duplicate(true)
	if not item.is_empty():
		item["number"] = ITEMS.keys().find(item_id) + 1
		# Explicit pinyin keys avoid platform-dependent collation of Chinese characters.
		item["pinyin"] = {"material_common": "pu tong cai liao", "material_fine": "jing liang cai liao", "material_rare": "xi you cai liao", "quest_sample": "ren wu yang jian", "sealed_note": "feng cun ji lu", "practice_token": "te shu cai liao", "drink": "yin pin bu gei"}.get(item_id, item_id)
	return item
