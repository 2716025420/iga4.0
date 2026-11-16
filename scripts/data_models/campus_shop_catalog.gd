class_name CampusShopCatalog
extends RefCounted

## Adjustable playtest pricing, outside basic welfare and story-card ownership.
const PRODUCTS := {
	"card_wrench_smash": {
		"kind": "card",
		"ref": "wrench_smash",
		"category": "cards",
		"buy": 90,
		"sell": 0
	},
	"card_scrap_shield": {
		"kind": "card",
		"ref": "scrap_shield",
		"category": "cards",
		"buy": 110,
		"sell": 0
	},
	"card_icy_soda": {
		"kind": "card",
		"ref": "icy_soda",
		"category": "cards",
		"buy": 80,
		"sell": 0
	},
	"card_overclock_torch": {
		"kind": "card",
		"ref": "overclock_torch",
		"category": "cards",
		"buy": 140,
		"sell": 0
	},
	"card_fake_cheque": {
		"kind": "card",
		"ref": "fake_cheque",
		"category": "cards",
		"buy": 180,
		"sell": 0
	},
	"card_steel_barricade": {
		"kind": "card",
		"ref": "steel_barricade",
		"category": "cards",
		"buy": 220,
		"sell": 0
	},
	"card_coin_gambit": {
		"kind": "card",
		"ref": "coin_gambit",
		"category": "cards",
		"buy": 160,
		"sell": 0
	},
	"card_counter_seal": {
		"kind": "card",
		"ref": "counter_seal",
		"category": "cards",
		"buy": 170,
		"sell": 0
	},
	"card_crimson_pulse": {
		"kind": "card",
		"ref": "crimson_pulse",
		"category": "cards",
		"buy": 210,
		"sell": 0
	},
	"card_desk_vault": {
		"kind": "card",
		"ref": "desk_vault",
		"category": "cards",
		"buy": 130,
		"sell": 0
	},
	"card_duel_draw": {
		"kind": "card",
		"ref": "duel_draw",
		"category": "cards",
		"buy": 140,
		"sell": 0
	},
	"card_emergency_tape": {
		"kind": "card",
		"ref": "emergency_tape",
		"category": "cards",
		"buy": 150,
		"sell": 0
	},
	"card_final_trump": {
		"kind": "card",
		"ref": "final_trump",
		"category": "cards",
		"buy": 260,
		"sell": 0
	},
	"card_focus_lens": {
		"kind": "card",
		"ref": "focus_lens",
		"category": "cards",
		"buy": 175,
		"sell": 0
	},
	"card_silent_library": {
		"kind": "card",
		"ref": "silent_library",
		"category": "cards",
		"buy": 195,
		"sell": 0
	},
	"card_tag_assist": {
		"kind": "card",
		"ref": "tag_assist",
		"category": "cards",
		"buy": 210,
		"sell": 0
	},
	"material_common": {
		"kind": "item",
		"ref": "material_common",
		"category": "materials",
		"buy": 12,
		"sell": 6
	},
	"material_fine": {
		"kind": "item",
		"ref": "material_fine",
		"category": "materials",
		"buy": 35,
		"sell": 17
	},
	"material_rare": {
		"kind": "item",
		"ref": "material_rare",
		"category": "materials",
		"buy": 90,
		"sell": 45
	},
	"drink": {
		"kind": "item",
		"ref": "drink",
		"category": "supplies",
		"buy": 45,
		"sell": 20
	}
}
const CATEGORIES := {"cards":"行动卡","materials":"练习素材","supplies":"饮品补给"}

static func definition(id: String) -> Dictionary:
	if not PRODUCTS.has(id): return {}
	var row: Dictionary = PRODUCTS[id].duplicate(true)
	row["id"] = id
	if row["kind"] == "card":
		var card: CardData = GameState.get_card(row["ref"])
		if card == null: return {}
		row["name"] = card.name
		row["description"] = card.get_dynamic_description()
		row["icon"] = SceneSkin.card_illustration_path(row["ref"])
		row["owned"] = 1 if GameState.unlocked_card_ids.has(row["ref"]) else 0
	else:
		var item := ItemCatalog.definition(row["ref"])
		row.merge(item,true)
		row["category"] = PRODUCTS[id]["category"]
		row["owned"] = GameState.get_inventory_quantity(row["ref"])
	return row

const REGION_SHOPS := {"university_nomos":"nomos_shop_test","university_arete":"shop","university_agora":"agora_shop_test","university_techne":"techne_shop_test","region_failed_alliance":"region_failed_alliance_shop_test","region_iga_church":"region_iga_church_shop_test"}

static func is_shop_location(id: String) -> bool:
	var region := CampusLife.current_region
	return id != "" and str(REGION_SHOPS.get(region,"shop" if region == "campus" else "")) == id and RegionCatalog.is_unlocked(region) and RegionCatalog.owns_place(region,id)

static func quote(id: String, quantity: Variant, mode: String) -> Dictionary:
	var result := {"ok":false,"message":"请选择有效商品","total":0,"quantity":0,"product":{}}
	var product := definition(id)
	if product.is_empty() or not GameState._whole_number(quantity) or int(quantity) < 1 or int(quantity) > 99 or mode not in ["buy","sell"]: return result
	result["product"] = product
	result["quantity"] = int(quantity)
	if not is_shop_location(CampusLife.current_location) or GameState.exploration_active or SceneManager.is_transitioning or DayCycle.has_story():
		result["message"] = "请到当前地区已开放的商店办理交易"
		return result
	if product["kind"] == "card" and (mode != "buy" or int(quantity) != 1 or product["owned"] > 0):
		result["message"] = "这张卡已拥有" if product["owned"] > 0 else "行动卡只能购买一张，不可回收"
		return result
	result["total"] = int(product[mode])*int(quantity)
	if mode == "buy" and GameState.energy_crystals < result["total"]:
		result["message"] = "零用钱不足"
		return result
	if mode == "sell" and (int(product["sell"]) <= 0 or int(product["owned"]) < int(quantity)):
		result["message"] = "可回收数量不足"
		return result
	if (mode == "buy" and product["kind"] == "item" and int(product["owned"]) > 999999-int(quantity)) or (mode == "sell" and GameState.energy_crystals > 999999-int(result["total"])):
		result["message"] = "已达到持有上限"
		return result
	result["ok"] = true
	result["message"] = "确认购买" if mode == "buy" else "确认回收"
	return result

static func valid_receipts(value: Variant) -> bool:
	if not value is Dictionary or value.size() > 128: return false
	for id in value:
		if not id is String or id.strip_edges() == "" or id.length() > 120 or not value[id] is bool or value[id] != true: return false
	return true
