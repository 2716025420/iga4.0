class_name ExplorationContent
extends RefCounted

const MATERIAL_NAMES := {"common": "普通材料", "fine": "精良材料", "rare": "稀有材料"}
const DUNGEONS: Array[Dictionary] = [
	{"id": "campus_basic", "title": "校园练习场", "difficulty": "初阶", "tier": 1, "quality": "common", "description": "沿着校园练习路线，整理一份日常材料。"},
	{"id": "campus_advanced", "title": "校园巡查线", "difficulty": "进阶", "tier": 2, "quality": "fine", "description": "完成更强的巡查挑战，收集精良材料。"},
	{"id": "campus_expert", "title": "校园综合挑战", "difficulty": "高阶", "tier": 3, "quality": "rare", "description": "完成高阶练习，带回稀有材料。"}
]

static func dungeon_definition(dungeon_id: String) -> Dictionary:
	for definition in DUNGEONS:
		if definition["id"] == dungeon_id:
			return definition.duplicate(true)
	return {}

static func dungeon_catalog(story_flags: Dictionary, visited_nodes: Array) -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	for definition in DUNGEONS:
		var item: Dictionary = definition.duplicate(true)
		var tier: int = int(item["tier"])
		var unlocked: bool = tier == 1 or (tier == 2 and (visited_nodes.has("n_robot") or story_flags.get("chapter_1_completed", false))) or (tier == 3 and story_flags.get("chapter_1_completed", false))
		item["unlocked"] = unlocked
		item["lock_reason"] = "" if unlocked else ("继续推进第一章后开放" if tier == 2 else "完成第一章后开放")
		item["reward_quality"] = item["quality"]
		item["material_name"] = MATERIAL_NAMES[item["quality"]]
		item["reward_range"] = "%s · 练习点 %d–%d" % [item["material_name"], 12 * tier, 30 * tier]
		item["status"] = "ready" if unlocked else "locked"
		item["active"] = false
		item["resume"] = false
		output.append(item)
	return output

static func node_title(node_type: int) -> String:
	match node_type:
		MapNodeData.NodeType.BATTLE: return "日常练习"
		MapNodeData.NodeType.ELITE: return "强化练习"
		MapNodeData.NodeType.CHEST: return "物资补给"
		MapNodeData.NodeType.REST: return "树荫休整"
		MapNodeData.NodeType.EVENT: return "路边小事"
		MapNodeData.NodeType.BOSS: return "终点挑战"
	return "校园路线"

static func node_description(node_type: int) -> String:
	match node_type:
		MapNodeData.NodeType.BATTLE: return "完成一场练习，获得材料与练习点。"
		MapNodeData.NodeType.ELITE: return "挑战更强的练习对手，奖励也更丰厚。"
		MapNodeData.NodeType.CHEST: return "整理补给箱，带走一份材料。"
		MapNodeData.NodeType.REST: return "在树荫下歇一会儿，恢复体力。"
		MapNodeData.NodeType.EVENT: return "整理物资，或坐下来喝口水。"
		MapNodeData.NodeType.BOSS: return "完成最后一场挑战，为这条路线画上句号。"
	return "选好接下来要走的方向。"

static func node_reward(dungeon_id: String, node_type: int) -> Dictionary:
	var definition := dungeon_definition(dungeon_id)
	if definition.is_empty(): return {"scrap_metal": 0, "materials": {}}
	var tier: int = int(definition["tier"])
	var quality: String = definition["quality"]
	var points: int = 0
	var amount: int = 0
	match node_type:
		MapNodeData.NodeType.BATTLE: points = 12 * tier; amount = 3 if tier == 1 else 1
		MapNodeData.NodeType.ELITE: points = 20 * tier; amount = 4 if tier == 1 else (2 if tier == 2 else 1)
		MapNodeData.NodeType.CHEST: points = 4 * tier; amount = 3 + tier
		MapNodeData.NodeType.EVENT: points = 6 * tier; amount = 1 + tier
		MapNodeData.NodeType.BOSS: points = 30 * tier; amount = 6 if tier == 1 else (3 if tier == 2 else 2)
	var materials: Dictionary = {}
	if amount > 0: materials[quality] = amount
	return {"scrap_metal": points, "materials": materials}

static func generate_nodes(dungeon_id: String, run_seed: int, run_id: int) -> Array[Dictionary]:
	var definition := dungeon_definition(dungeon_id)
	if definition.is_empty(): return []
	var random := RandomNumberGenerator.new()
	random.seed = run_seed
	var tier: int = int(definition["tier"])
	var patterns: Array = [
		[MapNodeData.NodeType.BATTLE, MapNodeData.NodeType.CHEST],
		[MapNodeData.NodeType.REST, MapNodeData.NodeType.BATTLE],
		[MapNodeData.NodeType.EVENT, MapNodeData.NodeType.ELITE],
		[MapNodeData.NodeType.BATTLE, MapNodeData.NodeType.CHEST],
		[MapNodeData.NodeType.ELITE, MapNodeData.NodeType.REST]
	]
	var nodes: Array[Dictionary] = []
	for layer in range(6):
		var types: Array = [MapNodeData.NodeType.BOSS] if layer == 5 else patterns[layer].duplicate()
		if layer < 5 and random.randi_range(0, 1) == 1: types.reverse()
		for branch in range(types.size()):
			var node_type: int = int(types[branch])
			var next_ids: Array[String] = []
			if layer < 5:
				for next_branch in range(1 if layer == 4 else 2):
					next_ids.append("x_%d_%d_%d" % [run_id, layer + 1, next_branch])
			var enemy_keys: Array[String] = []
			if node_type == MapNodeData.NodeType.BATTLE:
				enemy_keys.append("practice_guard" if random.randi_range(0, 1) == 0 else "practice_robot")
			elif node_type == MapNodeData.NodeType.ELITE:
				enemy_keys.append("practice_robot")
				if tier == 3: enemy_keys.append("practice_guard")
			elif node_type == MapNodeData.NodeType.BOSS:
				enemy_keys.append("practice_core")
			var reward := node_reward(dungeon_id, node_type)
			var choices: Array[Dictionary] = []
			if node_type == MapNodeData.NodeType.EVENT:
				choices = [{"id": "organize", "title": "整理物资", "description": "带走一份材料，也积累少量练习点。", "reward": reward.duplicate(true), "heal": 0}, {"id": "rest", "title": "喝水歇会儿", "description": "恢复 24 点体力，再慢慢出发。", "reward": {"scrap_metal": 4 * tier, "materials": {}}, "heal": 24}]
			nodes.append({"id": "x_%d_%d_%d" % [run_id, layer, branch], "layer": layer, "branch": branch, "type": node_type, "title": node_title(node_type), "description": node_description(node_type), "next": next_ids, "enemy_keys": enemy_keys, "reward": reward, "heal": 35 if node_type == MapNodeData.NodeType.REST else 0, "choices": choices})
	return nodes

static func enemy_specs(dungeon_id: String, node: Dictionary) -> Array[Dictionary]:
	var definition := dungeon_definition(dungeon_id)
	if definition.is_empty(): return []
	var tier: int = int(definition["tier"])
	var node_type: int = int(node.get("type", MapNodeData.NodeType.BATTLE))
	var output: Array[Dictionary] = []
	var keys: Array = node.get("enemy_keys", [])
	for index in range(keys.size()):
		var key: String = keys[index]
		var is_boss: bool = node_type == MapNodeData.NodeType.BOSS
		var is_elite: bool = node_type == MapNodeData.NodeType.ELITE
		var visual_id: String = "security_guard" if key == "practice_guard" else "campus_robot"
		var name: String = "巡查练习员" if key == "practice_guard" else ("训练机核心" if is_boss else "巡逻机器人")
		var attack: int = 12 + 2 * tier + (4 if is_elite else 0)
		var hp: int = 42 + 18 * tier + (30 if is_elite else 0)
		if key != "practice_guard": hp += 12
		if is_boss: hp = 90 + 40 * tier; attack = 12 + 3 * tier
		var spec := {"id": "%s_%d" % [key, index], "name": name, "title": "校园练习", "rank": EnemyData.EnemyRank.BOSS if is_boss else (EnemyData.EnemyRank.ELITE if is_elite else EnemyData.EnemyRank.NORMAL), "max_hp": hp, "base_atk": attack, "visual_id": visual_id, "sprite_path": "res://assets/sprites/enemies/phase_two/%s.png" % visual_id, "skills": [{"name": "稳步拦截", "type": "attack", "damage": attack}, {"name": "防守姿态", "type": "defend", "shield": 6 + 4 * tier}], "actions_per_turn": 2 if is_boss else 1, "has_phase_two": is_boss, "phase_two_hp_threshold": 0.5, "phase_two_skill": {"name": "连续拦截", "type": "attack", "damage": attack + 4 + tier}}
		output.append(spec)
	return output

static func reward_text(reward: Dictionary) -> String:
	var pieces: Array[String] = []
	var points: int = int(reward.get("scrap_metal", 0))
	if points > 0: pieces.append("练习点 +%d" % points)
	var materials: Dictionary = reward.get("materials", {})
	for quality in ["common", "fine", "rare"]:
		var amount: int = int(materials.get(quality, 0))
		if amount > 0: pieces.append("%s +%d" % [MATERIAL_NAMES[quality], amount])
	return " · ".join(pieces) if not pieces.is_empty() else "本次为休整，不获得永久材料。"
