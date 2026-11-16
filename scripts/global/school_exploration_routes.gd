class_name SchoolExplorationRoutes
extends RefCounted

const NORMAL_DEPTHS := 6
const PATTERNS: Array = [
	["battle", "story", "npc", "chest"],
	["rest", "merchant", "battle", "chest"],
	["elite", "story", "npc", "battle"],
	["chest", "rest", "battle", "merchant"],
	["story", "elite", "npc", "chest"],
	["battle", "merchant", "rest", "elite"]
]
const TITLES := {"battle": "巡查练习", "elite": "强化练习", "story": "拾到的留言", "npc": "路上的同学", "merchant": "训练联络点", "chest": "物资补给箱", "rest": "树荫下的长椅", "boss": "终点训练机", "exit": "通往校门的出口"}
const DESCRIPTIONS := {"battle": "前方有练习对手。准备好行动卡，再靠近。", "elite": "更强的练习对手守在这里，奖励也更丰厚。", "story": "读一读同学的留言，放松心情，恢复6点体力。", "npc": "有位同学正在整理散落的资料，也许可以帮忙。", "merchant": "核对训练记录，休息片刻，恢复8点体力。", "chest": "使用训练补给恢复24点体力；永久材料来自战斗。", "rest": "坐下来歇一会儿，恢复体力。", "boss": "出口前的最后一场挑战，所有路线在这里汇合。", "exit": "前方已经安全了。带着这一趟的收获回去。"}

static func node_type(kind: String) -> int:
	match kind:
		"battle": return MapNodeData.NodeType.BATTLE
		"elite": return MapNodeData.NodeType.ELITE
		"story": return MapNodeData.NodeType.STORY
		"chest": return MapNodeData.NodeType.CHEST
		"rest": return MapNodeData.NodeType.REST
		"boss": return MapNodeData.NodeType.BOSS
	return MapNodeData.NodeType.EVENT

static func kind_for(node: Dictionary) -> String:
	if node.has("kind"): return str(node["kind"])
	match int(node.get("type", -1)):
		MapNodeData.NodeType.BATTLE: return "battle"
		MapNodeData.NodeType.ELITE: return "elite"
		MapNodeData.NodeType.CHEST: return "chest"
		MapNodeData.NodeType.REST: return "rest"
		MapNodeData.NodeType.BOSS: return "boss"
		MapNodeData.NodeType.STORY: return "story"
	return "npc"

static func generate(dungeon_id: String, run_seed: int, run_id: int) -> Array[Dictionary]:
	var definition := ExplorationContent.dungeon_definition(dungeon_id)
	var nodes: Array[Dictionary] = []
	if definition.is_empty(): return nodes
	var random := RandomNumberGenerator.new()
	random.seed = run_seed
	var tier: int = definition["tier"]
	var quality: String = definition["quality"]
	for depth in range(NORMAL_DEPTHS + 2):
		var kinds: Array = ["boss"] if depth == NORMAL_DEPTHS else (["exit"] if depth == NORMAL_DEPTHS + 1 else PATTERNS[depth].duplicate())
		for index in range(kinds.size() - 1, 0, -1):
			var other := random.randi_range(0, index)
			var held: Variant = kinds[index]
			kinds[index] = kinds[other]
			kinds[other] = held
		for branch in kinds.size():
			var kind: String = kinds[branch]
			var type := node_type(kind)
			var enemies: Array[String] = []
			if kind == "battle": enemies.append("practice_guard" if random.randi_range(0, 1) == 0 else "practice_robot")
			elif kind == "elite":
				enemies.append("practice_robot")
				if tier == 3: enemies.append("practice_guard")
			elif kind == "boss": enemies.append("practice_core")
			var reward := ExplorationContent.node_reward(dungeon_id, type)
			var choices: Array[Dictionary] = []

			if kind == "exit": reward = {"scrap_metal":0, "materials":{}}

			var next: Array[String] = []
			if depth < NORMAL_DEPTHS + 1:
				for next_branch in range(4 if depth < NORMAL_DEPTHS - 1 else 1):
					next.append("r2_%d_%d_%d" % [run_id, depth + 1, next_branch])
			nodes.append({"id": "r2_%d_%d_%d" % [run_id, depth, branch], "layer": depth, "branch": branch, "type": type, "kind": kind, "title": TITLES[kind], "description": DESCRIPTIONS[kind], "next": next, "enemy_keys": enemies, "reward": reward, "heal": {"rest":35, "chest":24, "story":6, "merchant":8}.get(kind,0), "choices": choices})
	for index in nodes.size(): nodes[index] = normalize_support_node(nodes[index])
	return nodes

static func normalize_support_node(source: Dictionary) -> Dictionary:
	var node := source.duplicate(true)
	var kind := kind_for(node)
	if kind not in ["chest", "story", "npc", "merchant", "rest"]: return node
	node["reward"] = {"scrap_metal":0, "materials":{}}
	node["description"] = DESCRIPTIONS[kind]
	node["heal"] = {"rest":35, "chest":24, "story":6, "merchant":8}.get(kind,0)
	if kind == "npc":
		node["choices"] = [{"id":"help", "title":"一起整理", "description":"整理行装后一起休息，恢复18点体力。", "reward":node["reward"].duplicate(true), "heal":18}, {"id":"talk", "title":"坐下聊聊", "description":"和同学聊聊近路，恢复18点体力。", "reward":node["reward"].duplicate(true), "heal":18}]
	return node

static func dialogue_lines(node: Dictionary) -> Array[Dictionary]:
	var variants: Array[Array] = [
		[
			{"speaker": "叶舟", "char": "ye_zhou", "side": "left", "text": "路牌下面压着一张纸条。字写得很大：别着急，先看看周围。"},
			{"speaker": "叶舟", "char": "ye_zhou", "side": "left", "text": "背面画着通往校门的小箭头，还标出了附近的补给。像是先走过的同学留下的。"},
			{"speaker": "叶舟", "char": "ye_zhou", "side": "left", "text": "把纸条放回去吧。下一位路过的人，也许会用得上。", "emotion": "happy"}
		],
		[
			{"speaker": "杨子英", "char": "yang_zi_ying", "side": "right", "emotion": "happy", "text": "咦，长椅缝里夹着一张拍立得废片——构图还挺稳的嘛！"},
			{"speaker": "叶舟", "char": "ye_zhou", "side": "left", "emotion": "neutral", "text": "背面写着「红月升起前记得留足冷却 1 的轻型手牌」，是三年级摄影社前辈的笔记。"},
			{"speaker": "杨子英", "char": "yang_zi_ying", "side": "right", "emotion": "happy", "text": "我也把今天拍到的晴天樱枝塞一张在旁边，算作交换留念吧！"}
		],
		[
			{"speaker": "柳宇龙", "char": "liu_yu_long", "side": "right", "emotion": "happy", "text": "看这栏杆上的划痕编号——去年校内淘汰赛我也在这拐角卡过一次卡组！"},
			{"speaker": "叶舟", "char": "ye_zhou", "side": "left", "emotion": "neutral", "text": "下面贴了张终端便利贴：「别把两张重冷却牌在同一回合砸空」。"},
			{"speaker": "柳宇龙", "char": "liu_yu_long", "side": "right", "emotion": "neutral", "text": "哈哈，说得挺对。稳住防线再打反击才是最痛快的赢法！"}
		],
		[
			{"speaker": "姜梓", "char": "jiang_zi", "side": "right", "emotion": "neutral", "text": "巡逻终端留下了一页纸质巡检备忘，纸角压着半截蓝墨印章。"},
			{"speaker": "叶舟", "char": "ye_zhou", "side": "left", "emotion": "worried", "text": "上面写着「旧园南侧信号时有盲区，经过时务必保持个人终端处于护盾待机」。"},
			{"speaker": "姜梓", "char": "jiang_zi", "side": "right", "emotion": "neutral", "text": "看来早在这次事件前，校内就已经有人察觉到了外部频率的异常。"}
		],
		[
			{"speaker": "叶舟", "char": "ye_zhou", "side": "left", "emotion": "neutral", "text": "自动售货机侧面贴着一张橘子味糖纸折的小星星，底下有一行铅笔字。"},
			{"speaker": "叶舟", "char": "ye_zhou", "side": "left", "emotion": "happy", "text": "「给路过的二年级同学：紧张的时候记得深呼吸，冷却回合总会转回来的。」"}
		],
		[
			{"speaker": "叶舟", "char": "ye_zhou", "side": "left", "emotion": "neutral", "text": "旧公园秋千旁的告示栏角上，订着一份褪色的「六地区交流赛」旧赛程单。"},
			{"speaker": "杨子英", "char": "yang_zi_ying", "side": "right", "emotion": "happy", "text": "听说诺莫斯那边的赛场整棵包在巨树树冠里，以后真能去看看就好了。"}
		],
		[
			{"speaker": "叶舟", "char": "ye_zhou", "side": "left", "emotion": "neutral", "text": "石阶缝里吹来半张撕碎的草稿纸，画着十二星座符号旁边的一个小太阳。"},
			{"speaker": "叶舟", "char": "ye_zhou", "side": "left", "emotion": "neutral", "text": "旁注写着：「真正难模拟的从来不是算法参数，而是犹豫之后的决定。」"}
		],
		[
			{"speaker": "柳宇龙", "char": "liu_yu_long", "side": "right", "emotion": "neutral", "text": "看墙根那罐喝空的苏打水拉环，旁边用粉笔写着：今天护盾测试满分！"},
			{"speaker": "叶舟", "char": "ye_zhou", "side": "left", "emotion": "happy", "text": "把易拉罐顺手投进分类桶里，感觉呼吸也跟着轻松了些。"}
		]
	]
	var raw_id: String = str(node.get("id", "note"))
	var idx: int = 0 if int(node.get("layer", 0)) == 0 else (1 + abs(raw_id.hash()) % (variants.size() - 1))
	var picked: Array = variants[idx]
	var out: Array[Dictionary] = []
	for line in picked:
		out.append((line as Dictionary).duplicate(true))
	return out
